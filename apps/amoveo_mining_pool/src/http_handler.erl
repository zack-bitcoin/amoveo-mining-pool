-module(http_handler).
-export([init/3, handle/2, terminate/3, doit/1]).
init(_Type, Req, _Opts) -> {ok, Req, no_state}.
terminate(_Reason, _Req, _State) -> ok.
handle(Req, State) ->
    {ok, Data0, Req2} = cowboy_req:body(Req),
    {{IP, _}, Req3} = cowboy_req:peer(Req2),
    %io:fwrite("http handler got message: "),
    %io:fwrite(Data0),
    %io:fwrite("\n"),
    case bad_work:check(IP) of
	bad -> 
	    io:fwrite("ignore bad work\n"),
	    {ok, {ok, 0}, State};
	ok ->
	    Data1 = jiffy:decode(Data0),
	    Data2 = case Data1 of
			[<<"mining_data">>, PubkeyWithWorkerID] ->
						%{Pubkey, WorkerID} = pub_split(PubkeyWithWorkerID),
			    [<<"mining_data">>, 0];
			[<<"work">>, NonceAA, PubkeyWithWorkerID] ->
			    {Pubkey, WorkerID} = pub_split(PubkeyWithWorkerID),
			    [<<"work">>, NonceAA, Pubkey];
			_ -> Data1
		    end,
	    Data = packer:unpack_helper(Data2),

						%Data = packer:unpack(Data0),
	    D0 = case Data of
		     {work, Nonce, Pubkey22} ->
			 mining_pool_server:receive_work(Nonce, Pubkey22, IP);
		     _ -> doit(Data)
		 end,
						%D0 = doit(Data),
	    D = packer:pack(D0),
	    Headers=[{<<"content-type">>,<<"application/octet-stream">>},
		     {<<"Access-Control-Allow-Origin">>, <<"*">>}],
	    {ok, Req4} = cowboy_req:reply(200, Headers, D, Req3),
	    {ok, Req4, State}
    end.
doit({account, 2}) ->
    D = accounts:check(),%duplicating the database here is no good. It will be slow if there are too many accounts.
    {ok, dict:fetch(total, D)};
doit({account, Pubkey}) -> 
    accounts:balance(Pubkey);
doit({mining_data, _}) -> 
    {ok, [Hash, Nonce, Diff]} = 
	mining_pool_server:problem_api_mimic(),
    {ok, [Hash, Diff, Diff]};
doit({mining_data}) -> 
    mining_pool_server:problem_api_mimic().
%doit({work, Nonce, Pubkey}) ->
    %io:fwrite("attempted work \n"),
%    mining_pool_server:receive_work(Nonce, Pubkey, IP).
    

pub_split(<<Pubkey:704>>) ->
    {<<Pubkey:704>>, 0};
pub_split(PubkeyWithWorkerID) ->
    <<Pubkey:704, _, ID/binary>> = 
	PubkeyWithWorkerID,
    {<<Pubkey:704>>, base64:encode(ID)}.
