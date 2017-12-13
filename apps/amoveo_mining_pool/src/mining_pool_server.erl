-module(mining_pool_server).
-behaviour(gen_server).
-export([start_link/0,code_change/3,handle_call/3,handle_cast/2,handle_info/2,init/1,terminate/2]).
-define(FullNode, "http://localhost:8081/").
-record(data, {hash, nonce, diff, time}).
init(ok) -> {ok, request_new_problem()}.
start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, ok, []).
code_change(_OldVsn, State, _Extra) -> {ok, State}.
terminate(_, _) -> io:format("died!"), ok.
handle_info(_, X) -> {noreply, X}.
handle_cast(_, X) -> {noreply, X}.
handle_call(problem, _From, X) -> {reply, X, X};
handle_call(new_problem, _From, _) -> 
    X = request_new_problem(),
    {reply, X, X};
handle_call(_, _From, X) -> {reply, X, X}.

problem() -> gen_server:call(?MODULE, problem).
receive_work(Work, Pubkey) ->
    D = problem(),
    %if the work is good enough, give some money to pubkey.
    %if the work is good enough, try to make a block.
    % if we made a block, then we need to get a new problem
    ok.
request_new_problem() ->
    Data = <<"[\"mining_data\"]">>,
    R = talk_helper(Data, ?Peer, 10),
    {F, S, Third} = unpack_mining_data(R),
    X = #data{hash = F, nonce = S, diff = Third, time = now()}.
found_block(<<Nonce:256>>) ->
    BinNonce = base64:encode(<<Nonce:256>>),
    Data = << <<"[\"mining_data\",\"">>/binary, BinNonce/binary, <<"\"]">>/binary>>,
    talk_helper(Data, ?Peer, 40),%spend 8 seconds checking 5 times per second if we can start mining again.
    ok.
    
talk_helper2(Data, Peer) ->
    httpc:request(post, {Peer, [], "application/octet-stream", iolist_to_binary(Data)}, [{timeout, 3000}], []).
talk_helper(Data, Peer, N) ->
    if 
        N == 0 -> 
            io:fwrite("cannot connect to server"),
            1=2;
        true -> 
            case talk_helper2(Data, Peer) of
                {ok, {_Status, _Headers, []}} ->
                    timer:sleep(200),
                    talk_helper(Data, Peer, N - 1);
                {ok, {_, _, R}} -> R;
                _ -> io:fwrite("\nYou need to turn on and sync your Amoveo node before you can mine. You can get it here: https://github.com/zack-bitcoin/amoveo \n"),
                     1=2
            end
    end.
slice(Bin, Char) ->
    slice(Bin, Char, 0).
slice(Bin, Char, N) ->
    NN = N*8,
    <<First:NN, Char2:8, Second/binary>> = Bin,
    if
        N > size(Bin) -> 1=2;
        (Char == Char2) ->
            {<<First:NN>>, Second};
        true ->
            slice(Bin, Char, N+1)
    end.
unpack_mining_data(R) ->
    <<_:(8*11), R2/binary>> = list_to_binary(R),
    {First, R3} = slice(R2, hd("\"")),
    <<_:(8*2), R4/binary>> = R3,
    {Second, R5} = slice(R4, hd("\"")),
    <<_:8, R6/binary>> = R5,
    {Third, _} = slice(R6, hd("]")),
    F = base64:decode(First),
    S = base64:decode(Second),
    {F, S, Third}.
