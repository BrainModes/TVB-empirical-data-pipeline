#!/bin/bash
# Required arguments:
# 1. <subjectID> e.g. CN
path=$1
pfx=$2

cd ${path}/matlab_scripts
octave --eval "addpath(genpath('${path}/niak')); generateMasksDK('${path}/${pfx}/','${path}/${pfx}/')"

##Tell the Mothership we're done here...
touch ${path}/${pfx}/doneMask.txt