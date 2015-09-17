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

#Required Inputs
# 1. The path to the subjectfolder including the rawdata
# 2. The name of the subjectfolder
# 3. The chiffre used to store the DICOMs in the subfolder, usually just the two letters, se below
#Example: ./pipeline_final.sh /home/petra/DTI_Tracking/toronto subQL Q_L

#Init all Toolboxes
source ./pipeSetup.sh

######### Define Einvornment Variables ###############
path=$1
pfx=$2
#pfx2=$3

cd ${path}/${pfx}

######### Time Measurement ###########################
touch time.txt
time_file=${path}/${pfx}/time_68.txt



######### Structural Data (T1) Preprocessing #########
#Check if recon_all has been computed in the past
if [ ! -d "recon_all" ]; then

echo "START recon-all" >> $time_file
date >> $time_file

#Get the Name of the First file in the Dicom-Folder
firstFile=$(ls ${path}/${pfx}/RAWDATA/MPRAGE/ | sort -n | head -1)

recon-all -i ${path}/${pfx}/RAWDATA/MPRAGE/${firstFile} -subjid recon_all -sd ${path}/${pfx} -openmp 16 -all
mri_convert --in_type mgz --out_type nii --out_orientation RAS ${path}/${pfx}/recon_all/mri/aparc+aseg.mgz ${path}/${pfx}/recon_all/mri/aparc+aseg.nii

fi

T1=${path}/${pfx}/recon_all/mri/T1.mgz



######### Diffusion Data Preprocessing ################
#Check if dt_recon has been computed in the past
if [ ! -d "dt_recon" ]; then
echo "START dt_recon" >> $time_file
date >> $time_file

#Extract the diffusion vectors and the pulse intensity (bvec & bval)
mrinfo RAWDATA/DTI/ -grad btable.b
cut -f 1,2,3 btable.b > bvec
cut -f 4 btable.b > bval
mkdir dt_recon

#Get the Name of the First file in the Dicom-Folder
firstFile=$(ls ${path}/${pfx}/RAWDATA/DTI/ | sort -n | head -1)

dt_recon --i ${path}/${pfx}/RAWDATA/DTI/${firstFile} --b bval bvec --sd ${path}/${pfx} --s recon_all --o ${path}/${pfx}/dt_recon

fi

######### Whitematter Surface #########################
echo "START WM-Surfaces" >> $time_file
date >> $time_file

mkdir -p calc_images
cd calc_images
mri_surf2vol --hemi lh --mkmask --template $T1 --o lh_white.nii --sd ${path}/${pfx} --identity recon_all
mri_surf2vol --hemi rh --mkmask --merge lh_white.nii --o wm_outline.nii --sd ${path}/${pfx} --identity recon_all
#mri_convert --in_orientation LIA --out_orientation RAS wm_outline.nii wm_outline.nii


######### Rotations/Translations #######################
echo "START Rotations" >> $time_file
date >> $time_file

lowb=${path}/${pfx}/dt_recon/lowb.nii
wm_outline=${path}/${pfx}/calc_images/wm_outline.nii
rule=${path}/${pfx}/dt_recon/register.dat

#Rotate high-res (1mm) WM-border to match dwi data w/o resampling
mri_vol2vol --mov $lowb --targ $wm_outline --inv --interp nearest --o wmoutline2diff_1mm.nii --reg $rule --no-save-reg --no-resample
#Rotate high-res (1mm) WM-border to match dwi data with resampling
mri_vol2vol --mov $lowb --targ $wm_outline --inv --o wmoutline2diff.nii.gz --reg $rule --no-save-reg
#Filter out low voxels produced by trilin. interp.
fslmaths wmoutline2diff.nii.gz -thr 0.1 wmoutline2diff.nii.gz
#Binarize
fslmaths wmoutline2diff.nii.gz -bin wmoutline2diff.nii.gz && gunzip wmoutline2diff.nii.gz

#Rotate high-res (1mm) wmparc to match dwi data w/o resampling
mri_vol2vol --mov $lowb --targ ${path}/${pfx}/recon_all/mri/wmparc.mgz --inv --interp nearest --o wmparc2diff_1mm.nii --reg $rule --no-save-reg --no-resample
#Rotate high-res (1mm) aparc+aseg to match dwi data w/o resampling
mri_vol2vol --mov $lowb --targ ${path}/${pfx}/recon_all/mri/aparc+aseg.mgz --inv --interp nearest --o aparc+aseg2diff_1mm.nii --reg $rule --no-save-reg --no-resample
#Rotate high-res (1mm) aparc+aseg to match dwi data with resampling
mri_vol2vol --mov $lowb --targ ${path}/${pfx}/recon_all/mri/aparc+aseg.mgz --inv --interp nearest --o aparc+aseg2diff.nii --reg $rule --no-save-reg

#GZip the Files
gzip wmoutline2diff_1mm.nii
gzip wmparc2diff_1mm.nii



######### Create BrainMasks #############################
echo "START BrainMasks" >> $time_file
date >> $time_file

#Lowres Mask
aparc=${path}/${pfx}/calc_images/aparc+aseg2diff.nii
#Remove the Greymatter (in aparc+aseg, the Whitematter has the Voxelvalues 2 and 41 plus 251-255 for the CC)
fslmaths $aparc -uthr 41 -thr 41 wmmask_68.nii.gz
fslmaths $aparc -uthr 2 -thr 2 -add wmmask_68.nii.gz wmmask_68.nii.gz
fslmaths $aparc -uthr 255 -thr 251 -add wmmask_68.nii.gz wmmask_68.nii.gz
#Combine & Binarize
fslmaths wmmask_68.nii.gz -add wmoutline2diff.nii -bin wmmask_68.nii.gz

#Highres Mask
aparc=${path}/${pfx}/calc_images/aparc+aseg2diff_1mm.nii
#Remove the Greymatter (in aparc+aseg, the Whitematter has the Voxelvalues 2 and 41 plus 251-255 for the CC)
fslmaths $aparc -uthr 41 -thr 41 wmmask_1mm_68.nii.gz
fslmaths $aparc -uthr 2 -thr 2 -add wmmask_1mm_68.nii wmmask_1mm_68.nii.gz
fslmaths $aparc -uthr 255 -thr 251 -add wmmask_1mm_68.nii wmmask_1mm_68.nii.gz
#Combine & Binarize
fslmaths wmmask_1mm_68.nii -add $wm_outline -bin wmmask_1mm_68.nii.gz



######### MRTrix Preprocessing ###########################
echo "START MRTrix Preproc" >> $time_file
date >> $time_file


######## Check the diffusion data and see if they are compatible with the pipeline
######## Currently, we need single-shell data for mrtrix
numberOfShells="$(sort bval | uniq | wc -l | tr -d '[[:space:]]')"

if [ $numberOfShells -gt 2 ]; then
  #Write an error msg for the user....
  echo "ERROR! The pipeline currently only supports single-shell dwMRI data! Sorry." > ${path}/${pfx}/README_ERROR.txt
  #Tie up the download package...
  cd ${path}
  tar -zcvf ${pfx}_downloadData.tar.gz ${pfx}/ && rm -R ${pfx}/
  #Exit the script with an error
  exit 1
fi

######## Now check how many real directions the dwi-data include
######## Sometimes the data includes directions which were recorded double and will confuse the algorithms of mrtrix into assuming a higher number
######## of available variables for solving the equation system than availble which will lead to error in convergence
distinctDirections="$(( $(sort bvec | uniq | wc -l) - 1 ))"
if [ $distinctDirections -ge 6 ] && [ $distinctDirections -lt 15 ]; then lmax=2
elif [ $distinctDirections -ge 15 ] && [ $distinctDirections -lt 28 ]; then lmax=4
elif [ $distinctDirections -ge 28 ] && [ $distinctDirections -lt 45 ]; then lmax=6
elif [ $distinctDirections -ge 45 ] && [ $distinctDirections -lt 66 ]; then lmax=8
elif [ $distinctDirections -ge 66 ] && [ $distinctDirections -lt 91 ]; then lmax=10
elif [ $distinctDirections -ge 91 ] && [ $distinctDirections -lt 120 ]; then lmax=12
elif [ $distinctDirections -ge 120 ] && [ $distinctDirections -lt 153 ]; then lmax=14
elif [ $distinctDirections -ge 153 ] && [ $distinctDirections -lt 190 ]; then lmax=16
elif [ $distinctDirections -ge 190 ] && [ $distinctDirections -lt 231 ]; then lmax=18
elif [ $distinctDirections -ge 231 ]; then lmax=20
else
  echo "ERROR! Not enough distinct directions in your dwMRI data! Sorry." > ${path}/${pfx}/README_ERROR.txt
  #Tie up the download package...
  cd ${path}
  tar -zcvf ${pfx}_downloadData.tar.gz ${pfx}/ && rm -R ${pfx}/
  #Exit the script with an error
  exit 1
fi

########Insert ECC Case here
#Correct the bvecs
#xfmrot dwi-ec.ecclog bvecs.dat bvecs-rot.dat


cd ..
mkdir -p mrtrix_68
cd mrtrix_68
mrconvert ${path}/${pfx}/calc_images/wmmask_68.nii.gz wmmask.mif
mrconvert ${path}/${pfx}/calc_images/wmmask_1mm_68.nii.gz wmmask_1mm.mif
mkdir -p tracks_68

#Convert RAWDATA to MRTrix Format
mrconvert ${path}/${pfx}/RAWDATA/DTI/ dwi.mif
#Export the btable in MRTrix Format
mrinfo ${path}/${pfx}/RAWDATA/DTI/ -grad btable.b

#Diffusion tensor images
dwi2tensor dwi.mif -grad btable.b dt.mif
#Fractional anisotropy (FA) map
tensor2FA dt.mif fa.mif
#Remove noisy background by multiplying the FA Image with the binary brainmask
mrmult fa.mif wmmask.mif fa_corr.mif
#Eigenvector (EV) map
tensor2vector dt.mif ev.mif
#Scale the EV map by the FA Image
mrmult ev.mif fa_corr.mif ev_scaled.mif

#Mask of single-fibre voxels
erode wmmask.mif -npass 1 - | mrmult fa_corr.mif - - | threshold - -abs 0.7 sf.mif
#Response function coefficient
estimate_response dwi.mif -grad btable.b -lmax ${lmax} sf.mif response.txt
#CSD computation
#csdeconv dwi.mif -grad btable.b response.txt -lmax 8 -mask wmmask.mif CSD8.mif
#csdeconv dwi.mif -grad btable.b response.txt -mask wmmask.mif CSD8.mif
csdeconv dwi.mif -grad btable.b response.txt -lmax ${lmax} -mask wmmask.mif CSD8.mif

##Tell the Mothership we're done here...
touch ${path}/${pfx}/donePipe.txt
