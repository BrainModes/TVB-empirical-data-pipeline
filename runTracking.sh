#!/bin/bash

#This files performs the execution of xargs to compute the fiber tracking
#in parallel
#cat ./batch_track.sh | xargs -n 4 -P 0 ./trackingClusterDK.sh
cat ./batch_track.sh | parallel --colsep ' ' -j +0 ./trackingClusterDK.sh
