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
# Last Change: 09-09-2014

#This file holds the paths to the local installations of the Toolboxes required to execute the Pipeline
#
#Set the rootPath i.e. the folder holding the shell scripts for the pipeline
export rootPath=/home/petra/Simon/autoPipe

#Set Paths FREESUFER
FREESURFER_HOME=/home/petra/freesurfer/freesurfer

#Set Paths for FSL
FSLDIR=/home/petra/DTI_Tracking/bin/fsl

#Set Paths for MRTrix
MRTrixDIR=/home/petra/DTI_Tracking/bin/mrtrix_hotfix/


###################################################################
# Additional stuff required to be executed for using the toolboxes.
# Edit on own risk from here
###################################################################
SUBJECTS_DIR=${FREESURFER_HOME}/subjects
FUNCTIONALS_DIR=${FREESURFER_HOME}/sessions
PATH=${PATH}:${FREESURFER_HOME}/bin
export FREESURFER_HOME SUBJECTS_DIR FUNCTIONALS_DIR PATH
source ${FREESURFER_HOME}/FreeSurferEnv.sh
source ${FREESURFER_HOME}/SetUpFreeSurfer.sh 

. ${FSLDIR}/etc/fslconf/fsl.sh
PATH=${FSLDIR}/bin:${PATH}
export FSLDIR PATH

LD_LIBRARY_PATH=${MRTrixDIR}/lib/
export LD_LIBRARY_PATH
PATH=${MRTrixDIR}/bin:${PATH}
export PATH
