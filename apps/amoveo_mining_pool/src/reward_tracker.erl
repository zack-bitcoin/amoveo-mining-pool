-module(reward_tracker).
-behaviour(gen_server).
-export([start_link/0,code_change/3,handle_call/3,handle_cast/2,handle_info/2,init/1,terminate/2,
         did_work/2, new_block/1, save/0]).

-record(r, {pub, hash, paid = false}).
-record(h, {rs = []}).

-define(File, "reward_tracker.db").

initial_state() -> dict:new().

init(ok) -> 
    A = case file:read_file(?File) of
	    {error, enoent} -> initial_state();
	    {ok, B} ->
		case B of
		    "" -> initial_state();
		    _ -> D = binary_to_term(B),
                         D
		end
	end,
    {ok, A}.


save_internal(X) -> file:write_file(?File, term_to_binary(X)).
start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, ok, []).
code_change(_OldVsn, State, _Extra) -> {ok, State}.
terminate(_, X) -> 
    io:format("reward tracker died!"),
    save_internal(X),
    ok.
handle_info(_, X) -> {noreply, X}.
handle_cast({did_work, Pub, Hash}, X) -> 
    io:fwrite("reward tracker did work\n"),
    V1 = case dict:find(Hash, X) of
             error -> #h{};
             {ok, V = #h{}} -> V
         end,
    V2 = add(Pub, Hash, V1),
    X2 = dict:store(Hash, V2, X),
    {noreply, X2};
handle_cast({new_block, Hash}, X) -> 
    X2 = case dict:find(Hash, X) of
        error -> 
                 io:fwrite("we did not find that block\n"),
                 X;
        {ok, H = #h{rs = Rs}} -> 
                 io:fwrite("block was mined by us\n"),
                 Rs2 = pay_if_exists(Rs, Hash),
                 Hs2 = H#h{rs = Rs2},
                 dict:store(Hash, Hs2, X)
         end,
    {noreply, X2};
handle_cast(save, X) -> 
    save_internal(X),
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

save() ->
    gen_server:cast(?MODULE, save).
