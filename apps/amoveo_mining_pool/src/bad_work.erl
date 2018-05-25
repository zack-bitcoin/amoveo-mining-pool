-module(bad_work).
-behaviour(gen_server).
-export([start_link/0,code_change/3,handle_call/3,handle_cast/2,handle_info/2,init/1,terminate/2,
	check/1, received/1]).
init(ok) -> {ok, dict:new()}.
start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, ok, []).
code_change(_OldVsn, State, _Extra) -> {ok, State}.
terminate(_, _) -> io:format("died!"), ok.
handle_info(_, X) -> {noreply, X}.
handle_cast({r, T, IP}, X) -> 
    X2 = dict:store(IP, T, X),
    {noreply, X2};
handle_cast(_, X) -> {noreply, X}.
handle_call({check, IP}, _From, X) -> 
    {A, X2} = case dict:find(IP, X) of
		  error -> {ok, X};
		  {ok, T} ->
		      B = timer:now_diff(erlang:timestamp(), T),
		      if
			  B > 3000000 -> {ok, dict:erase(IP, X)};
			  true -> {bad, X}
		      end
	      end,
    {reply, A, X2};
handle_call(_, _From, X) -> {reply, X, X}.
received(IP) ->
    gen_server:cast(?MODULE, {r, erlang:timestamp(), IP}).
check(IP) ->
    gen_server:call(?MODULE, {check, IP}).
