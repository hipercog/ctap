%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Calculates exponential averaged RMS of a signal using the specified
% windowlength as the time constant.
% 
% USAGE: y = rms(signal, windowlength, downsampling)
% 
% SIGNAL is a 1-D data vector. WINDOWLENGTH is an integer length
% corresponding to the time constant.  DOWNSAMPLING is an integer. 
%
% Example 1:
%     Calculate exponentially-averaged RMS with a time constant
%     corresponding to 30 samples.  Return every 10th value.
% 
%        y=rms_exp(mysignal, 30, 10). 
%
% Example 2:
%     Calculate root mean square pressur level with exponential averaging
%     of a pressure [Pa] time series sampled at 44kHz.  The averaging time
%     is to be 0.125s.  Return values at 0.004s intervals.
%     
%       y = rms_exp(mysignal, 0.125*44000, 0.004*44000)
%       SPL = 20*log10(y/20E-6)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Author: George Scott Copeland, March 8,2007
%
% The exponential average is defined for time from -infinity to present,
% but I have found that for my data 6 times the time constant is a
% sufficiently good approximation to infinity.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function y = rms(signal, windowlength, downsampling)

signal = signal.^2; % Square the samples
wgts = exp(-[1:6*windowlength]/windowlength);
b=wgts/windowlength;
signal_averaged = filter(b,[1],signal);
mm=[1:downsampling:length(signal)];
sa = signal_averaged(mm);
y=sqrt(sa);







