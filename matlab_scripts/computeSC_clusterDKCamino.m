function computeSC_clusterDKCamino(wmborder_file,roi,outfile)
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

tic
display(['Computing SC for ROI ' num2str(roi) '.']);
load('../masks_68/affine_matrix.mat')

wmborder.img = load(wmborder_file);
region_table = [1001:1003,1005:1035,2001:2003,2005:2035];
region_id_table=[];
for regid = [1001:1003,1005:1035,2001:2003,2005:2035],
    tmpids=find(wmborder.img.img == regid);
    region_id_table=[region_id_table; regid*ones(length(tmpids),1), tmpids];
end
SC_cap(length(region_id_table)).e=[];
SC_dist(length(region_table),length(region_table)).dist=[];
SC_dist_new(length(region_id_table)).e=[];

% Count the numbers of failure tracks
off_seed=0;
too_short=0;
good_tracks=0;
wrong_seed=0;
expected_tracks=0;
wrong_target=0;
generated_tracks=0;

% Loop over regions
for region = roi,
    
    expected_tracks=expected_tracks+length(find(wmborder.img.img==region_table(region)))*200;
    %tilefiles = dir([num2str(region_table(region)) '*.tck']);
    %More safe way (esp. when dealing with subcort Regions)
    d = dir([num2str(region_table(region)) '*.bFloat']);
    %Select only files that have a max. of 2 trailing numbers that depict the ordering...
    % e.g. don't select the files like '10012_subID.tck' when processing
    % the region 10 ...
    i=regexp({d.name},['^' num2str(region_table(region)) '\d{1,2}_.*\.bFloat$']);
    files={d(~cellfun('isempty',i))};
    tilefiles = files{1};
    clear d i files
    
    for tile = 1:length(tilefiles),
        if tilefiles(tile).bytes > 2000,
            clear tck tracks
            tck = read_camino_trackfile(tilefiles(tile).name);
            
            tracks = tck2voxel_cluster(tck,affine_matrix);
            display([tilefiles(tile).name ': Tracks loaded.']);
            generated_tracks = generated_tracks + length(tracks.data);
            
            % Loop over tracks
            for trackind = 1:length(tracks.data),
                % Find the "actual" seed-voxel: sometimes a track starts in a seed
                % voxel then heads into the wm and crosses another voxel of the
                % seeding-region. In this case we consider the last voxel on the
                % track path belonging to the seed region as the actual seed voxel.
                % Then we check whether the remaining path length is at least 10 mm
                % long.
                
                %Generate Linear indices in the 256x256x256-Imagecube from
                %all the voxels of the current track
                pathinds=sub2ind(size(wmborder.img.img),tracks.data{1,trackind}(:,1),tracks.data{1,trackind}(:,2),tracks.data{1,trackind}(:,3));
                %Fetch the corresponding Region-IDs from the WM-Border
                pathids=wmborder.img.img(pathinds);
                
                
                %CAMINO FIX
                % It seems like sometimes Camino mixes the ordering of
                % seed- and target-IDs. Since this fact, we now test if the
                % seed is either at the beginning OR the end of the vector
                if(region_table(region) == pathids(end))
                    pathinds = flipud(pathinds);
                    pathids = flipud(pathids);
                end
                
                
                %Generate linear Indices from all the Regions that are not
                %Zero-valued, EXCLUDING THE END-POINT!
                inregids=find(pathids(1:end-1)~=0);
                
                
                if ~isempty(inregids), %Check if the Path has Points on the Border
                    tracklen=size(tracks.data{1,trackind},1)-inregids(end); %Measure the length from the Endpoint to the last Point that exits the starting Region
                    if tracklen > 40, %Check if the track has a minimum length (step-size is 0.2mm)
                        if pathids(end) ~= 0, %Check if the Path has a valid endpoint
                            if region_table(region) == pathids(inregids(end)), %Check if the Region-ID requested matches the Seedpoint-Region
                                good_tracks=good_tracks+1; %"[...] when you have eliminated the impossible, whatever remains, however improbable, must be the truth"
                                
                                seed_id=find(region_id_table(:,2) == pathinds(inregids(end)));
                                target_id = find(region_id_table(:,2)==pathinds(end));
                                
                                SC_cap(seed_id).e=[SC_cap(seed_id).e;target_id]; %Add a Connection from Seedvoxel to Targetvoxel
                                SC_cap(target_id).e=[SC_cap(target_id).e;seed_id]; %Add a Connection from Targetvoxel to Seedvoxel
                                
                                % Old distances computation
                                r1=find(region_table==pathids(end)); %Transfer the Indexnr. from Desikan-Numbering (i.e. 1001-2035) to a Matrix-Numbering (i.e. 1-68)
                                r2=find(region_table==pathids(inregids(end)));
                                
                                SC_dist(r1,r2).dist=[SC_dist(r1,r2).dist;tracklen]; %Add the distance of the current track to a pool of distances between the two ROIS
                                SC_dist(r2,r1).dist=[SC_dist(r2,r1).dist;tracklen];
                                
                                % New distances computation
                                SC_dist_new(seed_id).e=[SC_dist_new(seed_id).e;tracklen]; %Add a Connection from Seedvoxel to Targetvoxel
                                SC_dist_new(target_id).e=[SC_dist_new(target_id).e;tracklen]; %Add a Connection from Targetvoxel to Seedvoxel
                                
                            else
                                wrong_seed=wrong_seed+1;
                                %display('Error. Region mismatch.');
                            end
                            
                        else
                            wrong_target=wrong_target+1;
                        end
                    else
                        too_short=too_short+1;
                    end
                else
                    off_seed=off_seed+1;
                end
                
            end
        end
    end
end

for i = 1:length(region_id_table),
    [SC_cap(i).e, ia, ~]=unique(SC_cap(i).e); %Filter out the redundant connections i.e. just count distinct connections
    SC_dist_new(i).e=SC_dist_new(i).e(ia); %Only take the length of the distinct connections into account
end

time=toc;

%save(outfile,'SC_cap', 'SC_dist', 'SC_dist_new', 'off_seed', 'too_short', 'good_tracks', 'wrong_seed', 'expected_tracks', 'wrong_target', 'generated_tracks','time')
save(outfile,'-mat7-binary','SC_cap', 'SC_dist', 'SC_dist_new', 'off_seed', 'too_short', 'good_tracks', 'wrong_seed', 'expected_tracks', 'wrong_target', 'generated_tracks','time')

%Increase the counter by creating an empty File
fclose(fopen(['../masks_68/counter/' num2str(roi) '.txt'], 'w'));


end

function tracks = read_camino_trackfile(trackFileName)
%Convert the raw binary data from caminos tracking methods into a matlab
%struct using the sam naming as in MRTrix

%Init
tracks = struct();
tracks.data = {};

%Open the file using big-endian coding
f = fopen(trackFileName,'r', 'b');

%Init the counter
counter = 1;

%Loop through the file
while ~feof(f)
    
    %Get the length of the next track
    trackLength = floor(fread(f,1,'float'));
    
    %Get the seeding point of the current track
    seedPoint = round(fread(f,1,'float'));
    
    %TODO: Include failsafe using seedpoint i.e. seedpoint must be equal to
    % 1 or the last point in the array!
    
    %Extract the coords for the track-points
    xyz = fread(f,[3 trackLength], 'float');
    
    %Save into struct
    tracks.data{counter} = xyz';
    
    %Increase the counter
    counter = counter +1;
    
end

%Close the file
fclose(f);

%Remove the last entry because it's empty...
tracks.data(end) = [];

end

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