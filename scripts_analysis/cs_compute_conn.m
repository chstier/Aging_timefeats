function [] = cs_compute_conn(proc_folder)

% This script computes power and connectivity across subjects
% absolute power
% debiased wPLI 
% amplitude envelope coupling

% Written by J.Groß 2023, modified by C. Stier 2024

d = dir([proc_folder '*mat']); % get file names
s = readtable('demo_all_subjects.csv'); % get subject names

for k0 = 1:length(d)
 ts=load([proc_folder d(k0).name]);
 data=[];
 data.fsample=300;
 
 for k=1:214
  data.label{k}=num2str(k);
 end
 
 for k=1:30
  data.trial{k}=squeeze(ts.ts(:,k,:));
  data.time{k}=[0:1/300:9.999];
 end
 
 data.dimord='chan_time';
 
 cfg = [];
 cfg.output = 'fourier';
 cfg.method = 'mtmfft';
 cfg.taper = 'dpss';
 cfg.foi = [1:60];
 cfg.tapsmofrq = 1;
 cfg.keeptrials = 'yes';
 freq = ft_freqanalysis(cfg, data);
 pow=ft_freqdescriptives([],freq);
 
 cfg = [];
 cfg.method ='wpli_debiased';
 conn = ft_connectivityanalysis(cfg, freq);
 
 conn = rmfield(conn,'cfg');
 
 %for amplitude envelope coupling (AEC)
 fb = [4 8; 8 13; 13 30; 30 60]; %freq bands
 nbands=size(fb,1);
 aec=zeros(214,214,nbands);
 
 for ib=1:nbands
  cfg = [];
  cfg.bpfilter = 'yes';
  cfg.bpfreq = fb(ib,:);
  dataf = ft_preprocessing(cfg, data);
  aectmp=aecConnectivity_brainstorm(dataf);
  aec(:,:,ib)=squeeze(mean(aectmp,3));
 end
 
 name = cell2mat(s.Var1(k0));
 
 save([name '_pow_conn.mat'],'pow','conn','aec')
end

end
