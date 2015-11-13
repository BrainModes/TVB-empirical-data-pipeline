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
#
# Adapted to run locally by Hannelore Aerts
# Department of Data-Analysis, Faculty of Psychology and Educational Sciences,
# Ghent University, Belgium
# Correspondence: hannelore.aerts@ugent.be
# =============================================================================
# IMPORTANT: adapt subID to name of your subject folder + set path to MRtrix2
# (commands from MRtrix3 should run from terminal, by placing path to MRtrix3
# in your bashrc file)
# =============================================================================

# Input
subID="PAT03T1"
MRTrixDIR=/home/hannelore/mrtrix2/bin

# Check input
rootPath=$(pwd)
subFolder=$(pwd)/subjects

# Get information from batch track script in different variables
batch=${subFolder}/${subID}/mrtrix_68/masks_68/batch_track.sh
subjpath=${subFolder}/${subID}/mrtrix_68
maskfolder=${subjpath}/masks_68
seed=($(awk '{print $2}' $batch))
seedCount=($(awk '{print $3}' $batch))
roi=($(awk '{print $4}' $batch))


#### Fiber tracking

for (( i = 0; i < 348; i++ ))
do
  echo "Iteration number $i from 347 (start from 0)"
  ${MRTrixDIR}/streamtrack SD_PROB ${subjpath}/fodf.mif -seed $maskfolder/seedmask${seed[i]}_1mm.nii.gz -include $maskfolder/targetmask${roi[i]}_1mm.nii.gz -minlength 30 -stop -mask ${subFolder}/${subID}/calc_images/wmmask_1mm_68.nii.gz -nomaskinterp -unidirectional -num ${seedCount[i]} ${subjpath}/tracks_68/${seed[i]}_tracksCN.tck

done

