function alpha = variance_factor(data, refdata)
%VARIANCE_FACTOR - Calculate factor to equalize variances
%
% Description:
%   Output 'alpha' can be used to rescale 'data' so that the following 
%   equation holds:
%   var(alpha*data) = var(refdata)
%   
%   This is useful e.g. when visualizing signals of very different
%   amplitudes.

%% Vectorize inputs
data = data(:);
refdata = refdata(:);

%% Calculate mean row variances
meanvar_refdata = mean(var(refdata, 0, 1));
meanvar_data = mean(var(data, 0, 1));

%% Calculate alpha
alpha = sqrt(meanvar_refdata/meanvar_data);