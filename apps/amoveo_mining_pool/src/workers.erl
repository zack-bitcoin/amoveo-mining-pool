-module(workers).
-behaviour(gen_server).
-export([start_link/0,code_change/3,handle_call/3,handle_cast/2,handle_info/2,init/1,terminate/2, 
	 check/2, give_share/2, test/0]).
-record(worker, {period0 = 1, period1 = 1, timestamp}).
init(ok) -> {ok, dict:new()}.
start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, ok, []).
code_change(_OldVsn, State, _Extra) -> {ok, State}.
terminate(_, _) -> io:format("died!"), ok.
handle_info(_, X) -> {noreply, X}.
handle_cast({give_share, Pubkey, WorkerID, Time}, X) -> 
    Key = {Pubkey, WorkerID},
    N = case dict:find(Key, X) of
	    error -> #worker{timestamp = Time};
	    {ok, W} ->
		Units = 1000,
		D0 = timer:now_diff(Time, W#worker.timestamp) div Units,%in seconds/1000
		D = max(D0, 600 * Units),%if the miner didn't find a share in 10 minute, then assume it is shut off.
		E0 = config:small_average(),
		E1 = config:big_average(),
		#worker{period0 = ((W#worker.period0 * (E0 - 1))+D) div E0,
			period1 = ((W#worker.period1 * (E1 - 1))+D) div E1,
			timestamp = Time}
	end,
    X2 = dict:store(Key, N, X),
    {noreply, X2};
handle_cast(_, X) -> {noreply, X}.
handle_call({check, Pubkey, WorkerID}, _From, X) -> 
    Key = {Pubkey, WorkerID},
    V = case dict:find(Key, X) of
	    error -> 0;
	    {ok, Y} -> {Y#worker.period0, Y#worker.period1}
	end,
    {reply, V, X};
handle_call(_, _From, X) -> {reply, X, X}.

check(Pubkey, WorkerID) ->
    gen_server:call(?MODULE, {check, Pubkey, WorkerID}).
give_share(Pubkey, WorkerID) ->
    gen_server:cast(?MODULE, {give_share, Pubkey, WorkerID, erlang:timestamp()}).

test() ->
    Pubkey = 0,
    WorkerID = 0,
    %give_share(Pubkey, WorkerID),
    %give_share(Pubkey, WorkerID),
    %give_share(Pubkey, WorkerID),
    %timer:sleep(1000),
    give_share(Pubkey, WorkerID),
    check(Pubkey, WorkerID).
    
