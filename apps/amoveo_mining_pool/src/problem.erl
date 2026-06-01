%this is to remember what is the problem currently being mined.

-module(problem).
-behaviour(gen_server).
-export([start_link/0,code_change/3,handle_call/3,handle_cast/2,handle_info/2,init/1,terminate/2,
         check/0, update/2]).
-record(d, {problem, difficulty}).
init(ok) -> 
    {ok, [Problem, _, Difficulty]} = packer:unpack(talker:talk_helper({mining_data}, config:full_node(), 10000)),
    {ok, #d{problem = Problem, difficulty = Difficulty}}.
start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, ok, []).
code_change(_OldVsn, State, _Extra) -> {ok, State}.
terminate(_, _) -> io:format("died!"), ok.
handle_info(_, X) -> {noreply, X}.
handle_cast({update, Problem, Difficulty}, _) -> 
    {noreply, #d{problem = Problem, difficulty = Difficulty}};
handle_cast(_, X) -> {noreply, X}.
handle_call(check, _From, X) -> 
    {reply, {X#d.problem, X#d.difficulty}, X};
handle_call(_, _From, X) -> {reply, X, X}.

check() ->
    gen_server:call(?MODULE, check).

update(Problem, Difficulty) ->
    <<_:256>> = Problem,
    gen_server:cast(?MODULE, {update, Problem, Difficulty}).
