function aggregateSC68(outfile,wmborder_file, subID)
%Parameters:
%   outfile - String; Filename of the resulting File, e.g. 'subDA_SC.mat'
%   wmborder - .mat-File; 3D-Array containing the Imagecube of the
%               parcellated gmwmborder
%   subID - String; The Identiefier of the Subject, e.g. 'DA'


wmborder.img = load(wmborder_file);
region_table = [1001:1003,1005:1035,2001:2003,2005:2035];
counter=0;
%inverse_region_table = zeros(1,2035);
%region_id_table = zeros(nnz(wmborder.img.img),2);
region_id_table=[];
for regid = [1001:1003,1005:1035,2001:2003,2005:2035],
    counter=counter+1;
    inverse_region_table(regid) = counter; %Transfer table between DK-Numbering and Matrix Numbering
    tmpids=find(wmborder.img.img == regid);
    region_id_table=[region_id_table; regid*ones(length(tmpids),1), tmpids];    
end
SC_cap_agg_tmp(length(region_id_table)).e=[];

SC_cap_agg_bwflav1 = zeros(68,68);
SC_cap_agg_bwflav2 = zeros(68,68);
SC_cap_agg_counts = zeros(68,68);
SC_dist_agg_steps(68,68).dist=[];
SC_dist_median_agg_steps = zeros(68,68);
SC_dist_mean_agg_steps = zeros(68,68);
SC_dist_var_agg_steps = zeros(68,68);
SC_dist_mode_agg_steps = zeros(68,68);

for roi = 1:68,
    clear SC_cap SC_dist
    
    display(['Processing ROI: ' num2str(roi)]);
    
    load(['SC_row_' num2str(roi) subID '.mat'])
    
    for ind_ind=1:length(region_id_table),
        SC_cap_agg_tmp(ind_ind).e=[SC_cap_agg_tmp(ind_ind).e;SC_cap(ind_ind).e];
    end
    
    for roi2 = 1:68,
        SC_dist_agg_steps(roi,roi2).dist=[SC_dist_agg_steps(roi,roi2).dist;SC_dist(roi,roi2).dist];
        SC_dist_agg_steps(roi2,roi).dist=[SC_dist_agg_steps(roi2,roi).dist;SC_dist(roi2,roi).dist];
    end
end

for ind_ind=1:length(region_id_table),
    SC_cap_agg_tmp(ind_ind).e=unique(SC_cap_agg_tmp(ind_ind).e); 
    
    seed_id=find(region_table==region_id_table(ind_ind,1));
    target_ids=inverse_region_table(region_id_table(SC_cap_agg_tmp(ind_ind).e,1));
    for ti=1:length(target_ids),
        SC_cap_agg_bwflav1(seed_id,target_ids(ti)) = SC_cap_agg_bwflav1(seed_id,target_ids(ti)) + 1;
        SC_cap_agg_bwflav2(seed_id,target_ids(ti)) = SC_cap_agg_bwflav2(seed_id,target_ids(ti)) + (1/(length(target_ids)));
    end
end
 
for roi = 1:68,
    for roi2 = 1:68,
        if ~isempty(SC_dist_agg_steps(roi,roi2).dist),
            SC_cap_agg_counts(roi,roi2) = length(SC_dist_agg_steps(roi,roi2).dist);
            SC_dist_median_agg_steps(roi,roi2) = median(SC_dist_agg_steps(roi,roi2).dist);
            SC_dist_mean_agg_steps(roi,roi2) = mean(SC_dist_agg_steps(roi,roi2).dist);
            SC_dist_var_agg_steps(roi,roi2) = var(SC_dist_agg_steps(roi,roi2).dist);
            SC_dist_mode_agg_steps(roi,roi2) = mode(SC_dist_agg_steps(roi,roi2).dist);
        end
    end
end

%String to explain how to get from steps to length
steps2lenght = 'The steplength used for this tracking was 0.2mm/step. So for instance, a track length of 10 steps means 2mm.';

%Normalize the Cap.Matrices
SC_cap_agg_bwflav1_norm = (SC_cap_agg_bwflav1 - min(min(SC_cap_agg_bwflav1)))/(max(max(SC_cap_agg_bwflav1)) - min(min(SC_cap_agg_bwflav1)));
SC_cap_agg_bwflav2_norm = (SC_cap_agg_bwflav2 - min(min(SC_cap_agg_bwflav2)))/(max(max(SC_cap_agg_bwflav2)) - min(min(SC_cap_agg_bwflav2)));


save(outfile,'-mat7-binary', 'steps2lenght', 'SC_cap_agg_counts', 'SC_cap_agg_bwflav1','SC_cap_agg_bwflav2', 'SC_cap_agg_bwflav1_norm', 'SC_cap_agg_bwflav2_norm','SC_dist_agg_steps', 'SC_dist_mean_agg_steps', 'SC_dist_mode_agg_steps', 'SC_dist_median_agg_steps', 'SC_dist_var_agg_steps')
end

%{


fileID = fopen('batch_agg.sh','w');


fprintf(fileID, ['oarsub -l walltime=06:40:00 "octave --eval \\"aggregateSC_new(''subCN_SC.mat'',''/home/petra/DTI_Tracking/data/subCN/Tracking_Masks/wmborder.mat'', ''subCN'')\\""\n']);


fclose(fileID);

%}
