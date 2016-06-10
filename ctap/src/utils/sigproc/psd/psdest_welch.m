function [psd, info] = psdest_welch(x ,m, overlap, nfft, varargin)
%PSDEST_WELCH - PSD estimate using Welch's method
%
% Description:
%   Estimates the PSD of 'x' using Welch's averaged periodogram method. 
%   Unlike its Matlab counterpart pwelch.m this implementation corrects 
%   both the signal mean and variance changes introduced by windowing (see 
%   references for details). Uses Hamming window. 
%
%   Arguments 'm' and 'overlap' have to be set to match the length of 'x'.
%   Some good combinations for 500 Hz sampling rate are:
%   length(x)     m     overlap d       K     nfft
%   5s = 2500     1000  0.5     500     5     2048 tai 1024
%   10s = 5000    2000  0.75    1500    7     2048
%   20s = 10 000  2000  0.5     1000    9     2048 
%
%   Runtime constants not defined by function arguments: no
%
% Inputs:
%   x           n-by-1 double, time series of which the PSD is calculated
%   m           1-by-1 int, subsegment length in samples
%   overlap     1-by-1 numeric, overlap ratio (e.g. 0.5 for 50%)
%   nfft        1-by-1 int, FFT length that matches the length of m,
%               nfft = 2^n such that nfft > m (to give room for zeropadding).
%   varargin    Key-value pairs     
%   'detrend_mode'  string, Which syntaxt to use for detrend.m: 'matlab' 
%                   for Matlab style and 'biosig' for BioSig Toolbox style.
%                   The correct option depends on which version of
%                   detrend.m is in Matlab search path.
%
% Outputs:
%   psd      1-by-(nfft/2+1) double, The power spectrum density of 'x'
%   info     Calculation parameters
%    .method             string, Method name: 'welch-jkor'
%    .dlen               1-by-1 int, length(x)
%    .overlap            see input
%    .iPeriodogSegments  k-by-2 int, Subsegment indices
%    .m                  see input
%    .d                  1-by-1 int, Subsegment overlap in samples
%    .nfft               see input
%
% References:
%   Hayes, M.H. Statistical digital signal processing and modeling John
%   Wiley & Sons, 1996
%
%   Challis, R.E. & Kitney, R.I. Biomedical signal processing (in four
%   parts). Part 3. The power spectrum and coherence function
%   Med Biol Eng Comput, 1991, 29, 225-41
%
% Example: [PSD, info]=psdest_welch([1:1:500*5],2000,0.5,1024);
%
% See also: pwelch.m, psdest_welch_matlab.m, fvec.m 
%
% Version History:
% * First version (26.5.2006, Jussi Korpela, TTL)
% * Improved version on estimatepsd.m: calling syntax simplified and 
%   periodogram_jkor.m nested here instead of own file (20.3.2007, jkor, TTL)
% * Further minor improvements and help update (2.10.2007, jkor, TTL)
%
% Copyright 2005-2007 Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameter values
% Field names of 'Arg' can be used as keywords.

%Periodogram windowing: window type
Arg.window_type = 'hamming';
%Select which syntax to use for detrend.m
Arg.detrend_mode = 'matlab'; %'biosig' 

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end


%% Initialize
x=x(:); %convert to column vector
Lx = length(x);
d = overlap*m; %overlap in [samples]


%% Creating segments with overlap
seginds(1,:) = [1, m];
k = 2;
while seginds(k-1,2) < Lx
   seginds(k,1) = seginds(k-1,2) -d +1;  
   seginds(k,2) = seginds(k,1) +m -1;  
   k = k + 1;
end

if seginds(end, 2) > Lx
   seginds(end,2) = Lx; 
end


%% Going through the time series data in segments
psd_tmp = NaN(size(seginds,1),nfft/2+1);
%periodograms span into dim 2, one for each row
for i = 1:size(seginds,1)
    start = seginds(i,1);
    stop = seginds(i,2); 
    psd_tmp(i,:) = periodogram(x(start:stop), nfft);
end


%% Creating output
psd = mean(psd_tmp,1); %Average periodograms

info.method = 'welch-jkor';
info.dlen = Lx; %in samples
info.overlap = overlap;
info.iPeriodogSegments = seginds;
info.m = m; %in samples
info.d = d; %in samples
info.nfft = nfft;


    function psd = periodogram(y, nfft)
    %% Calculates the periodogram of 'y'
    %
    % Preprocesses 'y' (trend and mean removal) and calculates the 
    % periodogram of 'y' using window Arg.window_type. Vector 'y' will be 
    % zeropadded to nfft. Effects of the windowing procedure are corrected.
    %
    % Detrending syntax changes if BioSig Toolbox is in use. Currently the
    % change has to be done manually.
    %
    % Inputs:
    %   Needs 'y' and 'nfft' from the outer function.
    %
    % Outputs:
    %   psd      [(nfft/2+1), 1] double, the periodogram of 'y'
    %   info     calculation parameter documentation
    %
    % Jussi Korpela, 16.5.2005, TTL
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    y = y(:); %to column vector

    %% Check inputs
    if length(y) > nfft
       msg = 'Data longer than nfft. Data will be truncated.'; 
       warning('psdest_welch:dataSegmentTooShort', msg);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Parameters
    Ly = length(y);
    
    if strcmp(Arg.window_type, 'hamming')
        win = hamming(Ly); %Would Chebyshev be better (chebwin.m)?
    else
       error('psdest_welch:paramterValueError','Unrecognized ''window_type''.'); 
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Removing linear trend and mean
    
    if strcmp(Arg.detrend_mode, 'matlab')
        %%Matlab R2006b syntax:
        y = detrend(y, 'linear'); %Remove linear trend
        y = detrend(y, 'constant'); %Remove mean

    elseif strcmp(Arg.detrend_mode, 'biosig')
        %%Biosig Toolbox syntax:
        [y,t] = detrend(y, 1); %Remove linear trend (Biosig Toolbox syntax)
        [y,t] = detrend(y, 0); %Remove mean (Biosig Toolbox syntax)
        %[y,t] = detrend(y, 2); %Remove 2nd order polynomial (Biosig Toolbox syntax)
        clear('t');

    else
        error('psdest_welch:paramterValueError','Unrecognized ''detrend_mode''.'); 
    end
    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Windowing data
    % Corrections needed because of windowing: 
    k1 = y'*win/sum(win); %corrects the mean introduced by windowing
    k2 = sqrt(Ly/(win'*win)); %corrects the change in signal variance 
    % Windowing:
    wx = win.*(y-k1)*k2;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Calculating FFT (and zeropadding)
    if Ly <= nfft
        Xx = fft(wx,nfft); %zeropads automatically
    elseif Ly > nfft
        errmsg = 'Data vector too long. Aborting...';
        error('psdest_welch:dataTooLong',errmsg);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Creating output
    psd = (Xx.*conj(Xx))/Ly; %Auto spectrum

    %% Output variables
    psd = psd(1:length(psd)/2+1); %redundant values left out
    end
end
% EOF