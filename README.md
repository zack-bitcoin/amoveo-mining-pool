
Amoveo Mining Pool
===========

This is a mining pool for the [Amoveo blockchain](https://github.com/zack-bitcoin/amoveo).

You must be in `sync_mode:normal().` in order to run the mining pool.

A mining pool has a server. The server runs a full node of Amoveo so that they can calculate what we should be mining on next.

A mining pool has workers. The workers all ask the server what to work on, and give their work to the server.

The server pays the worker some money.

Some of the work can be used to make blocks to pay the server.

This software is only for the server. Different kinds of workers can connect to Amoveo Mining Pool, if they know your ip address and the port you are running this mining pool server on. By default it uses port 8085.


=== Turning it on and off

First make sure you have an Amoveo node running, and that the keys are unlocked on that node.

```
sh start.sh
```

To connect to it, so you can give it commands:
```
sh attach.sh
```
If it says "Node is not running!", this means that the Amoveo mining pool is shut off and there is nothing for you to connect to. So try using start.sh again to turn it on.

To disconnect, and allow it to run in the background, hold the CTRL key, and press D.

Then to turn it off, make sure you are attached, and run:

```
halt().
```

=== Configure your node

[the config file is here](apps/amoveo_mining_pool/src/config.erl)
There are comments in the config file to explain what each thing is for.

!!! WARNING !!!
Make sure to update the `pubkey` value in config.erl


=== internal commands

Make a blockchain transaction to pay this person the Veo they own:
```
accounts:pay_veo(base64:decode("BCjdlkTKyFh7BBx4grLUGFJCedmzo4e0XT1KJtbSwq5vCJHrPltHATB+maZ+Pncjnfvt9CsCcI9Rn1vO+fPLIV4=")).
```
^ pay_veo/1 is useful if someone wants to stop mining, and they can't afford to get to the limit where it automatically pays out.

give one share to this account:
```
accounts:give_share(base64:decode("BCjdlkTKyFh7BBx4grLUGFJCedmzo4e0XT1KJtbSwq5vCJHrPltHATB+maZ+Pncjnfvt9CsCcI9Rn1vO+fPLIV4=")).
```
give_share is run every time a miner submits enough work to solve a share.

Look up the data for an account:
```
accounts:balance(base64:decode("BCjdlkTKyFh7BBx4grLUGFJCedmzo4e0XT1KJtbSwq5vCJHrPltHATB+maZ+Pncjnfvt9CsCcI9Rn1vO+fPLIV4=")).
```

Make a copy of the current accounts database, and store it in variable V.
```
V = accounts:check().
```

got_reward/0 is run every time the pool finds a block. It is used to convert shares into Veo stored on the pool.
```
accounts:got_reward().
```

pay_veo/0 is for scanning the accounts to see if anyone has enough veo that we should make a tx to send them to veo.
```
accounts:pay_veo().
```

final_reward/0 is the command you run if you want to shut off the mining pool. Make sure that you have enough veo in your account first.
This pays everyone about enough so that you don't under-reward the people who mine that last few blocks.
```
accounts:final_reward().
```



=== API commands

```
curl -i -d '["mining_data"]' http://159.65.120.84:8085
```
returns something like:
```
["ok",[-6,"VU1yID0qrOXjcJDit8P2iqiyefUZMO213goxn+zTOU8=","DSSNQVfIj3v1AvyjplVmIg6+mezC0Hs=",10184]]
```

```
curl -i -d '["mining_data", 8383]' http://159.65.120.84:8085
curl -i -d '["mining_data","BCjdlkTKyFh7BBx4grLUGFJCedmzo4e0XT1KJtbSwq5vCJHrPltHATB+maZ+Pncjnfvt9CsCcI9Rn1vO+fPLIV4="]' http://159.65.120.84:8085
```
both these commands do the same thing, because the second part is ignored.

They both return something that looks like this:
```
["ok",[-6,"3DYUVXO5KPRgS7clcNqgvxLz07WT5Gh+so1c3MmVqTE=",10184,10184]]
```
This version doesn't send any entropy, and it sends the share difficulty twice.
This is to make the API compatible with AmoveoPool style miners.



Look up the total number of shares
```
curl -i -d '["account", 2]' http://159.65.120.84:8085
```
Yes it is poorly named. the encrypter github project needs to expand it's vocabulary.

it returns something like this:
```
["ok",22065]
```

Look up an account
```
curl -i -d '["account", "BCjdlkTKyFh7BBx4grLUGFJCedmzo4e0XT1KJtbSwq5vCJHrPltHATB+maZ+Pncjnfvt9CsCcI9Rn1vO+fPLIV4="]' http://159.65.120.84:8085
```

It returns something like this:
```
["ok",["account","BCjdlkTKyFh7BBx4grLUGFJCedmzo4e0XT1KJtbSwq5vCJHrPltHATB+maZ+Pncjnfvt9CsCcI9Rn1vO+fPLIV4=",22458701,0]]
```


submit work
```
curl -i -d '["work", Nonce, "BCjdlkTKyFh7BBx4grLUGFJCedmzo4e0XT1KJtbSwq5vCJHrPltHATB+maZ+Pncjnfvt9CsCcI9Rn1vO+fPLIV4="]' http://159.65.120.84:8085
```
Where Nonce is a base64 encoded string of a 23 byte binary of the Nonce.



