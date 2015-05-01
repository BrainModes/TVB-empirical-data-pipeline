#!/bin/bash
cat compSCcommand.txt | xargs -n 1 -P 68 ./runOctave.sh
