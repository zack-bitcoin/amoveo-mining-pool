Design
========

api -
* current problem we are working on.
* share solution to the problem. tell us your pubkey so we can pay you.

cron job for if a new block was found
every time a block is found, we need to update the problem we are working on, and we have a look at the block that now has 5 confirmations. If we mined that block, then we need to add the pubkey to the list of who should get paid. if the block height =0 mod 10, then we need to pay everyone from the list of who should get paid, using a multi tx, and add that multi-tx to a log of payments we have made.

gen_server 1 problem
we need to remember what problem we are working on.

gen_server 2 solutions
when a solution to the problem is found, we record which pubkey found that solution.

gen_server 3 to_pay
if a block has 5 confirmation, then whoever mined it should get added to this list of accounts that need to be paid.

gen_server 4 height
in order to know if a new block was found, we need to remember which block heights we have already found out about. so this gen server remembers the block height we have scanned so far.

status website page that shows what pubkeys are waiting for confirmations, or waiting for the next payout, our hashrate, and other data.

