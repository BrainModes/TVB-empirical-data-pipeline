#!/bin/bash

#Report PID
echo "The PID: $$"

subID=$1
split=$2

#Set the rootPath
export rootPath=/home/petra/Simon/autoPipe

### 1.) The Preprocessinge-Job ####################################
oarsub -n pipe_${subID} -l walltime=16:00:00 -p "host > 'n01'" "${rootPath}/preprocDK.sh ${rootPath}/ ${subID} ${split}"
echo "Wait for the Preprocessing-Job to finish"
sleep 4h
#Loop until the job has finished
while [ ! -f ${rootPath}/${subID}/donePipe.txt ]
do
	sleep 15m
done

### 2.1) RUN functional Processing ##########################
oarsub -n fc_${subID} -l walltime=02:00:00 -p "host > 'n01'" "${rootPath}/fmriFC.sh ${rootPath}/ ${subID}"

### 2.2) RUN generateMask.m ##################################
oarsub -n Mask_${subID} -l walltime=01:00:00 -p "host > 'n01'" "${rootPath}/genMaskDK.sh ${rootPath} ${subID}"
echo "Wait fo the Mask-Job to finish"
sleep 17m
while [ ! -f ${rootPath}/${subID}/doneMask.txt ]
do
	sleep 1m
done

### 3.) RUN the Tracking ####################################
cp ${rootPath}/trackingClusterDK.sh ${rootPath}/${subID}/mrtrix_68/masks_68
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
  oarsub -n cSC_${i}_${subID} -l walltime=03:00:00 -p "host > 'n01'" "octave --eval \"computeSC_clusterDK('./','_tracks${subID}.tck','../masks_68/wmborder.mat',${i},'SC_row_${i}${subID}.mat')\"" > /dev/null
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

oarsub -n aggreg_${subID} -l walltime=01:10:00 -p "host > 'n01'" "octave --eval \"aggregateSC_clusterDK('${subID}_SC.mat','${rootPath}/${subID}/mrtrix_68/masks_68/wmborder.mat','${subID}')\""
echo "aggregateSC job submitted"

