-module(hashpower_leaders).
-behaviour(gen_server).
-export([start_link/0,code_change/3,handle_call/3,handle_cast/2,handle_info/2,init/1,terminate/2,
        update/3, read/0, cron/0]).

-define(size, 50). %how many miners to include on the leader board.

-record(db, {rank = [], power = dict:new(), min_for_entry = 0}).
-record(acc, {pub, share_rate = 0, timestamp = {0,0,0}}).

init(ok) -> {ok, #db{}}.
start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, ok, []).
code_change(_OldVsn, State, _Extra) -> {ok, State}.
terminate(_, _) -> io:format("died!"), ok.
handle_info(_, X) -> {noreply, X}.
handle_cast({update, Pub, ShareRate, TimeStampNow}, X) -> 
    #db{rank = R, min_for_entry = M} = X,

    X2 = 
        if
            ShareRate < M -> 
                %not enough hashpower to be included in the leader board.
                X;
            true ->
                R2 = remove_rank(Pub, R),
                R3 = add_new_to_rank(Pub, ShareRate, TimeStampNow, R2),
                X#db{rank = R3}
        end,
    {noreply, X2};
handle_cast(clean, X) -> 
    #db{rank = R0} = X,
    %remove anyone who hasn't found shares in the last 1000 minutes.
    R = lists:filter(fun(#acc{timestamp = TS}) ->
                             abs(timer:now_diff(erlang:now(), TS)) < 
                                 (1000000 * 60 * 1000)
                     end, R0),
    %remove anyone who isn't in the top ?size.
    L = length(R),
    X2 = if
             (L > ?size) ->
                 Remove = L - ?size,
                 {_, R2} = lists:split(Remove, R),
                 X#db{rank = R2, 
                      min_for_entry = (hd(R2))#acc.share_rate};
             true -> X#db{rank = R}
         end,
    {noreply, X2};
handle_cast(_, X) -> {noreply, X}.
handle_call(read, _From, X) -> 
    {reply, X#db.rank, X};
handle_call(_, _From, X) -> {reply, X, X}.


add_new_to_rank(Pub, ShareRate, Now, []) ->
    NA = #acc{pub = Pub, share_rate = ShareRate, timestamp = Now},
    [NA];
add_new_to_rank(Pub, ShareRate, Now, [A=#acc{share_rate = SR}|R]) 
  when ShareRate > SR ->
    [A|add_new_to_rank(Pub, ShareRate, Now, R)];
add_new_to_rank(Pub, ShareRate, Now, [A|R]) ->
    NA = #acc{pub = Pub, share_rate = ShareRate, timestamp = Now},
    [A|[NA|R]].

remove_rank(Pub, []) -> [];
remove_rank(Pub, [#acc{pub = Pub}|T]) -> T;
remove_rank(Pub, [A|T]) -> 
    [A|remove_rank(Pub, T)].
    


update(Pub, ShareRate, TimeStampNow) ->
    gen_server:cast(?MODULE, {update, Pub, ShareRate, TimeStampNow}).

read() ->
    X = gen_server:call(?MODULE, read),
    lists:map(fun({acc, Pub, SR, _}) ->
                      [Pub, SR]
              end, X).
    

cron() ->
    %clean every minute.
    gen_server:cast(?MODULE, clean),
    spawn(fun() ->
                  timer:sleep(60000),
                  io:fwrite("hashpower leaders cron\n"),
                  cron()
          end).
