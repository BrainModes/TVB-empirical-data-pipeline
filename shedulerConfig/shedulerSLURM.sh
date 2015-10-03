#!/bin/bash
# Control script for the batch scheduler commands
# Use this file if your HPC uses SLURM

#####   Commands located inside the file pipeSubDK.sh   ####
####____________________________________________________####
#
### 1.) The Preprocessinge-Job
sbatch -J pipe_${subID} -t 00:08:00 -n 1 -N 1 -p normal -o ${logFolder}/${subID}_preproc.o%j ${rootPath}/preprocDK.sh ${subFolder}/ ${subID} > $jobFile

### 2.1) RUN functional Processing
sbatch -J fc_${subID} --dependency=afterok:${jobID} -o ${logFolder}/${subID}_functional.o%j -N 1 -n 1 -p normal -t 00:55:00 ${rootPath}/fmriFC.sh ${subFolder}/ ${subID} > $jobFile

### 2.2) RUN generateMask.m ##################################
sbatch -J Mask_${subID} --dependency=afterok:${jobID} -o ${logFolder}/${subID}_mask.o%j -N 1 -n 1 -p normal -t 01:00:00 ${rootPath}/genMaskDK.sh ${subFolder} ${subID} ${rootPath} > $jobFile

### 3.) RUN the Tracking ####################################
sbatch -J trk_${subID} --dependency=afterok:${jobID} -n 192 -p normal -o ${logFolder}/${subID}_tracking.o%j -t 03:30:00 ./runTracking.sh > $jobFile

### 4.) RUN computeSC_cluster_new.m #########################
sbatch -J cSC_${subID} --dependency=afterok:${jobID} -o ${logFolder}/${subID}_compSC.o%j -n 68 -p normal -t 03:30:00 ./runCompSC.sh > $jobFile

### 5). RUN aggregateSC_new.m ################################
sbatch -J aggreg_${subID} --dependency=afterok:${jobID} -o ${logFolder}/${subID}_aggregateSC.o%j -t 02:00:00 -N 1 -n 1 -p normal ./aggregateSC.sh $subID $subFolder > $jobFile
