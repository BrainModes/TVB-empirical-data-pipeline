#!/bin/bash
#Required Inputs
# 1. The path to the subjectfolder including the rawdata
# 2. The name of the subjectfolder
# 3. The chiffre used to store the DICOMs in the subfolder, usually just the two letters, se below
#Example: ./pipeline_final.sh /home/petra/DTI_Tracking/toronto subQL Q_L
######################New Checks!
#p : Path to Subject
#s : Subjectname
#ecc : Perform an Eddy Curent Correction (default is none)
# usage="usage: $0 -p PATH -s subject [-ecc]"
# 
# ecc_flag=off
# pfx=none
# subPath=none
# while [ $# -gt 0 ]
# do
#     case "$1" in
#         -ecc) ecc_flag=on;;
# 	-s) pfx="$2"; shift;;
# 	-p) subPath="$2"; shift;;
# 	-*) echo >&2 \
# 	    $usage
# 	    exit 1;;
# 	*)  break;;	# terminate while loop
#     esac
#     shift
# done
# #Check if -p & -s have been set
# if [ "$pfx" == "none" ]
# 	then
# 		echo >&2 \
# 		"Subjectname is missing! +++" \
# 	    $usage
# 	    exit 1;
# elif [ "$subPath" == "none" ]
# 	then
# 		echo >&2 \
# 		"Path is missing! +++" \
# 	    $usage
# 	    exit 1;
# fi
####### New Checks


#Set Paths FREESUFER
FREESURFER_HOME=/home/petra/freesurfer/freesurfer
SUBJECTS_DIR=${FREESURFER_HOME}/subjects
FUNCTIONALS_DIR=${FREESURFER_HOME}/sessions
PATH=${PATH}:${FREESURFER_HOME}/bin
export FREESURFER_HOME SUBJECTS_DIR FUNCTIONALS_DIR PATH
source ${FREESURFER_HOME}/FreeSurferEnv.sh
source ${FREESURFER_HOME}/SetUpFreeSurfer.sh 

#Set Paths for FSL
FSLDIR=/home/petra/DTI_Tracking/bin/fsl
. ${FSLDIR}/etc/fslconf/fsl.sh
PATH=${FSLDIR}/bin:${PATH}
export FSLDIR PATH

#Set Paths for MRTrix
MRTrixDIR=/home/petra/DTI_Tracking/bin/mrtrix_hotfix/
LD_LIBRARY_PATH=${MRTrixDIR}/lib/
export LD_LIBRARY_PATH
PATH=${MRTrixDIR}/bin:${PATH}
export PATH

######### Define Einvornment Variables ###############
path=$1
pfx=$2
pfx2=$3

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
firstFile=$(ls ${path}/${pfx}/RAWDATA/MPRAGE/${pfx2}/ | sort -n | head -1)

recon-all -i ${path}/${pfx}/RAWDATA/MPRAGE/${pfx2}/${firstFile} -subjid recon_all -sd ${path}/${pfx} -all
mri_convert --in_type mgz --out_type nii --out_orientation RAS ${path}/${pfx}/recon_all/mri/aparc+aseg.mgz ${path}/${pfx}/recon_all/mri/aparc+aseg.nii

fi

T1=${path}/${pfx}/recon_all/mri/T1.mgz



######### Diffusion Data Preprocessing ################
#Check if recon_all has been computed in the past
if [ ! -d "dt_recon" ]; then
echo "START dt_recon" >> $time_file
date >> $time_file

#Extract the diffusion vectors and the pulse intensity (bvec & bval)
mrinfo RAWDATA/DTI/${pfx2}/ -grad btable.b
cut -f 1,2,3 btable.b > bvec
cut -f 4 btable.b > bval
mkdir dt_recon

#Get the Name of the First file in the Dicom-Folder
firstFile=$(ls ${path}/${pfx}/RAWDATA/DTI/${pfx2}/ | sort -n | head -1)

dt_recon --i ${path}/${pfx}/RAWDATA/DTI/${pfx2}/${firstFile} --b bval bvec --sd ${path}/${pfx} --s recon_all --o ${path}/${pfx}/dt_recon

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
mri_vol2vol --mov $lowb --targ $wm_outline --inv --interp nearest --o wmoutline2diff.nii --reg $rule --no-save-reg
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
mrconvert ${path}/${pfx}/RAWDATA/DTI/${pfx2}/ dwi.mif
#Export the btable in MRTrix Format
mrinfo ${path}/${pfx}/RAWDATA/DTI/${pfx2}/ -grad btable.b

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
estimate_response dwi.mif -grad btable.b sf.mif response.txt
#CSD computation
#csdeconv dwi.mif -grad btable.b response.txt -lmax 8 -mask wmmask.mif CSD8.mif
csdeconv dwi.mif -grad btable.b response.txt -mask wmmask.mif CSD8.mif
#csdeconv dwi.mif -grad btable.b response.txt -lmax 6 -mask wmmask.mif CSD8.mif

##Tell the Mothership we're done here...
touch ${path}/${pfx}/donePipe.txt
















