function [X,dBA] = estimateLevel(x,Fs,C)

% ESTIMATELEVEL Estimates signal level in dBA.
%    ESTIMATELEVEL Implements an A-weighted signal
%    level meter. The FFT is used to compute the 
%    frequency spectrum.
%
% Author: Douglas R. Lanman, 11/21/05

% Calculate magnitude of FFT.
X = abs(fft(x));

% Add offset to prevent taking the log of zero.
X(find(X == 0)) = 1e-17;

% Retain frequencies below Nyquist rate.
f = (Fs/length(X))*[0:(length(X)-1)];
ind = find(f<Fs/2); 
f = f(ind); 
X = X(ind);

% Apply A-weighting filter.
A = filterA(f);
X = A'.*X;

% Estimate dBA value using Parseval's relation.
totalEnergy = sum(X.^2)/length(X);
meanEnergy = totalEnergy/((1/Fs)*length(x));
dBA = 10*log10(meanEnergy)+C;

% Estimate decibel level (for visualization).
X = 20*log10(X);