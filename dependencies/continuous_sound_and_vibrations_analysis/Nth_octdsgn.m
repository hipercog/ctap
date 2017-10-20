function [B, A]=Nth_octdsgn(Fs, Fc, N, n)
% % Nth_octdsgn:  Design of a one-Nth-octave filter.
% % 
% % Syntax
% % 
% % [B,A] = Nth_octdsgn(Fs, Fc, N, n);
% % 
% % **********************************************************************
% % 
% % Acknowledgement
% % 
% % This program is based on oct3dsgn by Christophe Couvreur.  
% % The original code and documentation was kept as much as possible.
% % 
% % See Matlab FEX ID 69     Title  octave
% % 
% % Author: Christophe Couvreur, Faculte Polytechnique de Mons (Belgium)
% %         couvreur@thor.fpms.ac.be
% % 
% % 
% % **********************************************************************
% % 
% % Description
% % 
% % [B,A] = Nth_octdsgn(Fs, Fc, N, n) designs a digital 1/N-octave filter
% % with sampling frequency Fs and center frequency Fc with a 
% % butterworth filter of order-n.
% % 
% % 
% % The filter is designed according to the Order-n specification 
% % of the ANSI S1.1-1986 standard. 
% % 
% % Default values for Fs is 50000 (Hz), Fc is 1000 Hz, N is 3, and n is 3.
% % 
% % It is recommended to use Nth_octdsgn with Nth_oct_time_filter which
% % implements the following:  Fs is iteratively resmapled to be in the 
% % range Fs/20 < Fc < Fs/5.  Further the built-in filter programs  
% % y=filter(B,A,X) or y=filtfilt(B,A,X) are used.  Further a filter settling 
% % progam filter_settling_data is used to settle the resampling filter
% % and the Nth_octdsgn filter.  
% % 
% % 
% % **********************************************************************
% % 
% % Input Variables
% % 
% % Fs=50000;           % (Hz) is the sampling rate of the time record.
% %                     % default is Fs=50000; Hz.
% % 
% % fc=10000;           % (Hz) is the center frequency for the one-Nth
% %                     % octave band filter
% % 
% % N=3;                % is the number of frequency bands per octave.  
% %                     % Can be any number > 0.  
% %                     % Default is 3 for third octave bands.  
% % 
% % n=3;                % is the order of the butterworth filter.  
% %                     % Default is 3 for a 3rd order butterworth filter.
% % 
% % **********************************************************************
% % 
% % Output Variables
% % 
% % B is an array of feedforward filter coefficients.
% % 
% % A is an array of feedback filter coefficients.
% % 
% % **********************************************************************
%  
% 
% Example='1';
%
% % Makes a filter for Fs=50000;  Fc=1000; N=3; n=3; 
% [B, A]=Nth_octdsgn;
% 
%
% Example='2';
% % The following filter is unstable.
% Fs=50000;
% Fc=1000; 
% N=24; 
% n=5; % 5th order butterworth filter
% [B, A]=Nth_octdsgn(Fs, Fc, N, n);
% 
%
% Example='3';
% % The following filter is stable.
% % Reducing the filter to 3rd order restores the stability.
% Fs=50000;
% Fc=1000; 
% N=24; 
% n=3;  % 3rd order butterworth filter
% [B, A]=Nth_octdsgn(Fs, Fc, N, n);
% 
%
% Example='5';
% % The following filter is stable.
% % Increasing the center frquency to 10000 Hz restores stability.  
% Fs=50000;
% Fc=10000;  % Center frequency is 10000 Hz
% N=24; 
% n=5; 
% [B, A]=Nth_octdsgn(Fs, Fc, N, n);
% 
% % **********************************************************************
% % 
% % References
% % 
% % 1)  ANSI S1.11-1986 American National Stadard Specification for 
% %                     Octave-Band and Fractional-Octave-Band Analog 
% %                     and Digital Filters.
% % 
% % 
% % **********************************************************************
% % 
% % This program requires the Matlab Signal Processing Toolbox
% % This program is based on the Octave Toolbox	by Christophe Couvreur
% % Matlab Central File Exchange ID 69
% %
% % **********************************************************************
% % 
% % Nth_octdsgn was written by Edward L. Zechmann  
% %
% %     date  7 December    2008
% % 
% % modified 14 July        2010    Updated Comments
% % 
% % modified  2 August      2010    Updated Comments
% % 
% % modified  4 August      2010    Updated Comments
% % 
% % modified 9 January      2012    Type cast the ouput B and A to double 
% 5                                 precision.  
% % 
% % **********************************************************************
% % 
% % Please feel free to modify this code.
% %
% % See Also: octave toolbox, resample, 
% %


if (nargin < 1 || isempty(Fs)) || ~isnumeric(Fs)
    Fs=50000;
end

if (nargin < 2 || isempty(Fc)) || ~isnumeric(Fc)
    Fc=1000;
end

if (nargin < 3 || isempty(N)) || ~isnumeric(N)
    N=3;
end

if (nargin < 4 || isempty(n)) || ~isnumeric(n)
    n=3;
end

if (Fc > 0.88*(Fs/2))
  error('Design not possible. Check frequencies.');
end
  
% Design Butterworth nth-order and one-Nth-octave filter 
% Note: BUTTER is based on a bilinear transformation, as suggested in [1]. 

% % Original code was kept as much as possible
f1 = Fc/(2^(1/(2*N))); 
f2 = Fc*(2^(1/(2*N))); 
Qr = Fc/(f2-f1); 
Qd = (pi/2/n)/(sin(pi/2/n))*Qr;
alpha = (1 + sqrt(1+4*Qd^2))/2/Qd; 
W1 = Fc/(Fs/2)/alpha; 
W2 = Fc/(Fs/2)*alpha;
[B,A] = butter(n,[W1,W2]); 

[B,A]=convert_double(B,A);

