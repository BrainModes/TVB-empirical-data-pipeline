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

#This script is intended to kill the pipeline after a certain amount of time to ensure that we dont encounter infinite loops due to some unforeseen reasons...
pipe_PID=$1

echo "The PID is: ${pipe_PID}"

#Wait a sufficent amount of time to enable the pipeline to finish..
sleep 48h
#Kill the process...
kill $pipe_PID