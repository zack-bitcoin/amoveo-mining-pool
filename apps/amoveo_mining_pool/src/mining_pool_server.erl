-module(mining_pool_server).
-behaviour(gen_server).
-export([start_link/0,code_change/3,handle_call/3,handle_cast/2,handle_info/2,init/1,terminate/2,
        start_cron/0, problem_api_mimic/0, receive_work/3]).
-record(data, {hash, nonce, diff, time}).
%init(ok) -> {ok, new_problem_internal()}.
init(ok) -> {ok, new_problem_internal()}.
start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, ok, []).
code_change(_OldVsn, State, _Extra) -> {ok, State}.
terminate(_, _) -> io:format("died!"), ok.
handle_info(_, X) -> {noreply, X}.
handle_cast(new_problem_cron, Y) -> 
    N = time_now(),
    T = Y#data.time,
    RP = config:refresh_period(),
    X = if 
            (((N-T) > RP) or ((N-T) < 0)) -> 
		case new_problem_internal() of
		    ok -> Y;
		    Z -> Z
		end;
            true -> Y
        end,
    {noreply, X};
handle_cast(_, X) -> {noreply, X}.
handle_call(problem, _From, X) -> 
    {reply, X, X};
handle_call(new_problem, _From, Y) -> 
    X = case new_problem_internal() of
	    ok -> Y;
	    Z -> Z
	end,
    {reply, X, X};
handle_call(_, _From, X) -> {reply, X, X}.
time_now() ->
    element(2, now()).
new_problem_internal() ->
    Data = {mining_data},
    case talker:talk_helper(Data, config:full_node(), 10000) of
	ok -> new_problem_internal();
	X ->
	    {ok, [F, S, Third]} = packer:unpack(X),
	    #data{hash = F, nonce = S, diff = Third, time = time_now()}
    end.
problem() -> gen_server:call(?MODULE, problem).
problem_api_mimic() -> 
    %looks the same as amoveo api.
    %io:fwrite("give them a problem\n"),
    D = problem(),
    Hash = D#data.hash,
    Nonce = D#data.nonce,
    Diff = easy_diff(D#data.diff),
    {ok, [Hash, Nonce, Diff]}.
new_problem() -> gen_server:call(?MODULE, new_problem).
start_cron() ->
    spawn(fun() -> 
		  start_cron2() 
	  end).
		  
start_cron2() ->
    %This checks every 0.1 seconds, to see if it is time to get a new problem.
    %We get a new problem every ?RefreshPeriod.
    timer:sleep(500),
    gen_server:cast(?MODULE, new_problem_cron),
    start_cron2().
receive_work(<<Nonce:184>>, Pubkey, IP) ->
    %io:fwrite("mining pool server receive work\n"),
    %Pubkey = base64:decode(Pubkey0),
    D = problem(),
    H = D#data.hash,
    Diff = D#data.diff,
    EasyDiff = easy_diff(D#data.diff),
    %io:fwrite(packer:pack({recent_work, H, Diff, Nonce})),
    %io:fwrite("\n"),
    Y = <<H/binary, Nonce:184>>,
    I = pow:hash2integer(hash:doit(Y), 1),
    if
	I > EasyDiff -> 
	    %io:fwrite("found share\n"),
	    accounts:give_share(Pubkey),
	    if 
		I > Diff -> 
		    io:fwrite("found block 000\n"),
		    found_block(<<Nonce:184>>),
		    io:fwrite("found block\n"),
		    io:fwrite(packer:pack({recent_work, H, Diff, Nonce})),
		    io:fwrite("\n"),
		    "found block";
		true -> 
		    "found work"
	    end;
	true ->
	    bad_work:received(IP),
	    "invalid work"
    end.
found_block(<<Nonce:184>>) ->
    %BinNonce = base64:encode(<<Nonce:184>>),
    Data = {work, <<Nonce:184>>, 0},
    _X = talker:talk_helper(Data, config:full_node(), 10),%spend 8 seconds checking 5 times per second if we can start mining again.
    %accounts:got_reward(),
    %accounts:pay_veo(),
    spawn(fun() ->
		  timer:sleep(1000),
		  new_problem()
	  end),
    ok.
easy_diff(D) ->
    max(257, D - (256 * config:share_block_ratio())).
