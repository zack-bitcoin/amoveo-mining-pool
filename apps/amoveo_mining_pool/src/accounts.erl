-module(accounts).
-behaviour(gen_server).
-export([start_link/0,code_change/3,handle_call/3,handle_cast/2,handle_info/2,init/1,terminate/2,
	 give_share/1,got_reward/0,pay_veo/0,balance/1,
	 check/0, final_reward/0,
	 fix_total/0]).

-record(account, {pubkey, veo = 0, work = 1}).
-define(File, "account.db").
initial_state() ->
    Shares = config:rt() * 
	round(math:pow(2, config:share_block_ratio())),
    D2 = dict:store(total, Shares, dict:new()),
    A = #account{pubkey = config:pubkey(),
		 work = Shares},
    store(A, D2).
init(ok) -> 
    A = case file:read_file(?File) of
	    {error, enoent} -> initial_state();
	    {ok, B} ->
		case B of
		    "" -> initial_state();
		    _ -> binary_to_term(B)
		end
	end,
    {ok, A}.
save(X) -> file:write_file(?File, term_to_binary(X)).
start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, ok, []).
code_change(_OldVsn, State, _Extra) -> {ok, State}.
terminate(_, _) -> io:format("died!"), ok.
handle_info(_, X) -> {noreply, X}.
handle_cast(fix_total, X) -> 
    Keys = dict:fetch_keys(X),
    Total = sum_total(Keys, X),
    X2 = dict:store(total, Total, X),
    {noreply, X2};
handle_cast({give_share, Pubkey}, X) -> 
    %if someone gives us valid work, then give their account a share.
    X2 = case dict:find(Pubkey, X) of
	     error ->
		 A = #account{pubkey = Pubkey},
		 store(A, X);
	     {ok, B} ->
		 B2 = B#account{work = B#account.work + 1},
		 store(B2, X)
	 end,
    Total = dict:fetch(total, X2),
    X3 = dict:store(total, Total+1, X2),
    save(X3),
    {noreply, X3};
handle_cast({pay, Limit}, X) -> 
    %reduce how many veo they have in the pool, pay them veo on the blockchain.
    X2 = pay_internal(dict:fetch_keys(X), X, Limit),
    save(X2),
    {noreply, X2};
handle_cast(reward, X) -> 
    %change shares into veo.
    TotalShares = dict:fetch(total, X),
    X2 = if 
	     TotalShares < 1 -> X;
	     true ->
		 {MT, MB} = config:miner_reward(),
		 Pay = config:block_reward()*(MB - MT) div MB,
		 PayPerShare = Pay div TotalShares,
		 Keys = dict:fetch_keys(X),
		 gr2(Keys, PayPerShare, X)
	 end,
    save(X2),
    {noreply, X2};
handle_cast(_, X) -> {noreply, X}.
handle_call({balance, Pubkey}, _From, X) -> 
    B = dict:find(Pubkey, X),
    {reply, B, X};
handle_call(_, _From, X) -> {reply, X, X}.

check() -> gen_server:call(?MODULE, check).
fix_total() -> gen_server:cast(?MODULE, fix_total).
balance(Pubkey) -> gen_server:call(?MODULE, {balance, Pubkey}).
give_share(Pubkey) -> gen_server:cast(?MODULE, {give_share, Pubkey}).
got_reward() -> gen_server:cast(?MODULE, reward).
pay_veo() -> gen_server:cast(?MODULE, {pay, config:payout_limit()}).
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
    V = H#account.veo,
    W = H#account.work,
    {RT, RB} = config:ratio(),
    A = H#account{work = W * RT div RB, veo = V + (PPS * W)},
    D2 = store(A, D),
    gr2(T, PPS, D2).
pay_internal([], X, _) -> X;
pay_internal([total|T], X, L) -> pay_internal(T, X, L);
pay_internal([K|T], X, Limit) ->
    H = dict:fetch(K, X),
    V = H#account.veo,
    Pubkey = H#account.pubkey,
    B = V > Limit,
    X2 = if
	     B -> spawn(fun() ->
				Msg = {spend, Pubkey, V},
				talker:talk_helper(Msg, config:full_node(), 10)
			end),
		  A2 = H#account{veo = 0},
		  store(A2, X);
	     true -> X
	 end,
    pay_internal(T, X2, Limit).
store(A, D) ->
    dict:store(A#account.pubkey, A, D).


sum_total([], _) -> 0;
sum_total([total|T], D) -> sum_total(T, D);
sum_total([H|T], D) ->
    A = dict:fetch(H, D),
    A#account.work + sum_total(T, D).
