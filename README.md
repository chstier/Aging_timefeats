Code in support of the work "Extensive MEG time-series phenotyping unveils neural markers predictive of age" https://doi.org/10.1101/2024.05.09.593348 

The provided repository contains all relevant scripts and main results but requires some external tools that need to be either placed in the Matlab path, included in the scripts/utilities directory, or the R path.

### External tools and toolboxes

- Matlab (tested with version MATLAB 9.5.0.1298439 (R2018b))
- Fieldtrip (tested with version 20191127) https://www.fieldtriptoolbox.org/
- SPM12 (tested with version 7487, https://www.fil.ion.ucl.ac.uk/spm/software/spm12/)
- Freesurfer (tested with version 6.0.0), https://surfer.nmr.mgh.harvard.edu/
- R (required, tested with version 4.2.2 (2022-10-31))
- HCTSA toolbox, https://github.com/benfulcher/hctsa
- MLconfound https://github.com/pni-lab/mlconfound

### Data

Raw data can be obtained via: https://camcan-archive.mrc-cbu.cam.ac.uk/dataaccess/ upon request

### Analysis steps

- 1 Pre-processing of single-subject MEG data
- 2 Compute time-series features on MEG data
- 3 Run partial least squares regressions
- 4 K-means clustering on regression weights
- 5 Visualize results
- 6 Do confounder analysis

