-module(mining_pool_server).
-behaviour(gen_server).
-export([start_link/0,code_change/3,handle_call/3,handle_cast/2,handle_info/2,init/1,terminate/2,
        start_cron/0, problem_api_mimic/0, receive_work/3,
	check_solution/1, found_solution/1]).
-record(data, {hash, nonce, diff, time, solutions = dict:new()}).
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
		new_problem_internal();
            true -> Y
        end,
    {noreply, X};
handle_cast({found_solution, S}, Y) ->
    D2 = dict:store(S, 0, Y#data.solutions),
    Y2 = Y#data{solutions = D2},
    {noreply, Y2};
handle_cast(_, X) -> {noreply, X}.
handle_call({check_solution, S}, _, Y) ->
    X = case dict:find(S, Y#data.solutions) of
	    error -> true;
	    {ok, _} -> false
	end,
    {reply, X, Y};
handle_call(problem, _From, X) -> 
    {reply, X, X};
handle_call(new_problem, _From, Y) -> 
    X = new_problem_internal(),
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
%receive_work(<<Nonce:184>>, Pubkey, IP) ->
receive_work(Nonce0, Pubkey, IP) ->
    %io:fwrite("mining pool server receive work\n"),
    %Pubkey = base64:decode(Pubkey0),
    Nonce = case Nonce0 of
                <<X:184>> -> X;
                <<X:256>> -> X
            end,
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
	    true = check_solution(Nonce),
	    found_solution(Nonce),
	    io:fwrite("found share\n"),
            io:fwrite("nonce: "),
            io:fwrite(integer_to_list(Nonce)),
            io:fwrite("\n"),
            io:fwrite("pub: "),
            io:fwrite(integer_to_list(Pubkey)),
	    accounts:give_share(Pubkey),
            reward_tracker:did_work(Pubkey, H),
	    if 
		I > Diff -> 
		    %io:fwrite("found block 000\n"),
		    found_block(<<Nonce:184>>),
                    io:fwrite("found block\n"),
		    %io:fwrite(packer:pack({recent_work, H, Diff, Nonce, Pubkey})),
		    %io:fwrite("\n"),
                    accounts:save(),
		    {ok, "found block"};
		true -> 
		    {ok, "found work"}
	    end;
	true ->
            io:fwrite("bad work received\n"),
	    bad_work:received(IP),
	    {ok, "invalid work"}
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
check_solution(N) ->
    gen_server:call(?MODULE, {check_solution, N}).
found_solution(N) ->
    gen_server:cast(?MODULE, {found_solution, N}).
