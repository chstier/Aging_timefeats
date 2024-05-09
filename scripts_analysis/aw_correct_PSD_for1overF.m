function [psdPeriodic, fooofResults, psdAperiodic] = aw_correct_PSD_for1overF(psd, freq, freqRangeOI, fooofSettings)

% This script uses the fooof/specparam algorithm to compute periodic and
% aperiodic components of the signal as indicated here:
% Donoghue, T. et al. Parameterizing neural power spectra into periodic 
% and aperiodic components. Nat. Neurosci. 23, 1655-1665 (2020))

% A. Wollbrink


if nargin < 4, fooofSettings = struct(); fprintf(1, '\n\n##### HINT: default fooof settings will be used. ####\n'); end
if nargin < 3, error('unsufficient number of input parameters defined by the user'); end

Nchans = size(psd, 1);

fprintf(1, '\ndata contain %d channels.\n', Nchans);

fprintf(1, '\n\n');
% parfor c = 1:Nchans
parfor c = 1:Nchans         
    fprintf(1, '\ncalculating FOOOF for channel %4d / %4d ...', c, Nchans);
    fres = fooof(freq, psd(c, :)', [freqRangeOI(1), freqRangeOI(2)], fooofSettings, true);
    fprintf(1, ' done.');

    fooofResults{c} = fres;
    psdAperiodic(c, :) = 10.0 ^ fres.aperiodic_params(1) * 1.0 ./ (freq .^ fres.aperiodic_params(2));
    psdP(c, :) = psd(c, :) - psdAperiodic(c, :);
end
fprintf(1, '\n\n');

psdPeriodic = psdP;

return;
