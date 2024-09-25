%% This script computes LASSO regressions for selected features
% CS 2024

%% Prepare input 
% load all features
load('all_subj_feat_full.mat')

% reshape data
dat = zeros(350, 214, 5988); % subjects x parcels x features

for s = 1:length(all_subj_feat_full)
 dat(s,:,:) = cell2mat(all_subj_feat_full(s));
end
 
% z-score
for k=1:350
 for k2=1:5988
  dat(k,:,k2) = zscore(dat(k,:,k2)); % z-score across subjects
 end
end

% get real age of participants
T = readtable('/home/uni10/nmri/projects/cstier/aging_features/demo_all_subjects.csv');
age = T.Var2;
Y = age;

% stratify age groups
group=[];
for g=1:7
  group=[group g*ones(1,50)];
end

% select features
acind=[84:123]; % use all AC lags
% acind=[5962:5979,5981]; % use all conventional features, but exclude local maxima (NANs)
nl=length(acind);

% determine parameters for LASSO
n_features = nl;
n_parcels = 214;
kfold=10;

%% Run LASSO with nested cross-validation and predict age

% run 50 times to get a more stable estimation
for iparc=1:50
 cv = cvpartition(group,"Kfold",kfold);
 Y1=zeros(size(Y));
 
   for ifold=1:kfold
    % reshape training data
    tmp=squeeze(dat(cv.training(ifold),:,acind));
    tmp2=reshape(tmp,[315 214*nl]);
    
    % perform CV again to find appropriate lambda
    [B,FitInfo] = lasso(tmp2,Y(cv.training(ifold)), 'CV', 10);
    
    idxLambda1SE = FitInfo.Index1SE;
    coef = B(:,idxLambda1SE); 
    beta(iparc,ifold,:) = coef;
    coef0 = FitInfo.Intercept(idxLambda1SE);
    interc(iparc,ifold) = coef0;
    
    % now predict in test data
    tmp_test=squeeze(dat(cv.test(ifold),:,acind));
    tmp2_test=reshape(tmp_test,[35 214*nl]);
    
    Y1(cv.test(ifold))= tmp2_test * coef + coef0;
    
    clear coef coef0
   end
   
   % save prediction performance for each repetition
   acc1(1,iparc)=corr(Y1,Y); %compute correlation
   mae1(1,iparc)=mean(abs(Y1-Y)); %compute mean absolute error
   mean_obs=mean(Y);
   r2_1(1,iparc)=1-(mean((Y-Y1).^2)/(mean((Y-mean_obs).^2))); %compute R2 score
   Y_pred(:,iparc) = Y1; 
end

save('Lasso_50rep_allAC.mat', 'beta', 'interc', 'acc1', 'mae1', 'r2_1', 'Y_pred')

% average across repetitions
av_acc = mean(acc1, 2);
av_mae = mean(mae1, 2);
av_r2 = mean(r2_1,2);
av_yhat = mean(Y_pred, 2);

% average betas across folds, then across repetitions
for iparc = 1:15
 av_beta_folds(iparc,:) = mean(abs(beta(iparc,:,:)), 2);
 av_beta_folds_notabs(iparc,:) = mean(beta(iparc,:,:), 2);
end

av_allbeta = mean(av_beta_folds, 1);
av_allbeta_notabs = mean(av_beta_folds_notabs, 1);

% project back to features/parcels
reshaped_results = reshape(av_allbeta, [n_parcels, n_features])';
reshaped_notabs = reshape(av_allbeta_notabs, [n_parcels, n_features])';

% transform weights according to Haufe et al.
for n = 1:nl
 idx = acind(n);
 feature_transf_abs(n,:) = (cov(dat(:,:,idx))*reshaped_results(n,:)')'; 
 feature_transf_notabs(n,:) = (cov(dat(:,:,idx))*reshaped_notabs(n,:)')'; 
end

save('Lasso_50rep_allAC_av_transf.mat', 'av_acc', 'av_mae', 'av_r2', 'av_yhat', 'av_allbeta', 'av_allbeta_notabs', 'reshaped_results', 'reshaped_notabs', 'feature_transf_abs', 'feature_transf_notabs')

% average across parcels to see results for each lag
feature_betas = mean(reshaped_results, 2);
feature_betas_notabs = mean(reshaped_notabs, 2);


%% Plot weights averaged across features
brain_abs = mean(reshaped_results, 1);
brain_notabs = mean(reshaped_notabs, 1);
 
% load maps for plotting
load('/conf/suma-all-fsaverage-10.mat','suma_all')
suma_schaefer = load(['/conf/atlas/Schaefer2018_200Parcels_7Networks_suma-all-fsaverage-10.mat'],'suma_all');
 
results_dir = '/analysis_lasso/';
file_name = 'lasso_brain_AC1_40_absolute';
feature = 'AC lags 1-40';
metric = 'lasso betas across features (absolute)'; 

% transform according to Haufe et al., 2014
sel_features = mean(dat(:,:, acind), 3);
transf = cov(sel_features)*brain_notabs';
 
 keydata = [transf suma_schaefer.suma_all.annot_key{1,1}];
                   vertex_data = zeros(2338,2);

                   for v = 1:length(suma_schaefer.suma_all.annot)
                       keynr = suma_schaefer.suma_all.annot(v);
                       if keynr == 0
                           vertex_data(v,1) = 0;
                       else
                           rownr = find(keydata(:,2) == keynr);
                           log_p_v = keydata(rownr,1);
                           vertex_data(v,1) = log_p_v;
                           logp = vertex_data(:,1);
                       end
                   end  

 opt=[];
 opt.title = [feature, metric];
 opt.output = [results_dir file_name '.png'];
 opt.per_hemi=1;
 opt.per_cortex=1;
 opt.rot=[90 0 ; -90 0];
 opt.opathresh = 0.00000000001;
 opt.colormap='hot';
 opt.colorbar='hot';
 opt.scale=1;

 hFig = cs_nmri_plot_surface_suma(suma_all, logp, opt);


 


