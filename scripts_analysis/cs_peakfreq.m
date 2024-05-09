function [peakfrequency_global, peakfrequency_localmax, peakfrequency_cog] = cs_peakfreq(analysis_folder)

% This function computes alpha peak frequency by detecting peaks (local maxima) 
% or using a center of gravity approach

% Written by C. Stier 2023, code provided by J. Groß

%% Prepare data
proc_dir = '/home/uni10/nmri/projects/cstier/aging_processing/';
load([analysis_folder '/all_subjects.mat'])

% loop over subjects
for i = 1:length(all_subjects)
 subject = all_subjects{i};
 subject = nmri_load_subject_most_advanced(subject);
 load(fullfile(proc_dir, subject.id, 'stats',['source_stats_lcmv_' subject.id '_' subject.exam_id '_singleshell.mat']));

 % Create fieldtrip data struct
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

 % Compute alpha power
 cfg = [];
 cfg.output = 'pow'; 
 cfg.method = 'mtmfft';
 cfg.taper = 'dpss';
 cfg.foi = [8:13];
 cfg.tapsmofrq = 1; 
 cfg.pad=20;
 %cfg.keeptrials = 'yes';
 powersp = ft_freqanalysis(cfg, data);

 %% globally
 % PAF global (across parcels)
 avgpow = mean(powersp.powspctrm,1);
 [~, pf_localmax] = findpeaks(avgpow,powersp.freq,'SortStr','descend','NPeaks',1);
 peakfrequency_global.localmax = pf_localmax;

 % center of gravity global (across parcels)
 pf_cog = sum(avgpow.*powersp.freq)/sum(avgpow);
 peakfrequency_global.cog = pf_cog;

 %% regional
 % loop over parcels 
 peakfrequency_localmax = [];
 peakfrequency_cog = [];

 for p = 1:length(powersp.label)

  [~, pf_localmax] = findpeaks(powersp.powspctrm(p,:), powersp.freq, 'SortStr','descend','NPeaks',1);
  if isempty(pf_localmax)
   pf_localmax = NaN;
   peakfrequency_localmax(p,1) = pf_localmax;
  else
  peakfrequency_localmax(p,1) = pf_localmax;
  end

  pf_cog = sum(powersp.powspctrm(p,:).*powersp.freq)/sum(powersp.powspctrm(p,:));
  peakfrequency_cog(p,1) = pf_cog;

 end

 %% save output for each subject
 file_name = fullfile(pwd, 'all_subjects_paf', ['paf_' subject.id '.mat']);
 save(file_name, 'peakfrequency_global', 'peakfrequency_localmax', 'peakfrequency_cog')
end

end
