%Map the vertices of the brainsuite cortex mesh (downsampled) onto the
%freesurfer mesh coordinates to transfer the Desikan Killaney parcellation
%onto the Brainsuite Mesh

%load the meshes
load('meshes.mat');

%Set the Atlas
AtlasNumber = 3; %Desikan Killaney
atlas = cortex_freesurfer.Atlas(AtlasNumber); 

%Init new atlas in brainsuite cortex
cortex_brainsuite.Atlas(AtlasNumber).Scouts = [];
cortex_brainsuite.Atlas(AtlasNumber).Scouts(length(atlas.Scouts)).Vertices = [];

%Now loop over all Regions in the given Atlas (e.g. Desikan Killaney) and
%create a hash table of which vertices do belong to which parcellation
hash_tab_fs = [];
for i = 1:length(atlas.Scouts)
   
    %Extract the mesh from the constructs
    vertices_fs = cortex_freesurfer.Vertices(atlas.Scouts(i).Vertices,:);
    
    hash_tab_fs = [hash_tab_fs; vertices_fs ones(size(vertices_fs,1),1)*i];
    
end 

%Create a list of the brainsuite mesh vertices which are to be mapped
vertices_bs = [];
for i=1:length(cortex_brainsuite.Atlas(2).Scouts)
   
    vertices_bs = [vertices_bs; cortex_brainsuite.Vertices(cortex_brainsuite.Atlas(2).Scouts(i).Vertices,:) cortex_brainsuite.Atlas(2).Scouts(i).Vertices];
    
end

%Search the nearest neighbours
IDX = knnsearch(hash_tab_fs(:,1:3), vertices_bs(:,1:3));
%TRANSLATED INto labels
new_labels = hash_tab_fs(IDX,4);

%Loop over all vertices and insertt them into a new Atlas
for i = 1:length(new_labels)
   
    label = new_labels(i);
    
    %Insert
    cortex_brainsuite.Atlas(AtlasNumber).Scouts(label).Vertices = [cortex_brainsuite.Atlas(AtlasNumber).Scouts(label).Vertices; vertices_bs(i,4)];
    
end

%Save the Mesh
save('tess_cortex_pial_low.mat', '-struct', 'cortex_brainsuite');