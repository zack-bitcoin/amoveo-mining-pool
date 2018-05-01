
-module(amoveo_mining_pool_app).
-behaviour(application).
-export([start/2, stop/1]).
start(_StartType, _StartArgs) ->
    inets:start(),
    start_http(),
    spawn(fun() ->
                  timer:sleep(1000),
                  mining_pool_server:start_cron()
          end),
    amoveo_mining_pool_sup:start_link().
stop(_State) -> ok.
start_http() ->
    Dispatch =
        cowboy_router:compile(
          [{'_', [{"/:file", file_handler, []},
		  {"/work/", http_handler, []},
		  {"/", http_handler, []}
		 ]}]),
    {ok, Port} = application:get_env(amoveo_mining_pool, port),
    {ok, _} = cowboy:start_http(
                http, 100,
                [{ip, {0, 0, 0, 0}}, {port, Port}],
                [{env, [{dispatch, Dispatch}]}]),
    ok.
    
