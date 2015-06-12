#!/bin/bash
# Automated checking of archive files to see if the folder structure inside
# mathes the requirements of the pipeline
#
# Currently supported file-formats: .tar.gz; .zip
#
# Usage ./checkArchive.sh fileName.format
#
# =============================================================================
# The folder structure must match the following pattern:
#
# +--RAWDATA
#   +--BOLD-EPI
#       +--IM-0001-0001.dcm
#       +-- ...
#   +--DTI
#       +--IM-0001-0001.dcm
#       +-- ...
#   +--MPRAGE
#       +--IM-0001-0001.dcm
#       +-- ...
# =============================================================================
#
# =============================================================================
# Authors: Michael Schirner, Simon Rothmeier, Petra Ritter
# BrainModes Research Group (head: P. Ritter)
# Charité University Medicine Berlin & Max Planck Institute Leipzig, Germany
# Correspondence: petra.ritter@charite.de
#
# When using this code please cite as follows:
# Schirner M, Rothmeier S, Jirsa V, McIntosh AR, Ritter P
# Constructing subject-specific Virtual Brains from multimodal neuroimaging
#
# This software is distributed under the terms of the GNU General Public License
# as published by the Free Software Foundation. Further details on the GPL
# license can be found at http://www.gnu.org/copyleft/gpl.html.
# =============================================================================
#

# Init
theFile=$1
retVal=0

#Define functions
checkFolderStructure() {
    inputString=$1
    retVal=0

    #Check for faulty structure
    if [[ $inputString != *"RAWDATA/"* ]]; then retVal=1; fi #Mainfolder must be namen RAWDATA
    if [[ $inputString != *"RAWDATA/MPRAGE/"* ]]; then retVal=1; fi  #Check for anatomical data folder with subID folder inside
    if [[ $inputString != *"RAWDATA/DTI/"* ]]; then retVal=1; fi #Check for DTI folder with subID folder inside

    #Optional: If BOLD data is include check if the data is formatted appropriate
    #if [[ $inputString == *"RAWDATA/BOLD-EPI/"* ]]
    #  then
    #  if [[ $inputString != *"RAWDATA/BOLD-EPI/"*"/"* ]]; then retVal=4; fi
    #fi

    return $retVal
}

# First determine if the file format is valid i.e. supported by this script
if [[ $theFile == *.zip ]]; then
  #List the folders inside the zip archive but remove MACOSX control files. Afterwards reduce the lines to just the folder names
  theString=$(zipinfo $theFile | grep '^d' | grep -v "MACOSX" | awk 'NF>1{print $NF}')
elif [[ $theFile == *.tar.gz ]]; then
  #List folder in the archive
  theString=$(tar -ztvf $theFile | grep '^d' | awk 'NF>1{print $NF}')
else
  #Error message + exit code 1
  echo "Error! Unsupported file-format for $theFile"
  exit 1
fi

#Check if the structure is valid
checkFolderStructure "$theString"
retVal=$?

#Check the return Value of the folder structure checking method
if [ $retVal == 0 ]; then
    exit 0
else
    exit 1
fi
