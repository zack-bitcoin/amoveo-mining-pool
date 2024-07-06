-module(http_handler).
-export([init/3, init/2, handle/2, terminate/3, doit/1]).
init(_Type, Req, _Opts) -> {ok, Req, no_state}.
init(Req0, Opts) ->
    handle(Req0, Opts).	
terminate(_Reason, _Req, _State) -> ok.
handle(Req, State) ->
    %{ok, Data0, Req2} = cowboy_req:body(Req),
    {ok, Data0, _Req2} = cowboy_req:read_body(Req),
    %{{IP, _}, Req3} = cowboy_req:peer(Req2),
    {IP, _} = cowboy_req:peer(Req),
%    io:fwrite("http handler got message: "),
%    io:fwrite(Data0),
%    io:fwrite("\n"),
    E = case bad_work:check(IP) of
	    bad -> 
		io:fwrite("ignore bad work\n"),
		packer:pack({ok, 0});
	    ok ->
		Data1 = jiffy:decode(Data0),
		Data2 = case Data1 of
			    [<<"mining_data">>, PubkeyWithWorkerID] ->
						%{Pubkey, WorkerID} = pub_split(PubkeyWithWorkerID),
				[<<"mining_data">>, 0];
			    [<<"work">>, NonceAA, PubkeyWithWorkerID] ->
				{Pubkey, _WorkerID} = pub_split(PubkeyWithWorkerID),
				[<<"work">>, NonceAA, Pubkey];
			    _ -> Data1
			end,
		%io:fwrite("data 0 is "),
		%io:fwrite(Data0),
		%io:fwrite("\n"),
		Data = packer:unpack_helper(Data2),
		%Data = packer:unpack(Data0),
		D0 = case Data of
			 {work, Nonce, Pubkey22} ->
			     mining_pool_server:receive_work(Nonce, Pubkey22, IP);
			 _ -> doit(Data)
		     end,
		packer:pack(D0)
	end,
    Headers = #{ <<"content-type">> => <<"application/octet-stream">>,
	       <<"Access-Control-Allow-Origin">> => <<"*">>},
    Req4 = cowboy_req:reply(200, Headers, E, Req),
    {ok, Req4, State}.

doit({account, 2}) ->
    D = accounts:check(),%duplicating the database here is no good. It will be slow if there are too many accounts.
    {ok, dict:fetch(total, D)};
doit({account, Pubkey}) -> 
    accounts:balance(Pubkey);
doit({spend, SR}) ->
    spawn(
      fun() ->R = element(2, SR),
	      {27, Pubkey, Height} = R,
	      {ok, NodeHeight} = packer:unpack(talker:talk_helper({height}, config:full_node(), 10)),
	      true = NodeHeight < Height + 3,
	      true = NodeHeight > Height - 1,
	      Sig = element(3, SR),
	      true = sign:verify_sig(R, Sig, Pubkey),
	      accounts:pay_veo(Pubkey)
      end),
    {ok, 0};
doit({height}) ->
    {ok, NodeHeight} = packer:unpack(talker:talk_helper({height}, config:full_node(), 10)),
    {ok, NodeHeight};
doit({mining_data, _}) -> 
    {ok, [Hash, Nonce, Diff]} = 
	mining_pool_server:problem_api_mimic(),
    {ok, [Hash, Diff, Diff]};
doit({mining_data}) -> 
    mining_pool_server:problem_api_mimic();
doit({accounts}) -> 
    {ok, hashpower_leaders:read()}.
%doit({work, Nonce, Pubkey}) ->
    %io:fwrite("attempted work \n"),
%    mining_pool_server:receive_work(Nonce, Pubkey, IP).
    

pub_split(<<Pubkey:704>>) ->
    {<<Pubkey:704>>, 0};
pub_split(PubkeyWithWorkerID) ->
    <<Pubkey:704, _, ID/binary>> = 
	PubkeyWithWorkerID,
    {<<Pubkey:704>>, base64:encode(ID)}.
