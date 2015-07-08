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

#Define the folder for the logfiles
logFolder=${subFolder}/${subID}/logfiles
#create the folder
mkdir $logFolder
#copy the kill-script into the logfolder
cp ${rootPath}/killPipe.sh $logfolder

#Define the jobFile
jobFile=${logFolder}/jobFile${subID}.txt
#Define the joblist which is used to kill all jobs for the current run if the user wants to abort the pipeline
jobListFile=${logFolder}/jobList${subID}.txt

### 1.) The Preprocessinge-Job ####################################
qsub -n pipe_${} -l walltime= 20:00:00 -l nodes=1:ppn=1 -o ${logFolder}/${subID}_preproc.o ${rootPath}/preprocDK.sh ${subFolder}/ ${subID} > $jobFile
echo "Wait for the Preprocessing-Job to finish"
#Extract the Job ID from the previously submitted job
jobID=$(tail -n 1 $jobFile)
echo $jobID >> $jobListFile

### 2.1) RUN functional Processing ##########################
#Check if BOLD data is provided
if [ -d "$subFolder/$subID/RAWDATA/BOLD-EPI" ]; then
	qsub -n fc_${subID} -W depend=afterok:${jobID} -o ${logFolder}/${subID}_functional.o -l nodes=1:ppn=1 -l walltime=00:55:00 ${rootPath}/fmriFC.sh ${subFolder}/ ${subID} > $jobFile
	#Extract the Job ID from the previously submitted job
	jobID=$(tail -n 1 $jobFile)
	echo $jobID >> $jobListFile
fi

### 2.2) RUN generateMask.m ##################################
qsub -n Mask_${subID} -W depend=afterok:${jobID} -o ${logFolder}/${subID}_mask.o -l nodes=1:ppn=1 -l walltime=01:00:00 ${rootPath}/genMaskDK.sh ${subFolder} ${subID} ${rootPath} > $jobFile
echo "Wait fo the Mask-Job to finish"
#Extract the Job ID from the previously submitted job
jobID=$(tail -n 1 $jobFile)
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
qsub -n trk_${subID} -W depend=afterok:${jobID} -l nodes=192:ppn=16 -o ${logFolder}/${subID}_tracking.o -l walltime=03:30:00 ./runTracking.sh > $jobFile
echo "Tracking jobs submitted"
#Extract the Job ID from the previously submitted job
jobID=$(tail -n 1 $jobFile )
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
qsub -n cSC_${subID} -W depend=afterok:${jobID} -o ${logFolder}/${subID}_compSC.o -l nodes=68:ppn=16  -l walltime=03:30:00 ./runCompSC.sh > $jobFile
echo "computeSC jobs submitted"
#Extract the Job ID from the previously submitted job
jobID=$(tail -n 1 $jobFile)
echo $jobID >> $jobListFile

### 5). RUN aggregateSC_new.m ################################
cd ${subFolder}/${subID}/mrtrix_68/masks_68
touch ${subFolder}/${subID}/doneCompSC.txt
cd ${subFolder}/${subID}/mrtrix_68/tracks_68
cp ${rootPath}/aggregateSC.sh ${subFolder}/${subID}/mrtrix_68/tracks_68

qsub -n aggreg_${subID} -W depend=afterok:${jobID} -o ${logFolder}/${subID}_aggregateSC.o -l walltime=02:00:00 -l nodes=1:ppn=1 ./aggregateSC.sh $subID $subFolder > $jobFile
echo "aggregateSC job submitted"
#Extract the Job ID from the previously submitted job
jobID=$(tail -n 1 $jobFile )
echo $jobID >> $jobListFile

### 6). Convert the Files into a single (TVB compatible) ZIP File ##############
qsub -n conn2TVB_${subID} -depend=afterok:${jobID} -m abe -o ${rootPath}/logfiles/${subID}_conn2TVB.o%j -l walltime=00:10:00 -l nodes=1:ppn=1 ./runOctave.sh "connectivity2TVBFS('${subID}','${subFolder}/${subID}','${subID}_SC.mat','recon_all')"
echo "connectivity2TVB job submitted"
#Extract the Job ID from the previously submitted job
jobID=$(tail -n 1 $jobFile)
echo $jobID >> $jobListFile
