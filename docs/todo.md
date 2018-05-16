* we need more explanations about shares and total-shares.
- shares get converted to veo
- block rewards are distributed based on how many shares you have.

* we should probably display the pubkey for the mining pool.

Right now the miner only rewards a worker who finds a block.

* mining pool should say the fee size, the number of active miners, last block made today, blocks made in last 24 hours, total veo distributed, current block height?

Instead we want to give out rewards that are 1/100th as big, and give them out 100 times per block mined.
The risk is that multiple people could send us the same work more than once.
To avoid this, we should remember every solution (or a few bytes of every solution), so that the same solution cannot be given more than once.


Maybe we should be able to turn down the frequency at which particular addresses get paid.


clarify that shares is not the total shares mined. it is your current outstanding balance of shares.

Clarify that veo and shares are 2 different balances.