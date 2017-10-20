function [LeqA, LeqA8, LeqC, LeqC8, Leq, Leq8, peak_dB, peak_dBA, peak_dBC, peak_Pa, peak_PaA, peak_PaC]=Leq_all_calc(y, Fs, cf, settling_time, resample_filter)
% % Leq_all_calc: Calculates levels and peaks for A, C, and linear weighting
% % 
% % Syntax:
% % 
% % [LeqA, LeqA8, LeqC, LeqC8, Leq, Leq8, peak_dB, peak_dBA, peak_dBC, peak_Pa, peak_PaA, peak_PaC]=Leq_all_calc(y, Fs, cf, settling_time, resample_filter);
% % 
% % *********************************************************************
% % 
% % Description
% % 
% % This program calculates the A-weighted, C-weighted and Linear weighted
% % sound levels, 8 hour equivalent sound levels, and peak levels, for the 
% % input sound pressure time record y.  The A and C-weighting filters use
% % resampling, iterative filtering and filter settling to maximize
% % accuracy and keep the filters as stable as possible.  
% % 
% % There are two options for the downsampling filters to optimize
% % performance for continuous signals or for impulsive signals. 
% % For continuous noise the time domain does not have significant 
% % impulses; however, for impulsive time records there are often very
% % large impulses with distinctive peaks.  
% % 
% % There are two antialiasing filters and interpolation schemes available.
% % The first program is the built-in Matlab "resample" progam which
% % uses a Kaiser window fir filter for antialising and uses an unknown 
% % interpolation method.  The second program available for downsampling 
% % is bessel_down_sample which uses a Bessel filter for antialiasing 
% % and uses interp with the cubic spline option for interpolation.  
% % 
% % The resample function has good antialising up to the Nyquist frequency;
% % however, it has significant ringing effect when there are impulses.  
% % The bessel_down_sample function has good antialising; however, there is
% % excessive attenuation near the Nyquist frequency.  
% % The bessel_down_sample function experiences no ringing due to impulses
% % so it is very useful for peak estimation.  
% %
% %
% % The input and output variables are described in more detail in the
% % respective sections below.
% % 
% % *********************************************************************
% % 
% % Leq_all_calc program is based on adsgn and cdsgn 
% % by Christophe Couvreur, see	Matlab FEX ID 69
% % 
% % Original Author: Christophe Couvreur, Faculte Polytechnique de Mons (Belgium)
% %         couvreur@thor.fpms.ac.be
% % 
% % *********************************************************************
% % 
% % Input Variables
% % 
% % y=randn(10000, 10); % multichannel input time record in (Pa).  
% %                     % Processsing assumes that y has more channels 
% %                     % than time record samples.
% %                     % default is y=randn(10000, 10);
% % 
% % Fs=50000;           % (Hz) sampling rate in Hz.  
% %                     % default is 50000 Hz.
% % 
% % cf=1;               % calibration factor multiplied by the time record 
% %                     % for calibration.   
% %                     % default is cf=1;  
% % 
% % settling_time=0.1;  % (seconds) is the time it takes the filter to 
% %                     % settle (seconds).
% %                     % default is settling_time=0.1;
% %
% % resample_filter=1;  % type of filter to use when resamling
% %                     % 1 resample function Kaiser window fir filter
% %                     % 2 Bessel filter 
% %                     % otherwise resample function Kaiser window fir
% %                     % filter
% %                     % default is resample_filter=1; (Kaiser window)
% %
% %
% % *********************************************************************
% % 
% % Output Variables
% % 
% % LeqA is the A-weighted sound pressure level dBA
% % LeqA8 is the 8-hour equivalent A-weighted sound pressure level dBA
% % 
% % LeqC is the C-weighted sound pressure level dBC
% % LeqC8 is the 8-hour equivalent C-weighted sound pressure level dBC
% % 
% % Leq is the Linear-weighted sound pressure level dB
% % Leq8 is the 8-hour equivalent Linear-weighted sound pressure level dB
% % 
% % peak_dB is the un-weighted peak level dB
% % peak_dBA is the A-weighted peak level dBA
% % peak_dBC is the C-weighted peak level dBC
% % 
% % peak_Pa is the un-weighted peak pressure in Pa
% % peak_PaA is the A-weighted peak pressure in Pa
% % peak_PaC is the C-weighted peak pressure in Pa
% % 
% % *********************************************************************
% 
% Example='1';
% 
% y=rand(1,100000);     % Pa Sound Pressure time record
% 
% Fs=50000;             % Hz sampling rate for sound pressure data
% 
% cf=1;                 % 1 calibration factor default value is 1
% 
% settling_time=0;      % seconds for the filter to settle
% resample_filter=1; 
% 
% [LeqA, LeqA8, LeqC, LeqC8, Leq, Leq8, peak_dB, peakA_dB, peak_dBC]=Leq_all_calc(y, Fs, cf, settling_time, resample_filter);
% 
% % Compare to a longer settling time
% settling_time=0.1;    % seconds for the filter to settle
% 
% [LeqA2, LeqA82, LeqC2, LeqC82, Leq2, Leq82, peak_dB2, peakA_dB2, peak_dBC2]=Leq_all_calc(y, Fs, cf, settling_time);
% diffs=[LeqA-LeqA2 LeqA8-LeqA82 LeqC-LeqC2 LeqC8-LeqC82 Leq-Leq2 Leq8-Leq82 peak_dB-peak_dB2 peakA_dB-peakA_dB peak_dBC-peak_dBC2]
% 
% 
% % *********************************************************************
% %
% % 
% % Subprograms
% %
% % Leq_all_calc requires the Matlab Signal Processing Toolbox
% %
% % 
% % 
% % List of Dependent Subprograms for 
% % Leq_all_calc
% % 
% % FEX ID# is the File ID on the Matlab Central File Exchange
% % 
% % 
% % Program Name   Author   FEX ID#
% %  1) ACdsgn		Edward L. Zechmann			
% %  2) ACweight_time_filter		Edward L. Zechmann			
% %  3) bessel_antialias		Edward L. Zechmann			
% %  4) bessel_digital		Edward L. Zechmann			
% %  5) bessel_down_sample		Edward L. Zechmann			
% %  6) convert_double		Edward L. Zechmann			
% %  7) filter_settling_data3		Edward L. Zechmann			
% %  8) geospace		Edward L. Zechmann			
% %  9) get_p_q2		Edward L. Zechmann			
% % 10) LMSloc		Alexandros Leontitsis		801	
% % 11) match_height_and_slopes2		Edward L. Zechmann			
% % 12) moving		Aslak Grinsted		8251	
% % 13) remove_filter_settling_data		Edward L. Zechmann			
% % 14) resample_interp3		Edward L. Zechmann			
% % 15) rms_val		Edward L. Zechmann			
% % 16) sub_mean		Edward L. Zechmann								
% % 
% % 
% % 
% % *********************************************************************
% %
% % Leq_all_calc is written by Edward L. Zechmann 
% %  
% %     date    uncertain   2007
% % 
% % modified 19 December    2007    Added comments and an example
% % 
% % modified 13 February    2008    Updated comments 
% %    
% % modified 15 August      2008    Updated comments 
% %  
% % modified 16 August      2008    Updated error checking and comments 
% %                     
% % modified 10 December    2008    Upgraded the A and C-
% %                                 weighting filter programs, 
% %                                 to include filter settling and 
% %                                 resampling.
% %  
% % modified 11 December    2008    Upgraded the A and C-
% %                                 weighting filter programs, 
% %                                 to include iterative filtering.  
% %                                 The filters are now very stable.
% % 
% %                                 Removed filter coefficients from input
% %                                 and output;
% %                                 Peaks pressures and Levels are output.
% %  
% % modified 16 December    2008    Use convolution to make filter
% %                                 coefficients (b and a) into  
% %                                 arrays from cell arrays.
% % 
% % modified  6 October     2009    Updated comments
% % 
% % modified  9 July        2010    Added an option to resample using a
% %                                 Bessel Filter.  Updated comments.
% % 
% % modified  4 August      2010    Updated Comments
% %
% % 
% % 
% %  
% % *********************************************************************
% % 
% % Please feel free to modify this code.
% % 
% % See also: adsgn, cdsgn, resample, ACdsgn, ACweight_time_filter
% % 

if nargin < 1 || isempty(y) || ~isnumeric(y)
    y=randn(10, 10000);
end

% Make the data have the correct data type and size
[y]=convert_double(y);

% Make sure the matrix y is oriented correctly.  
% Transpose if necessary.  
[m1 n1]=size(y);

if n1 > m1
    y=y';
end

if nargin < 2 || isempty(Fs) || ~isnumeric(Fs)
    Fs=50000;
end

if nargin < 3 || isempty(cf) || ~isnumeric(cf)
    cf=1;
end

% Set the settling time of the filters default is 0.1 seconds.
if (nargin < 4 || isempty(settling_time)) || ~isnumeric(settling_time)
    settling_time=0.1;
end

if (nargin < 5 || isempty(resample_filter)) || ~isnumeric(resample_filter)
    resample_filter=1;
end


% Apply the calibration factor to the time record.  
y = cf.*y;

% Calculate the A-weighted time record
[yA]=ACweight_time_filter(0, y, Fs, settling_time, resample_filter);

% Make sure the matrix y is oriented correctly.  
% Transpose if necessary.  
[m1 n1]=size(yA);

if n1 > m1
    yA=yA';
end

% Calculate the C-weighted time record
[yC]=ACweight_time_filter(1, y, Fs, settling_time, resample_filter);

% Make sure the matrix y is oriented correctly.  
% Transpose if necessary.  
[m1 n1]=size(yC);

if n1 > m1
    yC=yC';
end

% Reference level for dB scale. 
Pref = 20e-6;     

% Calculate the length of the time record.  
n1=length(y);

% Calculate the Linear-weighted Leq and Leq8
Leq   = 10 * log10(  (sqrt(sum(y.^2))./sqrt(n1)./Pref).^2  );
Leq8  = 10*log10(n1./Fs./(8*3600))*ones(size(Leq))+Leq;

% Calculate the A-weighted Leq and Leq8
LeqA  = 10 * log10(  (sqrt(sum(yA.^2))./sqrt(n1)./Pref).^2  );
LeqA8 = 10*log10(n1./Fs./(8*3600))*ones(size(LeqA))+LeqA;

% Calculate the C-weighted Leq and Leq8
LeqC  = 10 * log10(  (sqrt(sum(yC.^2))./sqrt(n1)./Pref).^2  );
LeqC8 = 10*log10(n1./Fs./(8*3600))*ones(size(LeqC))+LeqC;

% Find the index of the Linear, A-weighted, and C-weighted peak values
[abs_peak  y_ix ]=max(abs( y ));
[abs_peakA yA_ix]=max(abs( yA ));
[abs_peakC yC_ix]=max(abs( yC ));

% Return the Peak Levels in dB
peak_dB =20 * log10(abs(y(  y_ix, : ))/0.00002);
peak_dBA=20 * log10(abs(yA( yA_ix, : ))/0.00002);
peak_dBC=20 * log10(abs(yC( yC_ix, : ))/0.00002);

% Calculate the peak amplitudes in Pa 
peak_Pa =y(  y_ix, : );
peak_PaA=yA( yA_ix, : );
peak_PaC=yC( yC_ix, : );


