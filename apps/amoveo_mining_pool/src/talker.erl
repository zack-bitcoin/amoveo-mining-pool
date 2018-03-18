-module(talker).
-export([talk_helper/3]).


talk_helper2(Data, Peer) ->
    D2 = iolist_to_binary(packer:pack(Data)),
    httpc:request(post, {Peer, [], "application/octet-stream", D2}, [{timeout, 3000}], []).
talk_helper(Data, Peer, N) ->
    if 
        N == 0 -> 
            io:fwrite("cannot connect to server\n"),
	    io:fwrite(packer:pack(Peer)),
	    io:fwrite(packer:pack(Data)),
	    timer:sleep(2000),
	    talk_helper(Data, Peer, 1);
            %1=2;
        true -> 
            case talk_helper2(Data, Peer) of
                {ok, {_Status, _Headers, []}} ->
		    io:fwrite("first failure  mode \n"),
                    timer:sleep(100),
                    talk_helper(Data, Peer, N - 1);
                {ok, {_, _, R}} -> R;
                {error, timeout} -> 
		    io:fwrite(packer:pack(Data)),
		    io:fwrite("timeout error\n"),
		    timer:sleep(500),
		    talk_helper(Data, Peer, N - 1);
                X -> 
		    io:fwrite(packer:pack(X)),
		    io:fwrite("\nYou need to turn on and sync your Amoveo node before you can mine. You can get it here: https://github.com/zack-bitcoin/amoveo \n"),
		    timer:sleep(1000),
		    talk_helper(Data, Peer, N - 1)
                    % 1=2
            end
    end.
