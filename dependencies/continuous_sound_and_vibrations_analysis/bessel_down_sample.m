function [y_out, t_out, b, a]=bessel_down_sample(y, Fs, Fsn, settling_time, n)
% % bessel_down_sample: applies an antialiasing digital Bessel filter
% % 
% % Syntax:  
% % 
% % [y_out, t_out, b, a]=bessel_down_sample(y, Fs, Fsn, settling_time, n);
% % 
% % *********************************************************************
% % 
% % Description
% % 
% % Applies 5th order an antialiasing digital Bessel filter.  
% % downsamples to the new sampling rate is Fsn.  Using cubic spline 
% % interpolation to avoid ringing.    
% % 
% % This filter was designed to downsample impulsive noise time records
% % without introducing the ringing effects associated with other filters.  
% % 
% % 
% % 
% % *********************************************************************
% % 
% % Input Variables
% %
% % y=randn(50000, 1);  % multichannel input time record in (Pa).  
% %                     % Processsing assumes that y has more channels 
% %                     % than time record samples and automatically 
% %                     % transposes the data to the correct shape.  
% %                     % default is y=randn(50000, 1);
% % 
% % Fs=50000;           % (Hz) sampling rate in Hz.  
% %                     % default is 50000 Hz.
% % 
% % Fsn=10000;          % (Hz) Low frequency cutoff for application of
% %                     % antialising filter. 
% %                     % default is Fs_cutoff=10000; %(Hz)
% % 
% % settling_time=0.1;  % (seconds) is the time it takes the filter to 
% %                     % settle (seconds).
% %                     % default is settling_time=0.1;
% %
% % n=5;                % is the order of the digital Bessel filter.  
% %                     % Default is 5 for a 5th order Bessel filter.
% %                     % default is n=5; 
% % 
% %
% %
% % *********************************************************************
% % 
% % Output Variables
% % 
% % y_out is the filtered time record.  
% % 
% % t_out is the time record of the filtered and downsampled data.
% % 
% % b is an array of feedforward filter coefficients.
% % 
% % a is an array of feedbackfilter filter coefficients.
% % 
% %
% % *********************************************************************
% % 
% % 
% % Subprograms
% %
% % This program requires the Matlab Signal Processing Toolbox
% %
% % 
% % 
% % List of Dependent Subprograms for 
% % bessel_down_sample
% % 
% % FEX ID# is the File ID on the Matlab Central File Exchange
% % 
% % 
% % Program Name   Author   FEX ID#
% %  1) bessel_antialias		Edward L. Zechmann			
% %  2) bessel_digital		Edward L. Zechmann			
% %  3) convert_double		Edward L. Zechmann			
% %  4) filter_settling_data3		Edward L. Zechmann			
% %  5) geospace		Edward L. Zechmann			
% %  6) LMSloc		Alexandros Leontitsis		801	
% %  7) match_height_and_slopes2		Edward L. Zechmann			
% %  8) remove_filter_settling_data		Edward L. Zechmann			
% %  9) resample_interp3		Edward L. Zechmann			
% % 10) rms_val		Edward L. Zechmann							
% % 
% % 
% % *********************************************************************
% %
% % bessel_down_sample is written by Edward Zechmann
% %
% %     date  9 July        2010
% %
% % modified 13 July        2010    Added option to change the filter order
% %                                 Update Comments
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



if (nargin < 1 || isempty(y)) || ~isnumeric(y)
    y=randn(50000, 1);
end


% Make the data have the correct data type and size
[y]=convert_double(y);

[num_pts, num_mics]=size(y);

if num_mics > num_pts
    y=y';
    [num_pts, num_mics]=size(y);
end

if (nargin < 2 || isempty(Fs)) || ~isnumeric(Fs)
    Fs=50000;
end

if (nargin < 3 || isempty(Fsn)) || ~isnumeric(Fsn)
    Fsn=50000;
end

if (nargin < 4 || isempty(settling_time)) || ~isnumeric(settling_time)
    settling_time=0.1;
end

% Use a 5th order filter
if (nargin < 5 || isempty(n)) || ~isnumeric(n)
    n=5;
end




% Apply an antialiasing filter
[y_out, b, a]=bessel_antialias(y, Fs, Fsn, settling_time, n);

% Calculate the time record
t_in=1/Fs*(-1+(1:length(y_out)));

% Apply cubic spline interpolation to the antialised time record.  
% The interpolation downsamples with less ringing effect than the resample 
% function.  
[y_out, t_out]=resample_interp3(y_out, t_in, 1/Fsn);

