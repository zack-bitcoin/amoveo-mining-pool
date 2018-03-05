-module(http_handler).
-export([init/3, handle/2, terminate/3, doit/1]).
init(_Type, Req, _Opts) -> {ok, Req, no_state}.
terminate(_Reason, _Req, _State) -> ok.
handle(Req, State) ->
    {ok, Data0, Req2} = cowboy_req:body(Req),
    {{IP, _}, Req3} = cowboy_req:peer(Req2),
    io:fwrite("from IP "),
    io:fwrite(packer:pack(IP)),
    io:fwrite("\n"),
    Data = packer:unpack(Data0),
    D0 = doit(Data),
    D = packer:pack(D0),
    Headers=[{<<"content-type">>,<<"application/octet-stream">>},
    {<<"Access-Control-Allow-Origin">>, <<"*">>}],
    {ok, Req4} = cowboy_req:reply(200, Headers, D, Req3),
    {ok, Req4, State}.
%doit({problem}) -> 
%    mining_pool_server:problem();
doit({mining_data}) -> 
    mining_pool_server:problem_api_mimic();
doit({work, Nonce, Pubkey}) ->
    mining_pool_server:receive_work(Nonce, Pubkey).
    
