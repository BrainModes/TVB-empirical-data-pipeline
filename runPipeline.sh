#!/bin/bash
# =============================================================================
# Authors: Michael Schirner, Simon Rothmeier, Petra Ritter
# BrainModes Research Group (head: P. Ritter)
# Charité University Medicine Berlin & Max Planck Institute Leipzig, Germany
# Correspondence: petra.ritter@charite.de
#
# When using this code please cite as follows:
# Schirner M, Rothmeier S, Jirsa V, McIntosh AR, Ritter P (in prep)
# Constructing subject-specific Virtual Brains from multimodal neuroimaging
#
# This software is distributed under the terms of the GNU General Public License
# as published by the Free Software Foundation. Further details on the GPL
# license can be found at http://www.gnu.org/copyleft/gpl.html.
# =============================================================================

# Required arguments:
# -s : The subjects Name i.e. the foldername
# -a : Abbreviation of the name, used by OSIRIX when reorganising the DICOMS into subfolders. See example below
#Example: ./runPipeline.sh -s CN_20120324 -a C_N

### Check Input ###
export usage="Example: ./pipeline.sh -s CN_20120324 -a C_N"
export subID=none
export split=none
while [ $# -gt 0 ]
do
    case "$1" in
	-s) subID="$2"; shift;;
	-a) split="$2"; shift;;
	-*) echo >&2 \
	    $usage
	    exit 1;;
	*)  break;;	# terminate while loop
    esac
    shift
done
#Check if -a & -s have been set
if [ "$subID" == "none" ]
	then
		echo >&2 \
		"Subjectname is missing! +++" \
	    $usage
	    exit 1;
elif [ "$split" == "none" ]
	then
		echo >&2 \
		"Abbreviation is missing! +++" \
	    $usage
	    exit 1;
fi
### Check Input ###

#Run the Script in background
nohup ./pipeSubDK.sh ${subID} ${split} >& pipe_${subID}.log &

echo "The pipeline is now running in the background. Check the logs (pipe_${subID}.log). Come back again in ~16h"
