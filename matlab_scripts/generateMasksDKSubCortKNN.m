function generateMasksDKSubCortKNN(subPath,pathOnCluster)
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
% Last Change: 08-06-2014

%Approx. Runtime on a MacBook Pro 13" 2011 Core i5 --> ~23min
%This script is meant to be run locally for now!
tic
mask_output_folder=[subPath 'mrtrix_68/masks_68/'];
mkdir([subPath 'mrtrix_68/'],'masks_68')

%Set the desired Number of Seedpoints per voxel
seedsPerVoxel = 200;
%seedsPerVoxel = 2500;
%Mask Chunk Size
chunkSize = 100000/seedsPerVoxel;

%Extract and Save the Affine Matrix for later use
%header = load_untouch_header_only([subPath 'wmoutline2diff_1mm.nii.gz']);
%TODO: First uncompress into tmp-file, afterwards recompress!.....
%header = niak_read_hdr_nifti([subPath 'wmoutline2diff_1mm.nii.gz']);
%affine_matrix = inv([header.hist.srow_x; header.hist.srow_y; header.hist.srow_z; 0 0 0 1]);

[wmborder.hdr,wmborder.img] = niak_read_vol([subPath 'calc_images/wmoutline2diff_1mm.nii.gz']);
%[wmborder.hdr,wmborder.img] = niak_read_vol([subPath 'calc_images/wmoutline2diff.nii.gz']);
affine_matrix = inv(wmborder.hdr.info.mat);
save([mask_output_folder 'affine_matrix.mat'], 'affine_matrix')
[aparc.hdr,aparc.img] = niak_read_vol([subPath 'calc_images/aparc+aseg2diff_1mm.nii.gz']);
%[aparc.hdr,aparc.img] = niak_read_vol([subPath 'calc_images/aparc+aseg2diff.nii']);

% ++++++ KNN Ansatz ++++++++++++++++++++++++++++++++++
%Strip-off all non-cortical structures
CortStruct = aparc.img;
CortStruct(CortStruct < 1001) = 0;
CortStruct(CortStruct > 2035) = 0;
CortStruct(CortStruct == 2000) = 0;
CortStruct(CortStruct == 2004) = 0;
CortStruct(CortStruct == 1004) = 0;
%Get Indices of all nnz Voxels
tmp = find(CortStruct > 0);
[xCort,yCort,zCort] = ind2sub(size(aparc.img),tmp);


%Get the indices of all nnz-voxels
tmp = find(wmborder.img > 0);
[xBorder,yBorder,zBorder] = ind2sub(size(wmborder.img),tmp);
%Get the nearest neighbors of the wm-gm-borderline
Cort = [xCort yCort zCort];
Border = [xBorder yBorder zBorder];
[IDX,D] = knnsearch(Cort,Border);

%Clear everything above threshold
thresh = 1.1;
IDX(D > thresh) = []; Border(D > thresh,:) = [];

wmborder.img = zeros(size(wmborder.img));
for i = 1:size(Border,1)
    x = Cort(IDX(i),1); y = Cort(IDX(i),2); z = Cort(IDX(i),3);
    wmborder.img(Border(i,1),Border(i,2),Border(i,3)) = aparc.img(x,y,z); 
end
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++

% High-res GM-WM-border
% [nii.hdr,nii.img] = niak_read_vol([subPath 'calc_images/wmparc2diff_1mm.nii.gz']);
% nii.hdr.file_name = [mask_output_folder 'wmparcMask_1mm.nii.gz'];
% 
% nii.img(nii.img <  1001) = 0;
% nii.img(nii.img == 1004) = 0;
% nii.img(nii.img == 2004) = 0;
% nii.img(nii.img == 3004) = 0;
% nii.img(nii.img == 4004) = 0;
% nii.img(nii.img == 2000) = 0;
% nii.img(nii.img == 3000) = 0;
% nii.img(nii.img == 4000) = 0;
% nii.img(nii.img >  4035) = 0;
% nii.img(nii.img > 3000) = nii.img(nii.img > 3000) - 2000;
% nii.img(nii.img > 2036) = 0;
% nii.img(nii.img < 1001) = 0;
% 
% niak_write_vol(nii.hdr,nii.img);
% wmborder.img(wmborder.img > 0) = nii.img(wmborder.img > 0);



% +++++++++++++  Merge WM-Border with Subcort +++++++++++++++++++++++++++++
%Define Subcortical Structures
subCort = [10:13 16 17 18 26 28 49:54 58 60];
%SubC = aparc;
%SubC = zeros(size(aparc.img));
%tmp = zeros(size(nii.img));
tmp = [];
for i = subCort
   tmp = [tmp; find(aparc.img == i)]; 
end
WM = [2 41 251:255];
%Loop over all SubCort Voxels and check if they have a neighbor in WM.
for t = 1:size(tmp,1)
    [x,y,z] = ind2sub(size(aparc.img),tmp(t));
    
    %Check neighborhood
%     for i = x-1:x+1
%         for j = y-1:y+1
%             for k = z-1:z+1
    for i = [x-1 x+1]
        for j = [y-1 y+1]
            for k = [z-1 z+1]
                if (wmborder.img(i,j,k) == 0 && sum(aparc.img(i,j,k) == WM) > 0) %Check if Current Voxel is a WM Voxel
                     %SubC(i,j,k) = aparc.img(x,y,z);
                     wmborder.img(i,j,k) = aparc.img(x,y,z);
                end
            end
        end
    end
end

%wmborder.img = wmborder.img + SubC;
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

wmborder.hdr.file_name = [mask_output_folder 'gmwmborder_1mm.nii.gz'];
%wmborder.hdr.file_name = [mask_output_folder 'gmwmborder.nii.gz'];
niak_write_vol(wmborder.hdr,wmborder.img);


img=wmborder.img;
save([mask_output_folder 'wmborder.mat'], 'img')
clear img

% Seed & target masks
counter=0;
for i = [1001:1003,1005:1035,2001:2003,2005:2035 subCort]
    display(['Processing RegionID ' num2str(i)]);
    
    tmpimg=wmborder.img;
    tmpimg(tmpimg ~= i) = 0;
    tmpimg(tmpimg > 0) = 1;
    maskvoxel=find(tmpimg>0);
    nummasks=floor(length(maskvoxel)/chunkSize);
    for j = 1:nummasks,
        aparc.img=zeros(size(tmpimg));
        aparc.img(maskvoxel(1+(chunkSize*(j-1)):(chunkSize*j))) = 1;
        aparc.hdr.file_name = [mask_output_folder 'seedmask' num2str(i) num2str(j) '_1mm.nii.gz'];
        niak_write_vol(aparc.hdr,aparc.img);

        tmpfind=[num2str(i) num2str(j)];
        counter=counter+1;
        numseeds(counter,1)=str2num(tmpfind);
        numseeds(counter,2)=length(find(aparc.img>0));
        numseeds(counter,3)=i;
    end
    aparc.img=zeros(size(tmpimg));
    aparc.img(maskvoxel(1+(chunkSize*nummasks):end)) = 1;

    aparc.hdr.file_name = [mask_output_folder 'seedmask' num2str(i) num2str((nummasks+1)) '_1mm.nii.gz'];
    niak_write_vol(aparc.hdr,aparc.img);

    tmpfind=[num2str(i) num2str(nummasks+1)];
    counter=counter+1;
    numseeds(counter,1)=str2num(tmpfind);
    numseeds(counter,2)=length(find(aparc.img>0));
    numseeds(counter,3)=i;
        
    tmpimg=wmborder.img;
    tmpimg(tmpimg == i) = 0;
    tmpimg(tmpimg > 0) = 1;
    aparc.img=tmpimg;

    aparc.hdr.file_name = [mask_output_folder 'targetmask' num2str(i) '_1mm.nii.gz'];
    niak_write_vol(aparc.hdr,aparc.img);
    
end
numseeds(:,2)=numseeds(:,2)*seedsPerVoxel;

%Finally check if one of the masks has a seedcount of 0 and delete such
%entries
numseeds(numseeds(:,2) == 0,:) = [];

dlmwrite([mask_output_folder 'seedcount.txt'],numseeds,'delimiter', ' ','precision',10);

%Generate Batch File
load([mask_output_folder 'seedcount.txt'])
fileID = fopen([mask_output_folder 'batch_track.sh'],'w');
fprintf(fileID,'#!/bin/bash\n');
%fprintf(fileID,'export jid=$1\n');

slashes = strfind(subPath,'/'); %Find all occurences of the slash in the subPath
for roiid=1:size(seedcount,1),
    fprintf(fileID, ['oarsub -n trk_' subPath(slashes(end-1)+1:slashes(end)-1) ' -l walltime=06:00:00 -p "host > ''n01''" "./trackingClusterDK.sh ' pathOnCluster ' ' num2str(seedcount(roiid,1)) '"\n']);
end
fclose(fileID);

toc
end

function neigh = linNeigh(cubeSize,index)
% size: output of size(wmborder.img) i.e. 3 elements vector
% index: column vector of indices (size n x 1)
numRows = cubeSize(1);
numCols = cubeSize(2);
%numDepth = size(3);

%We got 26 Neighbours due to 3D + the voxel itself
neigh = zeros(size(index,1),27);
%Insert the voxel itself
neigh(:,14) = index;

% Z = 2
neigh(:,13) = index-1; neigh(:,15) = index+1;                                           %y+/-1
neigh(:,11) = index - numRows; neigh(:,10) = neigh(:,11) -1; neigh(:,12) = neigh(:,11) +1;    %x-1; y+/-1
neigh(:,17) = index + numRows; neigh(:,16) = neigh(:,17) -1; neigh(:,18) = neigh(:,17) +1;    %x+1; y+/-1

% Z - 1
neigh(:,5) = index - numRows*numCols;                                                   %z-1
neigh(:,4) = neigh(:,5) -1; neigh(:,6) = neigh(:,5) +1;                                 %y+/-1
neigh(:,2) = neigh(:,5) -numRows; neigh(:,1) = neigh(:,2) -1; neigh(:,3) = neigh(:,2) +1;   %x-1; y+/-1
neigh(:,8) = neigh(:,5) +numRows; neigh(:,7) = neigh(:,8) -1; neigh(:,9) = neigh(:,8) +1;   %x+1; y+/-1

% Z + 1
neigh(:,23) = index + numRows*numCols;                                                          %z-1
neigh(:,22) = neigh(:,23) -1; neigh(:,24) = neigh(:,23) +1;                                     %y+/-1
neigh(:,20) = neigh(:,23) -numRows; neigh(:,19) = neigh(:,20) -1; neigh(:,21) = neigh(:,20) +1;     %x-1; y+/-1
neigh(:,26) = neigh(:,23) +numRows; neigh(:,25) = neigh(:,26) -1; neigh(:,27) = neigh(:,26) +1;     %x+1; y+/-1

end


