function [snd, vibras_ha, vibras_wb, vibras_ms, round_kind_snd, round_digits_snd, round_kind_vibs_ha, round_digits_vibs_ha, round_kind_vibs_wb, round_digits_vibs_wb, round_kind_vibs_ms, round_digits_vibs_ms]=Continuous_Sound_and_Vibrations_Analysis(filenamesin, fileout_txt, fileout_struct, Tool_Name, same_ylim, fig_format, portrait_landscape, sod, resample_filter, filter_approach)
% % Continuous_Sound_and_Vibrations_Analysis: Loads time records and timeseries, Calculates metrics for sound and vibrations (hand arm and whole body).
% %
% % Syntax:
% %
% % [snd, vibras_ha, vibras_wb, vibras_ms]=Continuous_Sound_and_Vibrations_Analysis(filenamesin, fileout_txt, fileout_struct, Tool_Name, same_ylim, fig_format, portrait_landscape, sod, resample_filter, filter_approach );
% %
% % ********************************************************************
% %
% % Description:
% %
% % This program calculates metrics for continuous sound and vibrations
% % exposures.
% %
% % This program calculates metrics for continuous sound and vibrations.
% % Sound metrics include: peaks, Leq, LeqA, LeqC, kurtosis,
% % third octave band peaks and levels, and more.
% %
% % Vibration metrics for hand-arm include: arms, armq, Dy, peak, crest
% % factor, kurtosis, third octave band levels and peaks, and more.
% %
% % Vibration metrics for whole-body include: arms, armq, VDV, MSDV, crest
% % factor, kurtosis, third octave band levels and peaks, and more.
% %
% % The vibration metrics except for the third octave bands are calculated
% % using both the weighted and unweighted filters.
% %
% % Vibrations metrics are calculated for either the hand arm-vibrations
% % ISO 5349-1 to 5349-4 and the whole body vibrations ISO 2631-1.
% % ANSI standard ANSI S2.70 was updated to reflect a criteria for a
% % recommended vibration threshold.
% %
% % The metrics calculated in this program are for
% % time records of length 10 seconds to 2 minutes or longer.
% %
% % The program is limited in its memory and capacity to calculate long
% % time records.  In general, the program can process files with a few
% % million data points without crashing.
% %
% % The user selects either matlab or wav files to analyze for sound and
% % vibrations.  There are a series of prompts for output filenames,
% % formating of output images of the figures, and the Name of the device
% % under test (Tool Name).
% %
% % Whole Body Vibrations has seven different postures
% % The table below relates the type integer to each posture.
% %
% %      % type=1;    Standing
% %      % type=2;    Seated (Health)
% %      % type=3;    Seated (Comfort)
% %      % type=4;    Laying on back (recumbent) k=1 Pelvis, k=2 Head
% %      % type=5;    Rotational on supporting seat
% %      % type=6;    Rotational on seated backrest
% %      % type=7;    Rotational on feet
% %      % type=8;    Motion sickness
% %
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
% % The input and output variables are described in more detail in the
% % respective sections below.
% %
% % ********************************************************************
% %
% % Input Arguments
% %
% % filenamesin={'test1.mat', 'test2.mat'};
% %                             % Cell array of filenames to process
% %                             %
% %                             % default is uigetfile; a user windows
% %                             % interface for slecting files.
% %
% % fileout_txt='Cont_text';    % File name for the output text file.
% %                             %
% %                             % default is 'Cont_text';
% %
% % fileout_struct='Cont_snd_and_vibs';
% %                             % File name for the output Matlab Data
% %                             % structures file.
% %                             %
% %                             % default is 'Cont_text';
% %
% % Tool_Name='Recip Saw';      % String which is the name of the tool
% %                             % or device under test.
% %                             % Typically should be 30 caracters or less.
% %                             %
% %                             % default is Tool_Name='';
% %
% % same_ylim=1;                % 1 sets all of the limits of the y-axes to
% %                             % the same values for each channel.
% %                             % The y-limits of the sound data is
% %                             % independent of the y-limits of the
% %                             % vibrations data.
% %                             %
% %                             % if same_ylim ~= 1 then the y-axis
% %                             % limits can be differenet values.
% %                             %
% %                             % default is same_ylim=1;
% %
% % fig_format=[1,2,3,4,5,6];   % image format for saving the plot
% %                             % 1 pdf    default is 1 suggested
% %                             %          for simple documentation
% %                             % 2 fig
% %                             % 3 jpg  (200 dpi resolution)
% %                             % 4 eps2
% %                             % 5 tiff (200 dpi resolution)
% %                             % 6 tiff (no compression) suggested for
% %                             %         publications)
% %                             %
% %                             % default is fig_format=1; pdf format
% %
% % portrait_landscape=1;       % 1 is for Potrait
% %                             % Otherwise Landscape
% %
% % sod=0;              % 1 surpress outlier detection
% %                     % 0 find the outliers and remove them from the
% %                     % statistical analysis
% %                     % default is sod=1;
% %
% % resample_filter=1;  % type of filter to use when resampling
% %                     % 1 resample function Kaiser window fir filter
% %                     % 2 Bessel filter
% %                     % otherwise resample function Kaiser window fir
% %                     % filter
% %                     % default is resample_filter=1; (Kaiser window)
% %
% % filter_approach=1;  % Approach to Nth octave band filtering
% %                     % 1 uses fft 10x faster methods however non-causal
% %                     % 2 uses filter function tranditional approach
% %                     % otherwise uses 1 traditional approach
% %                     % default is filter_approach=1; (fft non-causal)
% %
% %
% % ********************************************************************
% %
% % Output Arguments
% %
% % The program saves data to an output text file which has the filename
% % fileout_txt with the extension '.txt'.
% %
% % A data structure output should be added one has been added for
% % sound and is being developed for vibrations.
% %
% % snd is a Matlab data structure containing the sound metrics and
% %          descriptive statistics.
% %
% %      snd{file_num, var_num}.filename
% %      snd{file_num, var_num}.variable
% %      snd{file_num, var_num}.metrics
% %      snd{file_num, var_num}.metrics_description
% %      snd{file_num, var_num}.stats_of_metrics
% %      snd{file_num, var_num}.stats_description
% %      snd{file_num, var_num}.num_samples
% %      snd{file_num, var_num}.data_type  (Continuous Sound)
% %
% %
% % vibras_xx is a Matlab data structure containing the vibrations metrics and
% %     descriptive statistics.
% %
% %   Fields pertaining to all vibrations data
% %
% %      vibras_xx{file_num, var_num, acel_num}.filename
% %      vibras_xx{file_num, var_num, acel_num}.num_samples (number of ranges)
% %      vibras_xx{file_num, var_num, acel_num}.data_type (Continuous Vibrations)
% %      vibras_xx{file_num, var_num, acel_num}.exposure_type
% %                                              (hand-arm), (whole body)
% %      vibras_xx{file_num, var_num, acel_num}.scaling_factor
% %      vibras_xx{file_num, var_num, acel_num}.third_oct_freq
% %
% %
% %   Fields For Hand Arm Vibration
% %
% %      vibras_ha{file_num, var_num, acel_num}.variable
% %      vibras_ha{file_num, var_num, acel_num}.metrics
% %      vibras_ha{file_num, var_num, acel_num}.metrics_description
% %      vibras_ha{file_num, var_num, acel_num}.stats_of_metrics
% %      vibras_ha{file_num, var_num, acel_num}.stats_description
% %      vibras_ha{file_num, var_num, acel_num}.total_metrics
% %      vibras_ha{file_num, var_num, acel_num}.stats_of_total_metrics
% %
% %   Fields For Whole Body Vibration
% %
% %      vibras_wb{file_num, var_num, acel_num, posture_num}.variable
% %      vibras_wb{file_num, var_num, acel_num, posture_num}.metrics
% %      vibras_wb{file_num, var_num, acel_num, posture_num}.metrics_description
% %      vibras_wb{file_num, var_num, acel_num, posture_num}.stats_of_metrics
% %      vibras_wb{file_num, var_num, acel_num, posture_num}.stats_description
% %      vibras_wb{file_num, var_num, acel_num, posture_num}.total_metrics
% %      vibras_wb{file_num, var_num, acel_num, posture_num}.stats_of_total_metrics
% %      vibras_wb{file_num, var_num, acel_num, posture_num}.exposure_type
% %      vibras_wb{file_num, var_num, acel_num}.posture
% %          (Standing),
% %          (Seated (Health)),
% %          (Seated (comfort)),
% %          (Laying on back (recumbent),
% %          (Rotational on supporting seat),
% %          (Rotational on seated backrest),
% %          (Rotational on feet)
% %
% %   Fields For Motion Sickness
% %
% %      vibras_ms{file_num, var_num, acel_num}.variable
% %      vibras_ms{file_num, var_num, acel_num}.metrics
% %      vibras_ms{file_num, var_num, acel_num}.metrics_description
% %      vibras_ms{file_num, var_num, acel_num}.stats_of_metrics
% %      vibras_ms{file_num, var_num, acel_num}.stats_description
% %      vibras_ms{file_num, var_num, acel_num}.total_metrics
% %      vibras_ms{file_num, var_num, acel_num}.stats_of_total_metrics
% %      vibras_ms{file_num, var_num, acel_num}.exposure_type
% %      vibras_ms{file_num, var_num, acel_num}.posture
% %          (Motion sickness)
% %
% %
% %
% %
% % round_kind_snd          % Array of values specifying the kind of
% %                         % rounding to perform on the sound data.
% %                         %
% %                         % if round_kind==1 number of significant digits
% %                         % if round_kind==0 specified digits place
% %
% % round_digits_snd        % Array of values either specifying the
% %                         % number of significant digits or the
% %                         % digits place for the sound data
% %
% % round_kind_vibs_ha      % Array of values specifying the kind of
% %                         % rounding to perform on the hand-arm
% %                         % vibrations data.
% %
% % round_digits_vibs_ha    % Array of values either specifying the
% %                         % number of significant digits or the
% %                         % digits place for the hadn arm vibrations data
% %
% % round_kind_vibs_wb      % Array of values specifying the kind of
% %                         % rounding to perform on the whole body
% %                         % vibrations data.
% %
% % round_digits_vibs_wb    % Array of values either specifying the
% %                         % number of significant digits or the
% %                         % digits place for the hole body
% %                         % vibrations data.
% %
% % round_kind_vibs_ms      % Array of values specifying the kind of
% %                         % rounding to perform on the motion sickness
% %                         % data.
% %
% % round_digits_vibs_ms    % Array of values either specifying the
% %                         % number of significant digits or the
% %                         % digits place for the motion sickness
% %                         % data.
% %
% %
% %
% % ********************************************************************
%
%
%
% Example='1';
%
% % One Example is shown for sound and vibrations.
% % The example illustrates the definitions of the time
% % increment variables which the user is prompted to select.
%
%
% % Step 1)  Create a data file;
%
% % Set the sampling rate variables for sound and vibrations
% Fs_SP=50000;
% Fs_vibs=5000;
%
% % Set the time increment variables for sound and vibrations
% % t_SP, dt_SP        are time increment varialbes for sound
% % t_vibs, dt_vibs    are time increment varialbes for vibrations
%
% dt_SP=1/Fs_SP;
% dt_vibs=1/Fs_vibs;
% t_SP=0:(1/Fs_SP):20;
% t_vibs=0:(1/Fs_vibs):20;
%
% % SP is the sound pressure data
% % (3 channels for 20 seconds at 50 KHz sampling rate)
% SP=randn(3, length(t_SP));
%
% % vibs is the sound pressure data
% % (3 channels triaxial accelerometer
% % for 20 seconds at 5 KHz sampling rate)
% vibs=randn(3, length(t_vibs));
%
% save('Example_data_file.mat', 'SP', 'Fs_SP','t_SP', 'dt_SP', 'vibs', 'Fs_vibs','t_vibs', 'dt_vibs');
%
%
% % Step 2)  Create the input arguments;
%
% % Now set the input arguments to read the file, process the data,
% % and save the output.
% % The user will be prompted to configure the variables as to sound,
% % vibrations, smapling rate and time increment.
% % configure the accelerometers
%
% filenamesin={'Example_data_file.mat'};
%
% fileout_txt='Example_Text_output';
%
% fileout_struct='Example_Matlab_output';
%
% Tool_Name='Fan';
%
% same_ylim=1;
%
% fig_format=[1,2,3,4,5,6];
%
% portrait_landscape=1;
%
% sod=0;              % 0 find the outliers and remove them from
%
% % Step 3)  Run the program;
%
% [snd, vibras_ha, vibras_wb, vibras_ms]=Continuous_Sound_and_Vibrations_Analysis(filenamesin, ...
% fileout_txt, fileout_struct, Tool_Name, same_ylim, fig_format, ...
% portrait_landscape, sod );
%
% %
% % ********************************************************************
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
% % Continuous_Sound_and_Vibrations_Analysis
% %
% % FEX ID# is the File ID on the Matlab Central File Exchange
% %
% %
% % Program Name   Author   FEX ID#
% %  1) accel_config		Edward L. Zechmann
% %  2) ACdsgn		Edward L. Zechmann
% %  3) ACweight_time_filter		Edward L. Zechmann
% %  4) bessel_antialias		Edward L. Zechmann
% %  5) bessel_digital		Edward L. Zechmann
% %  6) bessel_down_sample		Edward L. Zechmann
% %  7) channel_data_type_selection		Edward L. Zechmann
% %  8) combine_accel_directions_ha		Edward L. Zechmann
% %  9) combine_accel_directions_wb		Edward L. Zechmann
% % 10) config_accels		Edward L. Zechmann
% % 11) config_ha_accels		Edward L. Zechmann
% % 12) config_wb_accels		Edward L. Zechmann
% % 13) convert_double		Edward L. Zechmann
% % 14) data_loader2		Edward L. Zechmann
% % 15) data_outliers3		Edward L. Zechmann
% % 16) fastlts		Peter J. Rousseeuw		NA
% % 17) fastmcd		Peter J. Rousseeuw		NA
% % 18) file_extension		Edward L. Zechmann
% % 19) filter_attenuation		Edward L. Zechmann
% % 20) filter_settling_data3		Edward L. Zechmann
% % 21) find_nums		Edward L. Zechmann
% % 22) fix_YTick		Edward L. Zechmann
% % 23) fourier_nth_oct_time_filter3    Edward L. Zechmann
% % 24) genHyper		Ben Barrowes		6218
% % 25) geospace		Edward L. Zechmann
% % 26) get_p_q2		Edward L. Zechmann
% % 27) hand_arm_fil		Edward L. Zechmann
% % 28) hand_arm_time_fil		Edward L. Zechmann
% % 29) kurtosis_excess2		Edward L. Zechmann
% % 30) Leq_all_calc		Edward L. Zechmann
% % 31) m_round		Edward L. Zechmann
% % 32) match_height_and_slopes2		Edward L. Zechmann
% % 33) moving		Aslak Grinsted		8251
% % 34) nth_freq_band		Edward L. Zechmann
% % 35) Nth_oct_time_filter2		Edward L. Zechmann
% % 36) Nth_octdsgn		Edward L. Zechmann
% % 37) parseArgs		Malcolm Wood		10670
% % 38) plot_snd_vibs		Edward L. Zechmann
% % 39) pow10_round		Edward L. Zechmann
% % 40) print_data_loader_configuration_table		Edward L. Zechmann
% % 41) psuedo_box		Edward L. Zechmann
% % 42) rand_int		Edward L. Zechmann
% % 43) remove_filter_settling_data		Edward L. Zechmann
% % 44) resample_interp3		Edward L. Zechmann
% % 45) resample_plot		Edward L. Zechmann
% % 46) rmean		Edward L. Zechmann
% % 47) rms_val		Edward L. Zechmann
% % 48) save_a_plot2_audiological		Edward L. Zechmann
% % 49) sd_round		Edward L. Zechmann
% % 50) selectdlg2		Mike Thomson
% % 51) sub_mean		Edward L. Zechmann
% % 52) sub_mean2		Edward L. Zechmann
% % 53) subaxis		Aslak Grinsted		3696
% % 54) t_alpha		Edward L. Zechmann
% % 55) t_confidence_interval		Edward L. Zechmann
% % 56) t_icpbf		Edward L. Zechmann
% % 57) tableGUI		Joaquim Luis		10045
% % 58) variable_data_type_selection		Edward L. Zechmann
% % 59) Vibs_calc_hand_arm		Edward L. Zechmann
% % 60) Vibs_calc_whole_body		Edward L. Zechmann
% % 61) whole_Body_Filter		Edward L. Zechmann
% % 62) whole_body_time_filter		Edward L. Zechmann
% %
% %
% %
% % ********************************************************************
% %
% % Program Written by Edward L. Zechmann
% %
% %     date 10 August      2007
% %
% % modified 10 January     2008
% %
% % modified 17 January     2008    Updated comments
% %                                 began updating to data_loader2
% %
% % modified 14 July        2008     Completed update to data_loader2
% %
% % modified 24 July        2008    Added ability to process
% %                                 multiple variables
% %
% % modified  4 August      2008    Added comments
% %
% % modified 11 August      2008    Added comments
% %
% % modified 12 August      2008    Began adding the Matlab data
% %                                 structure output
% %
% % modified  2 September   2008    Began adding third octave peaks and
% %                                 levels.
% %
% % modified  3 September   2008     Added comments
% %
% % modified  5 September   2008    Finished third octave Added comments
% %                                 Finished Matlab data structure output
% %                                 Added comments
% %
% % modified  9 October     2008    Added Comments and modified the
% %                                 subprogram find_nums.
% %
% %                                 Fixed a bug with reporting the
% %                                 scaling factors for whole body
% %                                 vibration in the Matlab structure.
% %
% %                                 Increased the size of some list boxes.
% %
% %                                 Fixed bug where values of the mtrics
% %                                 were not reported to the metrics field
% %                                 if there was only one channel of
% %                                 vibrations.
% %
% % modified 10 December    2008    Upgraded the third octave band
% %                                 filtering programs, the A and C-
% %                                 weighting filter programs,
% %                                 hand_arm_time_fil2, and
% %                                 whole_body_time_filter to include
% %                                 filter settling and resampling.
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
% %                                 Use convolution to simplify filter
% %                                 coefficients (B1, B2, A1, A2) into
% %                                 arrays B and A.
% %
% %                                 Finished modifications to support
% %                                 filter settling and resampling.
% %
% % modified 15 January     2009    Updated the outlier removal program.
% %                                 Added rounding of the output.
% %
% % modified 18 January     2009    Updated the outlier removal program.
% %                                 Added rounding of the output.
% %
% % modified 21 January     2009    Split the seated posture into two cases
% %                                 Seated (Health) and Seated (Comfort).
% %                                 Only documentation needed adjustment.
% %
% % modified  9 October     2009    Updated Comments
% %
% % modified  5 August      2010    Added resampling option to use Bessel
% %                                 antialiasing filter or built-in Matlab
% %                                 resample function
% %                                 Updated Comments
% %
% % modified 18 January     2011    Fixed a bug in the splitting the seated
% %                                 posture into two cases.  The scaling
% %                                 factors for the two cases were switched.
% %                                 Updated Comments
% %
% % modified 15 February    2011    Fixed a bug in rounding and writing
% %                                 metrics to text file.
% %
% % modified 21 February    2011    Fixed several bugs in outputting vibs
% %                                 metrics.  Updated comments.
% %
% % modified  5 Janaury     2012    Replace LMSloc with fastlts.
% %                                 Updated comments
% %
% % modified 26 March       2012    Added Fourier third octave band filter
% %                                 Updated comments and examples.
% %
% %
% %
% % ********************************************************************
% %
% % Please feel free to modify this code.
% %
% % See Also: Impulsive_Noise_Meter, Calibrated Spectral Analysis,
% %           pressure_spectra, octave, main_snd_vibs
% %
% %



% Set the default values for unspecified input variables

if (nargin < 1 || isempty(filenamesin)) || ischar(filenamesin) || (~iscell(filenamesin) && numel(filenamesin) > 1)
    
    [filenamesin, pathname, filterindex] = uigetfile( {  '*.mat'; '*.wav'},  'Select the files To Process', 'MultiSelect', 'on');
    
    if isempty(filenamesin) || ischar(filenamesin) || (~iscell(filenamesin) && numel(filenamesin) > 1)
        
        % expecting a cell array of strings
        % if only one file is selected then it will be a character array or a
        % single string
        % convert into a cell array if necessary
        if ~isempty(filenamesin) && ischar(filenamesin) && isequal(exist(filenamesin, 'file'), 2)
            filenamesin={filenamesin};
        else
            if isempty(filenamesin)
                [filenamesin, pathname] = uigetfile( {  '*.mat';'*.wav'},  'Select the files To Process', 'MultiSelect', 'on');
            end
            if ischar(filenamesin) && isequal(exist(filenamesin, 'file'), 2)
                filenamesin={filenamesin};
            end
        end
        pathname=cd;
        cd(pathname);
    else
        cd( pathname);
    end
end

if ~iscell(filenamesin) || isempty(filenamesin) || length(filenamesin) < 1
    error('Must select at least 1 file to analyze');
end

if ~iscell(filenamesin) || isempty(filenamesin) || length(filenamesin) < 1
    error('Must select at least 1 file to analyze');
end

filenamesin=sort(filenamesin);



if (nargin < 2 || isempty(fileout_txt)) || ~ischar(fileout_txt)
    fileout_txt='Cont_text';
end

if (nargin < 3 || isempty(fileout_struct)) || ~ischar(fileout_struct)
    fileout_struct='Cont_snd_and_vibs';
end

if nargin < 4 || ~ischar(Tool_Name)
    Tool_Name='';
end

if (nargin < 5 || isempty(same_ylim)) || ~isnumeric(same_ylim)
    same_ylim=1;
end

if (nargin < 6 || isempty(fig_format)) || (any(~isnumeric(fig_format)) || any(logical(fig_format < 1))) || any(logical(fig_format > 6))
    fig_format=1;
end

fig_format=round(fig_format);
fig_format(fig_format<1)=1;
fig_format(fig_format>6)=6;

if (nargin < 7 || isempty(portrait_landscape)) || ~isnumeric(portrait_landscape)
    portrait_landscape=1;
end

if nargin < 8 || isempty(sod) || ~isnumeric(sod)
    sod=1;
end

if nargin < 9 || isempty(resample_filter) || ~isnumeric(resample_filter)
    resample_filter=1;
end

if ~isequal(resample_filter, 2)
    resample_filter=1;
end




% Initialize the output cell arrays of structures.
% The number of files, variables, accelerometers, and postures is
% not known until later so empty cell arrays are used.
snd={};
vibras_ha={};
vibras_wb={};
vibras_ms={};

% Another preallocation will happen the first time each dat type is
% processed are
flag_snd_first=1;
flag_vibs_ha_first=1;
flag_vibs_wb_first=1;
flag_vibs_ms_first=1;


close all;

ax_string='xyz';
wb_th_array=[];

sh=0.0;
sv=0.0;
ml=0.14;
mr=0.1;
mt=0.08;
mb=0.12;

% Initialize the hand arm filter coefficients
B=1;
A=1;

% initialize the recumbent position indicator: 1 for pelvis, 2 for head.
rpo=1;

% Initialize the filter coefficients and the scaling factors
filtercoeffs={};
filter_types=[];
scaling_factors=[];

flag_rs=0;  % flag for resampling the plot of the data to reduce the number of data points.  Program runs too slowly above 1000000 data samples.
flag10=1;
flag11=1;
flag100=1;
flag200=1;
type_selection={};
flag_select=0;  % flag for selecting the entire range automatically
flag_select2=0; % flag reset for each file to allow plotting the range on the figure
flag_select3=0; % flag for each file with same range sizes

ha_num_axes=1;
ha_scale=1;

ha_chan2={};
ha_axes2={};
ha_accels2=[];
num_ha_accels2=[];

Fs2=1;

wb_chan2={};
wb_axes2={};
wb_accels2=[];
num_wb_accels2=[];

per_mar=0.16;


% initialize the input configuration cell arrays for the wav files
% and the matlab data files
default_wav_settings_in={};
default_mat_config_in={};

% % **********************************************************************
% %
% % Describe the metrics for the sound pressure calculations
% %
% % snd_metrics_description

array_names={'Range Number', 'Beginning Time', 'Ending Time', 'LeqA', 'LeqA8', 'LeqC', 'LeqC8', 'Leq', 'Leq8', 'Kurtosis'};
array_units={'(Indices)',    '(s)',            '(s)',         '(dB)', '(dB)',  '(dB)',  '(dB)', '(dB)','(dB)', '(No Units)'};
num_snd_simple_metrics=length(array_names);

N_snd=3;  % third octave bands
min_f_snd=20;
max_f_snd=20000;
[fc_snd, fc_l,fc_u, fc_str_snd, fc_l_str, fc_u_str] = nth_freq_band(N_snd, min_f_snd, max_f_snd);
num_snd_bands=length(fc_snd);
num_x_filter_snd=1;
za=zeros(1, 2*num_snd_bands);

round_kind_snd=  [0 1 1  0  0  0  0  0  0 1 za];
round_digits_snd=[0 4 4 -1 -1 -1 -1 -1 -1 3 -1+za];


% append the strings for the simple sound metrics
snd_metric_str=cell(num_snd_simple_metrics+2*num_snd_bands, 1);
snd_metric_units=cell(num_snd_simple_metrics+2*num_snd_bands, 1);
num_snd_metrics=num_snd_simple_metrics+2*num_snd_bands;

for e1=1:num_snd_simple_metrics;
    snd_metric_str{e1}=array_names{e1};
    snd_metric_units{e1}=array_units{e1};
end

% append the strings for the third octave band sound metrics
for e1=1:num_snd_bands;
    snd_metric_str{num_snd_simple_metrics+e1}=['Peak ', fc_str_snd{e1}, ' Hz'];
    snd_metric_str{num_snd_simple_metrics+num_snd_bands+e1}=['Level ', fc_str_snd{e1}, ' Hz'];
    
    snd_metric_units{num_snd_simple_metrics+e1}='(dB)';
    snd_metric_units{num_snd_simple_metrics+num_snd_bands+e1}='(dB)';
end


% % **********************************************************************
% %
% % Describe the metrics for the Hand-Arm Vibrations Acceleration calculations
% %
% % vibs_ha_metrics_str
% % vibs_ha_metrics_units

array_names={ 'Channel', 'Accel',   'Axis',    'Scaling', 'Range Number', 'Beginning Time', 'Ending Time', 'arms_w',  'arms8h_w', 'Dy_w',    '50% Dy_w', 'armf_w^4', 'armf8h_w^4', 'Dy_w^4', '50% Dy_w^4', 'Peak Accel_w', 'Crest Factor_w', 'akurtosis_w', 'arms_un',  'arms8h_un', 'Dy_un',   '50% Dy_un', 'armf_un^4', 'armf8h_un^4', 'Dy_un^4', '50% Dy_un^4', 'Peak Accel_un', 'Crest Factor_un', 'akurtosis_un' };
array_units={'(Index)',  '(Index)', '(Index)', 'Factor',  '(Index)',      '(s)',            '(s)',         '(m/s^2)', '(m/s^2)',  '(Years)', '(Years)',  '(m/s^2)',  '(m/s^2)',    'Years',  'Years',      '(m/s^2)',      'No Units',       'No Units',    '(m/s^2)',  '(m/s^2)',   '(Years)', '(Years)',   '(m/s^2)',   '(m/s^2)',     'Years',   'Years',       '(m/s^2)',       'No Units',        'No Units'};
num_vibs_ha_simple_metrics=length(array_names);

N_vibs_ha=3; % third octave bands
min_f_vibs_ha=4;
max_f_vibs_ha=5000;
[fc_ha_vibs, fc_l,fc_u, fc_ha_vibs_str, fc_l_str, fc_u_str] = nth_freq_band(N_vibs_ha, min_f_vibs_ha, max_f_vibs_ha);
num_bands_vibs_ha=length(fc_ha_vibs);
num_x_filter_vibs_ha=1;

za=ones(1, 2*num_bands_vibs_ha);

round_kind_vibs_ha=  [0 0 0 1 0 1 1 1*ones(1, 22) 1*za];
round_digits_vibs_ha=[0 0 0 3 0 4 4 3*ones(1, 22) 3*za];


% append the strings for the simple hand arm vibrations metrics
vibs_ha_metric_str=cell(num_vibs_ha_simple_metrics+2*num_bands_vibs_ha, 1);
vibs_ha_metric_units=cell(num_vibs_ha_simple_metrics+2*num_bands_vibs_ha, 1);
num_ha_vibs_metrics=num_vibs_ha_simple_metrics+2*num_bands_vibs_ha;

for e1=1:num_vibs_ha_simple_metrics;
    vibs_ha_metric_str{e1}=array_names{e1};
    vibs_ha_metric_units{e1}=array_units{e1};
end

% append the strings for the third octave band hand arm vibrations metrics
for e1=1:num_bands_vibs_ha;
    vibs_ha_metric_str{num_vibs_ha_simple_metrics+e1}=['Peak ', fc_ha_vibs_str{e1}, ' Hz'];
    vibs_ha_metric_str{num_vibs_ha_simple_metrics+num_bands_vibs_ha+e1}=['arms ', fc_ha_vibs_str{e1}, ' Hz'];
    
    vibs_ha_metric_units{num_vibs_ha_simple_metrics+e1}='(m/s^2)';
    vibs_ha_metric_units{num_vibs_ha_simple_metrics+num_bands_vibs_ha+e1}='(m/s^2)';
end


% % **********************************************************************
% %
% % Describe the metrics for the Whole-Body Vibrations Acceleration
% % calculations
% %
% % vibs_wb_metrics_str
% % vibs_wb_metrics_units

array_names={'Posture', 'Channel', 'Accel',   'Axis',    'Scaling',  'Range Number', 'Beginning Time', 'Ending Time', 'arms_wb',  'arms8h_wb', 'VDV_wb',     'armq_wb^4', 'armq_8h_wb^4', 'Peak Accel_wb', 'Crest Factor_wb', 'akurtosis_wb',  'arms_un', 'arms8h_un', 'VDV_un',     'armf_un^4', 'armf_8h_un^4', 'Peak Accel_un', 'Crest Factor_un', 'akurtosis_un'  };
array_units={'(Index)', '(Index)', '(Index)', '(Index)', '(Factor)', '(Index)',      '(s)',            '(s)',         '(m/s^2)',  '(m/s^2)',   '(m/s^1.75)', '(m/s^2)',   '(m/s^2)',      '(m/s^2)',       'No Units',        'No Units',      '(m/s^2)', '(m/s^2)',   '(m/s^1.75)', '(m/s^2)',   '(m/s^2)',      '(m/s^2)',       'No Units',        'No Units',     };
num_vibs_wb_simple_metrics=length(array_names);

N_vibs_wb=3; % third octave bands
min_f_vibs_wb=0.1;
max_f_vibs_wb=400;
[fc_vibs_wb, fc_l,fc_u, fc_wb_str, fc_l_str, fc_u_str] = nth_freq_band(N_vibs_wb, min_f_vibs_wb, max_f_vibs_wb);
num_bands_vibs_wb=length(fc_vibs_wb);
num_x_filter_vibs_wb=1;

za=ones(1, 2*num_bands_vibs_wb);

round_kind_vibs_wb=  [0 0 0 0 1 0 1 1 1*ones(1, 16) 1*za];
round_digits_vibs_wb=[0 0 0 0 3 0 4 4 3*ones(1, 16) 3*za];


% append the strings for the simple whole body vibration metrics
vibs_wb_metric_str=cell(num_vibs_wb_simple_metrics+2*num_bands_vibs_wb, 1);
vibs_wb_metric_units=cell(num_vibs_wb_simple_metrics+2*num_bands_vibs_wb, 1);
num_wb_vibs_metrics=num_vibs_wb_simple_metrics+2*num_bands_vibs_wb;

for e1=1:num_vibs_wb_simple_metrics;
    vibs_wb_metric_str{e1}=array_names{e1};
    vibs_wb_metric_units{e1}=array_units{e1};
end

% append the strings for the third octave band whole body vibration metrics
for e1=1:num_bands_vibs_wb;
    vibs_wb_metric_str{num_vibs_wb_simple_metrics+e1}=['Peak ', fc_wb_str{e1}, ' Hz'];
    vibs_wb_metric_str{num_vibs_wb_simple_metrics+num_bands_vibs_wb+e1}=['Level ', fc_wb_str{e1}, ' Hz'];
    
    vibs_wb_metric_units{num_vibs_wb_simple_metrics+e1}='(m/s^2)';
    vibs_wb_metric_units{num_vibs_wb_simple_metrics+num_bands_vibs_wb+e1}='(m/s^2)';
end

posture={'Standing', 'Seated (Health)', 'Seated (Comfort)', 'Laying on Back (Recumbent', 'Rotational on Supporting Seat', 'Rotational on Seated Backrest', 'Rotational on Feet', 'Motion Sickness'};

% % **********************************************************************
% %
% % Describe the metrics for the Motion Sickness Vibrations Acceleration
% % Calculations
% %
% % vibs_ms_metrics_str
% % vibs_ms_metrics_units
array_names={'Posture', 'Channel', 'Accel',   'Axis',    'Scaling',  'Range Number', 'Beginning Time', 'Ending Time', 'arms_wb',  'arms8h_wb', 'VDV_wb',     'armq_wb^4', 'armq_8h_wb^4', 'Peak Accel_wb', 'Crest Factor_wb', 'akurtosis_wb', 'MSDV_wb',   'arms_un', 'arms8h_un', 'VDV_un',     'armf_un^4', 'armf_8h_un^4', 'Peak Accel_un', 'Crest Factor_un', 'akurtosis_un', 'MSDV_un'  };
array_units={'(Index)', '(Index)', '(Index)', '(Index)', '(Factor)', '(Index)',      '(s)',            '(s)',         '(m/s^2)',  '(m/s^2)',   '(m/s^1.75)', '(m/s^2)',   '(m/s^2)',      '(m/s^2)',       'No Units',        'No Units',     '(m/s^1.5)', '(m/s^2)', '(m/s^2)',   '(m/s^1.75)', '(m/s^2)',   '(m/s^2)',      '(m/s^2)',       'No Units',        'No Units',     '(m/s^1.5)'};
num_vibs_ms_simple_metrics=length(array_names);
%bb2=vibs_metrics_description(1, [1:8, 10:17]);


% Special case of motion sickness
N_vibs_ms=3; % third octave bands
min_f_vibs_ms=0.02;
max_f_vibs_ms=4;
[fc_vibs_ms, fc_l,fc_u, fc_ms_str, fc_l_str, fc_u_str] = nth_freq_band(N_vibs_ms, min_f_vibs_ms, max_f_vibs_ms);
num_bands_vibs_ms=length(fc_vibs_ms);
num_x_filter_vibs_ms=1;

za=ones(1, 2*num_bands_vibs_ms);

round_kind_vibs_ms=  [0 0 0 0 1 0 1 1 1*ones(1, 18) 1*za];
round_digits_vibs_ms=[0 0 0 0 3 0 4 4 3*ones(1, 18) 3*za];


% append the strings for the simple whole body vibration metrics
vibs_ms_metric_str=cell(num_vibs_ms_simple_metrics+2*num_bands_vibs_ms, 1);
vibs_ms_metric_units=cell(num_vibs_ms_simple_metrics+2*num_bands_vibs_ms, 1);
num_vibs_ms_metrics=num_vibs_ms_simple_metrics+2*num_bands_vibs_ms;

for e1=1:num_vibs_ms_simple_metrics;
    vibs_ms_metric_str{e1}=array_names{e1};
    vibs_ms_metric_units{e1}=array_units{e1};
end

% append the strings for the third octave band whole body vibration metrics
for e1=1:num_bands_vibs_ms;
    vibs_ms_metric_str{num_vibs_ms_simple_metrics+e1}=['Peak ', fc_ms_str{e1}, ' Hz'];
    vibs_ms_metric_str{num_vibs_ms_simple_metrics+num_bands_vibs_ms+e1}=['Level ', fc_ms_str{e1}, ' Hz'];
    
    vibs_ms_metric_units{num_vibs_ms_simple_metrics+e1}='(m/s^2)';
    vibs_ms_metric_units{num_vibs_ms_simple_metrics+num_bands_vibs_ms+e1}='(m/s^2)';
end

Selection=0;
e1=1;
k=1;
k5=1;

stat_str={'Arithmetic Mean', 'Robust Mean', 'Standard Deviation', '95% Confidence Interval', 'Median Index', 'Median Value', 'Minimum', 'Maximum'};

%create the text files to save the sound and vibrations data
[fileout_txt, ext]=file_extension(fileout_txt);
[fileout_struct, buf]=file_extension(fileout_struct);

fid_snd=fopen([fileout_txt '_snd.txt'], 'w');
fid_vibs=fopen([fileout_txt '_vibs.txt'], 'w');

% Since it is not known the size of snd and vibras_xx until run time
% memory is not preallocated to prevent filling in unnecessary zeros.


% *********************************************************************

k3 = menu('What Mode Do You Want?', 'Automated Mode', 'Manual Mode', 'Stop Program');

if k3 == 1
    k4 = menu('Whatcha Wanna Do?', 'Process Files For Continuous Noise and/or Vibrations', 'Stop Program');
    if k4 == 2;
        k=10000;
    else
        k=k4;
    end
    
elseif k3 == 2
    k = menu('Whatcha Wanna Do?', 'Load Data File', 'Stop Program');
    if k ~=1
        k=10000;
    end
else
    k=10000;
end



% Loop through the files
while k <= 5 &&  ( Selection <= length(filenamesin) )
    
    switch k
        
        case 1
            
            % This case Loads and plots the data
            %
            % Calls the data_loader2 to load the data
            % Calls plot_time to plot the data
            %
            
            % initialize the vibrations frequency weighting filter coefficient
            % arrays
            wb_th_array=[];
            % e1 is the file counter
            % increment the file counter
            
            if k3 == 1
                Selection=e1;
                e1=e1+1;
            else
                [Selection, ok] = listdlg('ListString', filenamesin, 'SelectionMode', 'single', 'InitialValue', e1, 'Name', 'Data File Selection Menu', 'PromptString', 'Select Data File to Load', 'OKString', 'Load Data File', 'ListSize', [500 500]);
                e1=e1+1;
            end
            
            if Selection <= length(filenamesin)
                
                % set the input file name to load data
                filename1=filenamesin{Selection};
                [filename1, filename1_ext]=file_extension(filename1);
                
                % set the output data file name to save the data
                filename2=strcat(filename1, '_', fileout_txt);
                
                [SP_var, vibs_var, Fs_SP_var, Fs_vibs_var, default_wav_settings_out, default_mat_config_out]=data_loader2(filenamesin{Selection}, default_wav_settings_in, default_mat_config_in);
                
                % set the default wav file setttings
                % for configuring the channels
                default_wav_settings_in=default_wav_settings_out;
                default_mat_config_in=default_mat_config_out;
                
                % Calculate the number of sound variables and the number of
                % vibrations variables
                
                if iscell(SP_var)
                    num_SP_vars=length(SP_var);
                else
                    if ~isempty(SP_var)
                        num_SP_vars=1;
                    else
                        num_SP_vars=0;
                    end
                end
                
                if iscell(vibs_var)
                    num_vibs_vars=length(vibs_var);
                else
                    if ~isempty(vibs_var)
                        num_vibs_vars=1;
                    else
                        num_vibs_vars=0;
                    end
                end
                
                max_num_vars=max([num_SP_vars num_vibs_vars]);
                
                % Process each variable like a separate file
                % e7 is the variable counter
                % reinitialize the variable counter to 1
                e7=1;
                
                % Send to the next case if automated
                % If not automated a prompt will appear
                if k3 == 1
                    k=2;
                else
                    k=2;
                end
                
            else
                k=10000;
            end
            
        case 2
            
            vibs=[];
            SP=[];
            t_SP=[];
            t_vibs=[];
            
            % Place the data into the variables ( SP, vibs, t_SP, t_vibs)
            %
            
            if iscell(SP_var)
                if  e7 <= num_SP_vars
                    SP=SP_var{e7};
                end
            else
                SP=SP_var;
            end
            
            if iscell(Fs_SP_var)
                if e7 <= length(Fs_SP_var)
                    Fs_SP=Fs_SP_var{e7};
                elseif length(Fs_SP_var) >= 1
                    Fs_SP=Fs_SP_var{1};
                else
                    % Default data acquisition rate
                    Fs_SP=50000;
                end
            else
                Fs_SP=Fs_SP_var;
            end
            
            if iscell(vibs_var)
                if  e7 <= num_vibs_vars
                    vibs=vibs_var{e7};
                end
            else
                vibs=vibs_var;
            end
            
            if iscell(Fs_vibs_var)
                if e7 <= length(Fs_vibs_var)
                    Fs_vibs=Fs_vibs_var{e7};
                elseif length(Fs_vibs_var) >= 1
                    Fs_vibs=Fs_vibs_var{1};
                else
                    % Default data acquisition rate
                    Fs_vibs=5000;
                end
            else
                Fs_vibs=Fs_vibs_var;
            end
            
            [m1 n1]=size(SP);
            
            if m1 > n1
                SP=SP';
                [m1 n1]=size(SP);
            end
            
            [m2 n2]=size(vibs);
            
            if m2 > n2
                vibs=vibs';
                [m2 n2]=size(vibs);
            end
            
            t_vibs=1./Fs_vibs*(0:(n2-1));
            t_SP=1./Fs_SP*(0:(n1-1));
            
            % remove the time varying mean value
            % Calculate a running average using a spline with 25 mean
            % values per second
            if ~isempty(SP)
                [SP]=sub_mean2(SP, Fs_SP, 15 );
            end
            
            % remove the mean value
            % Motion sickness and whole body vibrations are sensitive
            % to very low frequencies so a running mean may reduce
            % important variation in vibration amplitude
            if ~isempty(vibs)
                [vibs]=vibs-mean(vibs, 2)*ones(1, size(vibs, 2));
            end
            
            [m1, n1]=size(SP);
            [m2, n2]=size(vibs);
            last_x_axis=m1+m2;
            
            tot_num_samples=m1*n1+m2*n2;
            flag_rs=0;
            if tot_num_samples > 1000000
                flag_rs=1;
            end
            
            % This case plots the data
            
            h=figure(1);
            delete(h);
            h=figure(1);
            
            [h, h2, wb_th_array]=plot_snd_vibs(SP, Fs_SP, vibs, Fs_vibs, Tool_Name, filename1, {}, {}, same_ylim, {}  );
            
            
            
            min_t=min([min(t_SP'), min(t_vibs')]);
            max_t=max([max(t_SP'), max(t_vibs')]);
            
            % Send a message to the command line that a file is about to be
            % processed
            fprintf(1, '%s\r', ['File ', num2str(Selection), ' ' filename2] );
            
            % Send to the next case if automated
            % If not automated a prompt will appear
            if k3 == 1
                k=3;
            else
                k=3;
            end
            
            var_sel=e7;
            e7=e7+1;
            
            
        case 3
            %
            % This Case Saves the Plot to a File
            figure(1);
            
            for e2=1:length(h2);
                axes(h2(e2));
            end
            
            for e2=1:length(fig_format);
                save_a_plot2_audiological(fig_format(e2), filename2, portrait_landscape);
            end
            
            % Send to the next case if automated
            % If not automated a prompt will appear
            if k3 == 1
                k=4;
            else
                k=4;
            end
            
        case 4
            
            % This case selectes the time ranges to analyze.
            % Plots the time ranges on the figure.
            % Calculates the sound metrics for each time range
            % Calculates the vibrations metrics for each time range
            % Prints metrics to a tab delimited file
            % stores metrics in a cell array
            
            % ************************************************************
            %
            % Implement automatic range selections
            %
            % indices
            %
            
            figure(1);
            count2=0;
            count3=0;
            max_count=0;
            x2=[];
            x3=[];
            k2=1;
            flag_select2=0;  % Reset once for each file
            num_ranges=0;
            
            % update this code
            % ******************************************************
            if flag_select == 0
                k2 = menu('Choose a Range Selection Option.  Select at least one range before quitting', 'Manually Select a Range for Analysis', 'Select Entire Range Once', 'Always and Only Select Entire Range', 'Always and Only Select Specified Range Size', 'Quit Range Selection');
            else
                if flag_select3==0
                    k2=3;
                else
                    k2=4;
                end
            end
            
            h3=[];
            h4=[];
            
            while (k2 ~= 5) && isequal(flag_select2, 0)
                
                if (isempty(h3) || ~ishandle(h3)) && k2 < 3
                    h3 = msgbox({'Press OK to Continue', '', 'Instructions to Select a Range:', '', '1)   Wait for Figure to Completely Load!', '2)   Move Cursor over the Figure', '3)   Wait for Vertical and Horizontal Lines to Appear', '4)   Do Not Drag Cursor between the left and right ranges points.',  '5)   Click Left Range Point', '6)   Then Click Right Range Point', '', 'Press OK to Continue'}, 'Selecting a Range',  'help');
                end
                
                waitfor(h3);
                figure(1);
                flag1=0;
                
                while isequal(flag1, 0) && isequal(k2, 1)
                    [x,y] = ginput(2);
                    
                    if x(2) > x(1)
                        flag1 =1;
                    else
                        flag1 =0;
                        
                        h4 = warndlg( {'Click Left Range Point', 'Then Click Right Range Point', 'Do Not Drag Cursor', 'Press OK to Continue'}, 'Warning', 'modal');
                        waitfor(h4);
                        
                    end
                    
                end
                
                % *******************************************************
                %
                % Create an New Figure
                figure(1);
                
                [m1 n1]=size(SP);
                [m2 n2]=size(vibs);
                
                if k2 == 2 || k2 == 3
                    x=[min_t max_t];
                end
                
                
                num_ranges_snd=1;
                num_ranges_vibs=1;
                
                if k2 == 4
                    if flag_select == 0
                        % dlgbox
                        % % ********************************************************************
                        %
                        % Enter the maximum number of channels to be analyzed in a single file
                        %
                        prompt= {'Enter the number of seconds for each data range.'};
                        defAns={'5'};
                        dlg_title=['Range Duration (s) for Analysis.'];
                        num_lines=1;
                        
                        options.Resize='on';
                        options.WindowStyle='normal';
                        options.Interpreter='tex';
                        
                        pts_SP_vibs_cell = inputdlg(prompt,dlg_title,num_lines,defAns,options);
                        
                        if isempty(pts_SP_vibs_cell)
                            if m1 >= 1
                                num_secs=min([5, n1./Fs_SP]);
                            elseif m2 >= 1
                                num_secs=min([5, n2./Fs_vibs]);
                            else
                                num_secs=max([n1, n2]);
                            end
                            
                        else
                            num_secs=str2double(pts_SP_vibs_cell{1});
                        end
                        
                        % num_secs must be a positive real number
                        if num_secs  <= 0
                            num_secs=1;
                        end
                        
                    end
                    
                    % The number of pts for each range is determined by
                    % the sampling rate and duration of the range
                    pts_SP=floor(num_secs*Fs_SP);
                    pts_vibs=floor(num_secs*Fs_vibs);
                    
                    
                    flag_select=1;  % set for all files
                    flag_select2=1; % reset once for each file
                    flag_select3=1;  % set for all files with same range size
                    
                    num_ranges_snd=floor(n1/pts_SP);
                    num_ranges_vibs=floor(n2/pts_vibs);
                    
                    if num_ranges_snd < 1
                        pts_SP=n1;
                        num_ranges_snd=1;
                    end
                    
                    if num_ranges_vibs < 1
                        pts_vibs=n2;
                        num_ranges_vibs=1;
                    end
                    
                end
                
                
                if k2 == 3
                    flag_select=1;  % set for all files
                    flag_select2=1; % reset once for each file
                    flag_select3=0;
                end
                
                if m1 >= 1
                    
                    for e3=1:num_ranges_snd;
                        
                        if k2 == 4
                            ix1=1+pts_SP*(e3-1);
                            ix2=pts_SP*e3;
                        else
                            ix1=find(t_SP >= x(1), 1 );
                            ix2=find(t_SP <= x(2), 1, 'last' );
                        end
                        
                        x=[t_SP(ix1) t_SP(ix2)];
                        
                        if ~isempty(ix1) && ~isempty(ix2)
                            max_count=max_count+1;
                            count2=count2+1;
                            if max_count > count2
                                count2=max_count;
                            elseif max_count < count2
                                max_count=count2;
                            end
                            
                            x2=[x2 [ix1 ix2]];
                            
                            for e2=1:m1;
                                
                                if same_ylim == 1
                                    ylim1=per_mar*ceil( 10*(max(max(abs(SP)))) );
                                else
                                    ylim1=per_mar*ceil( 10*max(max(abs(SP(e2, :)))) );
                                end
                                
                                SP_max=max(max(SP(e2, ix1:ix2)));
                                
                                axes(h2(e2));
                                hold on;
                                plot( [x(1), x(2)], 0.04*ylim1+SP_max*[1 1], 'k', 'LineWidth', 2  );
                                plot( [x(1), x(1)], 0.01*ylim1*[0 8]+SP_max*[1 1], 'k', 'LineWidth', 2  );
                                plot( [x(2), x(2)], 0.01*ylim1*[0 8]+SP_max*[1 1], 'k', 'LineWidth', 2  );
                                
                                text( mean(x), 0.05*ylim1+SP_max, num2str(count2), 'Fontsize', 10, 'Color', [0 0 0], 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom' );
                                
                                ylim(ylim1*[-1 1]);
                            end
                            
                        end
                    end
                end
                
                figure(1);
                
                if m2 >= 1
                    
                    if k2 == 4
                        max_count=0;
                        count3=0;
                    end
                            
                    for e3=1:num_ranges_vibs;
                        
                        if k2 == 4
                            ix1=1+pts_vibs*(e3-1);
                            ix2=pts_vibs*e3;
                            x=[t_vibs(ix1) t_vibs(ix2)];
                        else
                            ix1=find(t_vibs >= x(1), 1 );
                            ix2=find(t_vibs <= x(2), 1, 'last' );
                        end
                        
                        
                        if ~isempty(ix1) && ~isempty(ix2)
                            
                            
                            x3=[x3 [ix1 ix2]];
                                                       
                            if m1 < 1
                                max_count=max_count+1;
                            end
                            count3=count3+1;
                            if max_count > count3
                                count3=max_count;
                            elseif max_count < count3
                                max_count=count3;
                            end
                            
                            for e2=(m1+1):(m1+m2);
                                axes(h2(e2));
                                hold on;
                                
                                if same_ylim == 1
                                    ylim2=per_mar*ceil( 10*(max(max(abs(vibs)))) );
                                else
                                    ylim2=per_mar*ceil( 10*(max(max(abs(vibs(e2-m1, :))))) );
                                end
                                
                                vibs_max=max(max(vibs(e2-m1, ix1:ix2)));
                                
                                plot( [x(1), x(2)], 0.04*ylim2+vibs_max*[1 1], 'k', 'LineWidth', 2  );
                                plot( [x(1), x(1)], 0.01*ylim2*[0 8]+vibs_max*[1 1], 'k', 'LineWidth', 2  );
                                plot( [x(2), x(2)], 0.01*ylim2*[0 8]+vibs_max*[1 1], 'k', 'LineWidth', 2  );
                                
                                text( 'Position', [mean(x), 0.05*ylim2+vibs_max, 0], 'String', num2str(count3), 'Interpreter', 'none', 'Fontsize', 10, 'Color', [0 0 0], 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom' );
                                ylim(ylim2*[-1 1]);
                            end
                        end
                    end
                    
                end
                
                if (k2 < 4) && (flag_select2 == 0)
                    k2 = menu('Choose a Range Selection Option.  Select at least one range before quitting', 'Select a Range for Analysis', 'Select Entire Range Once', 'Always and Only Select Entire Range ', 'Quit Range Selection');
                end
                
            end
            
            if ishandle(h3)
                close(h3);
                h3=[];
            end
            
            if ishandle(h4)
                close(h4);
                h4=[];
            end
            
            if m1 >= 1
                num_ranges_snd=floor(length(x2)/2);
            else
                num_ranges_snd=0;
            end
            
            if m2 >= 1
                num_ranges_vibs=floor(length(x3)/2);
            else
                num_ranges_vibs=0;
            end
            
            hold off;
            
            % ***********************************************************
            %
            % Process the Sound Data
            %
            
            
            
            if num_ranges_snd >= 1 && logical(m1 >= 1)
                
                if isequal(flag_snd_first, 1)
                    flag_snd_first=0;
                    snd=cell(length(filenamesin), var_sel);
                end
                
                
                for e3=1:m1; % num sound channels
                    
                    if isequal(e3, 1)
                        fprintf(fid_snd, ['Data File Name\r\n' filename1, ' \r\n']);
                    end
                    
                    fprintf(fid_snd, ['\tMic ' num2str(e3), ' \r\n']);
                    if floor(length(x2)/2) >= 1
                        
                        for e2=1:num_snd_metrics;
                            fprintf(fid_snd, '\t%s', snd_metric_str{e2});
                        end
                        fprintf(fid_snd, '\t\r\n');
                        
                    end
                    
                    % x2 has the beginning and ending x-coordinates for each
                    % range to evaluate.
                    for e2=1:num_ranges_snd; % number of ranges to calculate
                        SP2=SP(e3, x2(2*e2-1):x2(2*e2));
                        
                        % Calculate the kurtosis
                        kurt =kurtosis_excess2(SP2, 2);
                        dt_SP=(t_SP(2)-t_SP(1));
                        Fs=1/dt_SP;
                        
                        % Calculate the A-weighted, C-weighted, and Linear-Weighted
                        % sound pressure levels (dB) and peak amplitudes (Pa)
                        
                        % Set the settling time to 0.1 seconds which is a typical
                        % value.
                        settling_time=0.1;
                        
                        % Set the calibration factor to 1.
                        cf=1;
                        
                        % Calculate the Leq values
                        [LeqA, LeqA8, LeqC, LeqC8, Leq, Leq8]=Leq_all_calc(SP2, Fs, cf, settling_time, resample_filter);
                        
                        
                        % Calculate the third octave band sound pressure
                        % levels
                        % Set the input parameters for the
                        % Nth_oct_time_filter2
                        sensor=1;
                        settling_time=0.1;
                        filter_program=1;
                        N_snd=3;
                        method=1;
                        fil_order=3;
                        
                        if isequal(filter_approach, 1)
                            [fc_out, SP_levels, SP_peak_levels]=fourier_nth_oct_time_filter3(SP2, Fs, N_snd, fc_snd, sensor, method, fil_order);
                        else
                            [fc_out, SP_levels, SP_peak_levels]=Nth_oct_time_filter2(SP2, Fs, num_x_filter_snd, N_snd, fc_snd, sensor, settling_time, filter_program, resample_filter);
                        end
                        
                        % Concatenate the metrics
                        metrics_buf=[e2, t_SP((x2(2*e2-1))), t_SP(x2(2*e2)), LeqA, LeqA8, LeqC, LeqC8, Leq, Leq8, kurt, SP_peak_levels, SP_levels];
                        dB_or_linear=[0, 0,                  0,              1,    1,     1,    1,     1,   1,    0,   ones(size(SP_peak_levels)), ones(size(SP_levels))];
                        
                        % Print the sound metrics to a text files
                        [A2, A_str]=m_round(metrics_buf, round_kind_snd, round_digits_snd );
                        
                        fprintf(fid_snd, '\t');
                        
                        for e4=1:length(A_str);
                            fprintf(fid_snd, '%s\t', A_str{e4});
                        end
                        
                        fprintf(fid_snd, '\r\n');
                        
                        snd{Selection, var_sel}.metrics(e2, e3, :)=metrics_buf;
                        snd{Selection, var_sel}.data_type='Continuous_Sound';
                        
                    end
                    fprintf(fid_snd, '\r\n');
                end
                
                
                % md stands for "metrics description"
                md=cell(2, length(snd_metric_str));
                
                for e2=1:length(snd_metric_str);
                    md{1, e2}=snd_metric_str{e2};
                    md{2, e2}=snd_metric_units{e2};
                end
                
                snd{Selection, var_sel}.metrics_description=md;
                snd{Selection, var_sel}.filename=filenamesin{Selection};
                snd{Selection, var_sel}.variable=var_sel;
                
                
                % Do not use absolute value
                abs_rta=0;
                % Do not use absolute value
                abs_other=[];
                
                row_names={'Channel Number'};
                row_unit='';
                col_name='Range Number';
                
                
                % Outliers are identified for all
                % metric arrays independently.
                dep_var=0;
                
                metric_str2=cell(num_snd_metrics+1, 1);
                metric_units2=cell(num_snd_metrics+1, 1);
                
                metric_str2{1}=snd_metric_str{4};
                metric_units2{1}=snd_metric_units{4};
                
                for e3=1:num_snd_metrics;
                    metric_str2{e3+1}=snd_metric_str{e3};
                    metric_units2{e3+1}=snd_metric_units{e3};
                end
                
                % These four lines of code are added to more easily include
                % the dependent functions of data_outliers3 in the zip file.
                void_call=0;
                if void_call
                    data_outliers3(0);
                end
                
                round_kind_snd2=[1 round_kind_snd];
                round_digits_snd2=[3 round_digits_snd];
                
                dB_or_linear2=[1 dB_or_linear];
                
                function_str='data_outliers3(dB_or_linear2, snd{Selection, var_sel}.metrics(:, :, 4), dep_var, round_kind_snd2, round_digits_snd2, abs_rta, abs_other, sod, fid_snd, 1, row_names, row_unit, col_name, metric_str2, metric_units2';
                
                for e3=1:num_snd_metrics;
                    function_str=[function_str, ', squeeze(snd{Selection, var_sel}.metrics(:, :, ', num2str(e3), '))'];
                end
                
                function_str=[function_str,' )'];
                
                [ptsa, nptsa, rt_stats, other_stats, rt_outlier_stats, other_outlier_stats]=eval(function_str);
                
                
                snd{Selection, var_sel}.stats_of_metrics=other_stats;
                snd{Selection, var_sel}.stats_of_outlier_metrics=other_outlier_stats;
                snd{Selection, var_sel}.stats_description=stat_str;
                snd{Selection, var_sel}.num_samples=num_ranges_snd;
                snd{Selection, var_sel}.third_oct_freq=fc_snd;
                
            end
            
            % ***********************************************************
            %
            % Process the Vibrations Data
            %
            num_postures=0;
            selection=[];
            
            if num_ranges_vibs >= 1 && logical(m2 >= 1)
                
                if flag11 == 1
                    k5 = menu('Select the Vibrations Analysis to Perform.', 'Hand-Arm Vibration', 'Whole Body Vibration', 'Both Hand-Arma and Whole body', 'Neither Hand-Arm Nor Whole Body');
                    flag11 = menu('Reselect Analysis for each Data File?', 'Redo Selection of Vibrations Analysis for each Data File', 'Keep Current Selection of Hand-Arm and Whole Body for each Data File');
                end
                
                if k5 < 4
                    
                    ha_num_axes=1;
                    ha_scale=1;
                    % Configure the accelerometers
                    % there are m2 acceleromter channels to configure
                    if flag10 == 1
                        [num_accels, accel_num_chan, axis_chan_ix, chann_p_accel]=config_accels(m2, ax_string);
                        flag10 = menu('Whatcha Wanna Do?', 'Configure Accelerometers each time', 'Keep Accelerometer Configuration');
                    end
                    
                    if isequal(flag100, 1) && ( k5 == 1 || k5 == 3 ) && (num_accels > 0)
                        % Configure the accelerometers for hand arm
                        % vibrations
                        [ha_chan2, ha_axes2, ha_accels2, num_ha_accels2]=config_ha_accels(ax_string, num_accels, accel_num_chan, axis_chan_ix, chann_p_accel);
                        flag100 = menu('Whatcha Wanna Do?', 'Configure Hand-Arm Accelerometers each time', 'Keep Hand-Arm Accelerometer Configuration');
                    end
                    
                    fprintf(fid_vibs, ['Data File Name\r\n' filename1, ' \r\n']);
                    
                    if ( k5 == 1 || k5 == 3 ) && ~isempty(ha_accels2)
                        
                        % Implementing a resampling of the vibs data may
                        % speed up processing of the data.
                        
                        % configure the accelerometers for hand-arm and whole body vibrations
                        % num_accels                        % number of accels
                        % accel_num_chan                    % accelerometer number for each channel
                        % axis_chan_ix                      % axis designation for each channel
                        % chann_p_accel                     % number of channels for each accelerometer
                        % ha_accels                         % list of the Hand-Arm accels
                        % ha_accels2                        % list of the Hand-Arm accels
                        % num_ha_accels=length(ha_accels);  % number of accelerometers for measuring hand-arm vibrations
                        % ha_num_axes_p_accel=[];           % number of channels for each accelerometer
                        % ha_axes={};                       % designation of the direction (axis) for each channel
                        % ha_chan={};                       % designation the channel number for each accel and axis
                        % ha_axes2={};                      % designation of the direction (axis) for each channel after correction
                        % ha_chan2={};                      % designation the channel number for each accel and axis after correction channel numbers
                        
                        
                        % ***********************************************
                        %
                        % Process the Hand-Arm Vibrations Accelerometers
                        %
                        
                        if isequal(flag_vibs_ha_first, 1)
                            flag_vibs_ha_first=0;
                            vibras_ha=cell(length(filenamesin), var_sel, num_ha_accels2);
                        end
                        
                        for e3=1:num_ha_accels2;   % indexing accel number
                            
                            vibras_ha{Selection, var_sel, e3}.total_metrics=zeros( num_ranges_vibs, num_ha_vibs_metrics);
                            
                            ha_accel_num_buf=ha_accels2(e3);
                            
                            fprintf(fid_vibs, ['\tAccel ' num2str(ha_accel_num_buf), ' \r\n']);
                            
                            if num_ranges_vibs >= 1
                                fprintf(fid_vibs, '\tHand-Arm');
                                for e2=1:length(vibs_ha_metric_str);
                                    fprintf(fid_vibs, '\t%s', vibs_ha_metric_str{e2});
                                end
                                fprintf(fid_vibs, '\r\n\t\t');
                                
                                for e2=1:length(vibs_ha_metric_units);
                                    fprintf(fid_vibs, '\t%s', vibs_ha_metric_units{e2});
                                end
                                fprintf(fid_vibs, '\r\n');
                            end
                            
                            % indexing range number
                            for e2=1:num_ranges_vibs;
                                
                                % preallocate memory to the data buffers
                                data_buf=zeros(length(ha_chan2{e3}),  num_vibs_ha_simple_metrics-7);
                                data_buf3=zeros(length(ha_chan2{e3}), 2*num_bands_vibs_ha);
                                
                                for e4=1:length(ha_chan2{e3});  % indexing channel number
                                    
                                    % initialize the size of the vibras_ha
                                    % metrics
                                    if isequal(e4,1) && isequal(e2,1)
                                        vibras_ha{Selection, var_sel, e3}.metrics=zeros( num_ranges_vibs, length(ha_chan2{e3}), num_ha_vibs_metrics);
                                    end
                                    
                                    axes(h2(m1+ha_chan2{e3}(e4)));
                                    delete(wb_th_array(m1+ha_chan2{e3}(e4)));
                                    buffer1=get(gca, 'ylim');
                                    ylim2=buffer1(2);
                                    
                                    wb_th_array(m1+ha_chan2{e3}(e4))=text( max_t-0.02*(max_t-min_t), -0.98*ylim2, ['Accel ', num2str(ha_accel_num_buf), ' ', ax_string(ha_axes2{e3}(e4)), ' '], 'Fontsize', 10, 'Color', [0 0 0], 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', 'BackgroundColor', 'none' );
                                    
                                    vibs2=vibs(ha_chan2{e3}(e4), x3(2*e2-1):x3(2*e2));
                                    
                                    % Hand Arm vibrations analysis
                                    
                                    dt_vibs=(t_vibs(2)-t_vibs(1));
                                    Fs=1/dt_vibs;
                                    ha_num_axes=length(ha_chan2{e3});
                                    
                                    if ha_num_axes == 1
                                        ha_scale=sqrt(3);
                                    elseif ha_num_axes == 2
                                        ha_scale=sqrt(2);
                                    else
                                        ha_scale=1;
                                    end
                                    
                                    
                                    % Apply the hand arm filter
                                    % coefficients to the time records
                                    [vibs2hw_ha]=hand_arm_time_fil(vibs2, Fs, resample_filter);
                                    
                                    % Calculate the hand arm vibration
                                    % metrics
                                    [awrms, awrms8h, Dy, Dy_50, awhr4, awhr4_8h, Dy4, Dy4_50, peak_a, crest_factor, awhkurtosis, arms, arms8h, Dyun, Dyun_50, ahr4, ahr4_8h, Dy4un, Dy4un_50, peak_aun, crest_factorun, akurtosis]=vibs_calc_hand_arm(ha_scale*vibs2hw_ha, vibs2, Fs);
                                    
                                    
                                    % Calculate the one-third octave linear time average levels and peak levels.
                                    %
                                    N_vibs=3;
                                    sensor=2;
                                    settling_time=1;
                                    filter_program=2;
                                    method=1;
                                    fil_order=3;
                                    
                                    if isequal(filter_approach, 1)
                                        [fc_out, vibs_levels, vibs_peak_levels]=fourier_nth_oct_time_filter3(vibs2hw_ha, Fs, N_vibs, fc_ha_vibs, sensor, method, fil_order);
                                    else
                                        [fc_out, vibs_levels, vibs_peak_levels]=Nth_oct_time_filter2(vibs2hw_ha, Fs,   num_x_filter_vibs_ha, N_vibs, fc_ha_vibs, sensor, settling_time, filter_program, resample_filter);
                                    end
                                    
                                    % Combine the metrics into an array
                                    data_buf(e4, :)=[awrms, awrms8h, Dy, Dy_50, awhr4, awhr4_8h, Dy4, Dy4_50, peak_a, crest_factor, awhkurtosis, arms, arms8h, Dyun, Dyun_50, ahr4, ahr4_8h, Dy4un, Dy4un_50, peak_aun, crest_factorun, akurtosis];
                                    data_buf3(e4, :)=[vibs_peak_levels, vibs_levels ];
                                    
                                    % Print the values of the metrics to
                                    % the output file
                                    if length(ha_chan2{e3}) > 1
                                        fprintf(fid_vibs, '\tHand Arm\t');
                                    else
                                        fprintf(fid_vibs, '\tTotal\t');
                                    end
                                    
                                    
                                    fprintf(fid_vibs, [num2str(ha_chan2{e3}(e4)), '\t%i\t', ax_string(ha_axes2{e3}(e4)) ,'\t%f\t%i\t%f\t%f\t'], [ha_accel_num_buf, ha_scale, e2, t_vibs((x3(2*e2-1))), t_vibs(x3(2*e2))]);
                                    
                                    % Concatenate the metrics
                                    metrics_buf=[data_buf(e4, :) data_buf3(e4, :)];
                                    
                                    % Print the sound metrics to a text files
                                    [A2, A_str]=m_round(metrics_buf, round_kind_vibs_ha, round_digits_vibs_ha );
                                    
                                    for e5=1:length(A_str);
                                        
                                        fprintf(fid_vibs, '%s\t', A_str{e5});
                                        
                                    end
                                    
                                    
                                    fprintf(fid_vibs, '\r\n');
                                    
                                    vibras_ha{Selection, var_sel, e3}.scaling_factor=ha_scale;
                                    vibras_ha{Selection, var_sel, e3}.metrics(e2, e4, :)=[ha_chan2{e3}(e4), ha_accel_num_buf, ha_axes2{e3}(e4), ha_scale, e2, t_vibs((x3(2*e2-1))), t_vibs(x3(2*e2)), data_buf(e4, :), data_buf3(e4, :)];
                                    
                                end
                                
                                if length(ha_chan2{e3}) > 1
                                    % Combine vibrations metrics in different directions very carefully
                                    [data_buf2]=combine_accel_directions_ha(data_buf);
                                    % Analyze and Print total values for the accelerometer
                                    fprintf(fid_vibs, ['\tTotal \t', num2str(ha_chan2{e3}(1:end)), '\t%i\t', ax_string(ha_axes2{e3}(1:end)) ,'\t%f\t%i\t%f\t%f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t'], [ha_accel_num_buf, 1, e2, t_vibs((x3(2*e2-1))), t_vibs(x3(2*e2)), data_buf2]');
                                    
                                    % Print the total third octave
                                    % vibrations data
                                    data_buf4=sqrt(sum(data_buf3.^2, 1));
                                    
                                    [A2, buffer]=sd_round(data_buf4, 3);
                                    for e5=1:length(buffer);
                                        fprintf(fid_vibs, '%s\t', buffer{e5});
                                    end
                                    
                                    fprintf(fid_vibs, '\r\n');
                                    
                                    vibras_ha{Selection, var_sel, e3}.total_metrics(e2, :)=[-1, ha_accel_num_buf, -1, ha_scale, e2, t_vibs((x3(2*e2-1))), t_vibs(x3(2*e2)), data_buf2, data_buf4];
                                    
                                end
                                
                                fprintf(fid_vibs, '\r\n');
                                
                            end
                            fprintf(fid_vibs, '\r\n');
                            
                            fprintf(fid_vibs, '%s\r\n', ['Hand-Arm Vibrations Metrics for Accel ', num2str(ha_accel_num_buf), ' all Channels']);
                            
                            % Do not use absolute value
                            abs_rta=0;
                            % Do not use absolute value
                            abs_other=[];
                            
                            row_names={'Channel Number'};
                            row_unit='';
                            col_name='Range Number';
                            
                            
                            % Outliers are identified for all
                            % metric arrays independently.
                            dep_var=0;
                            
                            metric_str2=cell(num_ha_vibs_metrics+1, 1);
                            metric_units2=cell(num_ha_vibs_metrics+1, 1);
                            
                            metric_str2{1}=vibs_ha_metric_str{8};
                            metric_units2{1}=vibs_ha_metric_units{8};
                            
                            for e4=1:num_ha_vibs_metrics;
                                metric_str2{e4+1}=vibs_ha_metric_str{e4};
                                metric_units2{e4+1}=vibs_ha_metric_units{e4};
                            end
                            round_kind_vibs_ha2=[1 round_kind_vibs_ha, round_kind_vibs_ha];
                            round_digits_vibs_ha2=[3 round_digits_vibs_ha, round_digits_vibs_ha];
                            dB_or_linear_ha=zeros(size(round_digits_vibs_ha2));
                            
                            function_str='data_outliers3(dB_or_linear_ha, vibras_ha{Selection, var_sel, e3}.metrics(:, :, 8)'', dep_var, round_kind_vibs_ha2, round_digits_vibs_ha2, abs_rta, abs_other, sod, fid_vibs, 1, row_names, row_unit, col_name, metric_str2, metric_units2';
                            
                            for e4=1:num_ha_vibs_metrics;
                                function_str=[function_str, ', squeeze(vibras_ha{Selection, var_sel, e3}.metrics(:, :, ', num2str(e4), '))'''];
                            end
                            
                            function_str=[function_str,' )'];
                            
                            [ptsa, nptsa, rt_stats, ha_other_stats, ha_rt_outlier_stats, ha_other_outlier_stats]=eval(function_str);
                            
                            fprintf(fid_vibs, '\r\n%s\r\n', ['Hand-Arm Vibrations Total Metrics for Accel ', num2str(ha_accel_num_buf)]);
                            
                            
                            function_str='data_outliers3(dB_or_linear_ha, vibras_ha{Selection, var_sel, e3}.total_metrics(:, 8)'', dep_var, round_kind_vibs_ha2, round_digits_vibs_ha2, abs_rta, abs_other, sod, fid_vibs, 1, row_names, row_unit, col_name, metric_str2, metric_units2';
                            
                            for e4=1:num_ha_vibs_metrics;
                                function_str=[function_str, ', vibras_ha{Selection, var_sel, e3}.total_metrics(:, ', num2str(e4), ')'''];
                            end
                            
                            function_str=[function_str,' )'];
                            
                            [ptsa, nptsa, rt_stats, ha_total_other_stats, ha_rt_total_outlier_stats, ha_other_total_outlier_stats]=eval(function_str);
                            
                            % md stands for "metrics description"
                            md=cell(2, length(vibs_ha_metric_str));
                            
                            for e2=1:num_ha_vibs_metrics;
                                md{1, e2}=vibs_ha_metric_str{e2};
                                md{2, e2}=vibs_ha_metric_units{e2};
                            end
                            
                            vibras_ha{Selection, var_sel, e3}.filename=filenamesin{Selection};
                            vibras_ha{Selection, var_sel, e3}.variable=var_sel;
                            vibras_ha{Selection, var_sel, e3}.stats_of_metrics=ha_other_stats;
                            vibras_ha{Selection, var_sel, e3}.stats_of_outlier_metrics=ha_other_outlier_stats;
                            vibras_ha{Selection, var_sel, e3}.metrics_description=md;
                            vibras_ha{Selection, var_sel, e3}.stats_description=stat_str;
                            vibras_ha{Selection, var_sel, e3}.stats_of_total_metrics=ha_total_other_stats;
                            vibras_ha{Selection, var_sel, e3}.stats_of_total_outlier_metrics=ha_other_total_outlier_stats;
                            vibras_ha{Selection, var_sel, e3}.data_type='Continuous_Vibrations';
                            vibras_ha{Selection, var_sel, e3}.third_oct_freq=fc_ha_vibs;
                            
                        end
                    end
                    
                    % ***********************************************
                    %
                    % Finished calculating all hand-arm vibration metrics
                    %
                    % ***********************************************
                    
                    
                    % ***********************************************
                    %
                    % Process the Whole Body Vibrations Accelerometers
                    %
                    % ***********************************************
                    
                    %Conditional Statement for Whole Body Vibrations
                    if (k5 == 2 || k5 == 3) && logical(num_accels > 0)
                        
                        % Configure Whole body vibrations
                        % Currently thereare seven possibilities
                        str = { 'Standing', 'Seated (Health)', 'Seated (Comfort)', 'Laying On Back (Recumbent)', 'Rotational on Supporting Seat', 'Rotational on Seated Backrest', 'Rotational on Feet', 'Motion sickness' };
                        
                        ms_type=8;
                        
                        if flag200 == 1
                            [wb_chan2, wb_axes2, wb_accels2, num_wb_accels2]=config_wb_accels(ax_string, num_accels, accel_num_chan, axis_chan_ix, chann_p_accel);
                            for e3=1:num_wb_accels2;
                                [select_wb,ok] = listdlg('Name', 'Whole Body Vibrations', 'PromptString', {['Accel ' num2str(wb_accels2(e3)), ' Select all Applicable Postures'],' for Whole Body Vibration.'},'SelectionMode','multiple','ListString',str, 'ListSize', [500, 500]);
                                type_selection{e3}=select_wb;
                            end
                            flag200= menu('Whatcha Wanna Do?', 'Configure Whole Body Accelerometers each time', 'Keep Whole Body Accelerometer Configuration');
                        end
                        
                        
                        max_num_postures=1;
                        ep=0;
                        
                        % Determine the maximum number of postures
                        %
                        % indexing each accelerometer
                        for e3=1:num_wb_accels2;
                            
                            posture_array=type_selection{e3};
                            max_num_postures=max([max_num_postures, length(posture_array)]);
                            if isempty(posture_array)
                                ep=max([ep, 1]);
                                max_num_postures=max([max_num_postures, 1]);
                            end
                            
                        end
                        
                        
                        % Initialize the output cell arrays of metrics
                        % for the motion sickness
                        if ismember(ms_type, posture_array)
                            
                            if isequal(flag_vibs_ms_first, 1)
                                flag_vibs_ms_first=0;
                                vibras_ms=cell(length(filenamesin), var_sel, num_wb_accels2);
                            end
                            
                        end
                        
                        
                        % Initialize the output cell arrays of metrics
                        % for the whole body vibrations
                        if any(ismember(1:6, posture_array)) || isequal(ep, 1)
                            
                            if isequal(flag_vibs_wb_first, 1)
                                flag_vibs_wb_first=0;
                                vibras_wb=cell(length(filenamesin), var_sel, num_wb_accels2, max_num_postures);
                            end
                            
                        end
                        
                        
                        % Process Whole Body Vibrations Data
                        for e3=1:num_wb_accels2;  % indexing each accelerometer
                            
                            posture_array=type_selection{e3};
                            wb_accel_num_buf=wb_accels2(e3);
                            
                            if ok == 0
                                if k5 == 3
                                    k5=2;
                                    type_selection{e3}=[1];
                                    posture_array=[1];
                                else
                                    k5=4;
                                end
                            end
                            
                            
                            num_postures=length(posture_array);
                            
                            % indexing each posture selected
                            for e4=1:num_postures;
                                
                                type=posture_array(e4);
                                
                                if type < ms_type
                                    vibras_wb{Selection, var_sel, e3, e4}.total_metrics=zeros(num_ranges_vibs, num_wb_vibs_metrics);
                                else
                                    vibras_ms{Selection, var_sel, e3}.total_metrics=zeros(num_ranges_vibs, num_vibs_ms_metrics);
                                end
                                
                                if type < ms_type
                                    fprintf(fid_vibs, ['\tAccel ' num2str(wb_accel_num_buf), ' Whole Body \r\n']);
                                else
                                    fprintf(fid_vibs, ['\tAccel ' num2str(wb_accel_num_buf), ' Motion Sickness \r\n']);
                                end
                                
                                % Print the metrics descriptions and units
                                % For whole body vibrations and motion
                                % sickness
                                if num_ranges_vibs >= 1
                                    
                                    if type < ms_type
                                        
                                        for e6=1:length(vibs_wb_metric_str);
                                            fprintf(fid_vibs, '\t%s', vibs_wb_metric_str{e6});
                                        end
                                        fprintf(fid_vibs, '\r\n');
                                        
                                        for e6=1:length(vibs_wb_metric_str);
                                            fprintf(fid_vibs, '\t%s', vibs_wb_metric_units{e6});
                                        end
                                        
                                        fprintf(fid_vibs, '\r\n');
                                        
                                    else
                                        
                                        for e6=1:length(vibs_ms_metric_str);
                                            fprintf(fid_vibs, '\t%s', vibs_ms_metric_str{e6});
                                        end
                                        fprintf(fid_vibs, '\r\n');
                                        
                                        for e6=1:length(vibs_ms_metric_str);
                                            fprintf(fid_vibs, '\t%s', vibs_ms_metric_units{e6});
                                        end
                                        
                                        fprintf(fid_vibs, '\r\n');
                                        
                                    end
                                    
                                end
                                
                                % Initialize the output cell array for
                                % whole body vibrations and mnotion
                                % sickness.
                                if type < ms_type
                                    vibras_wb{Selection, var_sel, e3, e4}.metrics=zeros(num_ranges_vibs, length(wb_chan2{e3}), num_wb_vibs_metrics);
                                else
                                    vibras_ms{Selection, var_sel, e3}.metrics=zeros(num_ranges_vibs, length(wb_chan2{e3}), num_vibs_ms_metrics);
                                end
                                
                                
                                % indexing range number
                                for e2=1:num_ranges_vibs;
                                    
                                    if type < ms_type
                                        data_buf2=zeros(length(wb_chan2{e3}), num_vibs_wb_simple_metrics-8);
                                        data_buf3=zeros(length(wb_chan2{e3}), 2*num_bands_vibs_wb);
                                    else
                                        data_buf2=zeros(length(wb_chan2{e3}), num_vibs_ms_simple_metrics-8);
                                        data_buf3=zeros(length(wb_chan2{e3}), 2*num_bands_vibs_ms);
                                    end
                                    
                                    % indexing each channel selected
                                    for e5=1:length(wb_chan2{e3});
                                        
                                        if posture_array(e4) >= 1 && logical(posture_array(e4) <= ms_type)
                                            
                                            axis_desig=wb_axes2{e3}(e5);
                                            
                                            % For motion sickness, only the
                                            % z-axis (up and down motion)
                                            % has formulas.
                                            %
                                            % If given data in the x or y
                                            % axis directions, then the
                                            % formula for motion sickness due to acceleration
                                            % in the z-axis is applied.
                                            
                                            axes(h2(m1+wb_chan2{e3}(e5)));
                                            delete(wb_th_array(m1+wb_chan2{e3}(e5)));
                                            
                                            buffer1=get(gca, 'ylim');
                                            ylim2=buffer1(2);
                                            
                                            wb_th_array(m1+wb_chan2{e3}(e5))=text( max_t-0.02*(max_t-min_t), -0.98*ylim2, ['Accel ', num2str(wb_accel_num_buf), ' ', ax_string(axis_desig), ' '], 'Fontsize', 10, 'Color', [0 0 0], 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', 'BackgroundColor', 'none' );
                                            
                                            dt_vibs=(t_vibs(2)-t_vibs(1));
                                            Fs=1/dt_vibs;
                                            
                                            vibs2=vibs(wb_chan2{e3}(e5), x3(2*e2-1):x3(2*e2));
                                            
                                            % recumbent position indicator:
                                            % 1 means pelvis, 2 means head.  important with posture type 4
                                            rpo=1;
                                            
                                            % Calculate the filter
                                            % coefficients for the whole
                                            % body vibrations
                                            [filtercoeffs, filter_types, scaling_factors]=whole_body_filter(Fs, type, rpo);
                                            
                                            % Apply the filter coefficients
                                            % for the
                                            if type < ms_type
                                                settling_time=2;
                                            else
                                                settling_time=10;
                                            end
                                            
                                            % Process the vibrations time
                                            % record through the
                                            % appropriate whole body
                                            % vibrations filters.
                                            [vibs2_hw_wb, filtercoeffs, filter_types, scaling_factors]=whole_body_time_filter(vibs2, Fs, type, rpo, filtercoeffs, filter_types, scaling_factors, axis_desig, settling_time, resample_filter);
                                            
                                            % Calculate the whole body metrics
                                            [arms, arms8h, VDV, awhr4, awhr4_8h, peak_a, crest_factor, awhkurtosis, MSDV, armsun, arms8hun, VDVun, ahr4un, ahr4_8hun, peak_aun, crest_factorun, awhkurtosisun, MSDVun]=vibs_calc_whole_body(vibs2_hw_wb, vibs2, Fs);
                                            
                                            % Calculate the one-third octave linear time average levels and peak levels.
                                            % Run the third octave band fitler twice.
                                            %
                                            % Calculate the third octave
                                            % band peaks and levels
                                            N_vibs_wb=3;
                                            sensor=2;
                                            filter_program=2;
                                            method=1;
                                            fil_order=3;
                                            
                                            
                                            if type < ms_type
                                                if isequal(filter_approach, 1)
                                                    [fc_out, vibs_levels, vibs_peak_levels]=fourier_nth_oct_time_filter3(vibs2_hw_wb, Fs, N_vibs_wb, fc_vibs_wb, sensor, method, fil_order);
                                                else
                                                    settling_time=2;
                                                    [fc_out, vibs_levels, vibs_peak_levels]=Nth_oct_time_filter2(vibs2_hw_wb, Fs, num_x_filter_vibs_wb, N_vibs_wb, fc_vibs_wb, sensor, settling_time, filter_program, resample_filter);
                                                end
                                                
                                            else
                                                
                                                if isequal(filter_approach, 1)
                                                    [fc_out, vibs_levels, vibs_peak_levels]=fourier_nth_oct_time_filter3(vibs2_hw_wb, Fs, N_vibs_ms, fc_vibs_ms, sensor, method, fil_order);
                                                else
                                                    settling_time=10;
                                                    [fc_out, vibs_levels, vibs_peak_levels]=Nth_oct_time_filter2(vibs2_hw_wb, Fs, num_x_filter_vibs_ms, N_vibs_ms, fc_vibs_ms, sensor, settling_time, filter_program, resample_filter);
                                                end
                                                
                                            end
                                            
                                            
                                            
                                            sc=scaling_factors(1 , axis_desig);
                                            ssf=size(scaling_factors);
                                            
                                            sc_str=num2str(scaling_factors(1 , axis_desig));
                                            
                                            if sc == 0 && ssf(1) > 1
                                                sc_str=num2str(scaling_factors(2 , axis_desig));
                                                sc=scaling_factors(2 , axis_desig);
                                            end
                                            
                                            % Save metrics to a buffer
                                            if type < ms_type
                                                data_buf2(e5, :)=[arms, arms8h, VDV, awhr4, awhr4_8h, peak_a, crest_factor, awhkurtosis, armsun, arms8hun, VDVun, ahr4un, ahr4_8hun, peak_aun, crest_factorun, awhkurtosisun];
                                            else
                                                data_buf2(e5, :)=[arms, arms8h, VDV, awhr4, awhr4_8h, peak_a, crest_factor, awhkurtosis, MSDV, armsun, arms8hun, VDVun, ahr4un, ahr4_8hun, peak_aun, crest_factorun, awhkurtosisun, MSDVun];
                                            end
                                            
                                            
                                            % Save third octave band peaks and levels to a buffer
                                            data_buf3(e5, :)=[vibs_peak_levels, vibs_levels];
                                            
                                            
                                            % Save metrics to a buffer
                                            if length(wb_chan2{e3}) > 1
                                                
                                                % Concatenate the metrics
                                                metrics_buf=[e4, wb_chan2{e3}(e5), wb_accel_num_buf, axis_desig, sc, e2, t_vibs((x3(2*e2-1))), t_vibs(x3(2*e2)), data_buf2(e5, :), data_buf3(e5, :)];
                                                
                                                % Apply appropriate rounding to metrics
                                                if type < ms_type
                                                    [A2, A_str]=m_round(metrics_buf, round_kind_vibs_wb, round_digits_vibs_wb );
                                                else
                                                    [A2, A_str]=m_round(metrics_buf, round_kind_vibs_ms, round_digits_vibs_ms );
                                                end
                                                
                                                % Append metrics data to the
                                                % output cell arrays
                                                if type < ms_type
                                                    %fprintf(fid_vibs, ['\t', str{type},'\t%i\t%i\t', ax_string(axis_desig), '\t',sc_str , '\t%i\t%f\t%f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f'], [wb_chan2{e3}(e5), wb_accel_num_buf, e2, t_vibs((x3(2*e2-1))), t_vibs(x3(2*e2)), data_buf2(e5, :)]');
                                                    vibras_wb{Selection, var_sel, e3, e4}.metrics(e2, e5, :)=A2;
                                                    vibras_wb{Selection, var_sel, e3, e4}.scaling_factor(e5)=metrics_buf(5);
                                                else
                                                    %fprintf(fid_vibs, ['\t', str{type},'\t%i\t%i\t', ax_string(ones(1, length(axis_desig))), '\t',sc_str , '\t%i\t%f\t%f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f'], [wb_chan2{e3}(e5), wb_accel_num_buf, e2, t_vibs((x3(2*e2-1))), t_vibs(x3(2*e2)), data_buf2(e5, :)]');
                                                    vibras_ms{Selection, var_sel, e3}.metrics(e2, e5, :)=A2;
                                                    vibras_ms{Selection, var_sel, e3}.scaling_factor(e5)=metrics_buf(5);
                                                end
                                                
                                                
                                                % Print the vibrations
                                                % metrics to a text file
                                                fprintf(fid_vibs, ['\t', str{type}, '\t']);
                                                
                                                for e6=1:length(A_str);
                                                    if isequal(e6, 3)
                                                        if type < ms_type
                                                            fprintf(fid_vibs, [ax_string(axis_desig), '\t', sc_str]);
                                                        else
                                                            fprintf(fid_vibs, [ax_string(ones(1, length(axis_desig))), '\t', sc_str] );
                                                        end
                                                        
                                                    end
                                                    
                                                    if ~ismember(e6, [1, 4, 5])
                                                        fprintf(fid_vibs, '\t%s', A_str{e6});
                                                    end
                                                    
                                                end
                                                fprintf(fid_vibs, '\t\r\n');
                                                
                                            else
                                                data_buf4=sqrt(sum(data_buf3.^2, 1));
                                                
                                                % Make sure data_buf4 has
                                                % the correct orientation
                                                if size(data_buf4, 1) > size(data_buf4, 2)
                                                    data_buf4=data_buf4';
                                                end
                                                
                                                % Make sure data_buf4 has
                                                % the correct orientation
                                                if size(data_buf2, 1) > size(data_buf2, 2)
                                                    data_buf2=data_buf2';
                                                end
                                                
                                                % Make sure data_buf4 has
                                                % the correct orientation
                                                if size(data_buf3, 1) > size(data_buf3, 2)
                                                    data_buf3=data_buf3';
                                                end
                                                
                                                % Concatenate the metrics
                                                total_metrics_buf=[e4, wb_chan2{e3}(e5), wb_accel_num_buf, axis_desig, sc, e2, t_vibs((x3(2*e2-1))), t_vibs(x3(2*e2)), data_buf2, data_buf4];
                                                metrics_buf=[e4, wb_chan2{e3}(e5), wb_accel_num_buf, axis_desig, sc, e2, t_vibs((x3(2*e2-1))), t_vibs(x3(2*e2)), data_buf2(e5, :), data_buf3(e5, :)];
                                                
                                                if type < ms_type
                                                    [total_A2, total_A_str]=m_round(total_metrics_buf, round_kind_vibs_wb, round_digits_vibs_wb );
                                                    [A2, A_str]=            m_round(metrics_buf, round_kind_vibs_wb, round_digits_vibs_wb );
                                                else
                                                    [total_A2, total_A_str]=m_round(total_metrics_buf, round_kind_vibs_ms, round_digits_vibs_ms );
                                                    [A2, A_str]            =m_round(metrics_buf, round_kind_vibs_ms, round_digits_vibs_ms );
                                                end
                                                
                                                % Append the vibrations
                                                % metrics to the output
                                                % cell arrays.
                                                if type < ms_type
                                                    %fprintf(fid_vibs, ['\tTotal ', str{type}, '\t', num2str(wb_chan2{e3}(1:end)), '\t%i\t', ax_string(wb_axes2{e3}(1:end)) ,'\t', sc_str, '\t%i\t%f\t%f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f'], [wb_accel_num_buf, e2, t_vibs((x3(2*e2-1))), t_vibs(x3(2*e2)), data_buf2]');
                                                    vibras_wb{Selection, var_sel, e3, e4}.total_metrics(e2, :)=total_A2;
                                                    vibras_wb{Selection, var_sel, e3, e4}.metrics(e2, e5, :)=A2;
                                                    vibras_wb{Selection, var_sel, e3, e4}.scaling_factor(e5)=A2(5);
                                                    
                                                else
                                                    %fprintf(fid_vibs, ['\tTotal ', str{type}, '\t', num2str(wb_chan2{e3}(1:end)), '\t%i\t', ax_string(ones(1, length(wb_axes2{e3}(1:end)))) ,'\t', sc_str, '\t%i\t%f\t%f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f'], [wb_accel_num_buf, e2, t_vibs((x3(2*e2-1))), t_vibs(x3(2*e2)), data_buf2]');
                                                    vibras_ms{Selection, var_sel, e3}.total_metrics(e2, :)=total_A2;
                                                    vibras_ms{Selection, var_sel, e3}.metrics(e2, e5, :)=A2;
                                                    vibras_ms{Selection, var_sel, e3}.scaling_factor(e5)=A2(5);
                                                end
                                                
                                                
                                                % Print the vibrations metrics
                                                % to a text files
                                                fprintf(fid_vibs, ['\tTotal ', str{type}, '\t']);
                                                
                                                for e6=1:length(total_A_str);
                                                    
                                                    if isequal(e6, 2)
                                                        fprintf(fid_vibs, ['\t', num2str(wb_chan2{e3}(1:end))]);
                                                    end
                                                    
                                                    if isequal(e6, 3)
                                                        if type < ms_type
                                                            fprintf(fid_vibs, [ax_string(wb_axes2{e3}(1:end)), '\t', sc_str]);
                                                        else
                                                            fprintf(fid_vibs, [ax_string(ones(1, length(wb_axes2{e3}(1:end)))), '\t', sc_str] );
                                                        end
                                                        
                                                    end
                                                    
                                                    if ~ismember(e6, [1, 2, 4, 5])
                                                        fprintf(fid_vibs, '\t%s', total_A_str{e6});
                                                    end
                                                    
                                                end
                                                
                                                fprintf(fid_vibs, '\t\r\n');
                                            end
                                            
                                        end
                                    end
                                    
                                    
                                    % analyze and print the total values
                                    
                                    if length(wb_chan2{e3}) > 1
                                        
                                        % Combine vibrations metrics in different directions very carefully
                                        [data_buf2]=combine_accel_directions_wb(data_buf2, type);
                                        data_buf4=sqrt(sum(data_buf3.^2, 1));
                                        
                                        % Make sure data_buf4 has
                                        % the correct orientation
                                        if size(data_buf4, 1) > size(data_buf4, 2)
                                            data_buf4=data_buf4';
                                        end
                                        
                                        % Make sure data_buf2 has
                                        % the correct orientation
                                        if size(data_buf2, 1) > size(data_buf2, 2)
                                            data_buf2=data_buf2';
                                        end
                                        
                                        
                                        % Concatenate the metrics
                                        total_metrics_buf=[e4, -1, wb_accel_num_buf, -1, -1, e2, t_vibs((x3(2*e2-1))), t_vibs(x3(2*e2)), data_buf2, data_buf4];
                                        
                                        if type < ms_type
                                            [total_A2, total_A_str]=m_round(total_metrics_buf, round_kind_vibs_wb, round_digits_vibs_wb );
                                        else
                                            [total_A2, total_A_str]=m_round(total_metrics_buf, round_kind_vibs_ms, round_digits_vibs_ms );
                                        end
                                        
                                        % Append the vibrations
                                        % metrics to the output
                                        % cell arrays.
                                        if type < ms_type
                                            vibras_wb{Selection, var_sel, e3, e4}.total_metrics(e2, :)=total_A2;
                                        else
                                            vibras_ms{Selection, var_sel, e3}.total_metrics(e2, :)=total_A2;
                                        end
                                        
                                        
                                        % Print the vibrations metrics
                                        % to a text files
                                        fprintf(fid_vibs, ['\tTotal ', str{type}, '\t']);
                                        
                                        for e6=1:length(total_A_str);
                                            
                                            if isequal(e6, 2)
                                                fprintf(fid_vibs, ['\t', num2str(wb_chan2{e3}(1:end))]);
                                            end
                                            
                                            if isequal(e6, 3)
                                                if type < ms_type
                                                    fprintf(fid_vibs, [ax_string(wb_axes2{e3}(1:end)), '\t', sc_str]);
                                                else
                                                    fprintf(fid_vibs, [ax_string(ones(1, length(wb_axes2{e3}(1:end)))), '\t', sc_str] );
                                                end
                                                
                                            end
                                            
                                            if ~ismember(e6, [1, 2, 4, 5])
                                                fprintf(fid_vibs, '\t%s', total_A_str{e6});
                                            end
                                            
                                        end
                                        
                                        
                                        fprintf(fid_vibs, '\t\r\n');
                                        fprintf(fid_vibs, '\t\r\n');
                                    end
                                    fprintf(fid_vibs, '\r\n');
                                    
                                end
                                
                                
                                % Do not use absolute value
                                abs_rta=0;
                                % Do not use absolute value
                                abs_other=[];
                                
                                row_names={'Channel Number'};
                                row_unit='';
                                col_name='Range Number';
                                
                                
                                if type < ms_type
                                    
                                    fprintf(fid_vibs, '%s\r\n', ['Whole Body Vibrations Metrics for Accel ', num2str(wb_accel_num_buf), ' all Channels']);
                                    
                                    % Outliers are identified for all
                                    % metric arrays independently.
                                    dep_var=0;
                                    
                                    metric_str2=cell(num_wb_vibs_metrics+1, 1);
                                    metric_units2=cell(num_wb_vibs_metrics+1, 1);
                                    
                                    metric_str2{1}=vibs_wb_metric_str{9};
                                    metric_units2{1}=vibs_wb_metric_units{9};
                                    
                                    for e2=1:num_wb_vibs_metrics;
                                        metric_str2{e2+1}=vibs_wb_metric_str{e2};
                                        metric_units2{e2+1}=vibs_wb_metric_units{e2};
                                    end
                                    
                                    round_kind_vibs_wb2=[1 round_kind_vibs_wb];
                                    round_digits_vibs_wb2=[3 round_digits_vibs_wb];
                                    dB_or_linear_wb=zeros(size(round_digits_vibs_wb2));
                                    
                                    function_str='data_outliers3(dB_or_linear_wb, squeeze(vibras_wb{Selection, var_sel, e3, e4}.metrics(:,:, 9))'', dep_var, round_kind_vibs_wb2, round_digits_vibs_wb2, abs_rta, abs_other, sod, fid_vibs, 1, row_names, row_unit, col_name, metric_str2, metric_units2';
                                    
                                    for e5=1:num_wb_vibs_metrics;
                                        function_str=[function_str, ', squeeze(vibras_wb{Selection, var_sel, e3, e4}.metrics(:, :, ', num2str(e5), '))'''];
                                    end
                                    
                                    function_str=[function_str,' )'];
                                    
                                    [ptsa, nptsa, rt_stats, wb_other_stats, wb_rt_outlier_stats, wb_other_outlier_stats]=eval(function_str);
                                    
                                    fprintf(fid_vibs, '\r\n%s\r\n', ['Whole Body Vibrations Total Metrics for Accel ', num2str(wb_accel_num_buf)]);
                                    
                                    
                                    function_str='data_outliers3(dB_or_linear_wb, vibras_wb{Selection, var_sel, e3, e4}.total_metrics(:, 9)'', dep_var, round_kind_vibs_wb2, round_digits_vibs_wb2, abs_rta, abs_other, sod, fid_vibs, 1, row_names, row_unit, col_name, metric_str2, metric_units2';
                                    
                                    for e5=1:num_wb_vibs_metrics;
                                        function_str=[function_str, ', vibras_wb{Selection, var_sel, e3, e4}.total_metrics(:, ', num2str(e5), ')'''];
                                    end
                                    
                                    function_str=[function_str,' )'];
                                    
                                    [ptsa, nptsa, rt_stats, wb_total_other_stats, wb_rt_total_outlier_stats, wb_other_total_outlier_stats]=eval(function_str);
                                    
                                    md=cell(2, length(vibs_wb_metric_str));
                                    
                                    for e2=1:num_wb_vibs_metrics;
                                        md{1, e2}=vibs_wb_metric_str{e2};
                                        md{2, e2}=vibs_wb_metric_units{e2};
                                    end
                                    
                                    vibras_wb{Selection, var_sel, e3, e4}.filename=filenamesin{Selection};
                                    vibras_wb{Selection, var_sel, e3, e4}.variable=var_sel;
                                    vibras_wb{Selection, var_sel, e3, e4}.stats_of_metrics=wb_other_stats;
                                    vibras_wb{Selection, var_sel, e3, e4}.stats_of_outlier_metrics=wb_other_outlier_stats;
                                    vibras_wb{Selection, var_sel, e3, e4}.stats_of_total_metrics=wb_total_other_stats;
                                    vibras_wb{Selection, var_sel, e3, e4}.stats_of_total_outlier_metrics=wb_other_total_outlier_stats;
                                    vibras_wb{Selection, var_sel, e3, e4}.metrics_description=md;
                                    vibras_wb{Selection, var_sel, e3, e4}.stats_description=stat_str;
                                    vibras_wb{Selection, var_sel, e3, e4}.data_type='Continuous_Vibrations';
                                    vibras_wb{Selection, var_sel, e3, e4}.exposure_type='Whole Body';
                                    vibras_wb{Selection, var_sel, e3, e4}.posture=posture{type};
                                    vibras_wb{Selection, var_sel, e3, e4}.third_oct_freq=fc_vibs_wb;
                                    
                                else
                                    
                                    fprintf(fid_vibs, '%s\r\n', ['Motion Sickness Vibrations Metrics for Accel ', num2str(wb_accel_num_buf), ' all Channels']);
                                    
                                    
                                    % Outliers are identified for all
                                    % metric arrays independently.
                                    dep_var=0;
                                    
                                    metric_str2=cell(num_vibs_ms_metrics+1, 1);
                                    metric_units2=cell(num_vibs_ms_metrics+1, 1);
                                    
                                    metric_str2{1}=vibs_ms_metric_str{9};
                                    metric_units2{1}=vibs_ms_metric_units{9};
                                    
                                    for e2=1:num_vibs_ms_metrics;
                                        metric_str2{e2+1}=vibs_ms_metric_str{e2};
                                        metric_units2{e2+1}=vibs_ms_metric_units{e2};
                                    end
                                    
                                    round_kind_vibs_ms2=[1 round_kind_vibs_ms];
                                    round_digits_vibs_ms2=[3 round_digits_vibs_ms];
                                    dB_or_linear_ms=zeros(size(round_digits_vibs_ms2));
                                    
                                    function_str='data_outliers3(dB_or_linear_ms, squeeze(vibras_ms{Selection, var_sel, e3}.metrics(:, :, 9))'', dep_var, round_kind_vibs_ms2, round_digits_vibs_ms2, abs_rta, abs_other, sod, fid_vibs, 1, row_names, row_unit, col_name, metric_str2, metric_units2';
                                    
                                    for e5=1:num_vibs_ms_metrics;
                                        function_str=[function_str, ', squeeze(vibras_ms{Selection, var_sel, e3}.metrics(:, :, ', num2str(e5), '))'''];
                                    end
                                    
                                    function_str=[function_str,' )'];
                                    
                                    [ptsa, nptsa, rt_stats, ms_other_stats, ms_rt_outlier_stats, ms_other_outlier_stats]=eval(function_str);
                                    
                                    fprintf(fid_vibs, '\r\n%s\r\n', ['Motion Sickness Vibrations Total Metrics for Accel ', num2str(wb_accel_num_buf)]);
                                    
                                    function_str='data_outliers3(dB_or_linear_ms, vibras_ms{Selection, var_sel, e3}.total_metrics(:, 9)'', dep_var, round_kind_vibs_ms2, round_digits_vibs_ms2, abs_rta, abs_other, sod, fid_vibs, 1, row_names, row_unit, col_name, metric_str2, metric_units2';
                                    
                                    for e5=1:num_vibs_ms_metrics;
                                        function_str=[function_str, ', vibras_ms{Selection, var_sel, e3}.total_metrics(:, ', num2str(e5), ')'''];
                                    end
                                    
                                    function_str=[function_str,' )'];
                                    
                                    [ptsa, nptsa, rt_stats, ms_total_other_stats, ms_rt_total_outlier_stats, ms_other_total_outlier_stats]=eval(function_str);
                                    
                                    md=cell(2, length(vibs_ms_metric_str));
                                    
                                    for e2=1:num_vibs_ms_metrics;
                                        md{1, e2}=vibs_ms_metric_str{e2};
                                        md{2, e2}=vibs_ms_metric_units{e2};
                                    end
                                    
                                    vibras_ms{Selection, var_sel, e3}.filename=filenamesin{Selection};
                                    vibras_ms{Selection, var_sel, e3}.variable=var_sel;
                                    vibras_ms{Selection, var_sel, e3}.stats_of_metrics=ms_other_stats;
                                    vibras_ms{Selection, var_sel, e3}.stats_of_outlier_metrics=ms_other_outlier_stats;
                                    vibras_ms{Selection, var_sel, e3}.stats_of_total_metrics=ms_total_other_stats;
                                    vibras_ms{Selection, var_sel, e3}.stats_of_total_outlier_metrics=ms_other_total_outlier_stats;
                                    vibras_ms{Selection, var_sel, e3}.metrics_description=md;
                                    vibras_ms{Selection, var_sel, e3}.stats_description=stat_str;
                                    vibras_ms{Selection, var_sel, e3}.data_type='Continuous_Vibrations';
                                    vibras_ms{Selection, var_sel, e3}.exposure_type='Whole Body';
                                    vibras_ms{Selection, var_sel, e3}.posture=posture{type};
                                    vibras_ms{Selection, var_sel, e3}.third_oct_freq=fc_vibs_wb;
                                    
                                end
                            end
                            
                            fprintf(fid_vibs, '\r\n');
                            
                            
                        end
                        fprintf(fid_vibs, '\r\n');
                    end
                end
            end
            
            % Send to the next case if automated send to load file if not
            % automated
            if k3 == 1
                k=5;
            else
                k=5;
            end
            
            save(fileout_struct, 'snd', 'vibras_ha', 'vibras_wb', 'vibras_ms');
            
        case 5
            % This case saves the processed figure to a file
            %
            figure(1);
            for e2=1:length(h2);
                axes(h2(e2));
            end
            
            for e2=1:length(fig_format);
                save_a_plot2_audiological(fig_format(e2), [filename2 '_continuous'], portrait_landscape);
            end
            
            % Send to the next case if automated send to load file if not
            % automated
            if k3 == 1
                
                %num_vibs_vars
                %num_SP_vars
                if e7 > max_num_vars
                    k=1;
                else
                    k=2;
                end
                
            else
                k=1;
            end
            
        otherwise
            k=1000;
            
    end
    
    if k3 == 2;
        k = menu('Whatcha Wanna Do?', 'Load a file', 'Plot the data for a Variable', 'Save a Figure', 'Analyze a Data File', 'Save a Figure', 'Stop Program');
    end
    
end

fclose(fid_vibs);
fclose(fid_snd);
fclose('all');


