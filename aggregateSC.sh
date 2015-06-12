#/bin/bash
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

#Clean the results
rm ${subFolder}/${subID}/mrtrix_68/*.tck

#Tie up the download package...
tar -zcvf ${subFolder}/${subID}_downloadData.tar.gz ${subFolder}/${subID}/ && rm -R ${subFolder}/${subID}/
