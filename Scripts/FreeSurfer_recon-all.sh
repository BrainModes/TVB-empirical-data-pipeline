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
# IMPORTANT: adapt subID to name of your subject folder
# =============================================================================

# Input
subID="PAT03T1"

# Check input
rootPath=$(pwd)
subFolder=$(pwd)/subjects

#############################################################

echo "*** Load data & recon_all ***"
firstFile=$(ls ${subFolder}/${subID}/RAWDATA/MPRAGE/ | sort -n | head -1)

recon-all -i ${subFolder}/${subID}/RAWDATA/MPRAGE/${firstFile} -subjid recon_all -sd ${subFolder}/${subID} -all 

mri_convert --in_type mgz --out_type nii --out_orientation RAS ${subFolder}/${subID}/recon_all/mri/aparc+aseg.mgz ${subFolder}/${subID}/recon_all/mri/aparc+aseg.nii

T1=${subFolder}/${subID}/recon_all/mri/T1.mgz



