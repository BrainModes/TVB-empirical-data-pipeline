function theTable(subPath)
%Brainstem = 16
CorticalWhitmatter = [2 41];
subCort = [10:13 16 17 18 26 28 49:54 58 60];
roi = [1001:1003 1005:1035 2001:2003 2005:2035 subCort];
[aparc.hdr,aparc.img] = niak_read_vol([subPath 'calc_images/aparc+aseg2diff_1mm.nii.gz']);
cubeSize = size(aparc.img);
%get Voxel Size (assuming cubic voxels!)
voxelSize = aparc.hdr.info.voxel_size(1);

regionWMSurfaceSize = zeros(length(roi),2);

for i = 1:length(roi)
    regionWMSurfaceSize(i,1) = roi(i);
    
    index = find(aparc.img(:) == roi(i));
    
    %Get the values of the neighbour-voxels
    neigh = linNeigh(cubeSize,index);
    neigh = aparc.img(neigh(neigh > 0));
    
    regionWMSurfaceSize(i,2) = sum(ismember(neigh,CorticalWhitmatter)) * voxelSize^2;
end

%Now check how much interface there is between brainstem an subcortical
%regions
subCort(subCort == 16) = [];
index = find(aparc.img(:) == 16);
neigh = linNeigh(cubeSize,index);
neigh = aparc.img(neigh(neigh > 0));
%Count occurences
tmp = unique(neigh);
N = histc(neigh,tmp);
subCort2Brainstem = [tmp(ismember(tmp,subCort')) N(ismember(tmp,subCort))*(voxelSize^2)];

save([subPath '/theTable.mat'],'regionWMSurfaceSize','subCort2Brainstem');

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
%neigh(:,14) = index;

% Z = 2
neigh(:,13) = index-1; neigh(:,15) = index+1;                                           %y+/-1
neigh(:,11) = index - numRows; %neigh(:,10) = neigh(:,11) -1; neigh(:,12) = neigh(:,11) +1;    %x-1; y+/-1
neigh(:,17) = index + numRows; %neigh(:,16) = neigh(:,17) -1; neigh(:,18) = neigh(:,17) +1;    %x+1; y+/-1

% Z - 1
neigh(:,5) = index - numRows*numCols;                                                   %z-1
%neigh(:,4) = neigh(:,5) -1; neigh(:,6) = neigh(:,5) +1;                                 %y+/-1
%neigh(:,2) = neigh(:,5) -numRows; neigh(:,1) = neigh(:,2) -1; neigh(:,3) = neigh(:,2) +1;   %x-1; y+/-1
%neigh(:,8) = neigh(:,5) +numRows; neigh(:,7) = neigh(:,8) -1; neigh(:,9) = neigh(:,8) +1;   %x+1; y+/-1

% Z + 1
neigh(:,23) = index + numRows*numCols;                                                          %z-1
%neigh(:,22) = neigh(:,23) -1; neigh(:,24) = neigh(:,23) +1;                                     %y+/-1
%neigh(:,20) = neigh(:,23) -numRows; neigh(:,19) = neigh(:,20) -1; neigh(:,21) = neigh(:,20) +1;     %x-1; y+/-1
%neigh(:,26) = neigh(:,23) +numRows; neigh(:,25) = neigh(:,26) -1; neigh(:,27) = neigh(:,26) +1;     %x+1; y+/-1

end