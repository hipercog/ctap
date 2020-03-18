function [fc_out, SP_levels, SP_peak_levels, SP_bands]=Nth_oct_time_filter2(SP, Fs, num_x_filter, N, fc, sensor, settling_time, filter_program, resample_filter)
% % Nth_oct_time_filter2: Calculates the Nth octave center frequencies, sound levels, peak levels, and time records
% %
% % Syntax:
% %
% % [fc_out, SP_levels, SP_peak_levels, SP_bands]=Nth_oct_time_filter2(SP, Fs, num_x_filter, N, fc, sensor, settling_time, filter_program, resample_filter);
% %
% % **********************************************************************
% %
% % Description
% %
% % This program applies Nth octave band filters to the input time record.
% % The program outputs the center frequency bands, the time average rms
% % values, the peak values, and band filtered time records for each
% % Nth octave band respectively.
% %
% % Nth_octdsgn computes the filter coefficients using a 3rd order
% % butterworth filter for an Nth octave band filter according to
% % ANSI S1.11.  
% % 
% % To optimize filter stability, this program uses iterative downsampling
% % to make the sampling rate reasonable before applying the third octave
% % Butterworth filters.  
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
% % To avoid phase shift, the filtfilt Matlab program can
% % be used to implement the one-Nth octave filters.
% % 
% % 
% % The input and output variables are described in more detail in the
% % sections below respectively.
% %
% % **********************************************************************
% %
% % Input Variables
% %
% % SP=randn(10, 50000);
% %                     % (Pa) is the time record of the sound pressure
% %                     % default is SP=rand(1, 50000);
% %
% % Fs=50000;           % (Hz) is the sampling rate of the time record.
% %                     % default is Fs=50000; Hz.
% %
% % num_x_filter=2;     % This is the number of times the time record
% %                     % should be filtered.
% %                     % default is num_x_filter=2;
% %
% % N=3;                % is the number of frequency bands per octave.
% %                     % Can be any number > 0.
% %                     % Default is 3 for third octave bands.
% %
% % fc=[200, 250];      % (Hz) is an array of center frequencies for the third
% %                     % octave band filters
% %                     %
% %                     % if empty the third octave bands from 20 to 20000 Hz
% %                     % are used
% %                     %
% %                     % default is fc = [  20,  25, 31.5, 40,  50,  63,  ...
% %                     %  80,  100, 125,  160, 200, 250, 315, 400, 500, ...
% %                     %  630, 800, 1000, 1250, 1600, 2000, 2500, 3150, ...
% %                     %  4000, 5000, 6300, 8000, 10000, ...
% %                     %  12500, 16000, 20000];
% %
% % sensor=1;           % Constant integer input for selecting the sensor type
% %                     % 1 is for acoustic microphone Pref=20E-6 (Pa)
% %                     %
% %                     % 2 is for accelerometer output is in same
% %                     %   units as the input (m/s^2)
% %                     %
% %                     % 3 generic sensor multiply by 1: output is in same
% %                     %   units as the input
% %                     %
% %                     % default is sensor=1; For a microphone
% %
% % settling_time=0.1;  % (seconds) Time requiered for the filter to settle
% %                     % usually 0.1 seconds or less.
% %                     % This quantity is usually frequency dependent.
% %
% % filter_program=1;   % 1 is for using the filter progam otherwise the
% %                     % filtfilt program is used.
% %                     % filter.m runs faster and may settle
% %                     % more quickly.
% %                     % filtfilt.m is used to remove phase shift.
% %                     % default is filter_program=1 using filter progam.
% %
% % resample_filter=1;  % type of filter to use when resampling
% %                     % 1 resample function Kaiser window fir filter
% %                     % 2 Bessel filter
% %                     % otherwise resample function Kaiser window fir
% %                     % filter
% %                     % default is resample_filter=1; (Kaiser window)
% %
% %
% % **********************************************************************
% %
% % Output Variables
% %
% % fc_out          % (Hz) array of center frequencies
% %
% % SP_levels       % (units) sound pressure or other sensor metric for
% %                 % each channel and each frequency band
% %
% % SP_peak_levels  % (units) Maximum of the absolute value of the peak
% %                 % values for each frequency band
% %
% % SP_bands        % Time record for each mic channel and for each
% %                 % frequency band after filtering
% %
% %
% % **********************************************************************
% %
%
% Example='1';
%
% SP=randn(50000, 1);   % SP is the data variables in linear units such as
%                       % (Pa)
%
% Fs=50000;             % (Hz) Sampling rate
%
% num_x_filter=2;       % Number of times to filter the data.  Minimum
%                       % value is 1.  Typically a value of 2 to 10 at low
%                       % frequencies (Fc < 100), num_x_filter=10 has a
%                       % significant phase shift.
%
% N=3;                  % Number of bands per octave.
%
% fc=[];                % (Hz) Center frequency of the third-octave band
%
% sensor=1;             % acoustic microphone
%                       % output is in dB
%
% settling_time=1;      % (seconds) Time requiered for the filter to settle
%                       % usually 0.1 seconds or less.
%                       % This quantity is usually frequency dependent.
%
% filter_program=1;     % 1 is for using the filter progam otherwise the
%                       % filtfilt program is used.
%                       % default is filter_program=1 using filter progam.
% 
% resample_filter=1;
% 
% [fc_out, SP_levels, SP_peak_levels, SP_bands]=Nth_oct_time_filter2(SP, Fs, num_x_filter, N, fc, sensor, settling_time, filter_program, resample_filter);
%
% %
%
% Example='2';
%
% % Compare the spectra of white noise, pink noise, and brown noise.
% %
%
% x1 = spatialPattern([1,500000],0);    % white noise has a linearly
%                                       % increasing spectrum
%
% x2 = spatialPattern([1,500000],-1);   % pink noise has a constant
%                                       % spectrum
%
% x3 = spatialPattern([1,500000],-2);   % brown noise has a linearly
%                                       % increasing spectra
%
% Fs=50000;         % (Hz) Sampling rate
%
% num_x_filter=2;   % Number of times to filter the data.  
%
% N=3;              % number of bands per octave.
%
% min_f=20;         % is the minimum frequency band to calculate (Hz).
% max_f=20000;      % is the maximum frequency band to calculate (Hz).
%
% [fc] = nth_freq_band(N, min_f, max_f);
%
% sensor=1;         
%
% settling_time=1;  
%
% filter_program=1; 
%
% resample_filter=1;
%
% [fc_out1, SP_levels1]=Nth_oct_time_filter(x1, Fs, num_x_filter, N, min_f, max_f, sensor, settling_time, filter_program, resample_filter);
% [fc_out2, SP_levels2]=Nth_oct_time_filter(x2, Fs, num_x_filter, N, min_f, max_f, sensor, settling_time, filter_program, resample_filter);
% [fc_out3, SP_levels3]=Nth_oct_time_filter(x3, Fs, num_x_filter, N, min_f, max_f, sensor, settling_time, filter_program, resample_filter);
%
% % Plot the results
% figure(1);
% semilogx(fc_out1, SP_levels1, 'color', [1 1 1],         'linewidth', 2,                    'marker', 's', 'MarkerSize', 8);
% hold on;
% semilogx(fc_out2, SP_levels2, 'color', [1 0.6 0.784],   'linewidth', 2, 'linestyle', '--', 'marker', 'o', 'MarkerSize', 8);
% semilogx(fc_out3, SP_levels3, 'color', [0.682 0.467 0], 'linewidth', 2, 'linestyle', ':',  'marker', 'x', 'MarkerSize', 12);
% set(gca, 'color', 0.7*[1 1 1]);
% legend({'White Noise', 'Pink Noise', 'Brown Noise'}, 'location', 'SouthEast');
% xlabel('Frequency Hz', 'Fontsize', 28);
% ylabel('Sound Pressure Level (dB ref. 20 \mu Pa)', 'Fontsize', 28);
% title('Classical Third Octave Band Spectra', 'Fontsize', 40);
% set(gca, 'Fontsize', 20);
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
% % Subprograms
% %
% % This program requires the Matlab Signal Processing Toolbox
% % This program is based on the Octave Toolbox	by Christophe Couvreur
% % Matlab Central File Exchange ID 69
% %
% %
% % 
% % List of Dependent Subprograms for 
% % Nth_oct_time_filter2
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
% %  7) LMSloc		Alexandros Leontitsis		801	
% %  8) match_height_and_slopes2		Edward L. Zechmann			
% %  9) moving		Aslak Grinsted		8251	
% % 10) Nth_octdsgn		Edward L. Zechmann			
% % 11) remove_filter_settling_data		Edward L. Zechmann			
% % 12) resample_interp3		Edward L. Zechmann			
% % 13) rms_val		Edward L. Zechmann			
% % 14) sub_mean		Edward L. Zechmann				
% %
% %
% %
% % **********************************************************************
% %
% % Program was written by Edward L. Zechmann
% %
% %     date  7 December    2008    Copied content of Nth_oct_time_filter
% %                                 and modified code to use fc as an input
% %                                 variable.
% %
% % modified  8 December    2008    Updated Comments
% %
% % modified 10 December    2008    Updated Comments
% %
% % modified 16 December    2008    Generlaized program to Nth Octave Bands
% %
% % modified 22 December    2008    Updated Comments.  Finished Upgrade
% %
% % modified  5 January     2008    Added sub_mean to remove running
% %                                 average using a time constant at one-
% %                                 half the lowest center frequency.
% %
% % modified 26 March       2009    Fixed a bug in initilizing SPtrunc2
% %                                 Fixed a bug in initializing num_pts2
% %
% % modified  6 October     2009    Updated comments
% %
% % modified 31 December    2009    Added warnings for frequency
% %                                 resolution issues.
% %
% % modified 2 July         2010    Modified filter settling data program
% %                                 Updated the filter settling data
% %                                 removal.  Updated Comments
% %
% % modified 4 August       2010    Updated Comments
% %
% % modified 9 January      2012    Type cast the ouput Bc and Ac of 
% %                                 Nth_octdsg to double precision.  
% %
% % modified 15 March       2012    Changed the range_size to 8 and the 
% %                                 downsample_factor to 20 to improve 
% %                                 accuaracy of low frueqnecies when 
% %                                 processing short time records.   
% %
% %
% % **********************************************************************
% %
% % Please feel free to modify this code.
% %
% % See Also: Nth_oct_time_filter, octave, resample, filter, filtfilt
% %
% % See also: Octave Toolbox, resample, filter_settling_data3
% %
% %             Octave toolbox on Matlab Central File Exchange ID 69
% %             Author Christophe Couvreur, Faculte Polytechnique de Mons (Belgium)
% %             couvreur@thor.fpms.ac.beare
% %

if (nargin < 1 || isempty(SP)) || ~isnumeric(SP)
    SP=rand(1, 50000);
end

% Make the data have the correct data type and size
[SP]=convert_double(SP);

[num_pts, num_mics]=size(SP);

if num_mics > num_pts
    SP=SP';
    [num_pts, num_mics]=size(SP);
end

SP=convert_double(SP);

if (nargin < 2 || isempty(Fs)) || ~isnumeric(Fs)
    Fs=50000;
end

if (nargin < 3 || isempty(num_x_filter)) || ~isnumeric(num_x_filter)
    num_x_filter=2;
end

if (nargin < 4 || (isempty(N)) || ~isnumeric(N))
    N=20;
end

if (nargin < 5 || isempty(fc)) || ~isnumeric(fc)
    fc = [  20,  25, 31.5, 40,  50,  63,  80,  100,  125,  160, ...
        200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600, ...
        2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000, ...
        12500, 16000, 20000];
end

if (nargin < 6 || isempty(sensor)) || ~isnumeric(sensor)
    sensor=1;
end

if (nargin < 7 || isempty(settling_time)) || ~isnumeric(settling_time)
    settling_time=0.1;
end

if (nargin < 8 || (isempty(filter_program)) || ~isnumeric(filter_program))
    filter_program=1;
end

if (nargin < 9 || isempty(resample_filter)) || ~isnumeric(resample_filter)
    resample_filter=1;
end

if ~isequal(resample_filter, 2)
    resample_filter=1;
end


% Remove the running average from the signal.
% The time constant should be less than half the lowest frequency to
% resolve.
[SP]=sub_mean(SP, Fs, 0);

[num_pts, num_mics]=size(SP);

if num_mics > num_pts
    SP=SP';
    [num_pts, num_mics]=size(SP);
end

% By hard coding, a 3rd order butterworth filter is used.
n=3;

% Make sure center frequencies are positive.
fc=fc(fc > 0);

% sort the center frequencies to categorize the center frequncies into
% ranges for resampling.
[fc ix]=sort(fc);
fc_out=fc;

% count the frequency bands
num_bands=length(fc);

% srr is the sampling rate ratio
srr=Fs./fc;

% initialize the regime to ones.
regime=zeros(num_bands, 1);

% Using a small range size keeps
% increases the likelihood that the filters will be stable.
% In testing, using range_size=2, 4, or 8 resulted in nearly identical
% sound pressure levels; however, range_size=2 is more likely to result in
% a stable filter.
% 
% Further testing shows that the resampling techniques employed in this 
% program do not work well with short time records. 
% 
% So a range_size of 8 works better with short time records.  
% 

upsample_factor=5;

if isequal(resample_filter, 1)
    % resample function works great at small and large range sizes.
    range_size=8;
    downsample_factor=20;
else
    % Bessel filters have too much attenuation at high frequencies so use a
    % larger range size; however, the filters may be less stable.
    range_size=8;
    downsample_factor=20;
end


%
% For range_size=2; and downsample_factor=5; the regime follows the pattern
%
%   srr range        Ouput type        rf value   regime number
%        srr <=     2  output zeros                       1
%    2 < srr <=     5  upsample          rf=4             2
%    5 < srr <=    10  do nothing        rf=1             3
%   10 < srr <=    20  downsample        rf=1/2           4
%   20 < srr <=    40  downsample        rf=1/4           5
%   40 < srr <=    80  downsample        rf=1/8           6
%                      ...
%                      ...  iterative downsampling until the frequency
%                      ...  resolution limit is exceeded
%                      ...
%  fc <= 4/T           output zeros                       0

%
% For range_size=4; and downsample_factor=5; the regime follows the pattern
%
%   srr range        Ouput type        rf value   regime number
%        srr <=     2  output zeros                       1
%    2 < srr <=     5  upsample          rf=4             2
%    5 < srr <=    20  do nothing        rf=1             3
%   20 < srr <=    80  downsample        rf=1/4           4
%   80 < srr <=   320  downsample        rf=1/16          5
%  320 < srr <=  1280  downsample        rf=1/64          6
%                      ...
%                      ...  iterative downsampling until the frequency
%                      ...  resolution limit is exceeded
%                      ...
%  fc <= 4/T           output zeros                       0


%
% For range_size=8; and downsample_factor=5; the regime follows the pattern
%
%    srr range         Ouput type        rf value    regime number
%        srr <=     2  output zeros                       1
%    2 < srr <=     5  upsample          rf=4             2
%    5 < srr <=    40  do nothing        rf=1             3
%   40 < srr <=   320  downsample        rf=1/8           4
%  320 < srr <=  2560  downsample        rf=1/64          5
% 2560 < srr <= 20480  downsample        rf=1/512         6
%                      ...
%                      ...  iterative downsampling until the frequency
%                      ...  resolution limit is exceeded
%                      ...
%  fc <= 4/T         output zeros                      0


% Determine the regime for each frequency band
%
for e1=1:num_bands;

    if srr(e1) <= 2
        % Output Zeros since Center Frequency exceeds the Nyquist Frequency
        regime(e1)=1;
        warning(['Center frequency above Nyquist frequency: Outputting zeros for fc = ' num2str(fc(e1)), ' Hz.']);
    elseif  fc(e1) <= 4*Fs/(num_pts)
        % Output Zeros since Center Frequency is below the lower
        % frequency resolution limit
        regime(e1)=0;
        warning(['Length of data too short to resolve center frequency: Outputting zeros for fc = ', num2str(fc(e1)), ' Hz.']);
    elseif (2 < srr(e1)) && logical(srr(e1) <= upsample_factor)
        % The signal is upsampled
        regime(e1)=2;
    elseif logical(srr(e1) > downsample_factor)
        % The signal is downsampled
        regime(e1)=ceil(log(srr(e1)/downsample_factor)./log(range_size))+2;
    else
        regime(e1)=3;
    end

end



% set the reference sensor value
switch sensor

    case 1
        % reference sound pressure
        Pref=20*10^(-6); % Pa

    case 2
        % reference acceleration
        Pref=1; % m/s^2

    case 3
        Pref=1;

    otherwise
        Pref=1;
end


% Initialize the output variables to reasonable values
SP_levels=0;
SP_bands=0;
SP_peak_levels=0;
cregime=0;

% Initialize the previous channel index
pe1=0;

max_num_settling_pts=500000;

% Calculate the sound pressure levels, peak levels, and band time records
if logical(num_mics > 0) && ((logical(num_bands > 0) && logical(num_pts > 0)))


    SP_levels=zeros(num_mics, num_bands);
    SP_peak_levels=zeros(num_mics, num_bands);

    % The time record in each band is only initialized if
    % it is output.  This saves memory and reduces processing time.
    if nargout > 2
        SP_bands=zeros(num_mics, num_bands, num_pts);
    end



    for e1=1:num_mics;

        for e2=num_bands:(-1):1;

            % Set the third octave center frequency
            fc2=fc(e2);

            % initialize the flag which determines whether to output zeros
            flag2=0;

            % Determine whether to output zeros.
            % Initialize the data variable SP_trunc2.
            if isequal(regime(e2), 0) || isequal(regime(e2), 1)
                flag2=1;
            else
                if  ~isequal(e1, pe1) || logical(cregime > regime(e2)) || ~isequal(exist('SP_trunc2', 'var'), 1)
                    SP_trunc2=SP(:, e1);
                else
                    if cregime < 3 && regime(e2) >=3
                        SP_trunc2=SP(:, e1);
                    end
                end

            end

            settling_time2=max(settling_time, 10/fc2);

            if settling_time2*Fs > max_num_settling_pts
                settling_time2=max_num_settling_pts/Fs;
            end


            if isequal(flag2, 0)

                
                Fs2=Fs;

                % Resample the time record if necessary
                if regime(e2) > 1

                    if isequal(regime(e2), 2)

                        % set the resample rate
                        %upsample_factor=downsample_factor;
                        Fs2=Fs*upsample_factor;

                        
                        % upsample if necessary
                        if ~isequal(cregime, regime(e2)) || ~isequal(e1, pe1)

                            % Adding filter settling data
                            num_data_pts=length(SP_trunc2);
                            [y2, num_pts_se]=filter_settling_data3(Fs, SP_trunc2, settling_time2);

                            if isequal(resample_filter, 1)
                                SP_trunc2=resample(y2, upsample_factor, 1);
                            else   
                                [SP_trunc2]=resample_interp3(y2, -1+(1:length(y2)), 1/upsample_factor);
                            end
                            
                            % Remove the settling data from the time
                            % record.
                            [SP_trunc2]=remove_filter_settling_data(SP_trunc2, upsample_factor, num_pts_se, num_data_pts, 1);
                        end

                    elseif regime(e2) > 3

                        Fs2=Fs/(range_size^(regime(e2)-3));

                        % Down Sample if necessary
                        if ~isequal(cregime, regime(e2)) || ~isequal(e1, pe1)

                            % determine the amount of down sampling
                            if cregime >= 3 && logical(regime(e2) > cregime)
                                num_iter=regime(e2)-cregime;
                            else
                                num_iter=regime(e2)-3;
                            end

                            
                            for e3=1:num_iter;

                                % Calculate the sampling rate for selecting
                                % the filter settling data
                                Fs22=Fs/(range_size^(regime(e2)-3+e3-num_iter-1));

                                % Adding filter settling data
                                num_data_pts=length(SP_trunc2);
                                [y2, num_pts_se]=filter_settling_data3(Fs22, SP_trunc2, settling_time2);

                                % Downsample the time record with the
                                % preappended and postappended settling data.
                                if isequal(resample_filter, 1)
                                    SP_trunc2=resample(y2, 1, range_size);
                                else
                                    [SP_trunc2]=bessel_down_sample(y2, Fs22*range_size, Fs22, settling_time2);
                                end
                                
                                % Remove the settling data from the time
                                % record.
                                [SP_trunc2]=remove_filter_settling_data(SP_trunc2, range_size, num_pts_se, num_data_pts, 0);

                            end

                        end

                    end

                end

                % transfer the time record to a buffer variable
                SP_trunc22=SP_trunc2;
                
                % Calculate the 1/3 octave band filter coefficients
                [Bc, Ac]=Nth_octdsgn(Fs2, fc2, N, n);


                % Determine the size of data needed to keep the filter from failing
                flag3=0;
                [data_pts, num_chans]=size(SP_trunc22);
                filtorder=max([size(Bc, 2), size(Ac, 2)]);

                % If there is too little data then the filter will fail
                % replicate the time record several times so that there is
                % enough data to keep the filter from failing.
                if data_pts < 5*filtorder
                    flag3=1;
                    num_reps=ceil(5*filtorder/data_pts);
                    SP_trunc22 = repmat(SP_trunc22, 1, num_reps);
                end


                % Calculate, Preappend and postappend the filter settling data.
                num_data_pts=length(SP_trunc22);
                [SP_trunc22, num_pts_se]=filter_settling_data3(Fs2, SP_trunc22, settling_time2);


                % Apply the 1/3 octave bandpass filter to the data.
                for e3=1:num_x_filter;

                    if isequal(filter_program, 1)
                        SP_trunc22 = filter(Bc, Ac, SP_trunc22);
                    else
                        SP_trunc22 = filtfilt(Bc, Ac, SP_trunc22);
                    end

                end


                % Remove the settling data from the time
                % record.
                [SP_trunc22]=remove_filter_settling_data(SP_trunc22, 1, num_pts_se, num_data_pts, 2);



                % Remove any replicated data used to keep the filter from
                % failing.
                if flag3 == 1
                    SP_trunc22=SP_trunc22(1:data_pts, 1:num_chans);
                end


                % Only concatenate the 1/nth octave band time records
                % if the output variable exists.
                if nargout > 2

                    % resample the output time record to the original
                    % sampling rate

                    if regime(e2) == 2
                        % Adding filter settling data
                        num_data_pts=length(SP_trunc22);
                        [y2, num_pts_se]=filter_settling_data3(Fs*upsample_factor, SP_trunc22, settling_time2);

                        % Downsample the time record to reduce the sampling
                        % rate.
                        if isequal(resample_filter, 1)
                            SP_trunc22=resample(y2, 1, upsample_factor);
                        else
                            [SP_trunc22]=resample_interp3(y2, -1+(1:length(y2)), upsample_factor);
                        end

                        % Remove the settling data from the time
                        % record.
                        [SP_trunc22]=remove_filter_settling_data(SP_trunc22, upsample_factor, num_pts_se, num_data_pts, 0);

                    elseif regime(e2) > 3

                        % Calculate the down sampling factor applied to
                        % the data.  This will be used to upsample the data
                        % to the original samling rate.  
                        %
                        % This downsampling factor is called the reduction 
                        % factor.
                        reduction_factor=(range_size^(regime(e2)-3));

                        % Adding filter settling data
                        num_data_pts=length(SP_trunc22);
                        [y2, num_pts_se]=filter_settling_data3(Fs/reduction_factor, SP_trunc22, settling_time2);

                        % Upsample the time record to the original
                        % sampling rate.
                        if isequal(resample_filter, 1)
                            SP_trunc22=resample(y2, reduction_factor, 1);
                        else
                            [SP_trunc22]=resample_interp3(y2, -1+(1:length(y2)), 1/reduction_factor);
                        end
                        
                        % Remove the settling data from the time
                        % record.
                        [SP_trunc22]=remove_filter_settling_data(SP_trunc22, reduction_factor, num_pts_se, num_data_pts, 1);

                    end

                    % Append the time record for the microphone channel
                    % to the output band.
                    num_pts2=min([length(SP_trunc22) num_pts]);

                    for e3=1:num_pts2;
                        SP_bands(e1, ix(e2), e3)=SP_trunc22(e3);
                    end

                end


                % Calculate the levels and peak levels.
                switch sensor

                    case 1
                        SP_levels(e1, ix(e2))=10*log10((norm(SP_trunc22)./sqrt(length(SP_trunc22))./Pref).^2);
                        SP_peak_levels(e1, ix(e2))=20*log10(max(abs(SP_trunc22))./Pref);
                    case 2
                        SP_levels(e1, ix(e2))=norm(SP_trunc22)./sqrt(length(SP_trunc22));
                        SP_peak_levels(e1, ix(e2))=max(abs(SP_trunc22));
                    case 3
                        SP_levels(e1, ix(e2))=norm(SP_trunc22)./sqrt(length(SP_trunc22));
                        SP_peak_levels(e1, ix(e2))=max(abs(SP_trunc22));
                    otherwise
                        SP_levels(e1, ix(e2))=norm(SP_trunc22)./sqrt(length(SP_trunc22));
                        SP_peak_levels(e1, ix(e2))=max(abs(SP_trunc22));
                end

            else

                %
                % If the center frequency is greater than the
                % Nyquist freuqency or less than the minimum frequency
                % limit then output a zero time record and indicate
                % that the levels and peak levels are null.
                %

                if isequal(exist('SP_trunc22', 'var'), 1)
                    num_pts2=min([length(SP_trunc22) num_pts]);
                else
                    num_pts2=num_pts;
                end


                if nargout > 3

                    for e3=1:num_pts2;
                        SP_bands(e1, ix(e2), e3)=0;
                    end

                end

                switch sensor

                    case 1
                        SP_levels(e1, ix(e2))=-10^15;
                        SP_peak_levels(e1, ix(e2))=-10^15;
                    case 2
                        SP_levels(e1, ix(e2))=0;
                        SP_peak_levels(e1, ix(e2))=0;
                    case 3
                        SP_levels(e1, ix(e2))=0;
                        SP_peak_levels(e1, ix(e2))=0;
                    otherwise
                        SP_levels(e1, ix(e2))=0;
                        SP_peak_levels(e1, ix(e2))=0;
                end
            end


            % Set the previous hcannel index.
            pe1=e1;

            % Set the previous regime number.
            cregime=regime(e2);

        end
    end
end



