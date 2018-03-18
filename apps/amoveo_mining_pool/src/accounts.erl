-module(accounts).
-behaviour(gen_server).
-export([start_link/0,code_change/3,handle_call/3,handle_cast/2,handle_info/2,init/1,terminate/2,
	 give_share/1,got_reward/0,pay_veo/0,balance/1]).

-record(account, {pubkey, veo = 0, work = 1}).
-define(File, "account.db").
-define(LIMIT, 100000000).
init(ok) -> 
    A = case file:read_file(?File) of
	    {error, enoent} ->
		dict:store(total, 0, dict:new());
	    {ok, B} ->
		case B of
		    "" -> 
			dict:store(total, 0, dict:new());
		    _ ->
			binary_to_term(B)
		end
	end,
    {ok, A}.
save(X) -> file:write_file(?File, term_to_binary(X)).
start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, ok, []).
code_change(_OldVsn, State, _Extra) -> {ok, State}.
terminate(_, _) -> io:format("died!"), ok.
handle_info(_, X) -> {noreply, X}.
handle_cast({give_share, Pubkey}, X) -> 
    %if someone gives us valid work, then give their account a share.
    X2 = case dict:find(Pubkey, X) of
	     error ->
		 A = #account{pubkey = Pubkey},
		 dict:store(Pubkey, A, X);
	     {ok, B} ->
		 B2 = B#account{work = B#account.work + 1},
		 dict:store(Pubkey, B2, X)
	 end,
    Total = dict:fetch(total, X2),
    X3 = dict:store(total, Total+1, X2),
    {noreply, X3};
handle_cast(pay, X) -> 
    %reduce how many veo they have in the pool, pay them veo on the blockchain.
    X2 = pay_internal(dict:fetch_keys(X), X),
    {noreply, X2};
handle_cast(reward, X) -> 
    %change shares into veo.
    TotalShares = dict:fetch(total, X),
    X2 = if 
	     TotalShares < 1 -> X;
	     true ->
		 Pay = round(config:block_reward() * (1 - config:miner_reward())),
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

balance(Pubkey) -> gen_server:call(?MODULE, {balance, Pubkey}).
give_share(Pubkey) -> gen_server:cast(?MODULE, {give_share, Pubkey}).
got_reward() -> gen_server:cast(?MODULE, reward).
pay_veo() -> gen_server:cast(?MODULE, pay).

gr2([], _, X) -> dict:store(total, 0, X);
gr2([total|T], PPS, D) -> gr2(T, PPS, D);
gr2([K|T], PPS, D) ->
    H = dict:fetch(K, D),
    V = H#account.veo,
    W = H#account.work,
    A = H#account{work = 0, veo = V + (PPS * W)},
    D2 = dict:store(H#account.pubkey, A, D),
    gr2(T, PPS, D2).
pay_internal([], X) -> X;
pay_internal([total|T], X) -> pay_internal(T, X);
pay_internal([K|T], X) ->
    H = dict:fetch(K, X),
    V = H#account.veo,
    Pubkey = H#account.pubkey,
    B = V > ?LIMIT,
    X2 = if
	     B -> spawn(fun() ->
				Msg = {spend, Pubkey, V},
				talker:talk_helper(Msg, config:full_node(), 10)
			end),
		  A2 = H#account{veo = 0},
		  dict:store(A2#account.pubkey, A2, X);
	     true -> X
	 end,
    pay_internal(T, X2).
