%% Workflow for the computation of novel time-series features
% CS 2023

% Compute HCTSA features for each suject 
analysis_folder = pwd;
proc_folder = '/home/uni10/nmri/projects/cstier/aging_processing/all_subjects_lcmv/';
cs_compute_hctsa(analysis_folder, proc_folder);

% Filter hctsa features which give problems (NaNs, outliers complex values,..)
cs_filteredfeat(analysis_folder);

% Compute absolute power and connectivity on time-series data for each subject 
% (frequency-specific)
cs_compute_conn(proc_folder);

% Compute alpha peak frequency for each subject
cs_compute_alphapeak(analysis_folder); % using local maxima, center of gravity
cs_compute_instantfreq(analysis_folder); % based on instantaneous alpha freq

% Compute additional features for each subject
% (Hjorth parameters, mean absolute deviation, zero crossing, 
% zero crossing derivative, and weighted permutation entropy)
cs_compute_addfeatures(analysis_folder);

% Do spectral parameterization using specparam
cs_fooof_source_lcmv(analysis_folder);
