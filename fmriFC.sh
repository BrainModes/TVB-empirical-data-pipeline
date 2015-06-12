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

#This Script processes the fMRI BOLD Data of the subject using FSL & FREESURFER
#Required Inputs
# 1. The path to the subjectfolder including the rawdata
# 2. The name of the subjectfolder

#Init all Toolboxes
source ./pipeSetup.sh

path=$1
pfx=$2

folderName='bold'

cd ${path}/${pfx}

if [ ! -d $folderName ]; then
mkdir $folderName
fi

### Time Measurement
touch $folderName/time.txt
echo "START Bold Processing" >> $folderName/time.txt
date >> $folderName/time.txt

#FREESURFER Workaround
SUBJECTS_DIR=${path}/${pfx}

#Use aparc.a2009s+aseg volume mask from anatomical preprocessing
#cd recon_all/
#Map cortical labels from cortical parcellation (aparc) to the segmentation volume (aseg)
#mri_aparc2aseg --s recon_all --labelwm --hypo-as-wm --rip-unknown --volmask --o mri/wmparc.a2009s.mgz --ctxseg aparc.a2009s+aseg.mgz

#Compute Segementattion Statistics
#mri_segstats --seg mri/wmparc.a2009s.mgz --sum ../${folderName}/wmparc.a2009s.stats --pv mri/norm.mgz --excludeid 0 --brainmask mri/brainmask.mgz --in mri/norm.mgz --in-intensity-name norm --in-intensity-units MR --etiv --subject recon_all --surf-wm-vol --ctab-default

#cd ..
#Convert the raw DICOM Files to a single 4D-Nifti File (BOLD)
mri_convert -i RAWDATA/BOLD-EPI/IM-0001-0001.dcm --out_type nii -o ${folderName}/bold.nii.gz
#Convert the raw DICOM files to a single 3D-Nifti-File (T2)
#mri_convert -i RAWDATA/T2w_2D/*/IM-0001-0001.dcm --out_type nii -o ${folderName}/T2.nii.gz

#Get the number of DICOMs in the RAWDATA-folder
numVol=$(ls -1 RAWDATA/BOLD-EPI/* | wc -l)

cd $folderName

#Get the number of voxels in the 4D timeseries (bold.nii.gz)
numVox=$(fslstats bold.nii.gz -v | cut -f 1 -d " ")

#Convert freesurfer brainmask to NIFTI
mri_convert --in_type mgz --out_type nii ${SUBJECTS_DIR}/recon_all/mri/brainmask.mgz brainmask.nii.gz
#Mask the brainmask using aparc+aseg
mri_convert --in_type mgz --out_type nii ${SUBJECTS_DIR}/recon_all/mri/aparc+aseg.mgz aparc+aseg.nii.gz
#fslmaths aparc+aseg.nii.gz -bin aparc+aseg_bin.nii.gz
#fslmaths brainmask.nii.gz -mul aparc+aseg_bin.nii.gz brainmask.nii.gz
fslmaths brainmask.nii.gz -nan brainmask.nii.gz

## FIELDMAP Correction
#Convert DICOMS to Nifti
#Magnitude Image
#mri_convert -i ${path}/${pfx}/RAWDATA/DTI/fieldmap/*/IM-0001-0001-0001.dcm --out_type nii -o ${path}/${pfx}/${folderName}/magnitude.nii.gz
#Run bet on Magnitude Image i.e. extract the brain
#bet magnitude.nii.gz magnitude_betted.nii.gz
#Phase Image
#mri_convert -i ${path}/${pfx}/RAWDATA/DTI/fieldmap/*/IM-0002-0001.dcm --out_type nii -o ${path}/${pfx}/${folderName}/phase.nii.gz
#Assume we have SIEMENS Scanner Data....
#Prepare the Fieldmap
#fsl_prepare_fieldmap SIEMENS phase.nii.gz magnitude_betted.nii.gz fieldmap.nii.gz 2.46

##Preprocessing
#Copy the generic feat Config to the subject Folder & insert the subID
#!!! On Cluster: Change Path to Standard Image!
cp ${rootPath}/featConfig/default.fsf ./feat.fsf
sed -i -e s/numvolGEN/$((numVol))/g feat.fsf
sed -i -e s/numvoxGEN/$((numVox))/g feat.fsf
sed -i -e s/subGEN/${pfx}/g feat.fsf
sed -i -e s~pathGEN~${path}~g feat.fsf
#Run feat using the config created above
feat feat.fsf

## OLD STUFF ---------------------------------->>>>
#Register FSL Feat output to subject anatomical (from Freesurfer)
#reg-feat2anat --feat featDir.feat --subject recon_all

#Map freesurfer segmentations to functional
#aseg2feat --feat featDir.feat --aseg aparc+aseg

## NEW STUFF ---------------------------------->>>>
mkdir featDir.feat/reg/freesurfer
#Register example-func to freesurfer brainmask
flirt -in featDir.feat/mean_func.nii.gz -ref brainmask.nii.gz -out exfunc2anat_6DOF.nii.gz \
-omat exfunc2anat_6DOF.mat -bins 256 -cost corratio -searchrx -90 90 -searchry -90 90 \
-searchrz -90 90 -dof 6  -interp trilinear
#invert transformation
convert_xfm -omat anat2exfunc.mat -inverse exfunc2anat_6DOF.mat
#transform roimask to functional space using FLIRT (using Nearest Neighbor Interpolation for roimask)
flirt -in aparc+aseg.nii.gz -applyxfm -init anat2exfunc.mat -out featDir.feat/reg/freesurfer/aparc+aseg.nii.gz \
-paddingsize 0.0 -interp nearestneighbour -ref featDir.feat/mean_func.nii.gz

#Export average region time-series
mri_segstats --seg featDir.feat/reg/freesurfer/aparc+aseg.nii.gz --sum ../${folderName}/aparc_stats.txt --in featDir.feat/filtered_func_data.nii.gz --avgwf ${pfx}_ROIts.dat
#Remove all comment lines from the files (important for later MATLAB/OCTAVE import!)
sed '/^\#/d' ../${folderName}/aparc_stats.txt > ../${folderName}/aparc_stats_tmp.txt
#Remove the Strings
sed 's/Seg/0/g' ../${folderName}/aparc_stats_tmp.txt > ../${folderName}/aparc_stats_cleared.txt
rm ../${folderName}/aparc_stats_tmp.txt

echo "END Bold Processing" >> time.txt
date >> time.txt

cd ${rootPath}/matlab_scripts
module load octave
octave --eval "compFC('${path}/${pfx}/${folderName}','${pfx}')"
