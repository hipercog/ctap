function [yh, B, A, errors]=hand_arm_time_fil(y, Fs, B, A, settling_time, resample_filter)
% % hand_arm_time_fil: Calculates the hand arm vibrations filter coefficients and returns the filtered time record
% %
% % Syntax;
% %
% % [yh, B, A, errors]=hand_arm_time_fil(y, Fs, B, A, settling_time, resample_filter)
% %
% % ********************************************************************
% %
% % Description
% %
% % Calculates the hand arm vibrations filter coefficients and returns the
% % filtered time record.
% %
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
% % sections below respectively.
% %
% %
% % ********************************************************************
% %
% % Input Variables
% %
% % y=randn(10000, 10)  % multichannel input time record in (Pa).
% %                     % Processsing assumes that y has more channels
% %                     % than time record samples.
% %                     % default is y=randn(10000, 10);
% %
% % Fs=50000;           % (Hz) sampling rate in Hz.
% %                     % default is 50000 Hz.
% %
% % B is an array of feedforward filter coefficients for the hand arm vibration
% % 
% % A is an array of feedback filter coefficients for the hand arm vibration
% %                     % frequency weighting filter.
% %                     % default is B=1; A=1; The program recalculates
% %                     % B and A if the input values are not numeric,
% %                     % are empty, or have a length less than 4.
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
% % ********************************************************************
% %
% % Output Variables
% %
% % yh is the time record which has been filtered by the hand arm
% %             vibration frequency filter.
% % 
% % B is an array of feedforward filter coefficients for hand arm
% %             vibration frequency weighting filter.
% % 
% % A is an array of feedback filter coefficients for hand arm
% %             vibration frequency weighting filter.
% %
% % errors indicates whether the resampled sampling rate is within the
% %             tolerance of 5000 Hz.  Within tolerance 0 is output.
% %             outside of tolerance 1 is output.
% %
% % **********************************************************************
%
%
% Example='1';
%
% % An exaple with 1 channels of vibrations data
%
% y=randn(1, 50000);
% Fs=10000;
% B=1;
% A=1;
% settling_time=1;
%
% [yh, B, A, errors]=hand_arm_time_fil(y, Fs, B, A, settling_time);
%
% % Plot the results
% t_vibs=1/Fs*(0:(50000-1));
% subplot(2,1,1);
% plot(t_vibs, y);
% title('Unweighted Time Record');
% hold on;
% subplot(2,1,2);
% plot(t_vibs, yh);
% title('Weighted Time Record');
%
% % ********************************************************************
% %
% % This program requires the Matlab Signal Processing Toolbox
% %
% % 
% % List of Dependent Subprograms for 
% % hand_arm_time_fil
% % 
% % FEX ID# is the File ID on the Matlab Central File Exchange
% % 
% % 
% % Program Name   Author   FEX ID#
% %  1) bessel_antialias		Edward L. Zechmann			
% %  2) bessel_digital		Edward L. Zechmann			
% %  3) bessel_down_sample		Edward L. Zechmann			
% %  4) convert_double		Edward L. Zechmann			
% %  5) filter_settling_data3		Edward L. Zechmann			
% %  6) geospace		Edward L. Zechmann			
% %  7) get_p_q2		Edward L. Zechmann			
% %  8) hand_arm_fil		Edward L. Zechmann			
% %  9) LMSloc		Alexandros Leontitsis		801	
% % 10) match_height_and_slopes2		Edward L. Zechmann			
% % 11) remove_filter_settling_data		Edward L. Zechmann			
% % 12) resample_interp3		Edward L. Zechmann			
% % 13) rms_val		Edward L. Zechmann			
% % 14) sub_mean2		Edward L. Zechmann			
% %
% %
% % ********************************************************************
% %
% % Program Modified by Edward L. Zechmann
% %
% %  created    June        2007
% %
% % modified  3 September   2008    Updated comments
% %
% % modified 10 December    2008    Upgraded to include
% %                                 filter settling and resampling.
% %
% % modified 16 December    2008    Use convolution to simplify filter
% %                                 coefficients (B1, B2, A1, A2) into
% %                                 arrays B and A.
% %
% %                                 Finished modifications to support
% %                                 filter settling and resampling.
% %
% % modified 19 December    2008    Updated comments
% %
% % modified  5 January     2009    Added sub_mean to remove running
% %                                 average using a a number of averages
% %                                 per second at one-half the lowest
% %                                 frequency band of interest(1 Hz).
% %
% % modified  9 October     2009    Updated Comments
% % 
% % modified  9 July        2010    Added an option to resample using a
% %                                 Bessel Filter.  Updated comments.
% %
% % modified  4 August      2010    Updated Comments
% % 
% %
% %
% %
% % ********************************************************************
% %
% % Please Feel Free to Modify This Program
% %
% % See Also: hand_arm_fil, vibs_calc_hand_arm
% %


if nargin < 1 || isempty(y) || ~isnumeric(y)
    y=randn(10, 10000);
end

if nargin < 2 || isempty(Fs) || ~isnumeric(Fs)
    Fs=10000;
end

if nargin < 3 || isempty(B) || ~isnumeric(B)
    B=1;
end

if nargin < 4 || isempty(A) || ~isnumeric(A)
    A=1;
end

% Hand-arm vibrations require a longer filter settling time than for sound
% because the important frequencies are at least an order of magnitude
% lower.
if (nargin < 5 || isempty(settling_time)) || ~isnumeric(settling_time)
    settling_time=1;
end

if (nargin < 6 || isempty(resample_filter)) || ~isnumeric(resample_filter)
    resample_filter=1;
end

if ~isequal(resample_filter, 2)
    resample_filter=1;
end


% Remove the running average from the signal.
% The number of averages per second can be about one-tenth the lowest
% frequency to resolve.  For hand-arm vibrations, the lowest frequency to
% resolve according to ISO 5349-1 is 1.0 Hz
[y]=sub_mean2(y, Fs, 0);



% % ********************************************************************
% %
% set the flag for indicating whether to resample
flag0=0;

max_freq=60000;
min_freq=5000;

if Fs <= max_freq
    p=1;
    q=1;
    Fsn=Fs;
    errors=0;
else
    [Fsn, p, q, errors]=get_p_q2(Fs, max_freq, min_freq);
end

if ~isequal(Fsn, Fs)
    flag0=1;
end



% % ********************************************************************
% %

[num_samples, num_channels]=size(y);

% set the flag for indicating whether to transpose
flag1=0;

% Transpose the data so that the filters act along the time records
% not along the channels.
if num_samples < num_channels
    flag1=1;
    y=y';
    [num_samples, num_channels]=size(y);
end


if (nargin < 4) || (logical(length(B) < 4) ||  logical(length(A) < 4)) || logical(~isnumeric(B) || ~isnumeric(A))

    [B, A]=hand_arm_fil(Fsn);

end


% % ********************************************************************
%
% Downsample the data to a reasonable sampling rate to keep the hand arm
% vibrations filters as stable as possible.
if isequal(flag0, 1)

    % Adding filter settling data
    num_data_pts=num_samples;
    [y11, num_settle_pts]=filter_settling_data3(Fs, y(:, 1), settling_time);

    % Downsampling
    if isequal(resample_filter, 1)
        buf=resample(y11, p, q);
    else
        [buf]=bessel_down_sample(y11, Fs, Fs*p/q, settling_time);
    end

    % removing filter settling data
    [buf]=remove_filter_settling_data(buf, q/p, num_settle_pts, num_data_pts, 0);

    n2=length(buf);
    y2=zeros(n2, num_channels);
    y2(:, 1)=buf;
    clear('buf');
    if num_channels > 1
        for e1=2:num_channels;

            % Adding filter settling data
            [y11, num_settle_pts]=filter_settling_data3(Fs, y(:, e1), settling_time);

            % Downsampling
            if isequal(resample_filter, 1)
                buf=resample(y11, p, q);
            else
                [buf]=bessel_down_sample(y11, Fs, Fs*p/q, settling_time);
            end
            
            % removing filter settling data
            [buf]=remove_filter_settling_data(buf, q/p, num_settle_pts, num_data_pts, 0);
            y2(:, e1)=buf;
        end
    end
else
    y2=y;
end

clear('y');


% % ********************************************************************
%
% Apply the hand-arm weighting filters to each channel of data

yh=zeros(size(y2));

for e1=1:num_channels;
    
    % Adding filter settling data
    num_data_pts=length(y2(:, e1));
    [y11, num_settle_pts]=filter_settling_data3(Fsn, y2(:, e1), settling_time);

    % Apply the hand-arm vibrations filters
    buf = real(filter(B, A, y11 ));

    % Remove the settling data from the time record.
    [buf]=remove_filter_settling_data(buf, 1, num_settle_pts, num_data_pts, 2);    
    yh(:, e1)=buf;
    
end


% % ********************************************************************
%
% Resample if necessary so the output has the same size as the input
if isequal(flag0, 1)

    % Adding filter settling data
    num_data_pts=length(yh(:, 1));
    [y11, num_settle_pts]=filter_settling_data3(Fs, yh(:, 1), settling_time);

    % Upsampling
    if isequal(resample_filter, 1)
        buf=resample(y11, q, p);
    else
        t_in=q/p*1/Fs*(-1+(1:length(y11)));
        [buf]=resample_interp3(y11, t_in, 1/Fs);
        [buf]=bessel_antialias(buf, Fs, Fs/2.5, settling_time);
    end


    % removing filter settling data
    [buf]=remove_filter_settling_data(buf, q/p, num_settle_pts, num_data_pts, 1);


    num_samples2=length(buf);
    yhh=zeros(num_samples2, num_channels);
    yhh(:, 1)=buf;
    clear('buf');
    if num_channels > 1
        for e1=2:num_channels;

            % Adding filter settling data
            num_data_pts=length(yh(:, 1));
            [y11, num_settle_pts]=filter_settling_data3(Fs, yh(:, e1), settling_time);

            % Upsampling
            if isequal(resample_filter, 1)
                buf=resample(y11, q, p);
            else
                t_in=q/p*1/Fs*(-1+(1:length(y11)));
                [buf]=resample_interp3(y11, t_in, 1/Fs);
                [buf]=bessel_antialias(buf, Fs, Fs/2.5, settling_time);
            end

            % removing filter settling data
            [buf]=remove_filter_settling_data(buf, q/p, num_settle_pts, num_data_pts, 1);

            yhh(:, e1)=buf;
        end
    end
else
    yhh=yh;
end

clear('yh');


% % ********************************************************************
%
% Append the data to the output variable
if isequal(flag0, 1)
    if num_samples2 > num_samples
        num_samples2=num_samples;
    end

    yh=yhh(1:num_samples2, 1:num_channels);
else
    yh=yhh(1:num_samples, 1:num_channels);
end


% % ********************************************************************
%
% Output yh must have the same size as the original input matrix y.
% Transpose yh if necessary.
if isequal(flag1, 1)
    yh=yh';
end

