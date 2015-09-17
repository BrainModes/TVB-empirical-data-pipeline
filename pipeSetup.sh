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

#This file holds the paths to the local installations of the Toolboxes required to execute the Pipeline
#
#Set the rootPath i.e. the folder holding the shell scripts for the pipeline
export rootPath=/home1/03510/srothmei/tvbPipe

#Set the path to the folder holding the subject files
export subFolder=/work/03510/srothmei/subjects

#Define the folder for the logfiles
export logFolder=${subFolder}/${subID}/logfiles

#Set Paths FREESUFER
#FREESURFER_HOME=/home/petra/freesurfer/freesurfer
module load freesurfer

#Set Paths for FSL
FSLDIR=/home1/03510/srothmei/bin/fsl

#Set Paths for MRTrix
MRTrixDIR=/home1/03510/srothmei/bin/mrtrix-0.2


###################################################################
# Additional stuff required to be executed for using the toolboxes.
# Edit on own risk from here
###################################################################
#SUBJECTS_DIR=${FREESURFER_HOME}/subjects
#FUNCTIONALS_DIR=${FREESURFER_HOME}/sessions
#PATH=${PATH}:${FREESURFER_HOME}/bin
#export FREESURFER_HOME SUBJECTS_DIR FUNCTIONALS_DIR PATH
#source ${FREESURFER_HOME}/FreeSurferEnv.sh
#source ${FREESURFER_HOME}/SetUpFreeSurfer.sh

. ${FSLDIR}/etc/fslconf/fsl.sh
PATH=${FSLDIR}/bin:${PATH}
export FSLDIR PATH

LD_LIBRARY_PATH=${MRTrixDIR}/lib/
export LD_LIBRARY_PATH
PATH=${MRTrixDIR}/bin:${PATH}
export PATH

#Include GNU parallel
PATH=/home1/03510/srothmei/bin:${PATH}
