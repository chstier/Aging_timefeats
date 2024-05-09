function [] = cs_compute_addfeatures(analysis_folder)

proc_dir = '/home/uni10/nmri/projects/cstier/aging_processing/';

% This script computes additional features
%
% Horth-parameters 
% Hjorth, B. EEG analysis based on time domain properties. 
% Electroencephalogr. Clin. Neurophysiol. 29, 306?310 (1970).)

% Zero crossing, zero crossing derivative
% Mean absolute deviation

% Weighted permutation entropy
% Fadlallah, B., Chen, B., Keil, A. & Príncipe, J. Weighted-permutation 
% entropy: a complexity measure for time series incorporating amplitude
% information. Phys. Rev. E Stat. Nonlin. Soft Matter Phys. 87, 022911
% (2013)

% Written by C. Stier 2023, Code provided by E. Balestrieri 2023

%% prepare variables for saving
all_activity = {};
all_mobility = {};
all_complexity = {};
all_zcross = {};
all_zcrossd = {};
all_mad = {};
all_wph = {};

load([analysis_folder '/all_subjects.mat'])

%% loop over subjects
for i = 1:length(all_subjects)
 subject = all_subjects{i};
 subject = nmri_load_subject_most_advanced(subject);
 
 %% get times series
 load(fullfile(proc_dir, subject.id, 'stats',['source_stats_lcmv_' subject.id '_' subject.exam_id '_singleshell.mat']));

 % create fieldtrip data struct
  data=[];
  data.fsample=300;
  for k=1:214
      data.label{k}=num2str(k);
  end
  for k=1:30
  data.trial{k}=squeeze(ts(:,k,:));
  data.time{k}=[0:1/300:9.999];
  end
  data.dimord='chan_time';

 %% Now compute Hjorth parameters based on Elio Balestrieri's code

 [activity, mobility, complexity] = cs_hjorth(data);
 hjorth.activity = nanmean(activity, 2);
 hjorth.mobility = nanmean(mobility, 2);
 hjorth.complexity = nanmean(complexity, 2);
 
 % save individual values
 file_name = fullfile(pwd, 'all_subjects_addfeat', ['hjorth_' subject.id '.mat']);
 save(file_name, 'hjorth');
 
 %% Remaining features

 % compute zero_cross
 swap = cellfun(@(x) detrend(x'), data.trial, 'UniformOutput',false);
 marks = cellfun(@(x) convn(sign(x), ones(2, 1), 'same')', swap, 'UniformOutput',false);
 TEMP = cat(3, marks{:}); TEMP = squeeze(sum(TEMP==0, 2))';
 zerocross = nanmean(TEMP, 1)';
 clear TEMP

 % compute zero cross derivative
 swap = cellfun(@(x) diff(x'), data.trial, 'UniformOutput',false);
 marks = cellfun(@(x) convn(sign(x), ones(2, 1), 'same')', swap, 'UniformOutput',false);
 TEMP = cat(3, marks{:}); TEMP = squeeze(sum(TEMP==0, 2))';
 zerocross_deriv = nanmean(TEMP, 1)';
 clear TEMP

 % mad
 % Mean absolute deviation (MAD) of a sample of data
 TEMP = cellfun(@(x) mad(x,0,2), data.trial, 'UniformOutput',false);
 TEMP = cat(2, TEMP{:})';
 madout = nanmean(TEMP, 1)';
 clear TEMP

 % wpH
 for itrl = 1:ntrials
   for ichan = 1:nchans
       TEMP(itrl,ichan) = wpH(zscore(data.trial{itrl}(ichan,:)),3,1);
   end
 end  
 wpHout = nanmean(TEMP, 1)';
 clear TEMP
  
 all_zcross{i,1} = zerocross;
 all_zcrossd{i,1} = zerocross_deriv;
 all_mad{i,1} = madout;
 all_wph{i,1}= wpHout;
 
 addfeat.zcross = zerocross;
 addfeat.zcrossd = zerocross_deriv;
 addfeat.mad = madout;
 addfeat.wph = wpHout;
 
 % save individual values
 file_name = fullfile(pwd, 'all_subjects_addfeat', ['addfeat_' subject.id '.mat']);
 save(file_name, 'addfeat');
 
end

end
  
