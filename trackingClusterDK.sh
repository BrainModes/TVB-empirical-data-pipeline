#!/bin/bash
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

#Set Paths for MRTrix
MRTrixDIR=/home/petra/DTI_Tracking/bin/mrtrix_hotfix/
LD_LIBRARY_PATH=${MRTrixDIR}/lib/
export LD_LIBRARY_PATH
PATH=${MRTrixDIR}/bin:${PATH}
export PATH

export subjpath=${1}/mrtrix_68
export maskfolder=${subjpath}/masks_68

#### Fiber tracking
while read seedmaskindex seedCount roi        
do   
	if [ "$2" = "$seedmaskindex" ]
	then
		echo "\n Currently Processing ROI $roi\n" 
	
		streamtrack SD_PROB ${subjpath}/CSD8.mif -seed $maskfolder/seedmask${seedmaskindex}_1mm.nii.gz \
			-include $maskfolder/targetmask${roi}_1mm.nii.gz  -length 300 -stop \
			-mask ${1}/calc_images/wmmask_1mm_68.nii.gz -nomaskinterp -unidirectional -quiet -num $seedCount \
			${subjpath}/tracks_68/${seedmaskindex}_tracksCN.tck
			
	fi
done <$maskfolder/seedcount.txt

#If Jobs is done simply place a txt into the Counter-Folder
cd $maskfolder/counter
touch ${2}