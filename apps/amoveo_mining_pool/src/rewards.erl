%This module keeps track of the current block height.
%It checks if we found a block CONFIRMATION blocks ago, and if we did, it pays out a reward like this:
    %accounts:got_reward(),
    %accounts:pay_veo(),
-module(rewards).
-behaviour(gen_server).
-export([start_link/0,code_change/3,handle_call/3,handle_cast/2,handle_info/2,init/1,terminate/2,
	check/0, update/1]).
-define(File, "rewards.db").
initial_state() -> 0.
init(ok) ->
    A = case file:read_file(?File) of
	    {error, enoent} -> initial_state();
	    {ok, B} ->
		case B of
		    "" -> initial_state();
		    _ -> binary_to_term(B)
		end
	end,
    spawn(fun() -> rewards_cron() end),
    {ok, A}.
save(X) -> file:write_file(?File, term_to_binary(X)).
start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, ok, []).
code_change(_OldVsn, State, _Extra) -> {ok, State}.
terminate(_, _) -> io:format("died!"), ok.
handle_info(_, X) -> {noreply, X}.
handle_cast({update, H}, X) -> 
    X2 = max(H, X),
    save(X2),
    {noreply, X2};
handle_cast(_, X) -> {noreply, X}.
handle_call(check, _From, X) -> {reply, X, X};
handle_call(_, _From, X) -> {reply, X, X}.

check() -> gen_server:call(?MODULE, check).
update(H) -> gen_server:cast(?MODULE, {update, H}).

rewards_cron() ->    
    %io:fwrite("rewards cron\n"),
    timer:sleep(2000),
    spawn(fun() -> rewards_pusher:new_height() end),
    rewards_cron().
    
