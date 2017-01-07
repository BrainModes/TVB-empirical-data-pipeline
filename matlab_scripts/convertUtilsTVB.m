function convertUtilsTVB(subID,subFolder,brainstormPath,reconallPath)
% INPUT:
%   subID               ---     The identifier of the subject (must also be
%                               the one used within brainstorm!)
%   subFolder           ---     Complete path to the subjects folder
%                               including the ID, e.g. /home/petra/DTI_Pipe/QL_20120306 
%   weights             ---     The SC Matrix
%   delay               ---     The Matrix of distances between the regions of the SC matrix
%   brainstormFolder    ---     Path to the folder holding the results of
%                               the brainstorm toolbox
%   reconallFolder      ---     Path to the folder holding the results of
%                               FREESURFERs recon_all run
% OUTPUT: ConnectivityTVB_Brainstorm.zip --- See description below
%
% This script uses brainstorm functions, redefined below such that the
% installation of brainstorm is not necessary!!
%
%Stuff that need to be exportet from the Brainstorm-Folder:
% 1.) Headmask (full resolution) >> headmask
% 2.) Cortex-Mesh (15k resolution) >> cortex
% 3.) Channel Coordinates >> channels
% 4.) OpenMEEG BEM >> headmodel
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

cd(subFolder);
mkdir('TVB')
cd TVB

%Load the required things from the external toolboxes
MRI = load([brainstormPath '/anat/' subID '/subjectimage_T1.mat']);
cortex = load([brainstormPath '/anat/' subID '/tess_cortex_pial_low.mat']);
headmask = load([brainstormPath '/anat/' subID '/tess_head_mask.mat']);
channels = load([brainstormPath '/data/' subID '/@default_study/channel.mat']);
headmodel = load([brainstormPath '/data/' subID '/@default_study/headmodel_surf_openmeeg.mat']);
[hdr,~] = niak_read_vol([subFolder '/' reconallPath '/mri/aparc+aseg.nii']);
vox2ras = hdr.info.mat;
clear hdr

%Create the Region Mapping
labels = zeros(size(cortex.Vertices,1),1);
for i = 1:68
    labels(cortex.Atlas(3).Scouts(i).Vertices) = i-1; 
end

%Convert the LFM
ProjectionMatrix = bst_gain_orient(headmodel.Gain, headmodel.GridOrient);
ProjectionMatrix = ProjectionMatrix(1:61,:);

%Do the TVB Mesh Clean
[cortex.Vertices,cortex.Faces,cortex.VertNormals,labels, ProjectionMatrix] = removeFB(cortex.Vertices,cortex.Faces,cortex.VertNormals,labels, ProjectionMatrix);

%Save the Region Mapping
dlmwrite([subID '_RegionMapping.txt'],labels,'delimiter',' ')

%Convert Brainstorm Cortex-Mesh to RAS
temp = cs_scs2mri(MRI,cortex.Vertices' .*1000)';
temp = [temp ones(size(temp,1),1)]*vox2ras';
vertface2obj(temp(:,1:3),cortex.Faces,[subID '_cortex_brainstorm.obj']);
dlmwrite('vertices.txt',temp(:,1:3),'delimiter',' ','precision',20);
dlmwrite('triangles.txt',cortex.Faces - 1,'delimiter',' ','precision',20);
%Calculate new VertNormals
if(isfield(cortex,'VertNormals'))
    temp = cs_scs2mri(MRI,cortex.VertNormals' .*1000)';
    temp = [temp ones(size(temp,1),1)]*vox2ras';
    for i = 1:size(temp,1)
        temp(i,:) = temp(i,:)/norm(temp(i,:));
    end
    dlmwrite('normals.txt',temp(:,1:3),'delimiter',' ','precision',20);
    zip([subID '_Surface_Cortex'],{'normals.txt','triangles.txt','vertices.txt'})
    delete('vertices.txt'); delete('normals.txt'); delete('triangles.txt');
else
    zip([subID '_Surface_Cortex'],{'triangles.txt','vertices.txt'})
    delete('vertices.txt'); delete('triangles.txt');
end;

%Convert Brainstorm Face-Mesh to RAS
temp = cs_scs2mri(MRI,headmask.Vertices' .*1000)';
temp = [temp ones(size(temp,1),1)]*vox2ras';
vertface2obj(temp(:,1:3),headmask.Faces,[subID '_headmask_brainstorm.obj']);
dlmwrite('vertices.txt',temp(:,1:3),'delimiter',' ','precision',20);
dlmwrite('triangles.txt',headmask.Faces - 1,'delimiter',' ','precision',20);
%Calculate new VertNormals
if(isfield(headmask,'VertNormals'))
    temp = cs_scs2mri(MRI,headmask.VertNormals' .*1000)';
    temp = [temp ones(size(temp,1),1)]*vox2ras';
    for i = 1:size(temp,1)
        temp(i,:) = temp(i,:)/norm(temp(i,:));
    end
    dlmwrite('normals.txt',temp(:,1:3),'delimiter',' ','precision',20);
    zip([subID '_Surface_Face'],{'normals.txt','triangles.txt','vertices.txt'})
    delete('vertices.txt'); delete('normals.txt'); delete('triangles.txt');
else
    zip([subID '_Surface_Face'],{'triangles.txt','vertices.txt'})
    delete('vertices.txt'); delete('triangles.txt');   
end;

%Convert Channel Locations
fid = fopen([subID '_EEGLocations.txt'], 'wt');
string2write = ''; 
for i = 1:61
    coord = (channels.Channel(i).Loc)';
    coord = cs_scs2mri(MRI,channels.Channel(i).Loc .*1000)';
    coord = [coord ones(size(coord,1),1)]*vox2ras';
    %coord = coord(1:3)/norm(coord(1:3)); %Normalize
    string2write = [string2write '\n' channels.Channel(i).Name ' ' num2str(coord(1)) ' ' num2str(coord(2)) ' ' num2str(coord(3))];
end
fprintf(fid,string2write);
fclose(fid);

%Save the LFM
save([subID '_ProjectionMatrix.mat'],'ProjectionMatrix')

end

function vertface2obj(v,f,name)
% VERTFACE2OBJ Save a set of vertice coordinates and faces as a Wavefront/Alias Obj file
% VERTFACE2OBJ(v,f,fname)
%     v is a Nx3 matrix of vertex coordinates.
%     f is a Mx3 matrix of vertex indices. 
%     fname is the filename to save the obj file.

fid = fopen(name,'w');

for i=1:size(v,1)
fprintf(fid,'v %f %f %f\n',v(i,1),v(i,2),v(i,3));
end

fprintf(fid,'g foo\n');

for i=1:size(f,1);
fprintf(fid,'f %d %d %d\n',f(i,1),f(i,2),f(i,3));
end
fprintf(fid,'g\n');

fclose(fid);

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

function bd = blk_diag(A,n)
%BLK_DIAG Make or extract a sparse block diagonal matrix
% function bd = blk_diag(A,n);
% If A is not sparse, then
% returns a sparse block diagonal "bd", diagonalized from the
% elements in "A".
% "A" is ma x na, comprising bdn=(na/"n") blocks of submatrices.
% Each submatrix is ma x "n", and these submatrices are
% placed down the diagonal of the matrix.
%
% If A is already sparse, then the operation is reversed, yielding a block
% row matrix, where each set of n columns corresponds to a block element
% from the block diagonal.
%
% Routine uses NO for-loops for speed considerations.

% Copyright (c) 1993-1995, The Regents of the University of California.
% This software was produced under a U.S. Government contract
% (W-7405-ENG-36) by Los Alamos National Laboratory, which is operated
% by the University of California for the U.S. Department of Energy,
% and was funded in part by NIH grant R01-MH53213 through the University
% of Southern California to Los Alamos National Laboratory, 
% and was funded in part by NIH grant R01-EY08610 to Los Alamos
% National Laboratory.
% The U.S. Government is licensed to use, reproduce, and distribute this
% software.  Permission is granted to the public to copy and use this
% software without charge, provided that this Notice and any statement
% of authorship are reproduced on all copies.  Neither the Government
% nor the University makes any warranty, express or implied, or assumes
% any liability or responsibility for the use of this software.
%
% Author: John C. Mosher, Ph.D.
% Los Alamos National Laboratory
% Group ESA-MT, MS J580
% Los Alamos, NM 87545
% email: mosher@LANL.Gov

% July 29, 1993 Author
% September 28, 1993 JCM Conversion to sparse
% July 27, 1995 JCM inverse block diagonal added

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

if(~issparse(A)),		% then make block sparse
    [ma,na] = size(A);
    bdn = na/n; 			% number of submatrices
    
    if(bdn - fix(bdn)),
        error('Width of matrix must be even multiple of n');
    end
    
    if(0)
        i = [1:ma]';
        i = i(:,ones(1,n));
        i = i(:); 			% row indices first submatrix
        
        ml = length(i); 		% ma*n
        
        % ndx = [0:(bdn-1)]*ma; 	% row offsets per submatrix
        ndx = [0:ma:(ma*(bdn-1))]; 	% row offsets per submatrix
        
        i = i(:,ones(1,bdn)) + ndx(ones(ml,1),:);
    else
        tmp = reshape([1:(ma*bdn)]',ma,bdn);
        i = zeros(ma*n,bdn);
        for iblock = 1:n,
            i((iblock-1)*ma+[1:ma],:) = tmp;
        end
    end
    
    i = i(:); 			% row indices foreach sparse bd
    
    
    j = [1:na];
    j = j(ones(ma,1),:);
    j = j(:); 			% column indices foreach sparse bd
    
    bd = sparse(i,j,A(:));
    
else 				% already is sparse, unblock it
    
    [mA,na] = size(A);		% matrix always has na columns
    % how many entries in the first column?
    bdn = na/n;			% number of blocks
    ma = mA/bdn;			% rows in first block
    
    % blocks may themselves contain zero entries.  Build indexing as above
    if(0)
        i = [1:ma]';
        i = i(:,ones(1,n));
        i = i(:); 			% row indices first submatrix
        
        ml = length(i); 		% ma*n
        
        % ndx = [0:(bdn-1)]*ma; 	% row offsets per submatrix
        ndx = [0:ma:(ma*(bdn-1))]; 	% row offsets per submatrix
        
        i = i(:,ones(1,bdn)) + ndx(ones(ml,1),:);
    else
        tmp = reshape([1:(ma*bdn)]',ma,bdn);
        i = zeros(ma*n,bdn);
        for iblock = 1:n,
            i((iblock-1)*ma+[1:ma],:) = tmp;
        end
    end
    
    i = i(:); 			% row indices foreach sparse bd
    
    
    if(0)
        j = [1:na];
        j = j(ones(ma,1),:);
        j = j(:); 			% column indices foreach sparse bd
        
        % so now we have the complete two dimensional indexing. Convert to
        % one dimensional
        
        i = i + (j-1)*mA;
    else
        j = [0:mA:(mA*(na-1))];
        j = j(ones(ma,1),:);
        j = j(:);
        
        i = i + j;
    end
    
    bd = full(A(i)); 	% column vector
    bd = reshape(bd,ma,na);	% full matrix
end

end

function Gain = bst_gain_orient(Gain, GridOrient)
% BST_GAIN_ORIENT: Constrain source orientation on a leadfield matrix
%
% USAGE:  Gain = bst_gain_orient(Gain, GridOrient)
%
% INPUT: 
%     - Gain       : [nChannels,3*nSources] leadfield matrix
%     - GridOrient : [nSources,3] orientation for each source of the Gain matrix
% OUTPUT:
%     - Gain : [nChannels,nSources] leadfield matrix with fixed orientations

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
% Authors: Francois Tadel, 2009-2010

% Create a sparse block diagonal matrix for orientations
GridOrient = blk_diag(GridOrient', 1);
% Apply the orientation to the Gain matrix
Gain = Gain * GridOrient;

end

function [vertices,faces,normals,labels,ProjectionMatrix] = removeFB(vertices,faces,normals,labels,ProjectionMatrix)
    
    
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
    
     %Remove columns from the projection matrix
     ProjectionMatrix(:,FBtri) = [];
    
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