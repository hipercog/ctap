function [bz, az]=bessel_digital(Fs, Fcutoff, n)
% % bessel_digital: creates a digital low pass bessel filter of order n
% % 
% % Syntax:  
% % 
% % [bz, az]=bessel_digital(Fs, Fcutoff, n);
% % 
% % 
% % *********************************************************************
% % 
% % Description
% % 
% % Applies an antialiasing digital Bessel filter.  Assumes that Fs_cutoff 
% % will be the Nyquist Frequency for downsampling.  5th order Bessel 
% % filter is default.    
% % 
% % 
% % *********************************************************************
% % 
% % Input Variables
% % 
% % Fs=50000;           % (Hz) sampling rate in Hz.  
% %                     % default is 50000 Hz.
% % 
% % Fs_cutoff=10000;    % (Hz) Low frequency cutoff for application of
% %                     % antialising filter. 
% %                     % default is Fs_cutoff=10000; %(Hz)
% % 
% % n=3;                % is the order of the digital Bessel filter.  
% %                     % Default is 3 for a 3rd order Bessel filter.
% %                     % default is n=3; 
% % 
% %
% % 
% % **********************************************************************
% % 
% % Output Variables
% % 
% % bz is an array of feedforward filter coefficients.
% % 
% % az is an array of feedbackfilter coefficients. 
% % 
% % 
% % *********************************************************************
% % 
% % Subprograms
% %
% % This program requires the Matlab Signal Processing Toolbox
% %
% % 
% % *********************************************************************
% %
% % bessel_digital is written by Edward Zechmann
% %
% %     date 8 July         2010
% %
% % modified 13 July        2010    Update Comments
% %  
% % modified  5 August      2010    Update Comments
% %  
% % 
% % 
% % *********************************************************************
% % 
% % Please feel free to modify this code.
% % 
% % See also: resample, downsample, upsample, upfirdn
% % 

if (nargin < 1 || isempty(Fs)) || ~isnumeric(Fs)
    Fs=50000;
end

if (nargin < 2 || isempty(Fcutoff)) || ~isnumeric(Fcutoff)
    Fcutoff=1000;
end

if (nargin < 3 || isempty(n)) || ~isnumeric(n)
    n=3;
end

% Define an analog Bessel filter 
% on a unit samling rate
Wo=1;
[b, a]=besself(n, Wo);

% Apply the impulse invariance transformation to transform the analog
% filter into a digital filter.  
[bz, az] = impinvar(b, a, Fs/Fcutoff);





