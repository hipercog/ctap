function [yhw, filtercoeffs, filter_types, scaling_factors, errors]=whole_body_time_filter(y, Fs, type, k, filtercoeffs, filter_types, scaling_factors, axis_desig, settling_time, resample_filter)
% % whole_body_time_filter: Calculates the whole body vibrations filter coefficients and returns the filtered time record
% % 
% % Syntax;
% % 
% % [yhw, filtercoeffs, filter_types, scaling_factors]=whole_body_time_filter(y, Fs, type, k, filtercoeffs, filter_types, scaling_factors, axis_desig, settling_time, resample_filter);
% % 
% % ********************************************************************
% % 
% % Description
% % 
% % [yhw]=whole_body_time_filter(y, Fs, type, k, filtercoeffs, filter_types, scaling_factors, axis_desig, settling_time, resample_filter);
% % 
% % Returns a time record which has been filtered by the 
% % specified whole body filters, given the original time record y, 
% % sampling rate Fs, specified postures type, recording positions k, 
% % filter coefficients, filter types, scaling factors [kx, ky, kz], 
% % axis designations, and the filter settling time.  
% % 
% % The number of axes is limited to three because the filter 
% % coefficients are dependent on the axes.  If only one axis is specified 
% % it is assuemd to be teh z-zxis.   if there are two axis then they are 
% % assumed to be x and y axies resectively.   In general, a triaxial 
% % accelerometer is required for the complete filter set.   
% % 
% % Additionally, output arguments 2 through 4 return the filter 
% % coefficients, filter types, and scaling factors for the 
% % posture types specified in ISO 2631-1-1997.  Refer to the standard 
% % for definitions of filters and information on whole-body vibrations.  
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
% % In general, it is necessary to specify all of the inputs to get the
% % required output.  The input and output variables are described in
% % detail below.  
% % 
% % ********************************************************************
% %
% % Input Variables
% % 
% % y=randn(5000, 1);   % is the waveform.  It should have units of (m/s^2).  The size of y 
% %                     % should be [num_axes num_samples].  
% %                     % 
% %                     % The program automatically transposes y if The first dimension has 
% %                     % more elements than the second dimension.  y can have 1, 2, or 3 
% %                     % axes.  
% %                     % 
% %                     % The number of axes is limited to three because the filter 
% %                     % coefficients are dependent on the axes.  
% %                     % In general, a triaxial accelerometer is 
% %                     % required for the complete filter set.   
% %                     % 
% %                     % default is y=randn(5000, 1);
% % 
% % Fs=5000;            % (Hz) is the sampling rate Hz.
% %                     % default is Fs=5000;
% % 
% % 
% % type=1;             % specifies the posture of the whole body vibration exposure.
% %                     % type=1;    Standing
% %                     % type=2;    Seated (Health)
% %                     % type=3;    Seated (Comfort)
% %                     % type=4;    Laying on back (recumbent) k=1 Pelvis, k=2 Head
% %                     % type=5;    Rotational on supporting seat
% %                     % type=6;    Rotational on seated backrest
% %                     % type=7;    Rotational on feet
% %                     % type=8;    Motion sickness
% %                     % 
% %                     % default is type=1; 
% % 
% % k=1;                % ISO 2631 uses the variable k for multiple purposes 
% %                     % especially for the scaling factors. To avoid overloading 
% %                     % the definition of the variable k, in these programs, 
% %                     % the variable k is only used for posture type 4, 
% %                     % more specifically the recumbent posture z-axis recording position.
% %                     % 
% %                     % k specifies the pelvis or head if the recumbent posture was used.
% %                     % k is 1 for Pelvis vibration recordings 
% %                     % k is 2 for Head vibration recordings
% %                     % 
% %                     % default is k=1;
% % 
% % filtercoeffs        % are filter coefficients for the whole body vibrations
% %                     % data.  Each whole body vibration posture has one or more filters 
% %                     % each constisting of 4 transfer functions.  So the filtercoeffs is 
% %                     % a cell array of arrays of filter coefficients.  
% %                     % 
% %                     % default value come from running the code below
% %                     % [filtercoeffs, filter_types, scaling_factors]=whole_body_filter(Fs, type, k);
% % 
% % 
% % filter_types        % specify the filter definitions from ISO 2631-1-1997.
% %                     % There are six different filter definitions. 
% %                     % 
% %                     % default value come from running the code below
% %                     % [filtercoeffs, filter_types, scaling_factors]=whole_body_filter(Fs, type, k);
% % 
% % 
% % scaling_factors     % specify the scaling factors for each axis 
% %                     % according to ISO 2631-1-1997.  Typically the scalling factors are
% %                     % 1, 1.4, or 1.7.  In ISO 2631 the scaling factors are designated by
% %                     % the letter k for all axes.  To remove overloaded definitions, the
% %                     % variables kx, ky, and kz denote the scaling factors along the 
% %                     % X, Y, and Z axes respectively.  
% %                     % 
% %                     % default value come from running the code below
% %                     % [filtercoeffs, filter_types, scaling_factors]=whole_body_filter(Fs, type, k);
% % 
% % 
% % axis_desig=3;       % specifies the order of the axes contained in the waveform y
% %                     % Typically, axis_desig=[1 2 3] for typical setup 1 => x, 2 => y, 
% %                     % 3 => z.
% %                     %  
% %                     % If axis_desig is not fully disclosed then the program assumes 
% %                     % that the last axis is z and if there are two or more axes that  
% %                     % the first axis is x and if there are three axes that the second 
% %                     % axis is y.
% %                     %  
% %                     % default is axis_desig=3;
% % 
% %
% % settling_time=0.1;  % (seconds) Time requiered for the filter to settle
% %                     % default is dependent on the posture type.  
% %                     % 
% %                     % For type=7; Motion Sickness 
% %                     % default is settling_time=100; (seconds)
% %                     % 
% %                     % For all other types; 
% %                     % default is settling_time=20;  
% %                     % 
% %                     % The optimum settling_time is frequency dependent.
% %
% % resample_filter=1;  % type of filter to use when resampling
% %                     % 1 resample function Kaiser window fir filter
% %                     % 2 Bessel filter
% %                     % otherwise resample function Kaiser window fir
% %                     % filter
% %                     % default is resample_filter=1; (Kaiser window)
% %
% % 
% % ********************************************************************
% %
% % Output Variables
% %
% % yhw is the time record which has been filtered by the whole body
% %      vibration frequency filter.  
% %
% % filtercoeffs is a cell array of matrices of filter coefficients. 
% %      Each filter has four transfer functions and the filter 
% %      coefficients are stored in this cell array.  
% % 
% % filter_types is a row vector which specifies the filters used 
% %      for a posture type.  There are six filter types and seven posture 
% %      types.
% % 
% % scaling_factors are constants that are applied to the filters.  
% %       The scale factors are groupped into a 1x3 array or a 2x3 array.  
% %       The scale factors are applied to the axes of differnent filter 
% %       types.   
% %
% % errors indicates whether the resampled sampling rate is within the 
% %       tolerance of 5000 Hz.  Within tolerance 0 is output.  
% %       outside of tolerance 1 is output.   
% % 
% % ********************************************************************
% 
% Example='1';
% % Standing Posture 
% 
% y=randn(1, 10000); Fs=5000; type=1; k=1;
% [yhw, filtercoeffs, filter_types, scaling_factors]=whole_body_time_filter(y, Fs, type, k);
% 
% 
% Example='2';
% % Motion Sickness Posture 
% 
% Fs=100;  type=8;  k=1; axis_desig=1; settling_time=100;
% [filtercoeffs, filter_types, scaling_factors]=whole_body_filter(Fs, type,  k);
% [yhw, filtercoeffs, filter_types, scaling_factors]=whole_body_time_filter(y, Fs, type, k, filtercoeffs, filter_types, scaling_factors, axis_desig);
% 
% 
% % ********************************************************************
% % 
% % References For whole Body Vibrations
% % 
% % ISO 2631-1 1997  Mechanical vibration and shock-Evaluation of human
% %                  exposure to whole-body vibration-Part 1:
% %                  General Requirements
% % 
% % ********************************************************************
% % 
% % 
% % List of Dependent Subprograms for 
% % whole_body_time_filter
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
% %  8) LMSloc		Alexandros Leontitsis		801	
% %  9) match_height_and_slopes2		Edward L. Zechmann			
% % 10) remove_filter_settling_data		Edward L. Zechmann			
% % 11) resample_interp3		Edward L. Zechmann			
% % 12) rms_val		Edward L. Zechmann			
% % 13) sub_mean2		Edward L. Zechmann			
% % 14) whole_body_filter		Edward L. Zechmann						
% % 
% % 
% % ********************************************************************
% % 
% % Program Modified by Edward L. Zechmann
% % 
% %     date    June        2007
% % 
% % modified  3 September   2008    Updated Comments
% % 
% % modified  8 September   2008    Updated Comments
% % 
% % modified  9 September   2008    Updated Comments
% % 
% % modified 16 December    2008    Updated comments
% %                                 Added filter settling and resampling.  
% %                                 to optimize filter stability and
% %                                 minimize computation time. 
% % 
% % modified  5 January     2009    Added sub_mean to remove running
% %                                 average using a a number of averages 
% %                                 per second at one-half the lowest 
% %                                 frequency band of interest 0.02 Hz 
% %                                 for motion sickness and 0.1 Hz for 
% %                                 other whole body filters.
% %                                 
% % modified 21 January     2009    Split the seated posture into two cases 
% %                                 Seated (Health) and Seated (Comfort). 
% %
% % modified  9 October     2009    Updated Comments
% %
% % modified 10 July        2010    Added an option to resample using a
% %                                 Bessel Filter.  Updated the filter 
% %                                 settling data program.  
% %                                 Updated comments.
% % 
% % modified  4 August      2010    Updated Comments.
% %                             
% % modified 17 January     2011    Fixed a bug in the splitting the seated
% %                                 posture into two cases.  The scaling 
% %                                 factors for the two cases were switched.
% % 
% % modified 17 January     2011    Updated Comments.
% % 
% %   
% %   
% % ********************************************************************
% %
% % Please Feel Free to Modify This Program
% %
% % See Also: combine_accel_directions_wb, config_wb_accels, Vibs_calc_whole_body
% %

if (nargin < 1 || isempty(y)) || ~isnumeric(y)
    y=randn(5000, 1);
end

if (nargin < 2 || isempty(Fs)) || ~isnumeric(Fs)
    Fs=5000;
end

if (nargin < 3 || isempty(type)) || ~isnumeric(type)
    type=1;
end

if (nargin < 4 || isempty(type)) || ~isnumeric(type)
    k=1;
end

if (nargin < 7) || length(filtercoeffs) < 1 ||  length(filter_types) < 1 || length(scaling_factors) < 1 
    [filtercoeffs, filter_types, scaling_factors]=whole_body_filter(Fs, type, k);
end

if nargin < 8
    axis_desig=3;
end

% Whole body vibrations require very long settling times compared to 
% hand-arm vibrations and sound because the important frequencies are 
% one to three orders of magnitude lower.  
if (nargin < 9 || isempty(settling_time)) || ~isnumeric(settling_time)
    
    if isequal(type, 8)
        settling_time=100;
    else
        settling_time=20;
    end
    
end


if (nargin < 10 || isempty(resample_filter)) || ~isnumeric(resample_filter)
    resample_filter=1;
end

if ~isequal(resample_filter, 2)
    resample_filter=1;
end

% Remove the running average from the signal.
% The time constant should be less than one-tenth the lowest frequency to
% resolve.  For whole-body vibrations, the lowest frequency to resolve
% according to ISO 2631-1 is 0.02 Hz for motion sickness and 0.1 Hz 
% for other whole body filters.  

if isequal(type, 8)
    min_f=0.02;
else
    min_f=0.1;
end

[y]=sub_mean2(y, Fs, 0);


% set the flag for indicating whether to transpose
flag1=0;

% Transpose the data so that the filters act along the time records 
% not along the channels.   
[num_samples, num_axes]=size(y);

if num_axes > num_samples
    flag1=1;
    y=y';
    [num_samples, num_axes]=size(y);
end

if num_axes > 3
    num_axes=3;
end

% assume the prefered axes convention
% 1 axis z
% 2 axes x, z
% 3 axes x, y, z



if num_axes > length(axis_desig)
    
    if num_axes == 1
        
        axis_desig=3;
        
    elseif num_axes == 2
        
        if length(axis_desig) == 1
            axis_desig=[axis_desig 3];
        else
            axis_desig=[1, 3];
        end
        
    else
        axis_desig=[1 2 3];
    end

    %  if there are adiditional axes assume they are in the z-direction
    axis_desig(1:num_axes > length(axis_desig))=3;
    
end


size_sf=size(scaling_factors);

% e1 will increment for each axis of data
% axis_desig will choose the filter coefficients
 

% % ********************************************************************
% %
% set the flag for indicating whether to resample
flag0=0;



if isequal(type, 8)
    
    max_freq=500;
    min_freq=20;
    % Motion sickness use sampling rates around 50 Hz or less
    % higher sampling rates should be downsampled to reduce computation
    % time.  
    if Fs <= max_freq 
        p=1;
        q=1;
        Fsn=Fs;
        errors=0;
    else
        [Fsn, p, q, errors]=get_p_q2(Fs, max_freq, min_freq);
    end
    
else
    
    max_freq=20000;
    min_freq=2000;
    
    % Whole body vibrations use sampling rates around 2400 Hz or less
    % higher sampling rates should be downsampled to reduce computation
    % time.  
    if Fs <= max_freq 
        p=1;
        q=1;
        Fsn=Fs;
        errors=0;
    else
        [Fsn, p, q, errors]=get_p_q2(Fs, max_freq, min_freq);
    end
    
end


if ~isequal(Fsn, Fs)
    flag0=1;
end


% % ********************************************************************
% 
% Resample the data to a reasonable sampling rate to keep the whole body 
% vibrations and motion sickness filters as stable as possible and 
% minimize computation time.    
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
    y2=zeros(n2, num_axes);
    y2(:, 1)=buf;
    clear('buf');
    if num_axes > 1
        for e1=2:num_axes;
            
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
% Apply the whole body weighting filters to each channel of data

yH=zeros(size(y2));

for e1=1:num_axes;
    
    yhw=y2(:, e1);
    
    % Adding filter settling data
    num_data_pts=length(yhw);
    [buf, num_settle_pts]=filter_settling_data3(Fsn, yhw, settling_time);
    
    
    % % ***************************************************************
    % %
    % set the flag for selecting filter coefficients
    flag11=1;
    
    sc=scaling_factors(1, axis_desig(e1));
    
    if sc == 0 && size_sf(1) > 1
        sc=scaling_factors(2, axis_desig(e1));
        flag11=2;
    end
        
    
    for e2=1:4;
        
        BB=filtercoeffs{flag11}{e2}{1};
        AA=filtercoeffs{flag11}{e2}{2};
        
        
        % Apply the whole body vibrations filters
        if ~isequal(BB, 1) && ~isequal(AA, 1)
            buf = real(filter(BB, AA, buf));
        end
        
    end
    
    % removing filter settling data
    [buf]=remove_filter_settling_data(buf, 1, num_settle_pts, num_data_pts, 2);
    
    num_pts=min([length(buf), length(yH)]);
    
    % Remove the settling data from the time record.
    yH(1:num_pts, e1)=sc*buf(1:num_pts);
    
end




% % ********************************************************************
% 
% Resample if necessary so the output has the same size as the input 
if isequal(flag0, 1)
    
    % Adding filter settling data
    num_data_pts=length(yH(:, 1));
    [y11, num_settle_pts]=filter_settling_data3(Fs, yH(:, 1), settling_time);

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


    
    n2=length(buf);
    yhh=zeros(n2, num_axes);
    yhh(:, 1)=buf;
    clear('buf');
    if num_axes > 1
        for e1=2:num_axes;
            
            % Adding filter settling data
            num_data_pts=length(yH(:, e1));
            [y11, num_settle_pts]=filter_settling_data3(Fs, yH(:, e1), settling_time);

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
    yhh=yH;
end

clear('yH');


% % ********************************************************************
% 
% Output yhw must have the same size as the original input matrix y.
% Append the data to the output variable
if isequal(flag0, 1)
    if n2 > num_samples
        n2=num_samples;
    end

    yhw=yhh(1:n2, 1:num_axes);
else
    yhw=yhh(1:num_samples, 1:num_axes);
end


% % ********************************************************************
% 
% Output yhw must have the same size as the original input matrix y.
% Transpose yhw if necessary. 
if isequal(flag1, 1)
    yhw=yhw';
end



