#!/bin/bash

#Init all Toolboxes
source ./pipeSetup.sh

#Get the hostlist
hostlist=$(scontrol show hostname $SLURM_NODELIST | paste -d, -s)

#Run jobs in parallel
parallel --sshlogin $hostlist --delay .2 -j $(( $SLURM_CPUS_ON_NODE / 2 )) --workdir $(pwd) --joblog runtask.log --resume ./runOctave.sh {} < ./compSCcommand.txt
