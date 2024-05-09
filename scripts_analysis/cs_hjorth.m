function [activity, mobility, complexity] = cs_hjorth(data)

% written by CS May 2023: code adapted from E.B. 
% activity is defined as var(y(t)) where y(t) represents the signal:
% skipped

tmp = cat(3, data.trial{:}); % concatenate all trial data into one 
den = squeeze(var(tmp, [], 2));
num = squeeze(var(diff(tmp, 1, 2), [], 2));

mobility = sqrt(num./den);
activity = den;

% compute complexity
dertmp = diff(tmp, 1, 2);
complexity = sqrt(squeeze(var(diff(dertmp, 1, 2), [], 2))./den)./mobility;

end



