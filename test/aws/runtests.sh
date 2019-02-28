#!/bin/bash
# Change dir to AWSCore
cd $(dirname $0)/../..

/julia/bin/julia --project -e "using Pkg; Pkg.instantiate()"
# New stacks seem to get `ERROR: LoadError: IOError: write: broken pipe (EPIPE)`
# on tests unless AWSCore is precompiled separately for some reason ¯\_(ツ)_/¯
/julia/bin/julia --project -e "using AWSCore"
/julia/bin/julia --project -e "using Pkg; Pkg.build(); Pkg.test()"
