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

#############################################################

# Copy WM masks to MRtrix folder
cd ${subFolder}/${subID}/
mkdir -p mrtrix_68
cd mrtrix_68
${MRTrixDIR}/mrconvert ${subFolder}/${subID}/calc_images/wmmask_68.nii.gz wmmask.mif
${MRTrixDIR}/mrconvert ${subFolder}/${subID}/calc_images/wmmask_1mm_68.nii.gz wmmask_1mm.mif
mkdir -p tracks_68

#Convert RAWDATA to MRTrix Format
${MRTrixDIR}/mrconvert ${subFolder}/${subID}/RAWDATA/DTI/ dwi.mif
${MRTrixDIR}/mrinfo ${subFolder}/${subID}/RAWDATA/DTI/ -grad btable.b

#DTI analysis
${MRTrixDIR}/dwi2tensor dwi.mif -grad btable.b dt.mif
${MRTrixDIR}/tensor2FA dt.mif fa.mif
${MRTrixDIR}/mrmult fa.mif wmmask.mif fa_corr.mif
${MRTrixDIR}/tensor2vector dt.mif ev.mif
${MRTrixDIR}/mrmult ev.mif fa_corr.mif ev_scaled.mif

#Mask of single-fibre voxels
${MRTrixDIR}/erode wmmask.mif -npass 1 - | mrmult fa_corr.mif - - | threshold - -abs 0.7 sf.mif
#Response function coefficient (use mrtrix3, old failed)
dwi2response dwi.mif response.txt -grad btable.b -mask sf.mif 
#CSD computation (use mrtrix3)
dwi2fod dwi.mif -grad btable.b response.txt -mask wmmask.mif fodf.mif




