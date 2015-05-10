#!/bin/bash

#This files performs the execution of xargs to compute the fiber tracking
#in parallel
#cat ./batch_track.sh | xargs -n 4 -P 0 ./trackingClusterDK.sh

#Init all Toolboxes
source ./pipeSetup.sh

#Get the hostlist
hostlist=$(scontrol show hostname $SLURM_NODELIST | paste -d, -s)

#Run the jobs
parallel -C ' ' --sshlogin $hostlist --delay .2 -j $SLURM_CPUS_ON_NODE --workdir $(pwd) --joblog runtask.log --resume ./trackingClusterDK.sh {1} {2} {3} {4} < ./batch_track.sh
