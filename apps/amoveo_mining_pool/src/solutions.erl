-module(solutions).
-behaviour(gen_server).
-export([start_link/0,code_change/3,handle_call/3,handle_cast/2,handle_info/2,init/1,terminate/2,
        found_solution/3, lookup/1]).
-define(File, "solutions.db").
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
save(X) -> file:write_file(?File, term_to_binary(X)).
start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, ok, []).
code_change(_OldVsn, State, _Extra) -> {ok, State}.
terminate(_, _) -> io:format("died!"), ok.
handle_info(_, X) -> {noreply, X}.
handle_cast({found_solution, BlockHash, Height, Pubkey}, X) -> 
    case dict:find(BlockHash, X) of
        error ->
            X2 = remove_before(Height - 20, X),
            X3 = dict:store(BlockHash, {Pubkey, Height}, X2),
            save(X3),
            {noreply, X3};
        _ ->
            {noreply, X}
    end;
handle_cast(_, X) -> {noreply, X}.
handle_call({lookup, H}, _From, X) -> 
    {reply, dict:find(H, X), X};
handle_call(_, _From, X) -> {reply, X, X}.

remove_before(Height, D) ->
    dict:filter(fun(_, {_, Height2}) ->
                        Height2 > Height
                end, D).


found_solution(BlockHash, Height, Pubkey) ->
    <<_:256>> = BlockHash,
    <<_:520>> = Pubkey,
    gen_server:cast(?MODULE, {found_solution, BlockHash, Height, Pubkey}).

lookup(BlockHash) ->
    case gen_server:call(?MODULE, {lookup, BlockHash}) of
        error -> error;
        {ok, V} -> {ok, element(1, V)}
    end.
            
