%% This script performs K-means clustering on the beta weights of PLS regressions
% CS,2023

% set results dir
results_dir = fullfile(pwd, '/analysis_pls/');

% load computed features and reformat
load('all_subj_feat.mat')

dat = zeros(350, 214, 5961);
for s = 1:length(all_subj_feat)
 dat(s,:,:) = cell2mat(all_subj_feat(s));
end

% load accuracies from PLS regress
load(fullfile(results_dir, 'pls_av15_full_10k_5c_hctsa_r50_stratf.mat'))

% find indices of (highly) predictive features
idxx = find(av_acc > 0.7);

% transform beta weights for interpretability according to Haufe et al., 2014
tf_parcelw = zeros(length(idxx), 214);

for i = 1:length(idxx)
 index = idxx(i);

 value = av_parcelw(index,:)';
 accuracy = av_acc(index);

 obs_data = dat(:,:,index);
 transf = cov(obs_data)*value;
 
 tf_parcelw(i,:) = transf;
end
 
% scale data to keep weights similar across features
scaled_data = zscore(tf_parcelw');
 
% check how many clusters are useful
k = 10;
wss = zeros(1, 10);  % Initialize an array to store within-cluster sum of squares

for k = 1:10
 [idx, C, sumd, D] = kmeans(scaled_data, k, 'Display','final'); 
 wss(k) = sum(sumd); % get the sum of the within-cluster sum of squares
end

figure
plot(1:10, wss, 'o-');
xlabel('Number of Clusters (k)');
ylabel('Within-Cluster Sum of Squares (WSS)');

% decide on number of clusters and recompute
k = 4;
rng('default') % For reproducibility
[idx, C, sumd, D] = kmeans(scaled_data, k, 'Display','final', 'Replicates',10); 
cluster_assignments = idx;

% Create a cell array to store brain parcels for each cluster
clusters = cell(1, k);

% Organize brain parcels into clusters
for i = 1:k
    clusters{i} = find(cluster_assignments == i);
end

vec = zeros(214,1);
clus = {'cluster1', 'cluster2', 'cluster3', 'cluster4'};

for c = 1:length(clus)
 cluster = vec;
 cluster(clusters{1,c},1) = 1;
 
 clus_all{c} = cluster;
end

save('cluster_4means_7.mat', 'cluster_assignments', 'C', 'sumd', 'D', 'clus_all')

% load maps for plotting
load([pwd '/conf/suma-all-fsaverage-10.mat'],'suma_all')
suma_schaefer = load([pwd '/conf/atlas/Schaefer2018_200Parcels_7Networks_suma-all-fsaverage-10.mat'],'suma_all');
plot_surface = load(fullfile(pwd,'conf',['suma-all-fsaverage-40.mat'])); 
ref_surface = load(fullfile(pwd,'conf',['suma-all-fsaverage-10.mat']));  

remap_matrix=[];
[~, ~, remap_matrix.vertices, remap_matrix.weights ]=nmri_suma_surf2surf_transform(ref_surface.suma_all,plot_surface.suma_all, zeros([size(ref_surface.suma_all.pos,1),1]));

for c = 1:length(clus)
 
 keydata = [clus_all{c} suma_schaefer.suma_all.annot_key{1,1}];
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

 logp2 = nmri_suma_surf2surf_transform(ref_surface.suma_all,plot_surface.suma_all, logp, remap_matrix.vertices, remap_matrix.weights );
 
 opt=[];
 opt.title = ['k-means ' clus{c}];
 opt.output = [results_dir clus{c} '_7_transf.png'];
 opt.per_hemi=1;
 opt.per_cortex=1;
 opt.rot=[90 0 ; -90 0]; 
 opt.colormap='copper';
 opt.scale=1;

 hFig = cs_nmri_plot_surface_suma_nocolorb(plot_surface.suma_all, logp2, opt);

end

% find correspondence between features and clusters
% get labels
load('features_selected_full.mat')
labels = labels_selected_full(1:5961,:); % take hctsa features only
selected_labels = labels(idxx,:);
selected_accuracies = av_acc(idxx);
selected_errors = av_mae(idxx);

for i = 1:k
  % Find brain parcels in the current cluster
  cluster_indices = find(cluster_assignments == i);

  % Calculate the mean values of variables in the current cluster
  cluster_mean = mean(scaled_data(cluster_indices, :));

  % Sort variables according to mean absolute value
  [~, top_variable_indices] = sort(cluster_mean, 'descend');

  % Store the variable names in the current cluster
  variables_by_cluster{i} = top_variable_indices;

  var = selected_labels(variables_by_cluster{i},:);
  var.ClusterMean = sort(cluster_mean, 'descend')';
  var.accuracies = selected_accuracies(top_variable_indices)';
  var.errors = selected_errors(top_variable_indices)';

  filename = ['variables_' num2str(k) 'means_cluster_7.xlsx'];
  writetable(var,filename,'Sheet',i)
end

%% now concatenate clusterplots
results_dir = '/home/uni10/nmri/projects/cstier/aging_features/analysis_pls/clustering_pls_r50_stratf/acc_7/4Clusters';

% concat figures
name = [results_dir,'/4clusters_all_7_transf.png'];

% sort according to sum of squares
img1 = imread([results_dir '/cluster' num2str(1) '_7_transf.png']);
img2 = imread([results_dir '/cluster' num2str(2) '_7_transf.png']);
img3 = imread([results_dir '/cluster' num2str(3) '_7_transf.png']);
img4 = imread([results_dir '/cluster' num2str(4) '_7_transf.png']);

img = [img1; img4; img3; img2]; % order according to sum of squares 
imwrite(img,name);
