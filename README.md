
Amoveo Mining Pool
===========

This is a mining pool for the [Amoveo blockchain](https://github.com/zack-bitcoin/amoveo).

A mining pool has a server. The server runs a full node of Amoveo so that they can calculate what we should be mining on next.

A mining pool has workers. The workers all ask the server what to work on, and give their work to the server.

The server pays the worker some money.

Some of the work can be used to make blocks to pay the server.

This software is only for the server. Different kinds of workers can connect to Amoveo Mining Pool, if they know your ip address and the port you are running this mining pool server on. By default it uses port 8085.


=== Turning it on

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
