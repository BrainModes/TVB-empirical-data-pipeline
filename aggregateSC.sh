#!/bin/bash
#
# This script performs the final steps of the pipeline:
#   + Aggregate the SC matrix
#   + Convert the data into TVB format
#   + put all the resulting data (e.g. SC/FC matrices) into a single results-folder
#   + Delte the fiber tracks and put the whole folder into a compressed tarball
#
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
#

#Init
subID=$1
subFolder=$2

# Start with the aggregation
./runOctave.sh "aggregateSC_clusterDK('${subID}_SC.mat','${subFolder}/${subID}/mrtrix_68/masks_68/wmborder.mat','${subID}')"

#Now convert the results into tvb format
./runOctave.sh "connectivity2TVBFS('${subID}','${subFolder}/${subID}','${subID}_SC.mat','recon_all')"

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

#Remove the RAWDATA since the user has it anyway because he uploaded it...
rm -R ${subFolder}/${subID}/RAWDATA

#Remove some residual mrtrix-data, just in case there where some minor errors which might lead to a huge bloat of the folder size by not deleting
#tmp-files correctly...
rm -f ${subFolder}/${subID}/mrtrix_68/masks_68/mrtrix-*.nii

#Tie up the download package...
cd ${subFolder}
tar -zcvf ${subID}_downloadData.tar.gz ${subID}/ && rm -R ${subID}/
