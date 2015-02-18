#!/bin/bash

#Init all Toolboxes
source ./pipeSetup.sh

export pth=${1}
export subjpath=${1}/camino_68
export maskfolder=${subjpath}/masks_68

##Set the bedpost-dir
export bedpostDir=${subjpath}/bedpostx.bedpostX

#### Fiber tracking
while read seedmaskindex seedCount roi        
do   
	if [ "$2" = "$seedmaskindex" ]
	then
		echo "\n Currently Processing ROI $roi\n" 
	
		
		wmmask=${pth}/calc_images/wmmask_68.nii.gz
		seedmask=$maskfolder/seedmask${seedmaskindex}_1mm.nii.gz
		endmask=$maskfolder/gmwmborder_1mm.nii.gz
		seedsPerVoxel=2000
		outputFile=${subjpath}/tracks_68/${seedmaskindex}_tracks.bFloat
		outputProc=${subjpath}/tracks_68/${seedmaskindex}_proc.bFloat
			
		#Perform tracking itself
		track -tracker euler -interpolator nn -stepsize 0.2 -seedfile $seedmask -anisthresh 1.0 -anisfile $wmmask -inputmodel bedpostx -bedpostxdir $bedpostDir -iterations $seedsPerVoxel -outputfile $outputFile

		#Process streamlines
		#procstreamlines -seedfile $seedmask -endpointfile $seedmask -mintractlength 10 -maxtractlength 300 -truncateloops < $outputFile > tracks_procced.txt
		procstreamlines -endpointfile $endmask -mintractpoints 50 -maxtractpoints 1500 -truncateloops < $outputFile > $outputProc
		
		#Clean space....
		rm $outputFile
			
	fi
done <$maskfolder/seedcount.txt


#If Jobs is done simply place a txt into the Counter-Folder
cd $maskfolder/counter
touch ${2}