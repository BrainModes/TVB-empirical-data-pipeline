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

#Init all Toolboxes
source ./pipeSetup.sh

#Report PID
echo "The PID: $$"

subID=$1
split=$2

### 1.) The Preprocessinge-Job ####################################
#oarsub -n pipe_${subID} -l walltime=16:00:00 -p "host > 'n01'" "${rootPath}/preprocDK.sh ${rootPath}/ ${subID} ${split}"
sbatch -J pipe_${subID} -t 16:00:00 -N 1 -n 1 -o pipe_${subID}.o%j ${rootPath}/preprocDK.sh ${rootPath}/ ${subID} ${split}
echo "Wait for the Preprocessing-Job to finish"
sleep 4h
#Loop until the job has finished
while [ ! -f ${rootPath}/${subID}/donePipe.txt ]
do
	sleep 15m
done

### 2.1) RUN functional Processing ##########################
#oarsub -n fc_${subID} -l walltime=02:00:00 -p "host > 'n01'" "${rootPath}/fmriFC.sh ${rootPath}/ ${subID}"
sbatch -J fc_${subID} -o fc_${subID}.o%j -N 1 -n 1 -t 02:00:00 ${rootPath}/fmriFC.sh ${rootPath}/ ${subID}

### 2.2) RUN generateMask.m ##################################
#oarsub -n Mask_${subID} -l walltime=01:00:00 -p "host > 'n01'" "${rootPath}/genMaskDK.sh ${rootPath} ${subID}"
sbatch -J Mask_${subID} -o Mask_${subID}.o%j -N 1 -n 1 -t 01:00:00 ${rootPath}/genMaskDK.sh ${rootPath} ${subID}
echo "Wait fo the Mask-Job to finish"
sleep 17m
while [ ! -f ${rootPath}/${subID}/doneMask.txt ]
do
	sleep 1m
done

### 3.) RUN the Tracking ####################################
cp ${rootPath}/trackingClusterDK.sh ${rootPath}/${subID}/mrtrix_68/masks_68
cp ${rootPath}/pipeSetup.sh ${rootPath}/${subID}/mrtrix_68/masks_68
cd ${rootPath}/${subID}/mrtrix_68/masks_68
mkdir counter
chmod +x batch_track.sh
./batch_track.sh > /dev/null
echo "Tracking jobs submitted"

### 4.) RUN computeSC_cluster_new.m #########################
#First find out how many tracking processes have been started by counting the number of rows in the batch-script
numOfTrackings=$(( $(cat ./batch_track.sh | wc -l) - 1 )) #Minus 1 row because of the shebang 
echo "Waiting for ${numOfTrackings} tracking-jobs to finish..."
#First wait a reasonable amount of time...
sleep 1h
#Now start checking if the folder count holds enough files (i.e. all processes are finished)
folderCont=$(ls -1 counter/ | wc -l)
while [ $folderCont -lt $numOfTrackings ]
do
	echo "${folderCont} / ${numOfTrackings}"
	sleep 15m #Wait some time till we count again
	export folderCont=$(ls -1 counter/ | wc -l)
done
echo "All tracking-jobs finished"
touch ${rootPath}/${subID}/doneTracking.txt
rm counter/*

#Remove the OAR logfiles from Tracking since they produce a large overhead...
#rm OAR*

cp ${rootPath}/matlab_scripts/*.m ${rootPath}/${subID}/mrtrix_68/tracks_68
cd ${rootPath}/${subID}/mrtrix_68/tracks_68

for i in {1..68}
do
  #oarsub -n cSC_${i}_${subID} -l walltime=05:00:00 -p "host > 'n01'" "octave --eval \"computeSC_clusterDK('./','_tracks${subID}.tck','../masks_68/wmborder.mat',${i},'SC_row_${i}${subID}.mat')\"" > /dev/null
  sbatch -J cSC_${i}_${subID} -o cSC_${i}_${subID}.o%j -N 1 -n 1 -t 05:00:00 octave --eval "computeSC_clusterDK('./','_tracks${subID}.tck','../masks_68/wmborder.mat',${i},'SC_row_${i}${subID}.mat')"
done

echo "computeSC jobs submitted"

### 5). RUN aggregateSC_new.m ################################
cd ${rootPath}/${subID}/mrtrix_68/masks_68
#First wait a reasonable amount of time...
sleep 2h
#Now start checking if the folder count holds enough files (i.e. all processes are finished)
folderCont=$(ls -1 counter | wc -l)
expectedProcesses=68
while [ $folderCont -lt $expectedProcesses ]
do
	sleep 10m #Wait some time till we count again
	export folderCont=$(ls -1 counter/ | wc -l)
done

touch ${rootPath}/${subID}/doneCompSC.txt
#Clear the counter
rm -R counter/

cd ${rootPath}/${subID}/mrtrix_68/tracks_68

#oarsub -n aggreg_${subID} -l walltime=01:50:00 -p "host > 'n01'" "octave --eval \"aggregateSC_clusterDK('${subID}_SC.mat','${rootPath}/${subID}/mrtrix_68/masks_68/wmborder.mat','${subID}')\""
sbatch -J aggreg_${subID} -o aggreg_${subID}.o%j -t 01:50:00 -N 1 -n 1 octave --eval "aggregateSC_clusterDK('${subID}_SC.mat','${rootPath}/${subID}/mrtrix_68/masks_68/wmborder.mat','${subID}')"
echo "aggregateSC job submitted"

### 6). Convert the Files into a single (TVB compatible) ZIP File ##############
#First wait a reasonable amount of time...
sleep 20m
#Now check if the SC matrix is already saved onto the harddrive
if [ ! -f ${rootPath}/${subID}/mrtrix_68/tracks_68/${subID}_SC.mat ]; then
	#oarsub -n conn2TVB_${subID} -l walltime=00:10:00 -p "host > 'n01'" "octave --eval \"connectivity2TVBFS('${subID}','${rootPath}/${subID}','${subID}_SC.mat','recon_all')\""
	sbatch -J conn2TVB_${subID} -o conn2TVB_${subID}.o%j -t 00:10:00 -N 1 -n 1 octave --eval "connectivity2TVBFS('${subID}','${rootPath}/${subID}','${subID}_SC.mat','recon_all')"
	echo "connectivity2TVB job submitted"
fi


