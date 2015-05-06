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
# 1. <path the subject-folder>
# This requires the following folder structure for each subject:
# - SubjectXX/
#	+-mrtrix/
#		+--tracks/
#		+--masks/
#		+ CSD8.mif
# 2. <SeedMaskindex>

#Usually this file is called by the batch script created by the MATLAB Script createMasks.m

#Init all Toolboxes
source ./pipeSetup.sh

export subjpath=${1}/mrtrix_68
export maskfolder=${subjpath}/masks_68

export seedmaskindex=$2
export seedCount=$3
export roi=$4

#### Fiber tracking
echo "Currently Processing ROI $seedmaskindex"

streamtrack SD_PROB ${subjpath}/CSD8.mif -seed $maskfolder/seedmask${seedmaskindex}_1mm.nii.gz -include $maskfolder/targetmask${roi}_1mm.nii.gz  -minlength 30 -stop -mask ${1}/calc_images/wmmask_1mm_68.nii.gz -nomaskinterp -unidirectional -num $seedCount ${subjpath}/tracks_68/${seedmaskindex}_tracksCN.tck
