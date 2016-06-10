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
% MAYBEDO (BEN) - REPLACE WITH FUNCTIONALITY FROM FILE EXCHANGE, E.G.
%   http://www.mathworks.com/matlabcentral/fileexchange/41150-summarize


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

%check stats toolbox is present
try
    kurtosis(rand(1,10));
catch
    return;
end

% Trimmed Basic properties: without highest and lowest 'percent'/2 % of data
%---------------------------------------------------------------
lopc = quantile(sig, (Arg.tailPrc / 2));   % low  quantile

hipc  = quantile(sig, 1 - Arg.tailPrc / 2); % high quantile

tidx = find((sig >= lopc & sig <= hipc & ~isnan(sig)));

tM = mean(sig(tidx)); % mean with excluded Arg.tailPrc/2*100
                       % of highest and lowest values
tSD = std(sig(tidx)); % trimmed SD

sk = skewness(sig, 0); % skewness (third central moment divided by
                        % the cube of the standard deviation)
k = kurtosis(sig, 0) - 3; % kurtosis (fourth central  moment divided by 
                           % fourth power of the standard deviation)

% Kolmogorov-Smirnov Goodness-of-fit hypothesis test
%--------------------------------
cte = mean(sig); % central tendency estimate = mean
[muhat, sigmahat, muci, sigmaci] = normfit(sig, Arg.alpha);%#ok<*ASGLU>
kstail = 0; % 0 = 2-sided test
CDF = normcdf(sig, cte, sigmahat); % estimated cdf
[ksh, ksp, ksstat, kscv] = kstest(sig, [sig', CDF'], Arg.alpha, kstail);

%end STAT_stats()
