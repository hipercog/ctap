function [psd, info] = psdest_welch_matlab(x, m, overlap, nfft, varargin)
%PSDEST_WELCH_MATLAB - PSD estimation using Matlab's implementation of Welch's method
%
% Description:
%   Estimates the PSD of 'x' using Welch's averaged periodogram method as 
%   implemented in Matlab Signal Processing Toolbox (pwelch.m). 
%   Same output as psdest_welch.m.
%
%
% Syntax:
%   [psd, info] = estimatepsd_matlab(x, m, overlap, nfft, removeTrend);
%
% Inputs:
%   x           n-by-1 double, time series of which the PSD is calculated
%   m           1-by-1 int, subsegment length in samples
%   overlap     1-by-1 numeric, overlap ratio (e.g. 0.5 for 50%)
%   nfft        1-by-1 int, FFT length that matches the length of m,
%               nfft = 2^n such that nfft > m (to give room for
%               zeropadding).
%   varargin Key-value pairs         
%   'removeTrend'   string, Singal trend removal prior to estimation
%                   'no' -> 'x' is not modified prior to PSD estimation
%                   'yes' -> Linear trend and mean removed from 'x' prior
%                   to PSD estimation
%   'detrend_mode'  string, Which syntaxt to use for detrend.m: 'matlab' 
%                   for Matlab style and 'biosig' for BioSig Toolbox style.
%                   The correct option depends on which version of
%                   detrend.m is in Matlab search path.
%
% Outputs:
%  psd      1-by-(nfft/2+1) double, The power spectrum density of 'x'
%  info     Calculation parameters
%   .method             string, Method name: 'welch-matlab'
%   .dlen               1-by-1 int, length(x)
%   .overlap            see input
%   .m                  see input
%   .d                  1-by-1 int, Subsegment overlap in samples
%   .nfft               see input
%
% References: See Matlab help for pwelch.m
%
% Example:
%
% See also: pwelch.m, psdest_welch.m, fvec.m 
%
% Version History:
%   Minor improvements and help update (2.10.2007, jkor, TTL)
%   First version  (20.3.2007, jkor, TTL)
%
% Copyright 2007- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameter values
% Field names of 'Arg' can be used as keywords.

%Periodogram windowing: window type
Arg.window_type = 'hamming';
%Select if trend removal should be applied to x as a whole
Arg.removeTrend = 'yes';
%Select which syntax to use for detrend.m
Arg.detrend_mode = 'matlab'; %'biosig' 

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end


%% Initialize
Lx = length(x);


%% Removing linear trend and mean
if strcmp(Arg.removeTrend, 'yes')
    
    if strcmp(Arg.detrend_mode, 'matlab')
        %%Matlab R2006b syntax:
        x = detrend(x, 'linear'); %Remove linear trend
        x = detrend(x, 'constant'); %Remove mean

    elseif strcmp(Arg.detrend_mode, 'biosig')
        %%Biosig Toolbox syntax:
        [x,t] = detrend(x, 1); %Remove linear trend (Biosig Toolbox syntax)
        [x,t] = detrend(x, 0); %Remove mean (Biosig Toolbox syntax)
        %[x,t] = detrend(x, 2); %Remove 2nd order polynomial (Biosig Toolbox syntax)
        clear('t');

    else
        error('psdest_welch:paramterValueError','Unrecognized ''detrend_mode''.'); 
    end

end


%% Estimating PSD
% Matlab default PSD estimation ([Pxx,w] = pwelch(x,window,noverlap,PSD.nfft))
    
% Specify window
if strcmp(Arg.window_type, 'hamming')
    win = hamming(m);
    %Would Chebyshev be better (chebwin.m)?
else
   error('psdest_welch:paramterValueError','Unrecognized ''window_type''.'); 
end

d = overlap*m;

% Truncate x to match 'win' offset by 'd'
maxNwins = floor(numel(x)/numel(win));
psd = pwelch(x(1:maxNwins*numel(win)), win, d, nfft);


%% Creating output
info.method = 'welch-matlab';
info.dlen = length(x); %in samples
info.overlap = overlap;
info.m = m; %in samples
info.d = d; %in samples
info.nfft = nfft;
% EOF