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
# IMPORTANT: adapt subID to name of your subject folder 
# =============================================================================

# Input
subID="PAT03T1"

# Check input
rootPath=$(pwd)
subFolder=$(pwd)/subjects
cd ${subFolder}/${subID}/mrtrix_68/tracks_68

# Convert the results into TVB format
octave --eval "connectivity2TVBFS('${subID}','${subFolder}/${subID}','${subID}_SC.mat','recon_all')"

#Gather all the results in a single folder
resultFolder=${subFolder}/${subID}/results
#SC Matrices
cp ${subFolder}/${subID}/mrtrix_68/tracks_68/${subID}_SC.mat ${resultFolder}/${subID}_SC.mat
#FC matrices
if [ -d "$subFolder/$subID/RAWDATA/BOLD-EPI" ]; then
  cp ${subFolder}/${subID}/bold/${subID}_fMRI_new.mat ${resultFolder}/${subID}_fMRI_new.mat
fi

#Clean the results
rm ${subFolder}/${subID}/mrtrix_68/tracks_68/*.tck

#Remove the RAWDATA
#rm -R ${subFolder}/${subID}/RAWDATA

#Remove some residual mrtrix-data, just in case there where some minor errors which might lead to a huge bloat of the folder size by not deleting
#tmp-files correctly...
#rm -f ${subFolder}/${subID}/mrtrix_68/masks_68/mrtrix-*.nii

#Tie up the download package...
#cd ${subFolder}
#tar -zcvf ${subID}_downloadData.tar.gz ${subID}/ && rm -R ${subID}/





