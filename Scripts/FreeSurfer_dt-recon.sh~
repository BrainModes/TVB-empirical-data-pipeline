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
T1=${subFolder}/${subID}/recon_all/mri/T1.mgz


#############################################################


echo "*** Load data & dt_recon ***"
#Extract the diffusion vectors and the pulse intensity (bvec & bval)
dt_recon=${subFolder}/${subID}/dt_recon
mkdir $dt_recon
${MRTrixDIR}/mrinfo ${subFolder}/${subID}/RAWDATA/DTI/ -grad ${dt_recon}/btable.b
cut -f 1,2,3 ${dt_recon}/btable.b > ${dt_recon}/bvec
cut -f 4 ${dt_recon}/btable.b > ${dt_recon}/bval

#Get the Name of the First file in the Dicom-Folder
firstFile=$(ls ${subFolder}/${subID}/RAWDATA/DTI/ | sort -n | head -1)

dt_recon --i ${subFolder}/${subID}/RAWDATA/DTI/${firstFile} --b ${dt_recon}/bval ${dt_recon}/bvec --sd ${subFolder}/${subID} --s recon_all --no-ec --o ${subFolder}/${subID}/dt_recon
	#uses FSL eddy_correct: don't do with high b-values!

echo "*** WM surface ***"
mkdir -p ${subFolder}/${subID}/calc_images
cd ${subFolder}/${subID}/calc_images
mri_surf2vol --hemi lh --mkmask --template $T1 --o lh_white.nii --sd ${subFolder}/${subID} --identity recon_all
mri_surf2vol --hemi rh --mkmask --merge lh_white.nii --o wm_outline.nii --sd ${subFolder}/${subID} --identity recon_all
#(commented out by authors)mri_convert --in_orientation LIA --out_orientation RAS wm_outline.nii wm_outline.nii

echo "*** Rotations/Translations ***"
lowb=${subFolder}/${subID}/dt_recon/lowb.nii
wm_outline=${subFolder}/${subID}/calc_images/wm_outline.nii
rule=${subFolder}/${subID}/dt_recon/register.dat

#Rotate high-res (1mm) WM-border to match dwi data w/o resampling
mri_vol2vol --mov $lowb --targ $wm_outline --inv --interp nearest --o wmoutline2diff_1mm.nii --reg $rule --no-save-reg --no-resample
#Rotate high-res (1mm) WM-border to match dwi data with resampling
mri_vol2vol --mov $lowb --targ $wm_outline --inv --o wmoutline2diff.nii.gz --reg $rule --no-save-reg
#Filter out low voxels produced by trilin. interp.
fslmaths wmoutline2diff.nii.gz -thr 0.1 wmoutline2diff.nii.gz
#Binarize
fslmaths wmoutline2diff.nii.gz -bin wmoutline2diff.nii.gz && gunzip wmoutline2diff.nii.gz

#Rotate high-res (1mm) wmparc to match dwi data w/o resampling
mri_vol2vol --mov $lowb --targ ${subFolder}/${subID}/recon_all/mri/wmparc.mgz --inv --interp nearest --o wmparc2diff_1mm.nii --reg $rule --no-save-reg --no-resample
#Rotate high-res (1mm) aparc+aseg to match dwi data w/o resampling
mri_vol2vol --mov $lowb --targ ${subFolder}/${subID}/recon_all/mri/aparc+aseg.mgz --inv --interp nearest --o aparc+aseg2diff_1mm.nii --reg $rule --no-save-reg --no-resample
#Rotate high-res (1mm) aparc+aseg to match dwi data with resampling
mri_vol2vol --mov $lowb --targ ${subFolder}/${subID}/recon_all/mri/aparc+aseg.mgz --inv --interp nearest --o aparc+aseg2diff.nii --reg $rule --no-save-reg

#GZip the Files
gzip wmoutline2diff_1mm.nii
gzip wmparc2diff_1mm.nii


echo "*** Create brainmasks ***"

#Lowres Mask
aparc=${subFolder}/${subID}/calc_images/aparc+aseg2diff.nii
#Remove the GM (in aparc+aseg, the WM has the Voxelvalues 2 and 41 plus 251-255 for the CC)
fslmaths $aparc -uthr 41 -thr 41 wmmask_68.nii.gz
fslmaths $aparc -uthr 2 -thr 2 -add wmmask_68.nii.gz wmmask_68.nii.gz
fslmaths $aparc -uthr 255 -thr 251 -add wmmask_68.nii.gz wmmask_68.nii.gz
#Combine & Binarize
fslmaths wmmask_68.nii.gz -add wmoutline2diff.nii -bin wmmask_68.nii.gz

#Highres Mask
aparc=${subFolder}/${subID}/calc_images/aparc+aseg2diff_1mm.nii
#Remove the GM (in aparc+aseg, the WM has the Voxelvalues 2 and 41 plus 251-255 for the CC)
fslmaths $aparc -uthr 41 -thr 41 wmmask_1mm_68.nii.gz
fslmaths $aparc -uthr 2 -thr 2 -add wmmask_1mm_68.nii.gz wmmask_1mm_68.nii.gz
fslmaths $aparc -uthr 255 -thr 251 -add wmmask_1mm_68.nii.gz wmmask_1mm_68.nii.gz
#Combine & Binarize
fslmaths wmmask_1mm_68.nii.gz -add $wm_outline -bin wmmask_1mm_68.nii.gz

