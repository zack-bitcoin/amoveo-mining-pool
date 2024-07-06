-module(accounts).
-behaviour(gen_server).
-export([start_link/0,code_change/3,handle_call/3,handle_cast/2,handle_info/2,init/1,terminate/2,
	 give_share/1,got_reward/0,pay_veo/0,balance/1,
	 check/0, final_reward/0,pay_veo/1,
	 fix_total/0, total_veo/0, save_cron/0,
         new_share_rate/2,
	 save/0]).

-record(account, {pubkey, veo = 0, work = 1}).
-record(account2, {pubkey, veo = 0, work = 1, share_rate = 0, timestamp = {0,0,0}}).
-define(File, "account.db").

-define(smoothing, 200).%when calculating your hash rate, how many shares do we average over.



initial_state() ->
    SBR = config:share_block_ratio(),
    case SBR of
        1 ->
            D2 = dict:store(total, 1, dict:new()),
            A = #account2{pubkey = base64:decode(config:pubkey()),
                          work = 1},
            store(A, D2)
        _ ->
            Shares = config:rt() * 
                round(math:pow(2, SBR)),
            D2 = dict:store(total, Shares, dict:new()),
            A = #account2{pubkey = base64:decode(config:pubkey()),
                          work = Shares},
            store(A, D2)
    end.


init(ok) -> 
    A = case file:read_file(?File) of
	    {error, enoent} -> initial_state();
	    {ok, B} ->
		case B of
		    "" -> initial_state();
		    _ -> D = binary_to_term(B),
                         dict:map(fun(K, V) -> 
                                          case V of 
                                              #account{} -> account_version_update(V);
                                              _ -> V
                                          end
                                  end,
                                  D)
		end
	end,
    {ok, A}.
save_internal(X) -> file:write_file(?File, term_to_binary(X)).
start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, ok, []).
code_change(_OldVsn, State, _Extra) -> {ok, State}.
terminate(_, X) -> 
    io:format("accounts died!"), 
    save_internal(X),
    ok.
handle_info(_, X) -> {noreply, X}.
handle_cast(fix_total, X) -> 
    Keys = dict:fetch_keys(X),
    Total = sum_total(Keys, X),
    X2 = dict:store(total, Total, X),
    {noreply, X2};
handle_cast({give_share, Pubkey}, X) -> 
    %if someone gives us valid work, then give their account a share.
    BadKey = <<191,197,254,165,198,23,127,233,11,201,164,214,208,94,
	      150,219,111,47,168,132,15,42,181,222,128,130,84,209,42,
	      21,159,133,171,228,66,24,80,231,135,27,10,59,2,19,110,
	      10,55,200,207,191,159,82,152,42,53,36,207,66,201,130,
	      127,26,98,121,228>>,
    if
	Pubkey == BadKey -> {noreply, X};
	true ->
            NewTS = erlang:now(),
	    A = case dict:find(Pubkey, X) of
		     error ->
			 #account2{pubkey = Pubkey, 
                                   timestamp = NewTS};
		     {ok, B = #account2{timestamp = TS, share_rate = SR}} ->
                        SR2 = new_share_rate(SR, TS),
                        hashpower_leaders:update(Pubkey, SR2, NewTS),
                        B#account2{work = B#account2.work + 1,
                                  timestamp = NewTS,
                                  share_rate = SR2}
		 end,
	    X2 = store(A, X),
	    Total = dict:fetch(total, X2),
	    X3 = dict:store(total, Total+1, X2),
	    %save_internal(X3),
	    {noreply, X3}
    end;
handle_cast({pay, Limit}, X) -> 
    %reduce how many veo they have in the pool, pay them veo on the blockchain.
    X2 = pay_internal(dict:fetch_keys(X), X, Limit),
    %save_internal(X2),
    {noreply, X2};
handle_cast({pay_single, Pubkey}, X) ->
    X3 = case dict:find(Pubkey, X) of
	     error -> X;
	     {ok, total} -> X;
	     {ok, _} ->
		 X2 = pay_internal([Pubkey], X, config:tx_fee()),
		 %save_internal(X2),
		 X2
	 end,
    {noreply, X3};
handle_cast(reward, X) -> 
    %change shares into veo.
    TotalShares = dict:fetch(total, X),
    X2 = if 
	     TotalShares < 1 -> X;
	     true ->
		 {MT, MB} = config:pool_reward(),
		 Pay = config:block_reward()*(MB - MT) div MB,
		 PayPerShare = Pay div TotalShares,
		 Keys = dict:fetch_keys(X),
		 gr2(Keys, PayPerShare, X)
	 end,
    %save_internal(X2),
    {noreply, X2};
handle_cast(save, X) ->
    save_internal(X),
    {noreply, X};
handle_cast(_, X) -> {noreply, X}.
handle_call(balance, _From, X) -> 
    K = dict:fetch_keys(X),
    Z = sum_balance(K, X),
    {reply, Z, X};
handle_call({balance, Pubkey}, _From, X) -> 
    B = dict:find(Pubkey, X),
    {reply, B, X};
handle_call(_, _From, X) -> {reply, X, X}.

check() -> gen_server:call(?MODULE, check).
fix_total() -> gen_server:cast(?MODULE, fix_total).
balance(Pubkey) -> gen_server:call(?MODULE, {balance, Pubkey}).
total_veo() -> gen_server:call(?MODULE, balance).
give_share(Pubkey) -> gen_server:cast(?MODULE, {give_share, Pubkey}).
got_reward() -> gen_server:cast(?MODULE, reward).
pay_veo() -> gen_server:cast(?MODULE, {pay, config:payout_limit()}).
pay_veo(Pubkey) -> gen_server:cast(?MODULE, {pay_single, Pubkey}).
save() -> gen_server:cast(?MODULE, save).
    
save_cron() ->
    spawn(fun() -> save_cron2() end).
save_cron2() ->
    timer:sleep(1000 * config:save_period()),
    save(),
    save_cron2().
		  

sum_balance([], _) -> 0;
sum_balance([total|T], X) -> sum_balance(T, X);
sum_balance([H|T], X) ->
    A = dict:fetch(H, X),
    A#account2.veo + sum_balance(T, X).
final_reward() ->
    pay_times(config:rt()),
    gen_server:cast(?MODULE, {pay, config:tx_fee()}).
pay_times(0) -> ok;
pay_times(N) ->
    pay_veo(),
    timer:sleep(500),
    pay_times(N-1).

gr2([], _, X) -> X;
gr2([total|T], PPS, D) -> 
    Total = dict:fetch(total, D),
    {RT, RB} = config:ratio(),
    Total2 = Total * RT div RB,
    D2 = dict:store(total, Total2, D),
    gr2(T, PPS, D2);
gr2([K|T], PPS, D) ->
    H = dict:fetch(K, D),
    V = H#account2.veo,
    W = H#account2.work,
    {RT, RB} = config:ratio(),
    A = H#account2{work = W * RT div RB, veo = V + (PPS * W)},
    D2 = store(A, D),
    gr2(T, PPS, D2).
pay_internal([], X, _) -> X;
pay_internal([total|T], X, L) -> pay_internal(T, X, L);
pay_internal([K|T], X, Limit) ->
    H = dict:fetch(K, X),
    V = H#account2.veo,
    Pubkey = H#account2.pubkey,
    B = V > Limit,
    X2 = if
	     B -> spawn(fun() ->
                                {ok, Height} = packer:unpack(talker:talk_helper({height, 1}, config:full_node(), 3)),
				A = V - config:tx_fee(),
				S = binary_to_list(base64:encode(Pubkey)) ++ " amount: " ++ integer_to_list(A) ++ " height: " ++ integer_to_list(Height) ++ "\n",
				file:write_file(config:spend_log_file(), S, [append]),
				Msg = {spend, Pubkey, A},
				talker:talk_helper(Msg, config:full_node(), 10)
			end),
		  timer:sleep(500),
		  A2 = H#account2{veo = 0},
		  store(A2, X);
	     true -> X
	 end,
    pay_internal(T, X2, Limit).
store(A, D) ->
    dict:store(A#account2.pubkey, A, D).


sum_total([], _) -> 0;
sum_total([total|T], D) -> sum_total(T, D);
sum_total([H|T], D) ->
    A = dict:fetch(H, D),
    A#account2.work + sum_total(T, D).

account_version_update(#account{pubkey = P, veo = V, work = W}) ->
    #account2{pubkey = P, veo = V, work = W}.

new_share_rate(OldRate, TimeStamp) ->
    TimeDiffMicros = 
        timer:now_diff(erlang:now(), TimeStamp),
    SharesPerHour = 
        round((60 * 60 * 1000000) / TimeDiffMicros),
    ((OldRate*(?smoothing - 1)) + 
         SharesPerHour) div 
        (?smoothing).
    
