#!/bin/bash

# Fail on error
set -e

# Fail on unset var usage
set -o nounset

#
# Sanity checks
#

cd

#
# First, install Frenetic
#

./bin/setup-frenetic.sh

#
# Clone FlowLog
#

git clone git://github.com/mgscheer/FlowLog.git
