function [rng, M, med, SD, vr] = basic_stats(sig)
%BASIC_STATS returns basic statistics of the signal that don't require
%Statistics Toolbox
% 
% Outputs:
%   rng         - range: signal maximum minus minimum
%   M           - mean
%   med         - median
%   SD          - standard deviation
%   vr          - variance

% %% Parse input arguments and set varargin defaults
% p = inputParser;
% p.addRequired('sig', @isnumeric);
% 
% p.parse(sig, varargin{:});
% Arg = p.Results;

%% Make data a vector
if ~isvector(sig)
    sig = sig(:);
end


%% Statistical characteristics
%----------------------------
rng = max(sig) - min(sig); %range

M = mean(sig); % mean
med = median(sig); % median

SD = std(sig); % standard deviation
vr = var(sig); % variance (N-1 normalized)

%end basic_stats()
