-module(config).
-compile(export_all).

%mode() -> production.
mode() -> test.

refresh_period() -> 2.%how often we get a new problem from the server to work on. in seconds
full_node() -> 
    case mode() of
	test ->
	    "http://localhost:3011/";%useful for testing by connecting to `make multi-quick` mode in the amoveo full node.
	 production ->
	    "http://localhost:8081/"
    end.
share_block_ratio() -> 1.
spend_log_file() -> "spend.log".
