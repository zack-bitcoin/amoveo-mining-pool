-module(rewards_pusher).
-behaviour(gen_server).
-export([start_link/0,code_change/3,handle_call/3,handle_cast/2,handle_info/2,init/1,terminate/2]).
-export([new_height/0]).

init(ok) -> {ok, []}.
start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, ok, []).
code_change(_OldVsn, State, _Extra) -> {ok, State}.
terminate(_, _) -> io:format("died!"), ok.
handle_info(_, X) -> {noreply, X}.
handle_cast(new_height, X) -> 
    new_height_internal(),
    {noreply, X};
handle_cast(_, X) -> {noreply, X}.
handle_call(_, _From, X) -> {reply, X, X}.
new_height() ->
    gen_server:cast(?MODULE, new_height).
new_height_internal() -> 
    {ok, H} = packer:unpack(talker:talk_helper({height, 1}, config:full_node(), 3)),
    Confs = config:confirmations(),
    H2 = H - (2*Confs),
    %Old = rewards:check(),
    if 
	(H2 > 0) ->
	    {ok, ServerPub} = packer:unpack(talker:talk_helper({pubkey}, config:full_node(), 3)),
	    %{ok, Blocks} = packer:unpack(talker:talk_helper({blocks, 4, H2, H2 + Confs}}, config:full_node(), 3)),
            %blocks is a list of blocks. H2 is the starting height, H is the ending height of the range.
	    pay_rewards2(H2, H2+Confs, ServerPub);
	    %pay_rewards(Blocks, ServerPub),
	    %rewards:update(H2);
	true -> ok
    end.
pay_rewards(B, _ServerPub) when is_binary(B) -> 
    io:fwrite("rewards pusher got a binary instead of a list of blocks."),
    ok;
pay_rewards([], _ServerPub) -> 
    accounts:pay_veo();
pay_rewards([H|T], ServerPub) ->
    Txs = element(11, H),
    case Txs of
        [] -> io:fwrite("block 0\n");
        _ -> 
            CB = hd(Txs),
            Pub = base64:encode(element(2, CB)),
            if
                Pub == ServerPub -> accounts:got_reward();
                true -> ok
            end
    end,
    pay_rewards(T, ServerPub).
    
pay_rewards2(A, B, _ServerPub) when A > B -> ok;
pay_rewards2(Start, End, ServerPub) ->
    Hash = talker:talk_helper({block_hash, Start}, config:full_node(), 3),
    reward_tracker:new_block(Hash),
    pay_rewards2(Start + 1, End, ServerPub).
