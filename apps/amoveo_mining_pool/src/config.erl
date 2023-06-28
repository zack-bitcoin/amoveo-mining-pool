-module(config).
-compile(export_all).

%mode() -> production.
mode() -> test.
full_node() -> 
    case mode() of
	test ->
	    "http://localhost:3011/";%useful for testing by connecting to `make multi-quick` mode in the amoveo full node.
	 production ->
	    "http://localhost:8081/"
    end.
external() -> 
    X = full_node(),
    Y = lists:reverse(X),
    Z = [hd("/")|[hd("0")|tl(tl(Y))]],
    lists:reverse(Z).
pool_reward() -> {5, 100}.%this is the portion of the block reward that goes to the mining pool. It is a fraction {numerator, denominator}. for example {1, 9} would mean that 1/9th of the block reward is kept as a fee, and 8/9ths are paid to miners..
block_reward() -> 10382390.%40461210.%64139933.%100227592.
pubkey() -> "BCjdlkTKyFh7BBx4grLUGFJCedmzo4e0XT1KJtbSwq5vCJHrPltHATB+maZ+Pncjnfvt9CsCcI9Rn1vO+fPLIV4=". %Initially, this pubkey controls all the shares in the pool. About half of the first (rt() + 1) block rewards will go to this account. This is important so that we don't over-reward the miners of the first 10 blocks.
%When you are ready to shut off your node, first do `accounts:final_reward().` this way you don't under-reward the miners of the last 10 blocks. Use the extra money you got from the first 10 blocks to afford to pay the miners of the last 10 blocks.
share_block_ratio() -> 
    case mode() of
	test -> 2;
	production -> 11
    end.
%share_block_ratio() -> 11.% for every block, we pay out 2^share_block_ratio many rewards.
%so if this is 4, that means we pay 16 shares for every block we find on average. if it is 10, then we pay 1024 shares for every block we find.
rt() -> 9.%rewards are smoothed out over the last rt()+1 blocks.
ratio() -> {rt(), rt()+1}.
tx_fee() -> 100000.%when you shut off the pool, it pays out to everyone who has more than this much veo.
payout_limit() -> 40000000.%when a miner has more than this much veo, it automatically pays out to you.
refresh_period() -> 2.%how often we get a new problem from the server to work on. in seconds
confirmations() -> 5. %how many confirmations does a block need before we can pay out the reward
spend_log_file() -> "spend.log".
save_period() -> 600.%10 minutes
    
