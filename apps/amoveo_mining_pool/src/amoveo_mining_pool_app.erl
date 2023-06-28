
-module(amoveo_mining_pool_app).
-behaviour(application).
-export([start/2, stop/1]).
start(_StartType, _StartArgs) ->
    inets:start(),
    start_http(),
    mining_pool_server:start_cron(),
    %accounts:save_cron(),%switched to the strategy where we do this every time we find a block.
    hashpower_leaders:cron(),
    amoveo_mining_pool_sup:start_link().
stop(_State) -> ok.
start_http() ->
    Dispatch =
        cowboy_router:compile(
          [{'_', [
		  {"/work/", http_handler, []},
		  {"/:file", file_handler, []},
		  {"/", http_handler, []}
		 ]}]),
    {ok, Port} = application:get_env(amoveo_mining_pool, port),
    IP = {0,0,0,0},
    %{ok, _} = cowboy:start_http(
    %            http, 100,
    %            [{ip, IP}, {port, Port}],
    %            [{env, [{dispatch, Dispatch}]}]),
    {ok, _} = cowboy:start_clear(
                http, [{ip, IP}, {port, Port}],
                #{env => #{dispatch => Dispatch}}),
    ok.
    
