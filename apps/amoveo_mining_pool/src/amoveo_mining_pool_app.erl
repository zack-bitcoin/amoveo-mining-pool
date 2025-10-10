-module(amoveo_mining_pool_app).
-behaviour(application).
-export([start/2, stop/1]).

-define(reward, 8551991).

start(_StartType, _StartArgs) ->
    inets:start(),
    start_http(),
    spawn(fun() -> new_block_cron() end),
    amoveo_mining_pool_sup:start_link().
stop(_State) -> ok.
start_http() ->
    Dispatch =
        cowboy_router:compile(
          [{'_', [
		  {"/work/", http_handler, []},
		  {"/:file", file_handler, []},
		  {"/", http_handler, []}
		 ]}]),
    {ok, Port} = application:get_env(amoveo_mining_pool, port),
    IP = {0,0,0,0},
    {ok, _} = cowboy:start_clear(
                http, [{ip, IP}, {port, Port}],
                #{env => #{dispatch => Dispatch}}),
    ok.
    
new_block_cron() ->
    timer:sleep(3000),
    spawn(fun() ->
                  new_block_cron2()
          end),
    new_block_cron().
new_block_cron2() ->
    %{ok, ServerPub} = packer:unpack(talker:talk_helper({pubkey}, config:full_node(), 3)),
    {ok, H} = packer:unpack(talker:talk_helper({height, 1}, config:full_node(), 3)),%block:height().
    MH = height:check(),
    height:update(H),
    {ok, [Problem, _Random, Difficulty]} = packer:unpack(talker:talk_helper({mining_data}, config:full_node(), 10000)),
    problem:update(Problem, Difficulty),
    if
        (MH == 0) ->
            %if we are restarting the node, don't immediately send a payment, because maybe we already payed for this height.
            ok;
        (H > MH) ->
            %a new block was found.
            io:fwrite("new block was found\n"),

            {ok, BlockHash_5} = packer:unpack(talker:talk_helper({block_hash, 2, H-5}, config:full_node(), 3)),
            case solutions:lookup(hash:doit(BlockHash_5)) of
                error -> ok; %we didnt' mine that block
                {ok, Miner} ->
                    to_pay:add(Miner)
            end,
            if
                (0 == (H rem 10)) -> 
                    io:fwrite("time to pay\n"),
                    case to_pay:lookup() of
                        [] -> ok;
                        PayList ->
                            PayList2 = packer:pack(paylist_condenser(PayList)),
                    %[{Amount, Pubkey}|T]
                            {ok, Tx} = talker:talk_helper({spend, PayList2}, config:full_node(), 3),
                            file:write_file(config:spend_log_file(), binary_to_list(packer:pack(Tx)) ++ "\n", [append]),
                            ok
                    end;
                true -> ok
            end;
        true -> %no new block found. nothing to do.
            ok
    end.
   
paylist_condenser(L) ->
    D2 = lists:foldl(fun(Account, D) -> 
                             case dict:find(Account, D) of
                                 error -> dict:store(?reward, Account, D);
                                 {ok, V} -> dict:store(?reward+V, Account, D)
                             end
                     end, dict:new(), L),
    Ks = dict:fetch_keys(D2),
    lists:map(fun(K) ->
                      {dict:fetch(K, D2), K}
              end, Ks).
