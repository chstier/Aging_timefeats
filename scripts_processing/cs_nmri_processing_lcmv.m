function [ subject ] = cs_nmri_processing_lcmv(subject, data, params)
%  
% This function will do the projection of sensor level time-series data 
% to the source space using lcmv beamforming (projection to Schaefer parcels)
% 
% subject   =   subject structure, see nmri_read_subject
%               could be a struct or .m file or .mat file
% data      =   will return the data (optional)

% written by NF 11/2016 - 03/2017 and modified by Christina Stier, 2023

% check the call
if (~exist('subject','var') ) 
 error('Need a valid subject struct or .m/.mat file to work with')
end

% call the subject and params include
nmri_include_read_ps

if ~exist('data','var') || isempty(data) 
 % check if we have cleaned dataset (ICA or not)
 if (isfield(params,'useICA_clean') && params.useICA_clean==1)
  if (isfield(subject,'cleanICA_dataset') &&  exist(subject.cleanICA_dataset,'file'))
   input=subject.cleanICA_dataset;
   useICA=true;
  else
   error('ICA cleaned dataset not found - Run nmri_artifactrejection first')
  end
 else
%   if (isfield(subject,'clean_dataset') &&  exist(subject.clean_dataset,'file'))
%    input=subject.clean_dataset;
%    useICA=false;
%   else
%    error('Cleaned dataset (w/o ICA) not found - Run nmri_artifactrejection first')
%   end  
 end
 % retain subject info, if different
 load(input,'data'); 
 if (~exist('data','var') ) 
  error('Could not load data')
 end
end

if (strcmp(subject.dtype,'EEG'))
 if (~isfield(subject,'electrodes_aligned') || ~exist(subject.electrodes_aligned,'file'))
  error('Have not found EEG electrodes - should be generated by the headmodel step')
 end
 load(subject.electrodes_aligned,'elec_aligned','elec_present','elec_missing')
end

%% Get the modality-specific analysis params
[ params ] = nmri_get_modality_params( params, subject.dtype );

%% make dir / files
if (~isfield(subject,'stats_dir'))
 subject.stats_dir=fullfile(subject.analysis_dir,subject.id,'stats');
end
if (~exist(subject.stats_dir,'dir'))
 mkdir(subject.stats_dir)
end

if (~isfield(subject,'stats'))
 subject.stats=fullfile(subject.stats_dir,['source_stats_' subject.id '_' subject.exam_id '_' params.headmodel '.mat']);
end

%% Deal with trials selection
if (isfield(params,'nTrials'))
 nTrials=params.nTrials;
else
 nTrials=[]; % take all that are good
end

% check if we have a trial selection already
if (~isfield(subject,'SelectedTrials_file'))
 subject.SelectedTrials_file=fullfile(subject.analysis_dir,subject.id,'processed',['selected_trials_' subject.id '_' subject.exam_id '.mat']);
end
if (exist(subject.SelectedTrials_file,'file'))
 % if we have a file, load this, and be done
 disp('TrialSelection file found - loading')
 tsubj=load(subject.SelectedTrials_file,'subject');
 subject.SelectedTrials=tsubj.subject.SelectedTrials;
else
 % determine trials now
 badTrials = [];
 goodTrials = [1:length(data.trial)]; % start with all good
 
 
 if (isfield(params,'rejectEvents') && params.rejectEvents == 1)
  % check in dws_filt dataset not to miss atypically run processing
  if ~isfield(subject,'evt_timings_seconds') && ~isfield(subject,'evt_markerFile_notFound')
   subject_clean=load(subject.dws_filt_dataset,'subject');
   items=fieldnames(subject_clean.subject);
   for i=1:length(items)
    if length(items{i})>4 && strcmp(items{i}(1:4),'evt_')
     subject.(items{i})=subject_clean.subject.(items{i});
    end
   end
   if isfield(subject_clean.subject,'stamps') && isfield(subject_clean.subject.stamps,'readingevents')
    subject.stamps.readingevents=subject_clean.subject.stamps.readingevents;
   end
   clear subject_clean
  end
 end
 
  % call the central selection function now
 [ goodTrials, badTrials ] = nmri_trial_selector(subject,data,params);
  
 fprintf('\nTotal: GoodTrials, N=%d / BadTrials, N=%d\n',length(goodTrials),length(badTrials))
 subject.evt_goodTrials=goodTrials;
 subject.evt_badTrials=badTrials;
 
 if ~isempty(nTrials)
  % check if sufficient
  if (length(subject.evt_goodTrials)<nTrials)
   error(sprintf('Fewer good trials (%d) [after excluding events] in dataset than given in nTrials(%d)',length(subject.evt_goodTrials),nTrials))
  end
  % draw only from good trials then - make sure we are really random, use a
  % new rand stream
  s = RandStream('mt19937ar','Seed', seconds(round(milliseconds(second(datetime))*1000000)));
  subject.SelectedTrials = sort(datasample(s,subject.evt_goodTrials,nTrials,'Replace',false)); 
  fprintf('\nHave drawn N=%d random trials from all good trials now\n',length(subject.SelectedTrials))
 else
  % just take all good
  subject.SelectedTrials = goodTrials;
  fprintf('\nSelecting all good trials (N=%d) now\n',length(subject.SelectedTrials))
 end
  
 % and safe selection
 save(subject.SelectedTrials_file,'subject')
end

% we do not need trial markings any more now, remove to avoid Fieldtrip
% warnings
if isfield(data,'trial_markings')
 data=rmfield(data,'trial_markings');
end
if isfield(data,'trial_markings_sampleinfo')
 data=rmfield(data,'trial_markings_sampleinfo');
end

%% select just the wanted trials
cfg           = [];
cfg.trials    = subject.SelectedTrials;

% and also the non-bad channels - as of 01102019
if isfield(data,'bad_channels')
 good_channels={};
 for i=1:length(data.label)
  if ~any(strcmp(data.label{i},data.bad_channels))
   good_channels(end+1)=data.label(i);
  end
 end

 
 cfg.channel=good_channels;
 
 % we do not need bad_channels any more now, remove to avoid Fieldtrip
 % warnings
 if isfield(data,'bad_channels')
  data=rmfield(data,'bad_channels');
 end
 
end
data=ft_selectdata(cfg,data);

%% load dws-dataset to get grad-info
prev_subj = load(subject.dws_filt_dataset);
data.grad = prev_subj.data.grad;

% take only magnetometers
cfg = [];
cfg.channel = {'MEG*1'};
data = ft_selectdata(cfg, data);

% take only planar gradiometer 
% cfg = [];
% cfg.channel = {'MEG*2', 'MEG*3'};
% data = ft_selectdata(cfg, data);

% Now demean finally and re-reference if EEG
if (strcmp(subject.dtype,'EEG'))
 cfg          = [];
 cfg.demean   = params.preproc_cfg.demean;
 cfg.reref      = 'yes';
 cfg.refchannel = 'all';
 data        = ft_preprocessing(cfg,data);
end

%% make the QC dir
if (~isfield(subject,'QCdir'))
 subject.QCdir=fullfile(subject.analysis_dir,subject.id,'QC');
end
if (~exist(subject.QCdir,'dir'))
 mkdir(subject.QCdir)
end


%% load the head model and leadfield
if ~isfield(subject,'hdm_lead') || ~exist(subject.hdm_lead,'file')
 error('Could not find headmodel - Make sure to run nmri_make_hdm_suma first')
end
if ~isfield(subject,'suma_surface') || ~exist(subject.suma_surface,'file')
 error('Could not find SUMA surface - Make sure to run nmri_make_hdm_suma first')
end

load(subject.hdm_lead,'hdm','leadfield');
load(subject.suma_surface,'suma_all');


% check if leadfield, data and electrodes are consistant
if (length(leadfield.label)~=length(data.label)) || any(~strcmpi(leadfield.label,data.label))
 error('There is a mismatch between channels in the data and the leadfield. Maybe the data was changed (e.g. channels removed or added). Re-run the headmodel making (delete hdm_lead and electrodes_aligend [for EEG])')
end
 
%% Do lcmv on broadband (Fieldtrip version 20191127 is used)

% taggle again the line noise 
cfg=[];
cfg.dftfilter = 'yes';
cfg.dftreplace='neighbour';
data=ft_preprocessing(cfg, data);

% check outcome after filtering
cfg = [];
cfg.output  = 'pow';
cfg.channel = 'megmag';
cfg.method  = 'mtmfft';
cfg.taper   = 'dpss';
cfg.pad = 'nextpow2';
cfg.foi     = 0.5:1:150; % 1/cfg1.length  = 1;
cfg.tapsmofrq = 2;
data_freq   = ft_freqanalysis(cfg, data);

hFig = figure;
hold on;
plot(data_freq.freq, data_freq.powspctrm(:,:))
legend('All Magnetometer Neuromag306')
xlabel('Frequency (Hz)');
ylabel('Absolute Power (uV^2)');

saveas(hFig,fullfile(subject.QCdir,['mag_sensor_freqplot_beforelcmv_' subject.id '_' subject.exam_id '.png']),'png');        
set(hFig,'Visible','off')
close all

% make time the same across trials
for k=2:length(data.trial)
data.time{k}=data.time{1};
end

% scale the values to avoid numerical problems
for k=1:length(data.trial)
data.trial{k}=data.trial{k}*1e13;
end

% change Fieldtrip version as the old one made some filters complex valued
rmpath(genpath('/home/uni10/nmri/tools/fieldtrip/fieldtrip-20191127/'));
addpath('/home/uni10/nmri/tools/fieldtrip/fieldtrip-20220713/')

% buildcovariance matrix 
cfg = [];
cfg.covariance = 'yes';
cfg.removemean='yes';
cfg.preproc.detrend='yes';
avg = ft_timelockanalysis(cfg,data);

% compute filters
cfg = [];
cfg.method = 'lcmv';
cfg.channel = data.label;
cfg.headmodel = hdm;
cfg.sourcemodel = leadfield;
% cfg.grad = datatrl.grad;
cfg.lcmv.lambda = '5%';
cfg.lcmv.keepfilter = 'yes';
cfg.lcmv.fixedori = 'no';
cfg.lcmv.weightnorm='unitnoisegain';
cfg.lcmv.projectnoise = 'no';
source = ft_sourceanalysis(cfg, avg);

filter=cat(1,source.avg.filter{:}); 
%concatenate filters
inbrain=find(source.inside);
clear source
%find filters for each parcel within Schaefer atlas
%load atlas
load([pwd '/conf/atlas/Schaefer2018_200Parcels_7Networks_suma-all-fsaverage-10.mat'])

nroi=length(suma_all.annot_key{1});
ntrial=length(data.trial);
nsamp=3000;
ts=zeros(nroi,ntrial,nsamp);

for k=1:nroi 
 fi=find(suma_all.annot(inbrain) == suma_all.annot_key{1}(k));
 %find vertices in parcel
 tmpfilt=filter([3*fi-2 3*fi-1 3*fi],:); 
 %get corresponding filters
 c1=tmpfilt*avg.cov*tmpfilt'; 
 %compute source level power
 [u,s,v]=svd(c1); 
 %svd
 roifilt=tmpfilt'*u(:,1);
 %construct new parcel filter
 for k2=1:ntrial
  ts(k,k2,:)=roifilt'*data.trial{k2};
 end
end

% save projection
if (~isfield(subject,'stats_lcmv'))
 subject.stats_lcmv=fullfile(subject.stats_dir,['source_stats_lcmv_' subject.id '_' subject.exam_id '_' params.headmodel '.mat']);
end

save(subject.stats_lcmv, 'ts', '-v7.3')

%% if we got this far, place a stamp for completed processing
subject=nmri_stamp_subject(subject,['processing_lmcv_' params.headmodel],params);

end % final end