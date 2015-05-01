#!/bin/bash

#This files performs the execution of xargs to compute the fiber tracking
#in parallel
cat ./batch_track.sh | xargs -n 2 -P 192 ./trackingClusterDK.sh
