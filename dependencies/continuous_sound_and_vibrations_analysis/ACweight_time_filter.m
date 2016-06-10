function [yAC, errors]=ACweight_time_filter(type, y, Fs, settling_time, resample_filter)
% % ACweight_time_filter: Applies an A or C weighting time filter to a sound recording
% %
% % Syntax;
% %
% % [yAC, errors]=ACweight_time_filter(type, y, Fs, settling_time, resample_filter);
% %
% % ***********************************************************
% %
% % Description
% %
% % This program applies an A or C-weighting filter to
% % a sound pressure time record, then it outputs the A or C-weighted tme
% % record respectively.
% %
% % ACweight_time_filter uses the signal processing toolkit.
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
% % ***********************************************************
% %
% % Input Variables
% %
% % type=0;             % boolean which selects A or C weighting.
% %                     % 0 chooses A-weighting.
% %                     % 1 chooses C-weighting.  
% %                     % default is type=0; % (A-weighting)
% %
% % y=randn(10000, 10)  % multichannel input time record in (Pa).  
% %                     % Processsing assumes that y has more channels 
% %                     % than time record samples.
% %                     % default is y=randn(10000, 10);
% %
% % Fs=50000;           % (Hz) sampling rate in Hz.  
% %                     % default is 50000 Hz.
% %
% % settling_time=0.1;  % (seconds) is the time it takes the filter to 
% %                     % settle (seconds).
% %                     % default is settling_time=0.1;
% %
% % resample_filter=1;  % type of filter to use when resampling
% %                     % 1 resample function Kaiser window fir filter
% %                     % 2 Bessel filter 
% %                     % otherwise resample function Kaiser window fir
% %                     % filter
% %                     % default is resample_filter=1; (Kaiser window)
% %
% %
% % ***********************************************************
% %
% % Output Variables
% %
% % yAC is the A or C-weighted time record in (Pa).
% %
% % errors indicates whether the resampled sampling rate is within the
% %          tolerance of 5000 Hz.  Within tolerance 0 is output.
% %          outside of tolerance 1 is output.
% %
% % ***********************************************************
%
%
% Example='1';
%
% type=0;           % 0 selects A-weighting
%
% y=randn(1, 50000);% (Pa) waveform
%                   % y should have the size (num_channels, num_datasample)
%
% Fs=50000;         % (Hz) Sampling rate
%
% settling_time=0.1;% (seconds) Time it takes the filter to settle.
%
% [yA]=ACweight_time_filter(type, y, Fs, settling_time);
%
% % Plot the results!
% t=1/Fs*(0:(Fs-1));
% figure(1); plot(t, y, 'k'); hold on; plot(t, yA, 'g'); legend('Linear Time Record', 'A-weighted');
%
% type=1;           % 1 selects C-weighting
% [yC]=ACweight_time_filter(type, y, Fs, settling_time);
%
% % Plot the results!
% figure(2); plot(t, y, 'k'); hold on; plot(t, yC, 'g'); legend('Linear Time Record', 'C-weighted');
%
% % **********************************************************************
% %
% % References
% %
% % IEC/CD 1672: Electroacoustics-Sound Level Meters, Nov. 1996.
% %
% % ANSI S1.4: Specifications for Sound Level Meters, 1983.
% %
% % ***********************************************************
% %
% %
% % Subprograms
% %
% % This program requires the Matlab Signal Processing Toolbox
% % This program is based on the Octave Toolbox	by Christophe Couvreur
% % Matlab Central File Exchange ID 69
% % 
% % 
% % 
% % List of Dependent Subprograms for 
% % ACweight_time_filter
% % 
% % FEX ID# is the File ID on the Matlab Central File Exchange
% % 
% % 
% % Program Name   Author   FEX ID#
% %  1) ACdsgn		Edward L. Zechmann			
% %  2) bessel_antialias		Edward L. Zechmann			
% %  3) bessel_digital		Edward L. Zechmann			
% %  4) bessel_down_sample		Edward L. Zechmann			
% %  5) convert_double		Edward L. Zechmann			
% %  6) fastlts		Peter J. Rousseeuw		NA	
% %  7) fastmcd		Peter J. Rousseeuw		NA	
% %  8) filter_settling_data3		Edward L. Zechmann			
% %  9) geospace		Edward L. Zechmann			
% % 10) get_p_q2		Edward L. Zechmann			
% % 11) match_height_and_slopes2		Edward L. Zechmann			
% % 12) moving		Aslak Grinsted		8251	
% % 13) remove_filter_settling_data		Edward L. Zechmann			
% % 14) resample_interp3		Edward L. Zechmann			
% % 15) rmean		Edward L. Zechmann			
% % 16) rms_val		Edward L. Zechmann			
% % 17) sub_mean		Edward L. Zechmann			
% % 
% % ***********************************************************
% %
% % Written by Edward L. Zechmann
% %
% %     date    June        2007
% %
% % modified 15 November    2007    Updated comments
% %
% % modified 19 December    2007    Added a resampling routine
% %                                 to improve accruacy at low and
% %                                 high frequencies
% %                                 Updated comments
% %
% % modified 15 August      2008    Modified resampling routine to use
% %                                 a butterworth filter.
% %                                 Updated comments
% %
% % modified  9 September   2008    Reverted back to resample Matlab
% %                                 Program.
% %
% % modified 18 September   2008    Updated Comments
% %
% % modified 18 September   2008    Modified resampling method
% %
% % modified  6 December    2008    Added filter settling
% %
% % modified 10 December    2008    Added get_p_q to generalize the
% %                                 selection of the p and q for setting
% %                                 the resampling rate.
% %
% %                                 Combined Aweight_time_filter and
% %                                 Cweight_time_filter.
% %
% % modified 16 December    2008    Used convolution to make filter
% %                                 coefficients (b and a) into
% %                                 arrays from cell arrays.
% %
% % modified  5 January     2008    Added sub_mean to remove running
% %                                 average using a time constant set to
% %                                 5 Hz frequency.
% %
% % modified  6 October     2009    Updated comments
% %
% % modified  8 July        2010    Updated comments.  Increased maximum
% %                                 frequency to 250000 KHz.  Modified the
% %                                 filter settling data to have better
% %                                 continuity and phase matching
% % 
% % modified  9 July        2010    Added an option to resample using a
% %                                 Bessel Filter.  Updated comments.
% % 
% % modified  4 August      2010    Updated Comments.
% % 
% % modified  4 Janaury     2012    Replace LMSloc with fastlts.  
% %                                 Updated comments
% % 
% % 
% % ***********************************************************
% %
% %
% % Please feel free to modify this code.
% %
% % See also: Octave Toolbox, resample, filter_settling_data3
% %
% %             Octave toolbox on Matlab Central File Exchange ID 69
% %             Author Christophe Couvreur, Faculte Polytechnique de Mons (Belgium)
% %             couvreur@thor.fpms.ac.beare
% %
% %

if nargin < 1 || isempty(type) || ~isnumeric(type)
    type=0;
end

if nargin < 2 || isempty(y) || ~isnumeric(y)
    y=randn(10000, 10);
end

if nargin < 3 || isempty(Fs) || ~isnumeric(Fs)
    Fs=50000;
end

if (nargin < 4 || isempty(settling_time)) || ~isnumeric(settling_time)
    settling_time=0.1;
end

if (nargin < 5 || isempty(resample_filter)) || ~isnumeric(resample_filter)
    resample_filter=1;
end

if ~isequal(resample_filter, 2)
    resample_filter=1;
end


% set the flag for indicating whether to resample
flag0=0;


% Remove the running average from the signal.
% The time constant should be less than half the lowest frequency to
% resolve.
[y]=sub_mean(y, Fs, 0);

max_freq=333333;
min_freq=40000;

% upsampling is not supported
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

[num_samples, num_channels]=size(y);


% set the flag for indicating whether to transpose
flag1=0;

% Transpose the data so that the filters act along the time records
% not along the channels.
if num_channels > num_samples
    flag1=1;
    y=y';
    [num_samples, num_channels]=size(y);
end

% Resample the data to a reasonable sampling rate to keep the A or
% C-weighting filter as stable as possible.
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

    y2=zeros(length(buf), num_channels);
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

% Design the A or C-weighting filter

[Ba, Aa, Bc, Ac] = ACdsgn(Fsn);

if isequal(type, 0)
    B=Ba;
    A=Aa;
    %[B,A] = adsgn(Fsn);
else
    B=Bc;
    A=Ac;
    %[B,A] = cdsgn(Fsn);
end


yAC=zeros(size(y2));

% Apply the A or C-weighting filter
for e1=1:num_channels;
    
    % Adding filter settling data
    num_data_pts=length(y2(:, e1));
    [y11, num_settle_pts]=filter_settling_data3(Fsn, y2(:, e1), settling_time);
    
    % Applying the Filter
    buf = real(filter(B, A, y11 ));

    % removing filter settling data
    [buf]=remove_filter_settling_data(buf, 1, num_settle_pts, num_data_pts, 2);

    num_pts=min(size(buf, 1), size(yAC, 1));
    yAC(1:num_pts, e1)=buf(1:num_pts);
end




% Resample if necessary so the output has the same size as the input
if isequal(flag0, 1)

    % Adding filter settling data
    num_data_pts=length(yAC(:, 1));
    [y11, num_settle_pts]=filter_settling_data3(Fs, yAC(:, 1), settling_time);

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
    yAACC=zeros(num_samples2, num_channels);
    yAACC(:, 1)=buf;
    clear('buf');
    if num_channels > 1
        for e1=2:num_channels;
            
            % Adding filter settling data
            num_data_pts=length(yAC(:, e1));
            [y11, num_settle_pts]=filter_settling_data3(Fs, yAC(:, e1), settling_time);

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

            % %
            yAACC(:, e1)=buf;
        end
    end
else
    yAACC=yAC;
    num_samples2=length(yAC);
end


clear('yAC');

% Append the data to the output variable
if isequal(flag0, 1)
    if num_samples2 > num_samples
        num_samples2=num_samples;
    end

    yAC=yAACC(1:num_samples2, 1:num_channels);
else
    yAC=yAACC(1:num_samples2, 1:num_channels);
end

% Output yAC must have the same size as the original input matrix y.
% Transpose yAC if necessary.
if isequal(flag1, 1)
    yAC=yAC';
end

