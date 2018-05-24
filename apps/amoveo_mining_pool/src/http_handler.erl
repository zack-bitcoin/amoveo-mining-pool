
-module(http_handler).
-export([init/3, handle/2, terminate/3, doit/1]).
init(_Type, Req, _Opts) -> {ok, Req, no_state}.
terminate(_Reason, _Req, _State) -> ok.
handle(Req, State) ->
    {ok, Data0, Req2} = cowboy_req:body(Req),
    {{_IP, _}, Req3} = cowboy_req:peer(Req2),
    %io:fwrite("http handler got message: "),
    %io:fwrite(Data0),
    %io:fwrite("\n"),
    Data1 = jiffy:decode(Data0),
    Data2 = case Data1 of
		[<<"mining_data">>, PubkeyWithWorkerID] ->
		    {Pubkey, WorkerID} = pub_split(PubkeyWithWorkerID),
		    [<<"mining_data">>, Pubkey, WorkerID];
		[<<"work">>, Nonce, PubkeyWithWorkerID] ->
		    {Pubkey, WorkerID} = pub_split(PubkeyWithWorkerID),
		    [<<"work">>, Nonce, Pubkey, WorkerID];
		_ -> Data1
	    end,
    Data = packer:unpack_helper(Data2),
    case Data of
	{work, _, _} ->
	    %io:fwrite("work from IP "),
	    %io:fwrite(packer:pack(IP)),
	    %io:fwrite("\n"),
	    %io:fwrite(Data0),
	    %io:fwrite("\n"),
	    ok;
	_ -> ok
    end,
    D0 = doit(Data),
    D = packer:pack(D0),
    Headers=[{<<"content-type">>,<<"application/octet-stream">>},
    {<<"Access-Control-Allow-Origin">>, <<"*">>}],
    {ok, Req4} = cowboy_req:reply(200, Headers, D, Req3),
    {ok, Req4, State}.
doit({account, 2}) ->
    D = accounts:check(),%duplicating the database here is no good. It will be slow if there are too many accounts.
    {ok, dict:fetch(total, D)};
doit({account, Pubkey}) -> 
    accounts:balance(Pubkey);
doit({mining_data, _, 0}) -> 
    %{ok, [Hash, Nonce, Diff]}
    mining_pool_server:problem_api_mimic();
doit({mining_data}) -> 
    mining_pool_server:problem_api_mimic();
doit({mining_data, Pubkey, Worker}) ->
    X = workers:check(Pubkey, Worker),
    {ok, X};
doit({work, Nonce, Pubkey}) ->
    mining_pool_server:receive_work(Nonce, Pubkey, none);
doit({work, Nonce, Pubkey, WorkerID}) ->
    mining_pool_server:receive_work(Nonce, Pubkey, WorkerID).
    
pub_split(<<Pubkey:704>>) ->
    {<<Pubkey:704>>, 0};
pub_split(PubkeyWithWorkerID) ->
    <<Pubkey:704, _, ID/binary>> = 
	PubkeyWithWorkerID,
    {<<Pubkey:704>>, base64:encode(ID)}.
