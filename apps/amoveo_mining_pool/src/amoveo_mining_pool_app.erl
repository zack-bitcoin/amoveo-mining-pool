%%%-------------------------------------------------------------------
%% @doc amoveo_mining_pool public API
%% @end
%%%-------------------------------------------------------------------

-module(amoveo_mining_pool_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
    start_http(),
    %spawn(fun() ->
    %              timer:sleep(1000),
    mining_pool_server:start_cron(),
    %      end),
    amoveo_mining_pool_sup:start_link().

%%--------------------------------------------------------------------
stop(_State) ->
    ok.

%%====================================================================
%% Internal functions
%%====================================================================
start_http() ->
    Dispatch =
        cowboy_router:compile(
          [{'_', [%{"/:file", ext_file_handler, []},
                  {"/", http_handler, []}
                 ]}]),
    {ok, Port} = application:get_env(ae_core, port),
    {ok, _} = cowboy:start_http(
                http, 100,
                [{ip, {0, 0, 0, 0}}, {port, Port}],
                [{env, [{dispatch, Dispatch}]}]),
    ok.
    
