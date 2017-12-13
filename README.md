Amoveo Mining Pool
===========

This is a mining pool for the [Amoveo blockchain](https://github.com/zack-bitcoin/amoveo).

A mining pool has a server. The server runs a full node of Amoveo so that they can calculate what we should be mining on next.

A mining pool has workers. The workers all ask the server what to work on, and give their work to the server.

If the worker's work is sufficiently high, then the server pays the worker some money.

Some of the work can be used to make blocks to pay the server.

It uses erlang.

This is a work in progress, it does not yet function.