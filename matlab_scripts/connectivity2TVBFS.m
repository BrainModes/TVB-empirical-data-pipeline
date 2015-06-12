function connectivity2TVBFS(subID,subFolder,SC_matrix,reconallFolder)
% Usage: function connectivity2TVBFS(subID,subFolder,SC_matrix,reconallFolder)
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

files = cell(7,1);

cd(subFolder);
mkdir('results')
cd results

%Load the SC Matrices
SC = load([subFolder '/mrtrix_68/tracks_68/' SC_matrix]);
weights = SC.SC_cap_agg_bwflav2;
%Check if the delay-matrix is in the new or the old formatting
if (isfield(SC,'SC_dist_mean_agg'))
    delay = SC.SC_dist_mean_agg;
else
    delay = SC.SC_dist_mean_agg_steps;
end
clear SC

%Load the required things from the external toolboxes
[lh_vert, lh_faces] = read_surf([subFolder '/' reconallFolder '/surf/lh.pial']);
[rh_vert, rh_faces] = read_surf([subFolder '/' reconallFolder '/surf/rh.pial']);
cortexMesh.Vertices = [lh_vert; rh_vert];
cortexMesh.Faces = [lh_faces; rh_faces+size(lh_vert,1)]+1;

%Load Annotation-Tables
[~, lh_label, lh_colortable] = read_annotation([subFolder '/' reconallFolder '/label/lh.aparc.annot']);
[~, rh_label, rh_colortable] = read_annotation([subFolder '/' reconallFolder '/label/rh.aparc.annot']);
%Remove Corp.Cal.
lh_colortable.table(5,:) = []; rh_colortable.table(5,:) = [];
%Create the labels
labels = labelFStoLin(lh_vert,rh_vert,lh_label,rh_label,lh_colortable,rh_colortable);

%Calculate Normals
cortexMesh.VertNormals = calcNormals(cortexMesh);

if(length(cortexMesh.VertNormals) ~= cortexMesh.Vertices)
    display('Error! Vertex-Normals in connectivity2TVBSF.m could not be comnputed for all vertex-points. Using 0 Vectors instead');
    cortexMesh.VertNormals = cortexMesh.Vertices;
end

%Do the TVB Mesh Clean
[cortexMesh.Vertices,cortexMesh.Faces,cortexMesh.VertNormals,labels] = removeFB(cortexMesh.Vertices,cortexMesh.Faces,cortexMesh.VertNormals,labels);

%Label the vertices
labeled_vertices = [cortexMesh.Vertices labels];

%Create Labels
labels = cell(1,68);
labels(1:34) = strcat('lh_',lh_colortable.struct_names([2:4 6:end]));
labels(35:end) = strcat('rh_',rh_colortable.struct_names([2:4 6:end]));

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
IDX = dsearchn(cortexMesh.Vertices,centers);
%Set the NN as the new centers
centers = cortexMesh.Vertices(IDX,:);

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
%Since TVB expects the distances to be in mm, we need to convert the values
%from steps (steplength = 0.2mm) to mm
%delay = delay .* 0.2;
files{3} ='tract.txt';
save(files{3},'delay','-ascii')

%% 4. Orientation
orientation = zeros(68,3);

for r = 1:size(orientation,1)
    %First get all Vertex-Normals corresponding to the Vertices of a Region
    regionVertexNormals = cortexMesh.VertNormals(labeled_vertices(:,4) == r,:);
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

function vertexNormals = calcNormals(cortexMesh)
%Taken and modified from:
% This software is part of the Brainstorm software:
% http://neuroimage.usc.edu/brainstorm
%
% Copyright (c)2000-2014 University of Southern California & McGill University
figure('Visible','off');
hPatch = patch('Faces', cortexMesh.Faces, 'Vertices', cortexMesh.Vertices);

% Get patch vertices
vertexNormals = double(get(hPatch,'VertexNormals'));
close all

% Normalize normal vectors
nrm = sqrt(sum(vertexNormals.^2, 2));
nrm(nrm == 0) = 1;

vertexNormals = bsxfun(@rdivide, vertexNormals, nrm);

end

function label = labelFStoLin(lh_vert,rh_vert,lh_label,rh_label,lh_colortable,rh_colortable)

%Convert from FREESURFER ID numbering to linear numbering
for i = 1:length(lh_vert)
    if (lh_label(i) > 0)
        lh_label(i) = find(lh_colortable.table(:,5) == lh_label(i));
    else
        lh_label(i) = 1; %Set to unknown
    end
end
for i = 1:length(rh_vert)
    if (rh_label(i) > 0)
        rh_label(i) = find(rh_colortable.table(:,5) == rh_label(i));
    else
        rh_label(i) = 1; %Set to unknown
    end
end
rh_label = rh_label + max(lh_label) - 1;
rh_label(rh_label == 35) = 1;

label = [lh_label; rh_label]-1;

end

function [vertices,faces,normals,labels] = removeFB(vertices,faces,normals,labels)


%Look for all Vertices-indices that occur only once in the Faces-Matrix
FBtri = faces(:);
tmp = unique(FBtri);
FBtri = histc(FBtri,tmp);
FBtri = tmp(FBtri == 1);

%     %Create a MATLAB triangulation object
%     TR = triangulation(faces,vertices(:,1),vertices(:,2),vertices(:,3));
%
%     %Get the FreeBoundary Points
%     FBtri = freeBoundary(TR);
%     FBtri = FBtri(:);
%     [~,N,~] = unique(FBtri);
%     FBtri(N) = [];
%     FBtri = sort(FBtri);


%Remove Vertices
vertices(FBtri,:) = [];
normals(FBtri,:) = [];

for i = 1:length(FBtri)

    %Get the Rows of the Faces-Matrix including the target-vertex
    [targetRow,~] = find(faces == FBtri(i));

    faces(targetRow,:) = [];

    faces(faces > FBtri(i)) = faces(faces > FBtri(i)) - 1;

    %Remove Vertices from Labeling
    labels(FBtri(i)) = [];
    labels(labels > FBtri(i)) = labels(labels > FBtri(i)) - 1;

    FBtri = FBtri - 1;

end


end

function [vertices, label, colortable] = read_annotation(filename, varargin)
%
% NAME
%
%       function [vertices, label, colortable] = ...
%                                       read_annotation(filename [, verbosity])
%
% ARGUMENTS
% INPUT
%       filename        string          name of annotation file to read
%
% OPTIONAL
%       verbosity       int             if true (>0), disp running output
%                                       + if false (==0), be quiet and do not
%                                       + display any running output
%
% OUTPUT
%       vertices        vector          vector with values running from 0 to
%                                       + size(vertices)-1
%       label           vector          lookup of annotation values for
%                                       + corresponding vertex index.
%       colortable      struct          structure of annotation data
%                                       + see below
%
% DESCRIPTION
%
%       This function essentially reads in a FreeSurfer annotation file
%       <filename> and returns structures and vectors that together
%       assign each index in the surface vector to one of several
%       structure names.
%
% COLORTABLE STRUCTURE
%
%       Consists of the following fields:
%       o numEntries:   number of entries
%       o orig_tab:     filename of original colortable file
%       o struct_names: cell array of structure names
%       o table:        n x 5 matrix
%                       Columns 1,2,3 are RGB values for struct color
%                       Column 4 is a flag (usually 0)
%                       Column 5 is the structure ID, calculated from
%                       R + G*2^8 + B*2^16 + flag*2^24
%
% LABEL VECTOR
%
%       Each component of the <label> vector has a structureID value. To
%       match the structureID value with a structure name, lookup the row
%       index of the structureID in the 5th column of the colortable.table
%       matrix. Use this index as an offset into the struct_names field
%       to match the structureID with a string name.
%
% PRECONDITIONS
%
%       o <filename> must be a valid FreeSurfer annotation file.
%
% POSTCONDITIONS
%
%       o <colortable> will be an empty struct if not embedded in a
%         FreeSurfer annotation file.
%

%
% read_annotation.m
% Original Author: Bruce Fischl
% CVS Revision Info:
%    $Author: nicks $
%    $Date: 2011/03/02 00:04:12 $
%    $Revision: 1.7 $
%
% Copyright © 2011 The General Hospital Corporation (Boston, MA) "MGH"
%
% Terms and conditions for use, reproduction, distribution and contribution
% are found in the 'FreeSurfer Software License Agreement' contained
% in the file 'LICENSE' found in the FreeSurfer distribution, and here:
%
% https://surfer.nmr.mgh.harvard.edu/fswiki/FreeSurferSoftwareLicense
%
% Reporting: freesurfer@nmr.mgh.harvard.edu
%

fp = fopen(filename, 'r', 'b');

verbosity = 1;
if ~isempty(varargin)
    verbosity       = varargin{1};
end;

if(fp < 0)
    if verbosity, disp('Annotation file cannot be opened'); end;
    return;
end

A = fread(fp, 1, 'int');

tmp = fread(fp, 2*A, 'int');
vertices = tmp(1:2:end);
label = tmp(2:2:end);

bool = fread(fp, 1, 'int');
if(isempty(bool)) %means no colortable
    if verbosity, disp('No Colortable found.'); end;
    colortable = struct([]);
    fclose(fp);
    return;
end

if(bool)

    %Read colortable
    numEntries = fread(fp, 1, 'int');

    if(numEntries > 0)

        if verbosity, disp('Reading from Original Version'); end;
        colortable.numEntries = numEntries;
        len = fread(fp, 1, 'int');
        colortable.orig_tab = fread(fp, len, '*char')';
        colortable.orig_tab = colortable.orig_tab(1:end-1);

        colortable.struct_names = cell(numEntries,1);
        colortable.table = zeros(numEntries,5);
        for i = 1:numEntries
            len = fread(fp, 1, 'int');
            colortable.struct_names{i} = fread(fp, len, '*char')';
            colortable.struct_names{i} = colortable.struct_names{i}(1:end-1);
            colortable.table(i,1) = fread(fp, 1, 'int');
            colortable.table(i,2) = fread(fp, 1, 'int');
            colortable.table(i,3) = fread(fp, 1, 'int');
            colortable.table(i,4) = fread(fp, 1, 'int');
            colortable.table(i,5) = colortable.table(i,1) + colortable.table(i,2)*2^8 + colortable.table(i,3)*2^16 + colortable.table(i,4)*2^24;
        end
        if verbosity
            disp(['colortable with ' num2str(colortable.numEntries) ' entries read (originally ' colortable.orig_tab ')']);
        end
    else
        version = -numEntries;
        if verbosity
            if(version~=2)
                disp(['Error! Does not handle version ' num2str(version)]);
            else
                disp(['Reading from version ' num2str(version)]);
            end
        end
        numEntries = fread(fp, 1, 'int');
        colortable.numEntries = numEntries;
        len = fread(fp, 1, 'int');
        colortable.orig_tab = fread(fp, len, '*char')';
        colortable.orig_tab = colortable.orig_tab(1:end-1);

        colortable.struct_names = cell(numEntries,1);
        colortable.table = zeros(numEntries,5);

        numEntriesToRead = fread(fp, 1, 'int');
        for i = 1:numEntriesToRead
            structure = fread(fp, 1, 'int')+1;
            if (structure < 0)
                if verbosity, disp(['Error! Read entry, index ' num2str(structure)]); end;
            end
            if(~isempty(colortable.struct_names{structure}))
                if verbosity, disp(['Error! Duplicate Structure ' num2str(structure)]); end;
            end
            len = fread(fp, 1, 'int');
            colortable.struct_names{structure} = fread(fp, len, '*char')';
            colortable.struct_names{structure} = colortable.struct_names{structure}(1:end-1);
            colortable.table(structure,1) = fread(fp, 1, 'int');
            colortable.table(structure,2) = fread(fp, 1, 'int');
            colortable.table(structure,3) = fread(fp, 1, 'int');
            colortable.table(structure,4) = fread(fp, 1, 'int');
            colortable.table(structure,5) = colortable.table(structure,1) + colortable.table(structure,2)*2^8 + colortable.table(structure,3)*2^16 + colortable.table(structure,4)*2^24;
        end
        if verbosity
            disp(['colortable with ' num2str(colortable.numEntries) ' entries read (originally ' colortable.orig_tab ')']);
        end
    end
else
    if verbosity
        disp('Error! Should not be expecting bool = 0');
    end;
end

fclose(fp);
end

function [vertex_coords, faces] = read_surf(fname)
%
% [vertex_coords, faces] = read_surf(fname)
% reads a the vertex coordinates and face lists from a surface file
% note that reading the faces from a quad file can take a very long
% time due to the goofy format that they are stored in. If the faces
% output variable is not specified, they will not be read so it
% should execute pretty quickly.
%


%
% read_surf.m
%
% Original Author: Bruce Fischl
% CVS Revision Info:
%    $Author: nicks $
%    $Date: 2013/01/22 20:59:09 $
%    $Revision: 1.4.2.1 $
%
% Copyright © 2011 The General Hospital Corporation (Boston, MA) "MGH"
%
% Terms and conditions for use, reproduction, distribution and contribution
% are found in the 'FreeSurfer Software License Agreement' contained
% in the file 'LICENSE' found in the FreeSurfer distribution, and here:
%
% https://surfer.nmr.mgh.harvard.edu/fswiki/FreeSurferSoftwareLicense
%
% Reporting: freesurfer@nmr.mgh.harvard.edu
%


%fid = fopen(fname, 'r') ;
%nvertices = fscanf(fid, '%d', 1);
%all = fscanf(fid, '%d %f %f %f %f\n', [5, nvertices]) ;
%curv = all(5, :)' ;

% open it as a big-endian file


%QUAD_FILE_MAGIC_NUMBER =  (-1 & 0x00ffffff) ;
%NEW_QUAD_FILE_MAGIC_NUMBER =  (-3 & 0x00ffffff) ;

TRIANGLE_FILE_MAGIC_NUMBER =  16777214 ;
QUAD_FILE_MAGIC_NUMBER =  16777215 ;

fid = fopen(fname, 'rb', 'b') ;
if (fid < 0)
    str = sprintf('could not open curvature file %s.', fname) ;
    error(str) ;
end

%Simon's Hotfix
%magic = fread3(fid) ;
magic = TRIANGLE_FILE_MAGIC_NUMBER;

if(magic == QUAD_FILE_MAGIC_NUMBER)
    vnum = fread3(fid) ;
    fnum = fread3(fid) ;
    vertex_coords = fread(fid, vnum*3, 'int16') ./ 100 ;
    if (nargout > 1)
        for i=1:fnum
            for n=1:4
                faces(i,n) = fread3(fid) ;
            end
        end
    end
elseif (magic == TRIANGLE_FILE_MAGIC_NUMBER)
    fgets(fid) ;
    fgets(fid) ;
    vnum = fread(fid, 1, 'int32') ;
    fnum = fread(fid, 1, 'int32') ;
    vertex_coords = fread(fid, vnum*3, 'float32') ;
    if (nargout > 1)
        faces = fread(fid, fnum*3, 'int32') ;
        faces = reshape(faces, 3, fnum)' ;
    end
end

vertex_coords = reshape(vertex_coords, 3, vnum)' ;
fclose(fid) ;
end
