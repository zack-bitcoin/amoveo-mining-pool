
Amoveo Mining Pool
===========

Warning, if you are re-syncing your amoveo full node, make sure to turn off the mining pool first.

This is a mining pool for the [Amoveo blockchain](https://github.com/zack-bitcoin/amoveo).

Your Amoveo full node must be in `sync_mode:normal().` in order to run the mining pool.

A mining pool is software that runs on a public facing ubuntu server. The server also needs to be running a full node of Amoveo so that the mining pool can know what we are mining.

A mining pool has workers. The workers all ask the mining pool what to work on, and give their work to the server.

The server uses this work to produce valid Amoveo blocks, and earn veo.

The server pays the workers veo.

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
reward_tracker:save().
```
then run:
```
halt().
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


submit work
```
curl -i -d '["work", Nonce, "BCjdlkTKyFh7BBx4grLUGFJCedmzo4e0XT1KJtbSwq5vCJHrPltHATB+maZ+Pncjnfvt9CsCcI9Rn1vO+fPLIV4="]' http://159.65.120.84:8085
```
Where Nonce is a base64 encoded string of a 23 byte binary of the Nonce.



