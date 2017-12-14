# First recompile the code and rebuild the release.
./rebar3 compile
./rebar3 as prod release
# then launch the software
./_build/prod/rel/amoveo_mining_pool/bin/amoveo_mining_pool start
