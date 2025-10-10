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
    %io:fwrite("http handler got message: "),
    %io:fwrite(Data0),
    %io:fwrite("\n"),
    Data1 = jiffy:decode(Data0),
    Data2 = case Data1 of
                [<<"mining_data">>, _PubkeyWithWorkerID] ->
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
    D0 = case Data of
             {work, Nonce, Pubkey22} ->
                 receive_work(Nonce, Pubkey22, IP);
             _ -> doit(Data)
         end,
    E = packer:pack(D0),
    Headers = #{ <<"content-type">> => <<"application/octet-stream">>,
	       <<"Access-Control-Allow-Origin">> => <<"*">>},
    Req4 = cowboy_req:reply(200, Headers, E, Req),
    {ok, Req4, State}.

doit({mining_data, _}) -> 
    {Problem, Diff} = problem:check(),
    {ok, [Problem, Diff, Diff]};

%    {ok, [Hash, Nonce, Diff]} = 
%	mining_pool_server:problem_api_mimic(),
%    {ok, [Hash, Diff, Diff]};
doit({mining_data}) -> 
    {Problem, Diff} = problem:check(),
    {ok, [Problem, crypto:strong_rand_bytes(23), Diff]};
    %mining_pool_server:problem_api_mimic();

doit({status}) ->
    ok.


pub_split(<<Pubkey:704>>) ->
    {<<Pubkey:704>>, 0};
pub_split(PubkeyWithWorkerID) ->
    <<Pubkey:704, _, ID/binary>> = 
	PubkeyWithWorkerID,
    {<<Pubkey:704>>, base64:encode(ID)}.

receive_work(Nonce0, Pubkey, IP) ->
    io:fwrite("received work \n"),
    Nonce = case Nonce0 of
                <<X:184>> -> X;
                <<X:256>> -> X
            end,
    {Problem, Diff} = problem:check(),
    Y = <<Problem/binary, Nonce:184>>,
    I = pow:hash2integer(hash:doit(Y), 1),
    if
        I > Diff ->
            io:fwrite("work was valid. found block\n"),
            Height = height:check(),
            solutions:found_solution(Problem, Height, Pubkey),
            Data = {work, <<Nonce:184>>, 0},
            _X = talker:talk_helper(Data, config:full_node(), 10),
            ok;
        true ->
            ok
    end.
