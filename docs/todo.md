Right now the miner only rewards a worker who finds a block.

Instead we want to give out rewards that are 1/100th as big, and give them out 100 times per block mined.
The risk is that multiple people could send us the same work more than once.
To avoid this, we should remember every solution (or a few bytes of every solution), so that the same solution cannot be given more than once.