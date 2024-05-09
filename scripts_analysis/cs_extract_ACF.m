%% Extract autocorrelation function for each subject
% load feature of interest (here AC1-40)
load('all_subj_feat.mat')

dat = zeros(350, 214, 5961);
for s = 1:length(all_subj_feat)
 dat(s,:,:) = cell2mat(all_subj_feat(s));
end

% load feature labels
load('features_selected_full.mat')
index = find(strcmp(labels_selected_full.Name, 'AC_1') == 1);
index2 = find(strcmp(labels_selected_full.Name, 'AC_40') == 1);

feat = dat(:,:,index:index2);
save('data_AC1to40.mat', 'feat')

AC_t4 = zeros(350, 40);

for l = 1:length(feat(1,1,:))
 AC_t4(:,l) = feat(:,52, l); % indicate region of interest, here parcel V8 rh (row 173); parcel T4 lh (row 52)
end

save('data_AC1to40_t4.mat', 'AC_t4')
