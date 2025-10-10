-module(to_pay).
-behaviour(gen_server).
-export([start_link/0,code_change/3,handle_call/3,handle_cast/2,handle_info/2,init/1,terminate/2,
erase/0, add/1, lookup/0]).
-define(File, "to_pay.db").
initial_state() -> [].
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
handle_cast(erase, X) -> 
    X2 = [],
    save(X2),
    {noreply, X2};
handle_cast({add, Pub}, X) -> 
    X2 = [Pub|X],
    save(X2),
    {noreply, X2};
handle_cast(_, X) -> {noreply, X}.
handle_call(lookup, _From, X) -> {reply, X, X};
handle_call(_, _From, X) -> {reply, X, X}.

erase() ->
    gen_server:cast(?MODULE, erase).
add(Pub) ->
    gen_server:cast(?MODULE, {add, Pub}).
lookup() ->
    gen_server:call(?MODULE, lookup).
