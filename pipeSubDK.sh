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

subID=$1
#split=$2
setupPath=$2
#emailAdress=$3

#Init all Toolboxes
source ${setupPath}/pipeSetup.sh

#create the log-folder
mkdir $logFolder
#copy the kill-script into the logfolder
cp ${rootPath}/killPipe.sh $logfolder

#Define the jobFile
jobFile=${logFolder}/jobFile${subID}.txt
#Define the joblist which is used to kill all jobs for the current run if the user wants to abort the pipeline
jobListFile=${logFolder}/jobList${subID}.txt

### 1.) The Preprocessinge-Job ####################################
sbatch -J pipe_${subID} -t 00:08:00 -n 1 -N 1 -p normal -o ${logFolder}/${subID}_preproc.o%j ${rootPath}/preprocDK.sh ${subFolder}/ ${subID} > $jobFile
echo "Wait for the Preprocessing-Job to finish"
#Extract the Job ID from the previously submitted job
jobID=$(tail -n 1 $jobFile | cut -f 4 -d " ")
echo $jobID >> $jobListFile

### 2.1) RUN functional Processing ##########################
#Check if BOLD data is provided
if [ -d "$subFolder/$subID/RAWDATA/BOLD-EPI" ]; then
	sbatch -J fc_${subID} --dependency=afterok:${jobID} -o ${logFolder}/${subID}_functional.o%j -N 1 -n 1 -p normal -t 00:55:00 ${rootPath}/fmriFC.sh ${subFolder}/ ${subID} > $jobFile
	#Extract the Job ID from the previously submitted job
	jobIDBOLD=$(tail -n 1 $jobFile | cut -f 4 -d " ")
	echo $jobIDBOLD >> $jobListFile
fi

### 2.2) RUN generateMask.m ##################################
sbatch -J Mask_${subID} --dependency=afterok:${jobID} -o ${logFolder}/${subID}_mask.o%j -N 1 -n 1 -p normal -t 01:00:00 ${rootPath}/genMaskDK.sh ${subFolder} ${subID} ${rootPath} > $jobFile
echo "Wait fo the Mask-Job to finish"
#Extract the Job ID from the previously submitted job
jobID=$(tail -n 1 $jobFile | cut -f 4 -d " ")
echo $jobID >> $jobListFile

### 3.) RUN the Tracking ####################################
mkdir -p ${subFolder}/${subID}/mrtrix_68
mkdir -p ${subFolder}/${subID}/mrtrix_68/masks_68
mkdir -p ${subFolder}/${subID}/mrtrix_68/tracks_68
cp ${rootPath}/trackingClusterDK.sh ${subFolder}/${subID}/mrtrix_68/masks_68
cp ${rootPath}/pipeSetup.sh ${subFolder}/${subID}/mrtrix_68/masks_68
cp  ${rootPath}/runTracking.sh ${subFolder}/${subID}/mrtrix_68/masks_68
cd ${subFolder}/${subID}/mrtrix_68/masks_68
chmod +x *.sh
sbatch -J trk_${subID} --dependency=afterok:${jobID} -n 192 -p normal -o ${logFolder}/${subID}_tracking.o%j -t 03:30:00 ./runTracking.sh > $jobFile
echo "Tracking jobs submitted"
#Extract the Job ID from the previously submitted job
jobID=$(tail -n 1 $jobFile | cut -f 4 -d " ")
echo $jobID >> $jobListFile

### 4.) RUN computeSC_cluster_new.m #########################
cp ${rootPath}/matlab_scripts/*.m ${subFolder}/${subID}/mrtrix_68/tracks_68
cp ${rootPath}/runOctave.sh ${subFolder}/${subID}/mrtrix_68/tracks_68
cp ${rootPath}/runCompSC.sh ${subFolder}/${subID}/mrtrix_68/tracks_68
cp ${rootPath}/pipeSetup.sh ${subFolder}/${subID}/mrtrix_68/tracks_68
cd ${subFolder}/${subID}/mrtrix_68/tracks_68
chmod +x *.sh

#Generate a set of commands for the SC-jobs...
if [ ! -f "compSCcommand.txt" ]; then
	for i in {1..68}
	do
	 echo "computeSC_clusterDK('./','_tracks${subID}.tck','../masks_68/wmborder.mat',${i},'SC_row_${i}${subID}.mat')" >> compSCcommand.txt
	done
fi

#Now submit the job....
sbatch -J cSC_${subID} --dependency=afterok:${jobID} -o ${logFolder}/${subID}_compSC.o%j -n 68 -p normal -t 03:30:00 ./runCompSC.sh > $jobFile
echo "computeSC jobs submitted"
#Extract the Job ID from the previously submitted job
jobID=$(tail -n 1 $jobFile | cut -f 4 -d " ")
echo $jobID >> $jobListFile

### 5). RUN aggregateSC_new.m ################################
cd ${subFolder}/${subID}/mrtrix_68/masks_68
touch ${subFolder}/${subID}/doneCompSC.txt
cd ${subFolder}/${subID}/mrtrix_68/tracks_68
cp ${rootPath}/aggregateSC.sh ${subFolder}/${subID}/mrtrix_68/tracks_68

sbatch -J aggreg_${subID} --dependency=afterok:${jobID} -o ${logFolder}/${subID}_aggregateSC.o%j -t 02:00:00 -N 1 -n 1 -p normal ./aggregateSC.sh $subID $subFolder > $jobFile
echo "aggregateSC job submitted"
#Extract the Job ID from the previously submitted job
jobID=$(tail -n 1 $jobFile | cut -f 4 -d " ")
echo $jobID >> $jobListFile

### 6). Convert the Files into a single (TVB compatible) ZIP File ##############
#sbatch -J conn2TVB_${subID} --dependency=afterok:${jobID} --mail-user=${emailAdress} --mail-type=end -o ${rootPath}/logfiles/${subID}_conn2TVB.o%j -t 00:10:00 -N 1 -n 1 -p normal ./runOctave.sh "connectivity2TVBFS('${subID}','${subFolder}/${subID}','${subID}_SC.mat','recon_all')"
#echo "connectivity2TVB job submitted"
#Extract the Job ID from the previously submitted job
#jobID=$(tail -n 1 $jobFile | cut -f 4 -d " ")
#echo $jobID >> $jobListFile
