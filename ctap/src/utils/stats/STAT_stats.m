function [sk, k, lopc, hipc, tM, tSD, tidx, ksh] = STAT_stats(sig, varargin)
%STAT_STATS returns signal statistics that require the Statistics Toolbox
% 
% Description: basically the same idea as signalstat(), but internal to
% CTAP and therefore source of functions can be controlled
% 
% Outputs (everything depends on Statistics Toolbox):
%   sk          - skewness 
%   k           - kurtosis
%   lopc        - low 'percent/2'-Percentile ('percent/2'/100-Quantile)
%   hipc        - high 'percent/2'-Percentile ('percent/2'/100-Quantile)
%   tM          - trimmed mean, removing data < lopc and data > hipc
%   tSD         - trimmed standard dev, removing data < lopc and data > hipc
%   tidx        - index of the data retained after trimming
%   ksh         - output flag of the Kolmogorov-Smirnov test at level 'alpha' 
%                 0: data could be normally dist'd; 1: data not normally dist'd 
%                 -1: test could not be executed
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('sig', @isnumeric);
p.addParameter('tailPrc', 0.05, @isnumeric);
p.addParameter('alpha', 0.05, @isnumeric);

p.parse(sig, varargin{:});
Arg = p.Results;

%% Make data a vector
if ~isvector(sig)
    sig = sig(:);
end

sk = NaN;
k = NaN;
lopc = NaN;
hipc = NaN;
tM = NaN;
tSD = NaN;
tidx = NaN;
ksh = NaN;

% Trimmed Basic properties: without highest and lowest 'percent'/2 % of data
%---------------------------------------------------------------
try %we try/catch here as there seems to be a few things can go wrong.
    lopc = quantile(sig, (Arg.tailPrc / 2));   % low  quantile

    hipc  = quantile(sig, 1 - Arg.tailPrc / 2); % high quantile

    tidx = find((sig >= lopc & sig <= hipc & ~isnan(sig)));

    tM = mean(sig(tidx)); % mean with excluded Arg.tailPrc/2*100
                           % of highest and lowest values
    tSD = std(sig(tidx)); % trimmed SD
catch
    return;
end

sk = ctap_skewness(sig); % skewness (third central moment divided by
                        % the cube of the standard deviation)
                        
k = ctap_kurtosis(sig) - 3; % kurtosis (fourth central  moment divided by 
                           % fourth power of the standard deviation)

% Kolmogorov-Smirnov Goodness-of-fit hypothesis test
%--------------------------------
try
    cte = mean(sig); % central tendency estimate = mean
    [muhat, sigmahat, muci, sigmaci] = normfit(sig, Arg.alpha);%#ok<*ASGLU>
    kstail = 0; % 0 = 2-sided test
    CDF = normcdf(sig, cte, sigmahat); % estimated cdf
    [ksh, ksp, ksstat, kscv] = kstest(sig, [sig', CDF'], Arg.alpha, kstail);
catch
    %probably won't replicate this so requires expensive Matlab stats toolbox
    warning('STAT_stats:missing_function', 'You need Stats toolbox for this...')
    return;
end
%end STAT_stats()
