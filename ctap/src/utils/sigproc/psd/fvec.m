function f = fvec(nfft, fs)
%FVEC - Frequency vector for a power spectral density (PSD)
%
% Description:
%   Calculates frequency vector 'f' based on PSD length 'nfft' and signal
%   sampling rate 'fs'.
%
% Syntax:
%   f = fvec(nfft, fs);
%
% Inputs:
%   nfft    [1,1] int, PSD length
%   fs      [1,1] int, Signal sampling rate in [Hz]
%
% Outputs:
%   f       [nfft,1] double, Frequencies for a PSD of length 'nfft' in [Hz]
%
% References:
%
% Example: f = fvec(1024, 500);
%
% Notes: Include some good-to-know information
%
% See also: psdest_welch.m, psdest_welch_matlab.m
%
% Version History:
% 3.10.2007 Help included (Jussi Korpela, TTL) 
% 26.4.2007 Created (Jussi Korpela, TTL)
%
% Copyright 2007- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

freqRes = 1/(nfft/fs); %1/T, frequency resolution
f = (0:1:(nfft/2))*freqRes; %frequency vector in Hz