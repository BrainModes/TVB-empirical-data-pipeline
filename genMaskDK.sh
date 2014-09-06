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
# Last Change: 08-06-2014

# Required arguments:
# 1. <subjectID> e.g. CN
path=$1
pfx=$2

cd ${path}/matlab_scripts
octave --eval "addpath(genpath('${path}/niak')); generateMasksDK('${path}/${pfx}/','${path}/${pfx}/')"

##Tell the Mothership we're done here...
touch ${path}/${pfx}/doneMask.txt