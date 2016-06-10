function [y_out, b, a]=bessel_antialias(y, Fs, Fs_cutoff, settling_time, n)
% % bessel_antialias: applies an antialiasing digital Bessel filter
% % 
% % Syntax:  
% % 
% % [y_out, b, a]=bessel_antialias(y, Fs, Fs_cutoff, settling_time, n);
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
% % y=randn(50000, 1);  % multichannel input time record in (Pa).  
% %                     % Processsing assumes that y has more channels 
% %                     % than time record samples and automatically 
% %                     % transposes the data to the correct shape.  
% %                     % default is y=randn(50000, 1);
% % 
% % Fs=50000;           % (Hz) sampling rate in Hz.  
% %                     % default is 50000 Hz.
% % 
% % Fs_cutoff=10000;    % (Hz) Low frequency cutoff for application of
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
% % List of Dependent Subprograms for 
% % bessel_antialias
% % 
% % FEX ID# is the File ID on the Matlab Central File Exchange
% % 
% % 
% % Program Name   Author   FEX ID#
% % 1) bessel_digital		Edward L. Zechmann			
% % 2) convert_double		Edward L. Zechmann			
% % 3) filter_settling_data3		Edward L. Zechmann			
% % 4) geospace		Edward L. Zechmann			
% % 5) LMSloc		Alexandros Leontitsis		801	
% % 6) match_height_and_slopes2		Edward L. Zechmann			
% % 7) remove_filter_settling_data		Edward L. Zechmann			
% % 8) rms_val		Edward L. Zechmann				
% % 
% % 
% % *********************************************************************
% %
% % bessel_antialias is written by Edward Zechmann
% %
% %     date  9 July    2010
% %
% % modified 13 July    2010    Added option to change the filter order.
% %                             Update Comments
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

if (nargin < 3 || isempty(Fs_cutoff)) || ~isnumeric(Fs_cutoff)
    Fs_cutoff=10000;
end

if (nargin < 4 || isempty(settling_time)) || ~isnumeric(settling_time)
    settling_time=0.1;
end

% Use a 5th order filter
if (nargin < 5 || isempty(n)) || ~isnumeric(n)
    n=5;
end




% Filtering removes frequency components that would be aliased.

[b, a]=bessel_digital(1, 4*Fs_cutoff/Fs, n);

% Determine appropriate data for settling the filter.
num_data_pts=length(y);
[y2, num_pts_se]=filter_settling_data3(Fs, y, settling_time);
                            
y2 = filtfilt(b, a, y2);

% Remove the settling data from the time record. 
[y_out]=remove_filter_settling_data(y2, 1, num_pts_se, num_data_pts, 1);


