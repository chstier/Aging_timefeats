function [features_selected] = cs_1_filteredfeat(res, cq, analysis_folder)

% requires the hctsa toolbox
% output 'res': contains feauture values
% output 'cq': computation quality

%% Paths
cd([analysis_folder '/hctsa-main/'])
startup

cd(analysis_folder)
labels = SQL_Add('ops','INP_ops_hctsa_jg2.txt',false,false);

%% Get 
% mean over trials
res_mean = squeeze(nanmean(res, 2));
cq_mean = squeeze(nanmean(cq, 2));

% create mask for features giving problems
inv_feat_av = find(squeeze(mean(cq_mean, 1)) ~= 0);
feat_mask = ones(7525,1);
feat_mask(inv_feat_av,1) = 0;

% check out which features give same (constant) values in each parcel and save with '0'
rep_feat = [];
for f = 1:length(res_mean(1,:))
 reps = find(length(res_mean(:,f))-length(unique(res_mean(:,f)))>= 50); % give features for which almost 50% of brain regions show same values
 if isempty(reps)
  rep_feat(f) = 1;
 else
  rep_feat(f) = 0;
 end
end

% extend mask 
msk = feat_mask.*rep_feat';
res_mean(:, (msk' == 0)) = [];
labels((msk == 0),:) = [];

% loop over parcels and identify outliers among the features
for r = 1:size(res_mean,1)
 outl=find(abs((res_mean(r,:)-nanmean(res_mean(r,:)))./nanstd(res_mean(r,:))) >4);
 res_mean(r,outl) = NaN;
end

% identify NaNs
nan = [];
for f = 1:size(res_mean,2)
 nans = isnan(res_mean(:,f));
 if any(nans == 1)
  nan(f) = 0;
 else
  nan(f) = 1;
 end
end

% get rid of features creating outliers
res_mean(:, (nan == 0)) = []; 
labels((nan' == 0),:) = [];

% make a full mask, which can be applied for all subjects
mask = zeros(length(res(1,1,:)),1);
getfeat = labels.ID;
mask(getfeat,1) = 1;
save('feature_mask.mat', 'mask')

% save selected labels
labels = SQL_Add('ops','INP_ops_hctsa_jg2.txt',false,false); % reload all labels
labels_selected = labels((mask == 1), :);
save('features_selected.mat', 'labels_selected')


end
