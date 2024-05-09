%% Plot parcel weights derived from partial least squares regression
% of any feature of interest 
% CS August 2023

% load computed features
load('all_subj_feat_full.mat')

% Load observed data
dat = zeros(350, 214, 5988);

for s = 1:length(all_subj_feat_full)
 dat(s,:,:) = cell2mat(all_subj_feat_full(s));
end

% load output of interest
results_dir = fullfile(pwd, '/analysis_pls/');
load(fullfile(results_dir, 'pls_av_full_10k_5c_hctsa_r50_stratf.mat')) 

% find indices of predictive features
idx = find(av_acc>0.72);

% load feature labels
load('features_selected_full.mat')

% load maps for plotting
plot_surface = load(fullfile(pwd,'conf',['suma-all-fsaverage-40.mat'])); 
ref_surface = load(fullfile(pwd,'conf',['suma-all-fsaverage-10.mat']));  

remap_matrix=[];
[~, ~, remap_matrix.vertices, remap_matrix.weights ]=nmri_suma_surf2surf_transform(ref_surface.suma_all,plot_surface.suma_all, zeros([size(ref_surface.suma_all.pos,1),1]));

% loop over features of interest and plot
for i = 1:length(idx)
 index = idx(i);
 file_name = cell2mat(labels_selected_full.Name(index));
 
 value = av_parcelw(index,:)';
 accuracy = av_acc(index);
 error = av_mae(index);
 r2 = av_r2(index);
 
 obs_data = dat(:,:,index);
 transf = cov(obs_data)*value; % transform weights according to Haufe et al., 2014

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
                   
 logp2 = nmri_suma_surf2surf_transform(ref_surface.suma_all,plot_surface.suma_all, logp, remap_matrix.vertices, remap_matrix.weights );
 
 opt=[];
 opt.title = ['transf weights, accuracy: ', num2str(accuracy), ', error: ', num2str(error), ', R^2: ', num2str(r2)];
 opt.output = [results_dir file_name 'transf.png'];
 opt.per_hemi=1;
 opt.per_cortex=1;
 opt.rot=[90 0 ; -90 0];
 % opt.thresh=1.3;
 if abs(min(transf)) > max(transf)
  opt.clim=[min(transf) abs(min(transf))];
 else
  opt.clim=[-max(transf) max(transf)];
 end
%  opt.clim=[-1 1];
 opt.opathresh = 0.00000000001;
 opt.colormap='hot';
 opt.colorbar='hot';
 opt.scale=1;

 hFig = cs_nmri_plot_surface_suma(plot_surface.suma_all, logp2, opt);
end

