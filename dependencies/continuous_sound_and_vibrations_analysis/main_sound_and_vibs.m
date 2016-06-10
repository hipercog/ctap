function main_sound_and_vibs
% % Main_snd_and_vibs: Main Program for continuous sound and vibrations analysis
% %
% % Syntax:
% %
% % main_sound_and_vibs;
% %
% % ********************************************************************
% %
% % Description
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
% % This program prompts the user for all of the inputs to the
% % Continuous_Sound_and_Vibrations_Analysis.m program.
% %
% % This program has no Input or Output Variables.
% %
% % The user selects either matlab or wav files to analyze for sound and
% % vibrations.  There are a series of prompts for output filenames,
% % formating of output images of the figures, and the Name of the device
% % under test (Tool Name).
% %
% % The metrics calculated in this program are for
% % time records of length 10 seconds to 2 minutes or longer.
% %
% % The program is limited in its memory and capacity to calculate long
% % time records.  In general, the program can process files with a few
% % million data points without crashing.
% %
% % ********************************************************************
% %
% Example='a';
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
% save('Example_data_file.mat', 'SP', 'Fs_SP','t_SP', 'dt_SP', 'vibs', ...
% 'Fs_vibs','t_vibs', 'dt_vibs');
%
%
% % Step 2)  Run the program;
%
% main_sound_and_vibs;
%
%
% % ********************************************************************
% %
% % Subprograms
% %
% % Main_sound_and_vibs requires the Signal Processing Toolbox
% %
% % 
% % 
% % List of Dependent Subprograms for 
% % main_sound_and_vibs
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
% %  7) calc_diff_metrics_cont		Edward L. Zechmann			
% %  8) channel_data_type_selection		Edward L. Zechmann			
% %  9) choosebox		Peter Wasmeier		4141	
% % 10) combine_accel_directions_ha		Edward L. Zechmann			
% % 11) combine_accel_directions_wb		Edward L. Zechmann			
% % 12) config_accels		Edward L. Zechmann			
% % 13) config_ha_accels		Edward L. Zechmann			
% % 14) config_wb_accels		Edward L. Zechmann			
% % 15) Continuous_Sound_and_Vibrations_Analysis		Edward L. Zechmann			
% % 16) convert_double		Edward L. Zechmann			
% % 17) data_loader2		Edward L. Zechmann			
% % 18) data_outliers3		Edward L. Zechmann			
% % 19) fastlts		Peter J. Rousseeuw		NA	
% % 20) fastmcd		Peter J. Rousseeuw		NA	
% % 21) file_extension		Edward L. Zechmann			
% % 22) filter_attenuation		Edward L. Zechmann			
% % 23) filter_settling_data3		Edward L. Zechmann			
% % 24) find_nums		Edward L. Zechmann			
% % 25) fix_YTick		Edward L. Zechmann			
% % 26) fourier_nth_oct_time_filter3		Edward L. Zechmann			
% % 27) genHyper		Ben Barrowes		6218	
% % 28) geospace		Edward L. Zechmann			
% % 29) get_p_q2		Edward L. Zechmann			
% % 30) hand_arm_fil		Edward L. Zechmann			
% % 31) hand_arm_time_fil		Edward L. Zechmann			
% % 32) kurtosis2		William Murphy			
% % 33) Leq_all_calc		Edward L. Zechmann			
% % 34) m_round		Edward L. Zechmann			
% % 35) make_summary_cont_stats_table		Edward L. Zechmann			
% % 36) match_height_and_slopes2		Edward L. Zechmann			
% % 37) moving		Aslak Grinsted		8251	
% % 38) nth_freq_band		Edward L. Zechmann			
% % 39) Nth_oct_time_filter2		Edward L. Zechmann			
% % 40) Nth_octdsgn		Edward L. Zechmann			
% % 41) num_impulsive_samples		Edward L. Zechmann			
% % 42) parseArgs		Malcolm Wood		10670	
% % 43) plot_snd_vibs		Edward L. Zechmann			
% % 44) pow10_round		Edward L. Zechmann			
% % 45) print_channel_stats		Edward L. Zechmann			
% % 46) print_data_loader_configuration_table		Edward L. Zechmann			
% % 47) print_overall_stats		Edward L. Zechmann			
% % 48) psuedo_box		Edward L. Zechmann			
% % 49) rand_int		Edward L. Zechmann			
% % 50) remove_filter_settling_data		Edward L. Zechmann			
% % 51) resample_interp3		Edward L. Zechmann			
% % 52) resample_plot		Edward L. Zechmann			
% % 53) rmean		Edward L. Zechmann			
% % 54) rms_val		Edward L. Zechmann			
% % 55) save_a_plot2_audiological		Edward L. Zechmann			
% % 56) sd_round		Edward L. Zechmann			
% % 57) selectdlg2		Mike Thomson			
% % 58) splat_cell		Edward L. Zechmann			
% % 59) sub_mean		Edward L. Zechmann			
% % 60) sub_mean2		Edward L. Zechmann			
% % 61) subaxis		Aslak Grinsted		3696	
% % 62) t_alpha		Edward L. Zechmann			
% % 63) t_confidence_interval		Edward L. Zechmann			
% % 64) t_icpbf		Edward L. Zechmann			
% % 65) table_append_channels		Edward L. Zechmann			
% % 66) tableGUI		Joaquim Luis		10045	
% % 67) variable_data_type_selection		Edward L. Zechmann			
% % 68) Vibs_calc_hand_arm		Edward L. Zechmann			
% % 69) Vibs_calc_whole_body		Edward L. Zechmann			
% % 70) whole_Body_Filter		Edward L. Zechmann			
% % 71) whole_body_time_filter		Edward L. Zechmann											
% % 
% % 
% % ********************************************************************
% %
% % References (standards) used in Main_sound_and_vibs
% %
% %
% % References For Sound Analysis
% %
% % ANSI S1.4-1983   American National Standard
% %                  Specificaitons for Sound Level Meters
% %
% % ANSI S1.43-1997  American National Standard
% %                  Specificaitons for Integrating-Averaging Sound Level
% %                  Meters
% %
% % ANSI S1.11-1986  American National Standard
% %                  Specification for Octave-band and Fractional-Octave-
% %                  band Analog and Digital Filters
% %
% % ANSI S3.44-1986  American National Standard
% %                  Determination of Occupational Noise Exposure and
% %                  Estimation of Noise Induced Hearing Impairment
% %
% %
% % References For Vibrations Analysis
% %
% % ANSI S2.70-2006  American National Standard
% %                  Guide to the Measurement and Evaluation of Human
% %                  Exposure to Vibration Transmitted to the Hand.
% %
% % ISO 5349-1 2001  Mechanical vibration-Measurement and evaluation of
% %                  human exposure to hand-transmitted vibration-Part 1
% %                  General Requirements
% %
% % ISO 5349-2 2001  Mechanical vibration-Measurement and evaluation of
% %                  human exposure to hand-transmitted vibration-Part 2
% %                  Practical guidance for measurement at the workplace
% %
% %
% % ISO 2631-1 1997  Mechanical vibration and shock-Evaluation of human
% %                  exposure to whole-body vibration-Part 1:
% %                  General Requirements
% %
% % ********************************************************************
% %
% % Main_sound_and_vibs is written by Edward L. Zechmann
% %
% %     date  4 September   2008
% %
% % modified  9 September   2008    Updated dependent function
% %                                 Continuous_Sound_and_Vibrations_Analysis
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
% % modified 15 January     2009    Updated the outlier removal program.
% %                                 Added rounding of the output.
% %
% % modified 18 January     2009    Updated the summary statistics table
% %                                 to round those numbers wtih the same
% %                                 tye of rounding as in the
% %                                 Continuous_Sound_and_Vibrations_Analysis
% %
% % modified  9 October     2009    Updated Comments
% %
% % modified 27 April       2010    Fixed a bug in the calculation of VDV 
% %                                 added num_samples to the equation
% %                                 (num_samples/Fs)^(1/4)
% %
% % modified 18 January     2011    Fixed a bug in the splitting the seated
% %                                 posture into two cases.  The scaling 
% %                                 factors for the two cases were switched.
% %                                 Updated Comments
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
% %  
% % ********************************************************************
% %
% % See Also: Continuous_Sound_and_Vibrations_Analysis, Impulsive_Noise_Meter
% %



% % ********************************************************************
%
% Get input parameters using various input boxes
%


% % ********************************************************************
%
% Get the filenames to process
%

% Set the default values for unspecified input variables


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

if ~iscell(filenamesin) || isempty(filenamesin) || length(filenamesin) < 1
    error('Must select at least 1 file to analyze');
end

if ~iscell(filenamesin) || isempty(filenamesin) || length(filenamesin) < 1
    error('Must select at least 1 file to analyze');
end

filenamesin=sort(filenamesin);




% % ********************************************************************
%
% Get the filenames to save the text file and the matlab structures.
%
prompt= {'Enter the File Name for the Output Text file', 'Enter the File Name for the Output Matlab Sructure Data file.                     .'};
defAns={'Continuous_', 'Cont_snd_and_vibs'};
dlg_title='Enter File Names for Saving the Program Metrics and Descriptive Statistics';
num_lines=1;

options.Resize='on';
options.WindowStyle='normal';
options.Interpreter='tex';

file_name_cell = inputdlg(prompt,dlg_title,num_lines,defAns,options);

if isempty(file_name_cell)
    fileout_txt='Cont_text';
    fileout_struct='Cont_snd_and_vibs';
else
    fileout_txt=file_name_cell{1};
    fileout_struct=file_name_cell{2};
end

% % ********************************************************************
%
% Get the Tool Name
%
prompt= {'Enter the Tool Name or Description'};
defAns={'Circular Saw 6000'};
dlg_title='Device Under Test Name, Tool Name, or Description';
num_lines=1;

options.Resize='on';
options.WindowStyle='normal';
options.Interpreter='tex';

Tool_Name_cell = inputdlg(prompt,dlg_title,num_lines,defAns,options);

if isempty(Tool_Name_cell)
    Tool_Name='';
else
    Tool_Name=Tool_Name_cell{1};
end

% % ********************************************************************
%
% Prompt the user to declare which File Formats to save the Figures as
% Images
%
str{1}='1 .pdf   Portable Document Format Default';
str{2}='2 .fig    Matlab Figure Format';
str{3}='3 .jpg   (200 dpi resolution)';
str{4}='4 .eps  Encapsulated Post Script';
str{5}='5 .tiff   Tagged Image File Format (200 dpi resolution)';
str{6}='6 .tiff   (no compression) suggested for publications)';

prompt={'Which formats should the Files be saved in?', 'Select Desired Formats',' For Saving Figure Images'};
[fig_format,ok] = listdlg('Name', 'figure Formats', 'PromptString', prompt,'SelectionMode','multiple','ListString',str, 'InitialValue', [1], 'ListSize', [500, 500]);

if (isempty(fig_format) || any(logical(fig_format < 1))) || (any(logical(fig_format > 6)) || any(~isequal(ok, 1)))
    fig_format=1;
end

% % ********************************************************************
%
%  Get whether the y-axes should have the same limits
%
k3 = menu('Should the y-axes have the same limits For each channel?', 'Yes', 'No', 'Default');
if k3 < 3
    same_ylim=k3;
else
    same_ylim=1;
end

% % ********************************************************************
% Get whether the figures should be saved in portrait or landscape
k3 = menu('Choose Orientation of the Figures? Portrait is better for more than 4 channels of data.', 'Portrait', 'Landscape', 'Default');
if k3 < 3
    portrait_landscape=k3;
else
    portrait_landscape=1;
end



% % ********************************************************************
%
% Determine whether to Surpress Outlier Detection
%
sod=menu({'Identify Outliers and Remove them from Calculations of the Mean, STD, etc.', 'Allow Automated Detection and Removal of Anomalous Data.'}, 'Yes', 'No', 'Default');

if isequal(sod, 2)
    sod=1;
else
    sod=0;
end

% % ********************************************************************
%
% Determine which filtering approcah to use
%
filter_approach=menu({'Filtering Nth octave bands is performed to determine frequency conctent', 'There are two approcahes traditional filter function and Fast FFT (Non-causal)'}, '10x Faster FFT (Non-causal)','Traditional Filter Function', 'Default');

if isequal(filter_approach, 2)
    filter_approach=2;
else
    filter_approach=1;
end


if isequal(filter_approach, 2)
    % % ********************************************************************
    %
    % Determine which resample filter to use
    %
    resample_filter=menu({'Resampling is performed to optimize filter stability', 'Different resampling techniques can be used for continuous and impulsive signals'}, 'Continuous use Kaiser Window', 'Impulsive use Bessel Filter', 'Default');
    
    if isequal(resample_filter, 2)
        resample_filter=2;
    else
        resample_filter=1;
    end
else
    resample_filter=1;
end



% The summary table of metrics has not been programmed yet.  
not_coded=1;

if isequal(not_coded, 0)
    % % ********************************************************************
    %
    % Determine whether to print a summary table of the statistics
    %
    flag2=menu('Print a summary table of statistics to a text file?', 'Yes', 'No', 'Default');

    if isequal(flag2, 2)
        flag2=0;
    else
        flag2=1;
    end

    % flaga is whether to calculate differences of metrics, total values of
    % metrics or both for each each data type.
    flaga=zeros(4,1);
    flag3a=zeros(4,1);
    fileouta=cell(4,1);
    diff_chana=cell(4,1);

    data_type_a=cell(4,1);
    data_type_a{1}='Sound';
    data_type_a{2}='Hand Arm Vibrations';
    data_type_a{3}='Whole Body Vibrations';
    data_type_a{4}='Motion Sickness';

    stat_to_geta=cell(4,1);
    stat_to_get2a=cell(4,1);

    chan_string={'Channels', 'Accelerometers',  'Accelerometers', 'Accelerometers'};


    % % ********************************************************************
    %
    % Determine whether to print the Metrics for each mic or accel, Difference of the metrics for each mic or accel, or both
    %
    if isequal(flag2, 1)

        % Loop once for each data type
        for e1=1:4;

            flag3=menu({['For ', data_type_a{e1}, ' Data '], ['Print a summary table of statistics to a text file?']}, 'Yes', 'No', 'Default');

            if isequal(flag3, 2)
                flag3=0;
            else
                flag3=1;
            end

            flag3a(e1)=flag3;

            if isequal(flag3, 1)

                h = msgbox({'The following input boxes are for ', '', [ data_type_a{e1}, ' data.' ] }, data_type_a{e1}, 'non-modal');

                % % *******************************************************************
                %
                % Determine whether to print the Values, Difference of values, or both
                %
                flag4=menu('Select whether to Write to text file the Metrics, Difference of Metrics, or both?', 'Metrics for each channel', 'Difference in Metrics for each pair of Channels', 'Both Metrics and Differences in Metric', 'Default (Both)');

                if flag4 >= 3
                    flag4=3;
                end

                flaga(e1)=flag4;

                % % *******************************************************************
                %
                % Get the filenames to save the text file and the matlab structures.
                %
                prompt= {['For ', data_type_a{e1}, ' Enter the File Name for the Output Text file']};
                defAns={'metrics_stats'};
                dlg_title=['For ', data_type_a{e1}, ' Enter File Name for the Summary Descriptive Statistics'];
                num_lines=1;

                options.Resize='on';
                options.WindowStyle='normal';
                options.Interpreter='tex';

                file_name_cell = inputdlg(prompt, dlg_title, num_lines, defAns, options);

                if isempty(file_name_cell)
                    fileout='metrics_stats';
                else
                    fileout=file_name_cell{1};
                end

                fileouta{e1}=fileout;


                if flaga(e1) > 1

                    % % ********************************************************************
                    %
                    % Enter the maximum number of channels to be analyzed in a single file
                    %
                    prompt= {['Enter the Maximum number of channels of ', data_type_a{e1}, 'data to be analyzed in a single file and variable.']};
                    defAns={'2'};
                    dlg_title=['Enter the maximum number of channels of ', data_type_a{e1}, 'data  to analyze.'];
                    num_lines=1;

                    options.Resize='on';
                    options.WindowStyle='normal';
                    options.Interpreter='tex';

                    num_chan_cell = inputdlg(prompt,dlg_title,num_lines,defAns,options);

                    if isempty(num_chan_cell)
                        num_chan=2;
                    else
                        num_chan=str2double(num_chan_cell{1});
                    end

                    num_chan=round(num_chan);

                    if num_chan  < 1
                        num_chan=1;
                    end


                    % % *******************************************************************
                    %
                    % Determine which channels to output the difference of the metrics.
                    %
                    % diff chan is initially a row vector must be a column vector
                    accept_config=2;
                    diff_chan=[];
                    %
                    count=0;

                    if e1 == 1
                        prompt={['For ', data_type_a{e1}, 'Select pairs of Microphone Channels', ' to Calculate a Difference',' in Metrics between the two channels']};
                    else
                        prompt={['For ', data_type_a{e1}, 'Select pairs of Accelerometers (Total Vector Sum of Channels)', ' to Calculate a Difference',' in Total Metrics between the two Accelerometers']};
                    end


                    [buf, str]=pow10_round((1:num_chan), 0);

                    if e1 == 1
                        ColNames={'Channel Pair Number', 'Primary Channel', 'Minus Channel'};
                    else
                        ColNames={'Total Accelerometer Pair Number', 'Primary Accelerometer', 'Minus Accelerometer'};
                    end

                    out=[];

                    while isequal(accept_config, 2) && logical(count < 3+(floor(num_chan/2))^2)

                        % Provide help for selecting the channels to calculate a difference
                        % in the metrics.
                        h3=helpdlg({['To add a pair of ', chan_string{e1}, ' to Calculate Differences in Metrics.'], ...
                            ['Add the Primary ', chan_string{e1}, ' then the Minus Channel.'], '', ...
                            ['The ', chan_string{e1}, 'are paired together'], 'Alternating Primary then Minus', ...
                            ['The pairing of ', chan_string{e1}, 'is displayed in a Editable Table.']},[chan_string{e1}, ' Selection Help']);

                        count=count+1;
                        [diff_chan_update, ok] = choosebox('Name', [chan_string{e1}, ' Selection to Calculate a Difference'], 'PromptString', prompt, ...
                            'SelectString', ['Ordered Pairs of ', chan_string{e1}, ' to Calculate Differences in Metrics:'], ...
                            'SelectionMode', 'multiple', 'ChooseMode', 'copy', ...
                            'ListString', str, 'OKString', 'Finish and Update', 'ListSize', [500, 500]);

                        if ishandle(h3)
                            close(h3);
                        end

                        if length(diff_chan_update) >= 2

                            % The number of pairs must be even
                            num_new_pairs=floor(length(diff_chan_update)/2);
                            diff_chan=[diff_chan' diff_chan_update(1:(2*num_new_pairs))' ]';

                        end

                        if length(diff_chan) >= 2

                            [A2, A_str]=pow10_round(diff_chan', 0);
                            num_pairs=floor(length(A_str)/2);
                            t_cell=zeros(num_pairs, 3);

                            for e2=1:(num_pairs);
                                t_cell(e2,1)=e2;
                                t_cell(e2,2)=diff_chan(2*e2-1, 1);
                                t_cell(e2,3)=diff_chan(2*e2, 1);
                            end

                            if ishandle(out)
                                close(out);
                            end

                            out = tableGUI('FigName', ['Difference ', chan_string{e1}, ' Selection Table'], ...
                                'array', t_cell, 'ColNames', ColNames, 'ColWidth', 180, ...
                                'RowHeight', 30, 'HorAlin', 'center', 'modal', '', 'position', 'center');

                            % Select to Accept or Modify Configuration
                            accept_config=menu(['In the Table, are all of the pairings for ', chan_string{e1}, ' present and correct?'], 'Accept Configuration', ['Modify, Add, or Delete ', chan_string{e1}, ' to Configuration'] );

                            % Retrieve the channel difference configuration table.
                            hand=get(out, 'UserData');
                            data_new=zeros(num_pairs, 3);
                            row_list=[];

                            for e2=1:num_pairs;
                                for e3=1:3;

                                    buf1=round(str2double(get(hand.hEdits(e2, e3), 'string')));

                                    if (~isempty(buf1) && logical(buf1 >= 1)) && logical(buf1 <= num_chan)
                                        data_new(e2, e3)=buf1;
                                    else
                                        row_list=[row_list e2];
                                    end

                                end
                            end

                            buf2=setdiff(1:num_pairs, row_list);
                            diff_chan=zeros(2*length(buf2), 1);

                            for e2=1:length(buf2);
                                for e3=1:3;

                                    buf1=round(str2double(get(hand.hEdits(buf2(e2), e3), 'string')));
                                    if isequal(e3,2)
                                        diff_chan(2*e2-1, 1)=buf1;
                                    elseif isequal(e3,3)
                                        diff_chan(2*e2, 1)=buf1;
                                    end

                                end
                            end

                            if ishandle(out) && isequal(accept_config, 1)
                                close(out);
                            end
                        end

                    end

                    % Print the Configuration Table for the Last Time
                    [A2, A_str]=pow10_round(diff_chan', 0);

                    num_pairs=floor(length(A_str)/2);

                    t_cell=zeros(num_pairs, 3);

                    for e2=1:(num_pairs);
                        t_cell(e2,1)=e2;
                        t_cell(e2,2)=diff_chan(2*e2-1, 1);
                        t_cell(e2,3)=diff_chan(2*e2, 1);
                    end

                    h3=helpdlg({['Last Chance to Make sure the ', chan_string{e1}, ' Configuration is Correct'], '', ...
                        ['To add a pair of ', chan_string{e1}, 's to Calculate Differences in Metrics.'], ...
                        ['Add the Primary ', chan_string{e1}, ' then the Minus ', chan_string{e1}, '.'], '', ...
                        ['The ', chan_string{e1}, 's are paired together'], 'Alternating Primary then Minus', ...
                        ['The pairing of ', chan_string{e1}, 's is displayed in a Editable Table.']},...
                        [chan_string{e1}, ' Selection Help']);

                    out = tableGUI('FigName', ['Difference ', chan_string{e1}, ' Selection Table'], ...
                        'array', t_cell, 'ColNames', ColNames, 'ColWidth', 180, ...
                        'RowHeight', 30, 'HorAlin', 'center', 'modal', '', 'position', 'center');


                    % Retrieve the channel difference configuration table.
                    hand=get(out, 'UserData');
                    data_new=zeros(num_pairs, 3);
                    row_list=[];

                    for e2=1:num_pairs;
                        for e3=1:3;

                            buf1=round(str2double(get(hand.hEdits(e2, e3), 'string')));

                            if (~isempty(buf1) && logical(buf1 >= 1)) && logical(buf1 <= num_chan)
                                data_new(e2, e3)=buf1;
                            else
                                row_list=[row_list e2];
                            end

                        end
                    end

                    buf2=setdiff(1:num_pairs, row_list);
                    data_new=zeros(length(buf2), 3);

                    for e2=1:length(buf2);
                        for e3=1:3

                            buf1=round(str2double(get(hand.hEdits(e2, e3), 'string')));
                            if isequal(e3,2)
                                diff_chan(2*e2-1, 1)=buf1;
                            elseif isequal(e3,3)
                                diff_chan(2*e2, 1)=buf1;
                            end
                        end
                    end

                    if ishandle(out) && isequal(accept_config, 1)
                        close(out);
                    end

                    if ishandle(h3)
                        close(h3);
                    end

                    diff_chana{e1}=diff_chan;

                else

                    diff_chana{e1}=[];

                end

                % % ********************************************************************
                %
                % Determine which descriptive statistics to print to a text file.
                %
                str{1}='1    Artihmetic Mean';
                str{2}='2    Robust Mean';
                str{3}='3    Standard Deviation';
                str{4}='4    95% Confidence Interval';
                str{5}='5    Median';
                str{6}='6    Median Index';
                str{7}='7    Minimum';
                str{8}='8    Maximum';

                prompt={['Which descriptive statistics of the metrics across impulses for each ', chan_string{e1}, ' should be output to the file?'], 'Select desired descriptive statistics',' for printing to a text file.'};
                [stat_to_get,ok] = listdlg('Name', 'Descriptive Statistics ', 'PromptString', prompt,'SelectionMode','multiple','ListString',str, 'InitialValue', [1,2,3,7,8], 'ListSize', [500, 500]);

                if (isempty(stat_to_get) || any(logical(stat_to_get < 1))) || (any(logical(stat_to_get > 8)) || any(~isequal(ok, 1)))
                    stat_to_get=1;
                end

                stat_to_geta{e1}=stat_to_get;

                prompt={['Which descriptive statistics of the metrics across files for each ', chan_string{e1}, ' should be output to the file?'], 'Select Desired descriptive statistics',' for printing to a text file.'};
                [stat_to_get2,ok] = listdlg('Name', 'Descriptive Statistics ', 'PromptString', prompt,'SelectionMode','multiple','ListString',str, 'InitialValue', [1,2,3,7,8], 'ListSize', [500, 500]);

                if (isempty(stat_to_get2) || any(logical(stat_to_get2 < 1))) || (any(logical(stat_to_get2 > 8)) || any(~isequal(ok, 1)))
                    stat_to_get2=1;
                end

                stat_to_get2a{e1}=stat_to_get2;

            end

            if ishandle(h)
                close(h);
            end

        end

    end

end


% % ********************************************************************
%
%  Run the Continuous_Sound_and_Vibrations_Analysis Program
%

[snd, vibras_ha, vibras_wb, vibras_ms, round_kind_snd, round_digits_snd, round_kind_vibs_ha, round_digits_vibs_ha, round_kind_vibs_wb, round_digits_vibs_wb, round_kind_vibs_ms, round_digits_vibs_ms]=Continuous_Sound_and_Vibrations_Analysis(filenamesin, fileout_txt, fileout_struct, Tool_Name, same_ylim, fig_format, portrait_landscape, sod, resample_filter, filter_approach);


% % ********************************************************************
% %
% %  The output matlab cell arrays of data structures namely:
% %  snd, vibras_ha, vibras_wb, and vibras_ms were saved to
% %  to the matlab workspace nameed  fileout_struct
% %
% %  The output text files for the sound and vibrations data were saved to
% %  file names of the format
% %  For Sound      Data      fileout_txt '_snd.mat'
% %  For Vibrations Data      fileout_txt '_vibs.mat'


if isequal(not_coded, 0)

    if isequal(flag2, 1)

        for e1=1:4;

            % % ********************************************************************
            %
            % Calculate the difference between channels selected for difference
            % calculations.
            %

            % snd
            % vibras_ha
            % vibras_wb
            % vibras_ms

            switch flag3a(e1)
                case 1
                    ratio_metrics=[3, 4, 5, 20];
                    [snd]=calc_diff_metrics_cont(snd, diff_chana{e1}, flaga(e1), ratio_metrics, round_kind_snd, round_digits_snd);
                case 2
                    ratio_metrics=[3, 4, 5, 20];
                    [vibras_ha]=calc_diff_metrics_cont(vibras_ha, diff_chana{e1}, flaga(e1), ratio_metrics, round_kind_vibs_ha, round_digits_vibs_ha);
                case 3
                    ratio_metrics=[3, 4, 5, 20];
                    [vibras_wb]=calc_diff_metrics_cont(vibras_wb, diff_chana{e1}, flaga(e1), ratio_metrics, round_kind_vibs_wb, round_digits_vibs_wb);
                case 4
                    ratio_metrics=[3, 4, 5, 20];
                    [vibras_ms]=calc_diff_metrics_cont(vibras_ms, diff_chana{e1}, flaga(e1), ratio_metrics, round_kind_vibs_ms, round_digits_vibs_ms);
                otherwise
                    ratio_metrics=[3, 4, 5, 20];
                    [snd]=calc_diff_metrics_cont(snd, diff_chana{e1}, flaga(e1), ratio_metrics, round_kind_snd, round_digits_snd);
            end



            % ********************************************************************
            %
            % Run the make_summary_cont_stats_table to output a text file
            % summary table of the metrics.
            switch flag3a(e1)
                case 1
                    ratio_metrics=[3, 4, 5, 20];
                    make_summary_cont_stats_table(snd,       stat_to_geta{e1}, stat_to_get2a{e1}, fileouta{e1}, flag3a(e1), flaga(e1), ratio_metrics, round_kind_snd, round_digits_snd);
                case 2
                    ratio_metrics=[3, 4, 5, 20];
                    make_summary_cont_stats_table(vibras_ha, stat_to_geta{e1}, stat_to_get2a{e1}, fileouta{e1}, flag3a(e1), flaga(e1), ratio_metrics, round_kind_vibs_ha, round_digits_vibs_ha);
                case 3
                    ratio_metrics=[3, 4, 5, 20];
                    make_summary_cont_stats_table(vibras_wb, stat_to_geta{e1}, stat_to_get2a{e1}, fileouta{e1}, flag3a(e1), flaga(e1), ratio_metrics, round_kind_vibs_wb, round_digits_vibs_wb);
                case 4
                    ratio_metrics=[3, 4, 5, 20];
                    make_summary_cont_stats_table(vibras_ms, stat_to_geta{e1}, stat_to_get2a{e1}, fileouta{e1}, flag3a(e1), flaga(e1), ratio_metrics, round_kind_vibs_ms, round_digits_vibs_ms);
                otherwise
                    ratio_metrics=[3, 4, 5, 20];
                    make_summary_cont_stats_table(snd,       stat_to_geta{e1}, stat_to_get2a{e1}, fileouta{e1}, 1,           flaga(e1), ratio_metrics, round_kind_snd, round_digits_snd);
            end

        end
    end

end
