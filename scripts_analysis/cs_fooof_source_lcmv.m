function [subject] = cs_fooof_source_lcmv(analysis_folder)

% This code does spectral parameterization on source-projected time-series
% using the specparam algorithm (see reference:
% Donoghue, T. et al. Parameterizing neural power spectra into periodic 
% and aperiodic components. Nat. Neurosci. 23, 1655-1665 (2020))

% CS 2023

%% Prepare paths/data
proc_dir = '/home/uni10/nmri/projects/cstier/aging_processing/';

% loop over subjects
for i = 1:length(all_subjects)
 subject = all_subjects{i};
 subject = nmri_load_subject_most_advanced(subject);
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

 cfg = [];
 cfg.output = 'pow';
 cfg.method = 'mtmfft';
 cfg.taper = 'dpss';
 cfg.foi = [1:60];
 cfg.tapsmofrq = 1;
 cfg.pad='nextpow2';
 specData = ft_freqanalysis(cfg, data);

 %% Set parameters
 studyParams.fooof.fooofSettings = struct();
 %studyParams.fooof.fooofSettings.aperiodic_mode = 'knee';
 studyParams.fooof.fooofSettings.peak_width_limits=[1, 8]; % default: [0.5, 12]
 % studyParams.fooof.fooofSettings.max_n_peaks=6; %default: inf
 % studyParams.fooof.fooofSettings.min_peak_height=0.4; %default: 0
 studyParams.fooof.freqRangeOI = [1 60];

 % % set python version:
 % pyversion("/home/uni10/stier1/.conda/envs/py36/bin/python3.6")
 % pyversion
 pyenv("ExecutionMode","OutOfProcess")

 specDataFooofCorr = specData; % specData derived from a ft_freqanalysis call with method set to 'mtmfft'
 [specDataFooofCorr.psd, fooofResults, specDataFooofCorr.psdAperiodic] = aw_correct_PSD_for1overF(specData.powspctrm, specData.freq, studyParams.fooof.freqRangeOI, studyParams.fooof.fooofSettings);

 fooof.results = fooofResults;
 fooof.corrpsd = specDataFooofCorr.psd;
 fooof.aperiodicpsd = specDataFooofCorr.psdAperiodic;
 file_name = fullfile(analysis_folder, 'all_subjects_fooof', ['fooof_' subject.id '.mat']);

 save(file_name, 'fooof');

end

end

