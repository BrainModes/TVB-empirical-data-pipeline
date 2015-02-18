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

# Required arguments:
# 1. <subjectID> e.g. CN
path=$1
pfx=$2
multiShell=$3

cd ${path}/matlab_scripts
octave --eval "addpath(genpath('${path}/niak')); generateMasksDK('${path}/${pfx}/','${path}/${pfx}/','${multiShell}')"

##Tell the Mothership we're done here...
touch ${path}/${pfx}/doneMask.txt