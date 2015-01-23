function tck = tck2voxel_cluster(tck,affine_matrix)
%This function converts the Scanner coordinates from MRTRix's tck-Files to
%Voxel Coordinates using the affine Transformation matrix inside the header
%of a reference image (e.g. the Brainmask used for tracking!)
%INPUT:
%tck - The Struct obtained via the MRTrix MATLAB function read_mrtrix_tracks
%refimage - The NIFTI File with the affine Matrix in it's header
%OUTPUT:
%The tck-Struct with transformed coordinates
%
% =============================================================================
% Authors: Michael Schirner, Simon Rothmeier, Petra Ritter
% BrainModes Research Group (head: P. Ritter)
% Charité University Medicine Berlin & Max Planck Institute Leipzig, Germany
% Correspondence: petra.ritter@charite.de
%
% When using this code please cite as follows:
% Schirner M, Rothmeier S, Jirsa V, McIntosh AR, Ritter P (in prep)
% Constructing subject-specific Virtual Brains from multimodal neuroimaging
%
% This software is distributed under the terms of the GNU General Public License
% as published by the Free Software Foundation. Further details on the GPL
% license can be found at http://www.gnu.org/copyleft/gpl.html.
% =============================================================================


%First load the header information of the image to get the matrix
%header = load_untouch_header_only(refimage);
%Inside the header, one can find the affine transformation to get from
%voxel's to scanner coords. Hence the matrix needs to be inverted
%affine_matrix = inv([header.hist.srow_x; header.hist.srow_y; header.hist.srow_z; 0 0 0 1]);

%Loop over all the Tracts in the Structure
for ii = 1:length(tck.data) 
    %Transform the Coordinates by multiplying the Matrix of Coordinates
    %with the affine transformation matrix
    zw = round([tck.data{ii} ones(size(tck.data{ii},1),1)]*affine_matrix');
    %Write into the structure
    tck.data{ii} = zw(:,1:3) + 1;
end

end