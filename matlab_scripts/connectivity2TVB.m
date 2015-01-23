function connectivity2TVB(subID,subFolder,SC_matrix,brainstormFolder,reconallFolder)
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

% INPUT:
%   subID               ---     The identifier of the subject (must also be
%                               the one used within brainstorm!)
%   subFolder           ---     Complete path to the subjects folder
%                               including the ID, e.g. /home/petra/DTI_Pipe/QL_20120306 
%   SC_matrix           ---     The SC Matrix (.mat file)
%   brainstormFolder    ---     Path to the folder holding the results of
%                               the brainstorm toolbox
%   reconallFolder      ---     Path to the folder holding the results of
%                               FREESURFERs recon_all run
% OUTPUT: ConnectivityTVB_Brainstorm.zip --- See description below
%
% Bring the Connectivity Data into the right format for a import into TVB
% TVB needs a Zip-File comntaining the following data:
%
% 1. Weights - Matrix of weights, Text file containing values separated by
% spaces/tabs, no negative values
%
% 2. Position - container for connectivity centers; text file containing
% values separated by spaces/tabs; on the first row there should be a header
% of the form 'labels X Y Z'; each row represents data for a region center
%
% 3. Tract - connectivity tract lengths; text file containing values
% separated by spaces/tabs; contains a matrix of tract lengths; nonnegative
%
% 4. Orientation - connectivity center orientations; ext file containing
% values separated by spaces/tabs; each row represents orientation for a
% region center; each row should have at least 3 columns for region center orientation (3 float values separated with spaces or tabs)
%
% 5. Area - connectivity areas; text file containing one area on each line (as float value)
%
% 6. Cortical - connectivity cortical/non-cortical region flags; text file containing one boolean value on each line 
% (as 0 or 1 value) being 1 when corresponding region is cortical.
%
% 7. Hemisphere - hemisphere inclusion flag for connectivity regions; text file containing one boolean value on each line 
% (as 0 or 1 value) being 1 when corresponding region is in the right hemisphere and 0 when in left hemisphere.
files = cell(7,1);

cd(subFolder);
mkdir('TVB')
cd TVB

%Load the SC Matrices
SC = load([subFolder '/' SC_matrix]);
weights = SC.SC_cap_agg_bwflav2;
%Check if the delay-matrix is in the new or the old formatting
if (isfield(SC,'SC_dist_mean_agg'))
    delay = SC.SC_dist_mean_agg;
else
    delay = SC.SC_dist_mean_agg_steps;
end
clear SC

%Load the required things from the external toolboxes
MRI = load([subFolder '/' brainstormFolder '/anat/' subID '/subjectimage_T1.mat']);
cortexMesh = load([subFolder '/' brainstormFolder '/anat/' subID '/tess_cortex_pial_low.mat']);
[hdr,~] = niak_read_vol([subFolder '/' reconallFolder '/mri/aparc+aseg.nii']);
vox2ras = hdr.info.mat;
clear hdr

%Convert Brainstorm Cortex-Mesh to RAS
vertices = cs_scs2mri(MRI,cortexMesh.Vertices' .*1000)'; %USES BRAINSTORM FUNCTION! Defined below...
vertices = [vertices ones(size(vertices,1),1)]*vox2ras';
vertices = vertices(:,1:3);

labels = zeros(size(vertices,1),1);
for i = 1:68
   labels(cortexMesh.Atlas(3).Scouts(i).Vertices) = i; 
end

labeled_vertices = [vertices labels];

%Calculate new VertNormals
vertexNormals = cs_scs2mri(MRI,cortexMesh.VertNormals' .*1000)';
vertexNormals = [vertexNormals ones(size(vertexNormals,1),1)]*vox2ras';
for i = 1:size(vertexNormals,1)
    vertexNormals(i,:) = vertexNormals(i,:)/norm(vertexNormals(i,:));
end
vertexNormals = vertexNormals(:,1:3);


labels = cell(1,68);
for i = 1:68
   labels{i} = cortexMesh.Atlas(3).Scouts(i).Label; 
end

%% 1.Weights
%weights = weights;
files{1} = 'weights.txt';
save(files{1},'weights','-ascii')

%% 2. Position
%Calculate the Centers of the Regions:
%Here i'll just take the mean of all vertice-coordinates belonging to a
%Region.
centers = zeros(68,3);
for r = 1:size(centers,1)    
    %First get all Vertices corresponding to a Region
    regionVertices = labeled_vertices(labeled_vertices(:,4) == r,1:3);
    %Compute the mean of each Coordinate (x,y,z)
    centers(r,:) = mean(regionVertices);
end
%Search the Nearest-Neighbors
IDX = knnsearch(vertices,centers);
%Set the NN as the new centers
centers = vertices(IDX,:);

files{2} = 'centres.txt';
fid = fopen(files{2}, 'wt');
%string2write = ['labels' char(9) 'X' char(9) 'Y' char(9) 'Z'];
string2write = '';
for r = 1:size(centers,1) 
    string2write = [string2write '\n ' strrep(labels{r}, ' ', '_') char(9) num2str(centers(r,1)) char(9) num2str(centers(r,2)) char(9) num2str(centers(r,3))];
end
fprintf(fid,string2write);
fclose(fid);


%% 3. Tract
%This is equivalent to the delay matrix (?)
files{3} ='tract.txt';
save(files{3},'delay','-ascii')

%% 4. Orientation
orientation = zeros(68,3);

for r = 1:size(orientation,1)   
    %First get all Vertex-Normals corresponding to the Vertices of a Region
    regionVertexNormals = vertexNormals(labeled_vertices(:,4) == r,:);
    %Now compute mean Vector
    orientation(r,:) = mean(regionVertexNormals);
    %Normalize the Vector
    orientation(r,:) = orientation(r,:)/norm(orientation(r,:));
end
files{4} = 'orientation.txt';
dlmwrite(files{4},orientation,'delimiter',' ','precision',20);

%% 5. Area
%I'm not quite sure how to get to the exact value for the surface in mm^2
%so for now i just count the surface vertices corresponding to each region
%EDIT: According to the TVB Dokumentation, this attribute is not mandatory
%for the Input!
area = zeros(68,1);
for r = 1:size(area,1)
   area(r) = nnz(labeled_vertices(:,4) == r); 
end
files{5} ='area.txt';
dlmwrite(files{5},area,'delimiter',' ','precision',20);

%% 6. Cortical
%All areas are cortical, hence
cortical = ones(68,1);
files{6} = 'cortical.txt';
dlmwrite(files{6},cortical,'delimiter',' ','precision',20);

%% 7. Hemisphere
%Hard-Coded for the GLEBS-ROI-Mask!
hemisphere = [zeros(34,1); ones(34,1)];
files{7} ='hemisphere.txt';
dlmwrite(files{7},hemisphere,'delimiter',' ','precision',20);

%% Assemble the ZIP
zip([subID '_Connectivity'],files)
for i = 1:length(files)
    delete(files{i})
end

end

function [mriCoord] = cs_scs2mri(MRI,scsCoord)
% CS_SCS2MRI: Transform SCS point coordinates (in mm) to MRI coordinate system (in mm) 
%
% USAGE:  [mriCoord] = cs_scs2mri(MRI,scsCoord);
%
% INPUT: 
%     - MRI      : A proper Brainstorm MRI structure (i.e. from any subjectimage file, 
%                  with fiducial points and SCS system properly defined)
%     - scsCoord : a 3xN matric of corresponding point coordinates in the SCS system (in mm)
%     - mriCoord : a 3xN matrix of point coordinates in the MRI system (in mm)

% NOTES:
%  Definition of original transform is the following:
%  Xscs = MRI.SCS.R Xmri + MRI.SCS.T ; 
%  (Xmri in mm)
%
% @=============================================================================
% This software is part of the Brainstorm software:
% http://neuroimage.usc.edu/brainstorm
% 
% Copyright (c)2000-2014 University of Southern California & McGill University
% This software is distributed under the terms of the GNU General Public License
% as published by the Free Software Foundation. Further details on the GPL
% license can be found at http://www.gnu.org/copyleft/gpl.html.
% 
% FOR RESEARCH PURPOSES ONLY. THE SOFTWARE IS PROVIDED "AS IS," AND THE
% UNIVERSITY OF SOUTHERN CALIFORNIA AND ITS COLLABORATORS DO NOT MAKE ANY
% WARRANTY, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
% MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, NOR DO THEY ASSUME ANY
% LIABILITY OR RESPONSIBILITY FOR THE USE OF THIS SOFTWARE.
%
% For more information type "brainstorm license" at command prompt.
% =============================================================================@
%
% Authors: Sylvain Baillet, Alexei Ossadtchi, 2004
%          Francois Tadel, 2008-2010

% Check matrices orientation
if (size(scsCoord, 1) ~= 3)
    error('scsCoord must have 3 rows (X,Y,Z).');
end

if ~isfield(MRI,'SCS') || ~isfield(MRI.SCS,'R') || ~isfield(MRI.SCS,'T') || isempty(MRI.SCS.R) || isempty(MRI.SCS.T)
    mriCoord = [];
    return
end
if isfield(MRI, 'R') && isfield(MRI, 'T')
    MRI.SCS=MRI;
end

mriCoord = MRI.SCS.R \ (scsCoord - repmat(MRI.SCS.T,1,size(scsCoord,2)));

end