-module(reward_tracker).
-behaviour(gen_server).
-export([start_link/0,code_change/3,handle_call/3,handle_cast/2,handle_info/2,init/1,terminate/2,
         did_work/2, new_block/1]).

-record(r, {pub, hash, paid = false}).
-record(h, {rs = []}).

init(ok) -> {ok, []}.
start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, ok, []).
code_change(_OldVsn, State, _Extra) -> {ok, State}.
terminate(_, _) -> io:format("died!"), ok.
handle_info(_, X) -> {noreply, X}.
handle_cast({did_work, Pub, Hash}, X) -> 
    V2 = case dict:find(Hash, X) of
             error -> #h{};
             {ok, V = #h{}} -> add(Pub, Hash, V)
         end,
    X2 = dict:store(Hash, V2, X),
    {noreply, X};
handle_cast({new_block, Hash}, X) -> 
    io:fwrite("reward tracker, new block \n"),
    X2 = case dict:find(Hash, X) of
        error -> X;
        {ok, H = #h{rs = Rs}} -> 
                 Rs2 = pay_if_exists(Rs, Hash),
                 Hs2 = H#h{rs = Rs2},
                 dict:store(Hash, Hs2, X)
         end,
    {noreply, X};
handle_cast(_, X) -> {noreply, X}.
handle_call(_, _From, X) -> {reply, X, X}.

pay_if_exists([], _) -> [];
pay_if_exists([R = #r{pub = Pub, hash = Hash, paid = false}|T], Hash) -> 
    pay(Pub),
    [R#r{paid = true}|T];
pay_if_exists([H|T], Hash) -> 
    R = pay_if_exists(T, Hash),
    [R|pay_if_exists(T, Hash)].

add(Pub, Hash, H) ->
    B = is_in(Hash, H#h.rs),
    if
        B -> H;
        true -> 
            R = H#h.rs,
            H#h{rs = [#r{hash = Hash, pub = Pub}|R]}
    end.

pay(Pubkey) ->
    io:fwrite("reward tracker, make payment\n"),
    BlockReward = 10382390,
    V = BlockReward * 5 div 6,
    {ok, Height} = packer:unpack(talker:talk_helper({height, 1}, config:full_node(), 3)),
    A = V - config:tx_fee(),
    S = binary_to_list(base64:encode(Pubkey)) ++ " amount: " ++ integer_to_list(A) ++ " height: " ++ integer_to_list(Height) ++ "\n",
    file:write_file(config:spend_log_file(), S, [append]),
    Msg = {spend, Pubkey, A},
    talker:talk_helper(Msg, config:full_node(), 10).
    

is_in(Hash, []) -> false;
is_in(Hash, [R = #r{hash = Hash}|_]) -> true;
is_in(Hash, [_|T]) -> 
    is_in(Hash, T).

did_work(Pub, Hash) ->
    gen_server:cast(?MODULE, {did_work, Pub, Hash}).

new_block(Hash) ->
    gen_server:cast(?MODULE, {new_block, Hash}).
