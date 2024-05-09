function [res, cq] = cs_compute_hctsa(analysis_folder, proc_folder)

% Compute HCTSA features for each suject 
% 
% Toolbox needed:
% https://hctsa-users.gitbook.io/hctsa-manual
% 
% References: 
% B.D. Fulcher and N.S. Jones. hctsa: A computational framework for 
% automated time-series phenotyping using massive feature extraction. 
% Cell Systems 5, 527 (2017).

% B.D. Fulcher, M.A. Little, N.S. Jones. Highly comparative time-series 
% analysis: the empirical structure of time series and their methods. 
% J. Roy. Soc. Interface 10, 20130048 (2013).

% Written by J. Groß 2023, modified by C. Stier 2024 


startup

% cd /scratch/tmp/grossjoa/features
OP=SQL_Add('ops','INP_ops_hctsa_jg2.txt',false,false); % 
javaaddpath(fullfile(analysis_folder, '/hctsa-main/Toolboxes/infodynamics-dist/infodynamics.jar'))

% use parallel processing 
p=parpool(2);
parfor k2=1:p.NumWorkers
  javaaddpath('/home/uni10/nmri/projects/cstier/aging_features/hctsa-main/Toolboxes/infodynamics-dist/infodynamics.jar')
end

d = dir([proc_folder '*mat']); % get file names
nsubj=length(d);

for k0=[1:7] % loop over subjects - change according to your processing capacities
 load([proc_folder d(k0).name]) % get source-reconstructed time-series for each subject
 res=zeros(214,30,7525); % parcels, trials, number of features
 cq=zeros(214,30,7525,'uint8');
 
 parfor k2=1:214
     for k=1:30
         [res(k2,k,:),ct,cqtmp]=TS_CalculateFeatureVector(squeeze(ts(k2,k,:)), false, OP);
         cq(k2,k,:)=uint8(cqtmp);
     end
 end
 
 save([d(k0).name(1:30) '_features_all'],'res','cq') % save results
end
