%% This script does partial least squares regressions for each feature 
% JG 2023 / CS 2023

%% Prepare input for PLSR
% load all features
load('all_subj_feat_full.mat')

% reshape data
dat = zeros(350, 214, 5988); % subjects x parcels x features

for s = 1:length(all_subj_feat_full)
 dat(s,:,:) = cell2mat(all_subj_feat_full(s));
end

% get real age of participants
T = readtable('/home/uni10/nmri/projects/cstier/aging_features/demo_all_subjects.csv');
age = T.Var2;
Y = age;

% determine parameters for PLS
nfeat= size(dat,3);
kfold=10;
ncomp=5; %number of latent components

% stratify age groups
group=[];
for g=1:7
  group=[group g*ones(1,50)];
end

%% Run PLSR and evaluate prediction performance

% run 50 times to get a more stable estimation
for r = 1:50
 
 %design training and test partition
 cv = cvpartition(group,"Kfold",kfold);
 
 Y1=zeros(size(Y));
 acc1=zeros(1,nfeat);
 parcelweights=zeros(nfeat,214);
 mae1=acc1;
 var = {}; % store PCTVAR
 
 % loop over features
 for k=1:nfeat
  Y1=zeros(size(Y));
 
 try 
  %use try because there can be errors when NaNs are present
  beta=zeros(10,215);
 
  % now loop over folds
  for ifold=1:kfold
   %build PLS model on training data
   [xl,yl,XS,YS,beta(ifold,:),PCTVAR,mse,stat]= plsregress(dat(cv.training(ifold),:,k),Y(cv.training(ifold)),ncomp);
   %predict age in test data
   Y1(cv.test(ifold))=[ones(length(find(cv.test(ifold))),1) dat(cv.test(ifold),:,k)]*beta(ifold,:)'; 
   
   % Compute the mean of the training set for this fold (dummy model);
   % predict with constant mean age and compute difference to real model
   dummy = mean(Y(cv.training(ifold)));
   Y_dummy = repmat(dummy, length(Y(cv.test(ifold))), 1);
   
   dummy_mae(r,ifold,k) = mean(abs(Y_dummy - Y(cv.test(ifold))));
   mean_obs = mean(Y(cv.test(ifold)));
   dummy_r2(r,ifold,k) = 1 - (mean((Y(cv.test(ifold)) - Y_dummy).^2) / (mean((Y(cv.test(ifold)) - mean_obs).^2)));
  
   % Do prediction with real data and compute metrics for the fold only
   Y_real =[ones(length(find(cv.test(ifold))),1) dat(cv.test(ifold),:,k)]*beta(ifold,:)'; 
   real_mae(r,ifold,k) = mean(abs(Y_real - Y(cv.test(ifold))));
   mean_obs = mean(Y(cv.test(ifold)));
   real_r2(r,ifold,k) = 1 - (mean((Y(cv.test(ifold)) - Y_real).^2) / (mean((Y(cv.test(ifold)) - mean_obs).^2)));
   
   % Calculate the pairwise differences in performance metric
   mae_diff(r, ifold, k) = real_mae(r,ifold,k) - dummy_mae(r,ifold,k);
   r2_diff(r, ifold, k) = real_r2(r,ifold,k) - dummy_r2(r,ifold,k);
  end
 end
 
 if length(mae_diff) < k
  mae_diff(r, 1:10, k) = NaN;
  r2_diff(r, 1:10, k) = NaN;
  mae_diff_folds(r,k) = NaN;
  r2_diff_folds(r,k) = NaN;
  std_diff_folds(r,k) = NaN;
  mae_diff_prc(r,:,k) = [NaN NaN];
  mae_diff_pr_ref(r,k) = NaN;   %
 else
  % compute metrics across folds
  mae_diff_folds(r,k) = mean(mae_diff(r,:,k), 2);
  r2_diff_folds(r,k) = mean(r2_diff(r,:,k), 2);
  std_diff_folds(r,k) = std(mae_diff(r,:,k));
  mae_diff_prc(r,:,k) = prctile(mae_diff(r,:,k), [2.5 97.5]);
  mae_diff_pr_ref(r,k) = sum(mae_diff(r,:,k) < 0) / kfold;   % count how often PLS was better than the dummy model 
 end
 
 % get prediction performance meaures for the real model
 parcelweights(k,:)=mean(beta(:,2:end),1); %these are the weights for each parcel for brain plots
 acc1(1,k)=corr(Y1,Y); %compute correlation
 mae1(1,k)=mean(abs(Y1-Y)); %compute mean absolute error
 mean_obs=mean(Y);
 r2_1(1,k)=1-(mean((Y-Y1).^2)/(mean((Y-mean_obs).^2))); %compute R2 score
 
 var{k} = PCTVAR; 
 percvar(:,k) = cumsum(100*PCTVAR(2,:))';
 yhat(:,k) = Y1;
 msee{k} = mse;
 mse_y(:,k) = mse(2,:)';
 mse_x(:,k) = mse(1,:)';
 end
 
 % store differences for each repetition
 all_parcelw(r,:,:) = parcelweights;
 all_mae(r,:) = mae1;
 all_acc(r,:) = acc1;
 all_var(r,:) = var;
 all_percvar(:,:,r) = percvar;
 all_mse_y(:,:,r) = mse_y;
 all_mse_x(:,:,r) = mse_x;
 all_yhat(:,:,r) = yhat; 
 all_r2(r,:) = r2_1;
 
end

% save original model for all 50 runs
save('pls_all_full_10k_5c_hctsa_r50_stratf.mat', 'all_parcelw', 'all_mae', 'all_acc', 'all_var', 'all_percvar', 'all_mse_y', 'all_mse_x', 'all_yhat', 'all_r2')

% average across different partitions
av_parcelw = squeeze(nanmean(all_parcelw, 1));
av_mae = nanmean(all_mae, 1);
av_acc = nanmean(all_acc, 1);
av_percvar = squeeze(nanmean(all_percvar, 3));
av_mse_y = squeeze(nanmean(all_mse_y, 3));
av_mse_x = squeeze(nanmean(all_mse_x, 3));
av_yhat = squeeze(nanmean(all_yhat, 3));
av_r2 = nanmean(all_r2, 1);

save('pls_av_full_10k_5c_hctsa_r50_stratf.mat', 'av_parcelw', 'av_mae', 'av_acc', 'av_percvar', 'av_mse_y', 'av_mse_x', 'av_yhat', 'av_r2')

% save performance metrics (dummy model)
av_mae_rep = nanmean(mae_diff_folds, 1);
av_std_rep = nanmean(std_diff_folds, 1);
av_r2_rep = nanmean(r2_diff_folds, 1);
av_prc_rep = squeeze(nanmean(mae_diff_prc, 1));
av_mae_pr_ref = nanmean(mae_diff_pr_ref, 1);

save('pls_perform_diff_r50_stratf.mat', 'mae_diff', 'r2_diff', 'mae_diff_folds', 'mae_diff_pr_ref', 'std_diff_folds', 'r2_diff_folds')
save('pls_avperform_diff_r50_stratf.mat','av_mae_rep', 'av_std_rep', 'av_std_rep', 'av_r2_rep', 'av_prc_rep', 'av_mae_pr_ref');

for k=1:nfeat
  mae_dummy_folds(:,k) = mean(dummy_mae(:,:,k), 2);
  r2_dummy_folds(:,k) = mean(dummy_r2(:,:,k), 2);
  std_dummy_folds(:,k) = std(dummy_mae(:,:,k));
  mae_dummy_prc(:,:,k) = prctile(dummy_mae(:,:,k), [2.5 97.5]);

  mae_real_folds(:,k) = mean(real_mae(:,:,k), 2);
  r2_real_folds(:,k) = mean(real_r2(:,:,k), 2);
  std_real_folds(:,k) = std(real_mae(:,:,k));
  mae_real_prc(:,:,k) = prctile(real_mae(:,:,k), [2.5 97.5]);
end

av_mae_dummy = nanmean(mae_dummy_folds, 1);
av_r2_dummy = nanmean(r2_dummy_folds, 1);
av_std_dummy = nanmean(std_dummy_folds, 1);
av_mae_dummy_prc = squeeze(nanmean(mae_dummy_prc, 2));

av_mae_real = nanmean(mae_real_folds, 1);
av_r2_real = nanmean(r2_real_folds, 1);
av_std_real = nanmean(std_real_folds, 1);
av_mae_real_prc = squeeze(nanmean(mae_real_prc, 2));


save('pls_perform_dummy_r50_stratf.mat', 'dummy_mae', 'dummy_r2', 'real_mae', 'real_r2');
save('pls_avperform_dummy_r50_stratf.mat', 'av_mae_dummy', 'av_r2_dummy', 'av_std_dummy', 'av_mae_dummy_prc', 'av_mae_real', 'av_r2_real', 'av_std_real', 'av_mae_real_prc');




