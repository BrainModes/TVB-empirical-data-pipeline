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
#
# Adapted to run locally by Hannelore Aerts
# Department of Data-Analysis, Faculty of Psychology and Educational Sciences,
# Ghent University, Belgium
# Correspondence: hannelore.aerts@ugent.be
# =============================================================================
# Folder structure:
# TVB-pipeline 
#	> all TVB-pipeline folders (doc, featConfig, matlab_scripts, niak, 
#	  shedulerConfig)
#	> Scripts: put scripts from this version of the pipeline in this folder
#	> subjects > subjID > RAWDATA > BOLD-EPI / DTI / MPRAGE with DICOMs
#	> TVB_pipe.sh script
# =============================================================================

scripts_path="Scripts"

echo "*************************************************************"
echo "***               TVB empirical data pipeline             ***"
echo "*************************************************************"

echo "************ T1 preprocessing with FreeSurfer *******"
#${scripts_path}/FreeSurfer_recon-all.sh

 
echo "********** DWI preprocessing with FreeSurfer ********"	
#${scripts_path}/FreeSurfer_dt-recon.sh


echo "********** DWI preprocessing with MRtrix2 ***********"
#${scripts_path}/MRtrix_prepro.sh

echo "**************** fMRI preprocessing *****************"
#${scripts_path}/fmriFC.sh

echo "****************** Generate mask ********************"
${scripts_path}/mask.sh

echo "********************* Tracking **********************"
${scripts_path}/runTracking.sh

echo "************** Compute SC matrix  *******************"
${scripts_path}/computeSC.sh

echo "************** Aggregate SC matrix  *****************"
${scripts_path}/aggregateSC.sh

echo "**** Convert to TVB format and clean up results  ****"
${scripts_path}/convert2TVB.sh



