function [mean_iapf, iapf_global] = cs_instantfreq(analysis_folder)

% This code computes instantaneous alpha peak frequency 
% as described here:
% Cohen, M. X. Fluctuations in oscillation frequency control spike timing 
% and coordinate neural networks. J. Neurosci. 34, 8988?8998 (2014).
%
% Written by C.Stier 2023, code provided by J. Groß

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

 % bandpass filter in fieldtrip
 cfg_bp = [];
 cfg_bp.bpfilter = 'yes';
 cfg_bp.bpfreq = [8, 13];

 dat_bp = ft_preprocessing(cfg_bp, data);

 % Compute instantaneous alpha peak freq
 nchans = 214;
 ntrials = 30;

 mat_pre = nan(2999, nchans, ntrials);
 mat_cut = nan(2900, nchans, ntrials);

 for k1=1:ntrials
     for k2=1:nchans
         iapf=dat_bp.fsample/(2*pi)*diff(smooth(unwrap(angle(hilbert(dat_bp.trial{k1}(k2,:)))),round(dat_bp.fsample/4)));
         mat_pre(:, k2, k1) = iapf;
         mat_cut(:,k2, k1) = iapf(50:end-50,1); % get rid of filter artefacts
     end
     av_iapf = squeeze(nanmean(mat_cut, 1));
 end

 % take average across trials so that one peak freq left for each parcel (regional)
 mean_iapf = nanmean(av_iapf, 2);

 % global average
 iapf_global = mean(mean_iapf);

 %% save output for each subject
 file_name = fullfile(pwd, 'all_subjects_paf', ['iapf_' subject.id '.mat']);
 save(file_name, 'iapf_global', 'mean_iapf')

end

end
 
