%% This script contains code for a t-test adapted for repeated k-fold cross-validation
% CS 2024

% Referenz: C. Nadeau, Y. Bengio, Inference for the Generalization Error. 
% Springer Science and Business Media LLC (2003) 
% https:/doi.org/10.1023/a:1024068626366.

%% Prepare input
% load all features
load('all_subj_feat_full.mat')

dat = zeros(350, 214, 5988);

for s = 1:length(all_subj_feat_full)
 dat(s,:,:) = cell2mat(all_subj_feat_full(s));
end

% get real age of participants
T = readtable('/home/uni10/nmri/projects/cstier/aging_features/demo_all_subjects.csv');
age = T.Var2;
Y = age;

% settings (folds, components for PLSR)
kfold=10;
ncomp=5;

% stratify according to age
group=[];
for g=1:7
  group=[group g*ones(1,50)];
end

% get index for data of interest
X1 = 94; % index = 94 for AC11
X2 = 5974; % index = 5979 for PAF center of gravity
index = 1;
runs = 50;

%% Run PLS and compute pairwise differences in the performance metrics
% run 50 times to get a more stable estimation
for r = 1:50
 
 %design training and test partition
 cv = cvpartition(group,"Kfold",kfold);
 
 for ifold=1:kfold
 
  % index age vector but for the split only
  Y_f_k1 = zeros(35,1); % size of test set
  acc_f_k1 = [];
  
  Y_f_k2 = zeros(35,1); % size of test set
  acc_f_k2 = [];
  
  Yorig = Y(cv.test(ifold));
  mean_obs=mean(Yorig);

  % feature 1
  % build PLS model on training data
  [xl,yl,XS,YS,beta1(ifold,:),PCTVAR,mse,stat]= plsregress(dat(cv.training(ifold),:,X1),Y(cv.training(ifold)),ncomp);
  % predict age in test data
  Y_f_k1=[ones(length(find(cv.test(ifold))),1) dat(cv.test(ifold),:,X1)]*beta1(ifold,:)';
  % accuracy/mae/R^2
  acc_f_k1 = corr(Y_f_k1, Yorig);
  mae_f_k1 = mean(Y_f_k1-Yorig);
  r2_k1 = 1 -(mean((Yorig-Y_f_k1).^2)/(mean((Yorig-mean_obs).^2)));
  
  % feature 2
  % build PLS model on training data
  [xl,yl,XS,YS,beta2(ifold,:),PCTVAR,mse,stat]= plsregress(dat(cv.training(ifold),:,X2),Y(cv.training(ifold)),ncomp);
  % predict age in test data
  Y_f_k2=[ones(length(find(cv.test(ifold))),1) dat(cv.test(ifold),:,X2)]*beta2(ifold,:)';
  % accuracy/mae/R^2
  acc_f_k2 = corr(Y_f_k2, Yorig);
  mae_f_k2 = mean(Y_f_k2-Yorig);
  r2_k2 = 1 -(mean((Yorig-Y_f_k2).^2)/(mean((Yorig-mean_obs).^2)));

  % difference in performance between feature1 and feature2
  acc_diff(index) = acc_f_k1 - acc_f_k2;
  mae_diff(index) = mae_f_k2 - mae_f_k1;
  r2_diff(index) = r2_k1 - r2_k2;
  index = index + 1;
  
 end
end

% mean and variance of the differences across repetitions
m_acc = mean(acc_diff); 
m_mae = mean(mae_diff);
m_r2 = mean(r2_diff);

metrics = [m_acc, m_mae, m_r2];
variable = {'acc', 'mae', 'r2'};
diff = [acc_diff; mae_diff; r2_diff];

%% Test for significance
% Calculate n1 and n2
n1 = sum(cv.TrainSize(1)); % training data
n2 = sum(cv.TestSize(1)); % test data

for i = 1:length(metrics)
 m = metrics(i);
 d = diff(i,:)';
 
 sigma_squared = var(d,1); 

 % Corrected t-test statistic
 t_stat = m / sqrt((1 + (n2/n1)) * (sigma_squared / (kfold * runs)));
 
 % Degrees of freedom
 df = kfold * runs - 1;

 % one-sided test such that k1 < k2 
 % p-value for right-tailed test
 % p_value_right = 1 - tcdf(t_stat, df);

 % p-value for left-tailed test k1 > k2 
 p_value_left = tcdf(t_stat, df);

 % store t-test results
 results(i).variable = variable{i};
 results(i).sigma2 = sigma_squared;
 results(i).tstat = t_stat;
 results(i).p_value_2s = p_value_2s;
 results(i).p_value_left = p_value_right;
 results(i).p_value_right = p_value_left;
 

 % do wilcoxon signed rank test and store results
 [p_wilcox, h] = signrank(diff(i,:)');
 results(i).p_wilcox = p_wilcox;
 results(i).h_wilcox = h;

end

writetable(struct2table(results), 'pairwisediff_AC11_adjalpha.xlsx');
save('results_AC11_adjalpha_p.mat', 'results')



