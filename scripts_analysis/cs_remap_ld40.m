
% load surface to be plotted and the current ref surface 
plot_surface = load(fullfile(pwd,'conf',['suma-all-fsaverage-40.mat'])); 
ref_surface = load(fullfile(pwd,'conf',['suma-all-fsaverage-10.mat']));  

%
remap_matrix=[];
[~, ~, remap_matrix.vertices, remap_matrix.weights ]=nmri_suma_surf2surf_transform(ref_surface.suma_all,plot_surface.suma_all, zeros([size(ref_surface.suma_all.pos,1),1]));

rootfolder = ('/home/uni10/nmri/projects/GoeEpiLongterm/nfocke/AllGGE_redux/results/');
hdm = {'individual', 'canonical'};
h = 1;
metric = {'power', 'coh_img'};
m = 1;

% test
refmap = load_mgh(fullfile(rootfolder, hdm{h}, 'full/Cx-GGE/', metric{m}, '/palm_surface/palm_out_dpv_cohen_m2_c2.mgz'));

p_map=nmri_suma_surf2surf_transform(ref_surface.suma_all,plot_surface.suma_all, refmap, remap_matrix.vertices, remap_matrix.weights );

hFig=cs_nmri_plot_surface_suma(plot_surface.suma_all,p_map,opt);
close(hFig)

%% re-map group comparison (IGE > controls) HD-EEG (Niels)
% start of with HD-EEG surface results

rootdir = '/home/uni10/nmri/projects/GoeEpiLongterm/nfocke/AllGGE_redux/results/individual/';
% rootdir = '/home/uni10/nmri/projects/loew8/analyse_cx_vs_allpat_05_10_22/results_sample_christina_21_11_22/cx-pat/coh_img/palm_surface/';

plot_surface = load(fullfile(pwd,'conf',['suma-all-fsaverage-40.mat'])); 
ref_surface = load(fullfile(pwd,'conf',['suma-all-fsaverage-10.mat']));
remap_matrix=[];
[~, ~, remap_matrix.vertices, remap_matrix.weights ]=nmri_suma_surf2surf_transform(ref_surface.suma_all,plot_surface.suma_all, zeros([size(ref_surface.suma_all.pos,1),1]));

fig_dir = '/home/uni10/nmri/projects/cstier/channels_analysis/results/groupcontrasts_remapped_theta/';

opt=[];
opt.per_hemi=1;
opt.per_cortex=1;
opt.rot=[90 0 ; -90 0];
opt.thresh=1.3;
opt.clim=[1.3 5]; % set thresholds accordingly (will show -log10(p))
opt.colormap='hot';
opt.colorbar='hot';
opt.scale=1;

freqname = {'m2_'};
analysis_type = {'palm_out_tfce_'};
analysis_type_2={'tstat_fwep_'};
contrasts = {'c2'};
density = {'full', '192','128', '64', '48','32','IFCN1020_ext','IFCN1020'};
metric = {'power'};

% rootdir = [results_dir '/Beta1/'];

for var_metric = 1:length(metric)
  for d = 1:length(density)
      for var_analysis_type = 1:length(analysis_type)
          for var_analysis_type_2 = 1:length(analysis_type_2)
              for var_contrasts = 1:length(contrasts)

                  log_p_map=load_mgh([rootdir...
                      density{d} '/Cx-GGE/'...
                      metric{1, var_metric} '/palm_surface/'...
                      analysis_type{1,var_analysis_type} analysis_type_2{1, var_analysis_type_2}...
                      freqname{1}...
                      contrasts{1, var_contrasts} '.mgz']);

                  p_map=nmri_suma_surf2surf_transform(ref_surface.suma_all,plot_surface.suma_all, log_p_map, remap_matrix.vertices, remap_matrix.weights );   

 %                  opt.title=strcat(cell2mat(freqname),cell2mat(metric(1, var_metric)),cell2mat(analysis_type(1,var_analysis_type)),cell2mat(analysis_type_2(1, var_analysis_type_2)),cell2mat(contrasts(1, var_contrasts))) ;
                  opt.output=strcat(fig_dir, cell2mat(density(1, d)), cell2mat(metric(1, var_metric)),cell2mat(analysis_type(1,var_analysis_type)),cell2mat(analysis_type_2(1, var_analysis_type_2)), cell2mat(freqname(1, 1)), cell2mat(contrasts(1, var_contrasts)),'.png');

                  hFig = cs_nmri_plot_surface_suma(plot_surface.suma_all, p_map, opt);
              end
          end
      end
  end
end
     
%% Overview plots 

fig_dir = '/home/uni10/nmri/projects/cstier/channels_analysis/results/groupcontrasts_remapped_theta/';
results_dir = '/home/uni10/nmri/projects/cstier/channels_analysis/results/groupcontrasts_remapped_theta/';

% 
% copyfile ([results_dir '/Alpha/fig_*'], [results_dir '/figures']);
% copyfile ([results_dir '/Beta1/fig_*'], [results_dir '/figures']);
% copyfile ([results_dir '/Beta2/fig_*'], [results_dir '/figures']);
% copyfile ([results_dir '/Delta/fig_*'], [results_dir '/figures']);
% copyfile ([results_dir '/Gamma/fig_*'], [results_dir '/figures']);
% copyfile ([results_dir '/Theta/fig_*'], [results_dir '/figures']);

% rootdir = [results_dir '/figures/'];
% fig_dir = [rootdir '/' 'concat_fig'];
% if(~exist(fig_dir,'dir'))
%     mkdir(fig_dir)
% end

freqname = {'m2_'};
analysis_type = {'palm_out_tfce_'};
analysis_type_2={'tstat_fwep_'};
contrasts = {'c2'};
density = {'full', '192','128', '64', '48','32','IFCN1020_ext','IFCN1020'};
metric = {'power', 'coh_img'};


% for f = 1:length(freqname)
    for var_metric = 1:length(metric)
        for var_analysis_type = 1:length(analysis_type)
            for var_analysis_type_2 = 1:length(analysis_type_2)
                for var_contrasts = 1:length(contrasts)
                     
                name =[fig_dir, '/fig_all_freq_' ...
                    metric{1, var_metric}...
                    analysis_type{1,var_analysis_type} analysis_type_2{1, var_analysis_type_2}...
                    contrasts{1, var_contrasts} '.png'];
                img1 = imread([fig_dir...
                    density{1, 1}...
                    metric{1, var_metric}...
                    analysis_type{1,var_analysis_type}... 
                    analysis_type_2{1, var_analysis_type_2}...
                    freqname{1,1} contrasts{1, var_contrasts} '.png']);
                img2 = imread([fig_dir... 
                    density{1, 2}...
                    metric{1, var_metric}...
                    analysis_type{1,var_analysis_type}... 
                    analysis_type_2{1, var_analysis_type_2}...
                    freqname{1,1} contrasts{1, var_contrasts} '.png']);
                img3 = imread([fig_dir... 
                    density{1, 3}...
                    metric{1, var_metric}...
                    analysis_type{1,var_analysis_type}... 
                    analysis_type_2{1, var_analysis_type_2}...
                    freqname{1,1} contrasts{1, var_contrasts} '.png']);
                img4 = imread([fig_dir... 
                    density{1, 4}...
                    metric{1, var_metric}...
                    analysis_type{1,var_analysis_type}... 
                    analysis_type_2{1, var_analysis_type_2}...
                    freqname{1,1} contrasts{1, var_contrasts} '.png']);
                img5 = imread([fig_dir... 
                    density{1, 5}...
                    metric{1, var_metric}...
                    analysis_type{1,var_analysis_type}... 
                    analysis_type_2{1, var_analysis_type_2}...
                    freqname{1,1} contrasts{1, var_contrasts} '.png']);
                img6 = imread([fig_dir... 
                    density{1, 6}...
                    metric{1, var_metric}...
                    analysis_type{1,var_analysis_type}... 
                    analysis_type_2{1, var_analysis_type_2}...
                    freqname{1,1} contrasts{1, var_contrasts} '.png']);
                img7 = imread([fig_dir... 
                    density{1, 7}...
                    metric{1, var_metric}...
                    analysis_type{1,var_analysis_type}... 
                    analysis_type_2{1, var_analysis_type_2}...
                    freqname{1,1} contrasts{1, var_contrasts} '.png']);
                img8 = imread([fig_dir... 
                    density{1, 8}...
                    metric{1, var_metric}...
                    analysis_type{1,var_analysis_type}... 
                    analysis_type_2{1, var_analysis_type_2}...
                    freqname{1,1} contrasts{1, var_contrasts} '.png']);
                
                img = [img1; img2; img3; img4; img5; img6; img7; img8];
                    
                
                imwrite (img, name);
                end
            end
        end
    end
% end
%      