-module(amoveo_mining_pool_sup).
-behaviour(supervisor).
%% API
-export([start_link/0]).
-export([init/1]).
-define(SERVER, ?MODULE).
%-define(keys, [mining_pool_server, accounts, rewards, rewards_pusher, bad_work, hashpower_leaders]).
-define(keys, [mining_pool_server, accounts, rewards, rewards_pusher, bad_work, hashpower_leaders, reward_tracker]).
start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).
child_maker([]) -> [];
child_maker([H|T]) -> [?CHILD(H, worker)|child_maker(T)].
init([]) ->
    Workers = child_maker(?keys),
    {ok, { {one_for_one, 50000, 1}, Workers} }.

%%====================================================================
%% Internal functions
%%====================================================================
