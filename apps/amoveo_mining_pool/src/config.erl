-module(config).
-compile(export_all).

%full_node() -> "http://localhost:3011/".%useful for testing by connecting to `make multi-quick` mode in the amoveo full node.
full_node() -> "http://localhost:8081/".
miner_reward() -> {2, 100}.
block_reward() -> 100000000.
pubkey() -> 
    <<4,40,221,150,68,202,200,88,123,4,28,120,130,178,212,24,
     82,66,121,217,179,163,135,180,93,61,74,38,214,210,194,
     174,111,8,145,235,62,91,71,1,48,126,153,166,126,62,119,
     35,157,251,237,244,43,2,112,143,81,159,91,206,249,243,
     203,33,94>>.
share_block_ratio() -> 11.%so if this is 4, that means we pay 16 shares for every block we find on average. if it is 10, then we pay 1024 shares for every block we find.
rt() -> 9.%rewards are smoothed out over the last rt()+1 blocks.
ratio() -> {rt(), rt()+1}.
tx_fee() -> 152000.%when you shut off the pool, it pays out to everyone who has more than this much veo.
payout_limit() -> 50000000.%when you have more than this much veo, it automatically pays out to you.
refresh_period() -> 2.%how often we get a new problem from the server to work on. in seconds
