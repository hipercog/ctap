function [fid, mean_vals, max_num_channels, max_num_diff_channels]=print_channel_stats(s, fid, flag, max_channels, num_metrics, num_vars, num_files, stat_to_get, stat_to_get2, num_channels_a, sum_num_channels_a, num_diff_channels_a, ratio_metrics, round_kind, round_digits)
% % print_channel_stats: Print the ststistics for each channel for the impulsive sound table
% % 
% % Syntax:
% % 
% % [fid, mean_vals, max_num_channels, max_num_diff_channels]=print_channel_stats(s, fid, flag, max_channels, num_metrics, num_vars, num_files, stat_to_get, stat_to_get2, num_channels_a, sum_num_channels_a, num_diff_channels_a, ratio_metrics, round_kind, round_digits);
% % 
% % *****************************************************************
% %  
% % Description:
% % 
% % This program takes the output from the Impulsive_Noise_Meter and displays the
% % the impulsive Noise metrics in a table with a standardized format.
% % 
% % The input and output variables are described below.
% % 
% % 
% % *****************************************************************
% % 
% % Input Variables
% % 
% % s={};                   % is the data structure created using the
% %                         % Impulsive_Noise_Meter.  
% %                         % default is load shock_tube.  
% % 
% % fid=fopen('test.txt', 'w');
% %                         % is the file identifier for saving the table
% %                         % to a tab delimited text file.
% % 
% % flag=3;  % is a scalar which specifies which data are printed.  
% %          % The absolute values of the metrics can be printed.
% %          % The difference in metrics between two channels can be
% %          % printed. 
% % 
% %      flag=1; print absolute stats only
% %      flag=2; print difference stats only
% %      flag=3; print both absolute and difference stats
% %      if flag does not equal 1, 2, or 3 then print both absolute and
% %      difference stats.
% % 
% % max_channels=1; % is the number of channels to be processed.
% %                 % The default is max_channels=1;
% % 
% % num_metrics=10; % is the number of metrics to be processed.
% %                 % The default is num_metrics=10; 
% % 
% % num_vars=1;     % is the number of variables to be processed.
% %                 % The default is num_vars=1; 
% % 
% % num_files=1;    % is the number of files of data metrics stored in s.
% % 
% % stat_to_get=(1:8);  % is a vector or constant stipulating which 
% %                     % metric to display in the table.
% %                     % 
% %                     % Any combination of the following stats can be 
% %                     % displayed by placing the index fo the stat in
% %                     % the desired order.
% %                     % 
% %                     % stat_to_get=1;  % Arithmetic Mean
% %                     % stat_to_get=2;  % Robust Mean
% %                     % stat_to_get=3;  % Standard Deviation
% %                     % stat_to_get=4;  % 95% Confidence Interval
% %                     % stat_to_get=5;  % Median
% %                     % stat_to_get=6;  % Median Index
% %                     % stat_to_get=7;  % Minimum
% %                     % stat_to_get=8;  % Maximum
% %                     % 
% %                     % default is stat_to_get=1;  
% %                     % which return all of the stats, 
% %                     % from mean to maximum!
% % 
% % stat_to_get2=1;     % is a scalar similar to stat_to_get but it is for the 
% %                     % channel and overall statistics.
% %                     % The default is stat_to_get2=1;
% %                     
% % num_channels_a=ones(num_files, num_vars);   
% %                      
% % 
% % sum_num_channels_a=ones(num_files, num_vars);  
% %                      
% % 
% % num_diff_channels_a=zeros(num_files, num_vars);   
% %  
% % ratio_metrics=[3, 4, 5, 20];    % is an array of indices of metrics for
% %                                 % the diff_chans array that are
% %                                 % calculated as ratios instead of
% %                                 % differences
% %                         
% % round_kind=1;           % Array of values one element for the rta array
% %                         % and one element for each varargin array
% %                         % (see example)
% %                         % 1 round to specified number of significant
% %                         % digits
% %                         %
% %                         % 0 round to specified digits place
% %                         %
% %                         % default is round_kind=1;
% %
% % round_digits=3;         % Array of values one element for the rta array
% %                         % and one element for each varargin array
% %                         % (see example)% Type of rounding depends on round_kind
% %                         %
% %                         % if round_kind==1 number of significant digits
% %                         % if round_kind==0 specified digits place
% %                         %
% %                         % default is round_digits=3;
% %
% % *****************************************************************
% % 
% % Output Variables
% % 
% % fid is the file identifier it is both an input and an output incase it
% %                changes during processing.
% % 
% % mean_vals is the cell array of mean_vals across the files for each channel
% %                and each variable.
% % 
% % max_num_channels is the maximum number of channels that exist for any
% %                file or variable.  
% % 
% % max_num_diff_channels is the maximum number of channels that are
% %                specified to be used in calculating the differnece 
% %                between two channels.  The channels are paired so that 
% %                the differences are always between two paired channels.  
% % 
% % *****************************************************************
% %
% Example='s';
%
% % This is an example using shock tube data! The data compares two
% % data acquisition rates.
%
% % An example which outputs the mean of the metrics.
%
% load shock_tube;
% stat_to_get=1;
% fileout
% [bb_table, bb2]=make_table_compare_systems(s, stat_to_get, fileout);
%
%
% % An example which outputs all of the metrics.
%
% load shock_tube;
% stat_to_get=[1:7];
% fileout
% [bb_table, bb2]=make_table_compare_systems(s, stat_to_get, fileout);
% 
% 
%  
% % *****************************************************************
% % 
% % 
% % Subprograms
% % 
% % 
% % List of Dependent Subprograms for 
% % print_channel_stats
% % 
% % FEX ID# is the File ID on the Matlab Central File Exchange
% % 
% % 
% % Program Name   Author   FEX ID#
% % 1) genHyper		Ben Barrowes		6218	
% % 2) LMSloc		Alexandros Leontitsis		801	
% % 3) m_round		Edward L. Zechmann			
% % 4) pow10_round		Edward L. Zechmann			
% % 5) sd_round		Edward L. Zechmann			
% % 6) splat_cell		Edward L. Zechmann			
% % 7) t_alpha		Edward L. Zechmann			
% % 8) t_confidence_interval		Edward L. Zechmann			
% % 9) t_icpbf		Edward L. Zechmann			
% % 
% % 
% % *****************************************************************
% %
% % Written by Edward L. Zechmann
% %
% %     date  1 September   2008
% %
% % modified 10 September   2008    Updated comments.
% %
% % modified 18 January     2009    Updated to include rounding.
% % 
% % modified  6 October     2009    Updated comments
% % 
% % modified  5 Janaury     2012    Replace LMSloc with fastlts.  
% %                                 Updated comments
% % 
% % 
% %
% %
% % *****************************************************************
% %
% % Please feel free to modify this code.
% %
% % See Also:  Impulsive_Noise_Meter, Continuous_Sound_and_Vibrations_Analysis
% %


if (nargin < 1 || isempty(s)) || ~iscell(s)
    s={}; 
    load shock_tube;
end

if (nargin < 2 || isempty(fid)) || ~isnumeric(fid)
    fid=fopen('test.txt', 'w');
end

if (nargin < 3 || isempty(flag)) || ~isnumeric(flag)
    flag=3;
end

if (nargin < 4 || isempty(max_channels)) || ~isnumeric(max_channels)
    max_channels=1;
end

if (nargin < 5 || isempty(num_metrics)) || ~isnumeric(num_metrics)
    num_metrics=10; 
end

if (nargin < 6 || isempty(num_vars)) || ~isnumeric(num_vars)
    num_vars=1;
end

if (nargin < 7 || isempty(num_files)) || ~isnumeric(num_files)
    num_files=1;
end

if (nargin < 8 || isempty(stat_to_get)) || ~isnumeric(stat_to_get)
    stat_to_get=(1:8);
end

if (nargin < 9 || isempty(stat_to_get2)) || ~isnumeric(stat_to_get2)
    stat_to_get2=1;
end

if (nargin < 10 || isempty(num_channels_a)) || ~isnumeric(num_channels_a)
    num_channels_a=ones(num_files, num_vars);
end

if (nargin < 11 || isempty(sum_num_channels_a)) || ~isnumeric(sum_num_channels_a)
    sum_num_channels_a=ones(num_files, num_vars);
end

if (nargin < 12 || isempty(num_diff_channels_a)) || ~isnumeric(num_diff_channels_a)
    num_diff_channels_a=zeros(num_files, num_vars);
end

if (nargin < 13 || isempty(ratio_metrics )) || ~isnumeric(ratio_metrics )
    ratio_metrics=1;
end

if (nargin < 14 || isempty(round_kind)) || ~isnumeric(round_kind)
    round_kind=1;
end

if (nargin < 15 || isempty(round_digits)) || ~isnumeric(round_digits)
    round_digits=3;
end



% Determine the length of the one-dimensional rounding arrays.
num_kinds=length(round_kind);
num_digits=length(round_digits);

% Print the Mean averaged over the files for each channel
mean_vals=cell(max_channels, num_metrics*num_vars);
max_num_channels=0;
max_num_diff_channels=0;

for e1=1:num_files;  
    for e3=1:num_vars; % Number of Variables (Number of Data Acquisition Systems)
        max_num_channels=max([max_num_channels num_channels_a(e1, e3)]);
        max_num_diff_channels=max([max_num_diff_channels num_diff_channels_a(e1, e3)]);
    end
end


for e2=1:max_channels; % Channels
    
    if e2 == 1
        fprintf(fid, '%s\t\t',['     ', s{1,1}.stats_description{stat_to_get2}, ' for Each Channel']);
    else
        fprintf(fid, '\t\t');
    end

    switch flag

        case 1
            if e2 <= max_num_channels
                fprintf(fid, '%s\t\t', ['Channel ' num2str(e2)]);
            end
        case 2
            if e2 <= max_num_diff_channels
                fprintf(fid, '%s\t\t', ['Diff Channel ' num2str(s{e1,e3}.diff_chan(2*e2-1)), ' - ', num2str(s{e1,e3}.diff_chan(2*e2))]);
            end
        case 3
            if e2 <= max_num_channels
                fprintf(fid, '%s\t\t', ['Channel ' num2str(e2)]);
            elseif e2-max_num_channels <= max_num_diff_channels
                fprintf(fid, '%s\t\t', ['Diff Channel ' num2str(s{e1,e3}.diff_chan(2*(e2-max_num_channels)-1)), ' - ', num2str(s{e1,e3}.diff_chan(2*(e2-max_num_channels)))]);
            end
        otherwise
            if e2 <= max_num_channels
                fprintf(fid, '%s\t\t', ['Channel ' num2str(e2)]);
            elseif e2-max_num_channels <= max_num_diff_channels
                fprintf(fid, '%s\t\t', ['Diff Channel ' num2str(s{e1,e3}.diff_chan(2*(e2-max_num_channels)-1)), ' - ', num2str(s{e1,e3}.diff_chan(2*(e2-max_num_channels)))]);
            end
    end

    cc=cell(num_files, 1);

    for e4=1:num_metrics; % Data Metrics
        
        for e3=1:num_vars; % Number of Variables (Number of Data Acquisition Systems)

            cc=cell(num_files, 1);

            for e1=1:num_files;    % Data files

                num_channels=num_channels_a(e1, e3);
                num_diff_channels=num_diff_channels_a(e1, e3);
                sum_num_channels=sum_num_channels_a(e1, e3);

                if sum_num_channels > 0

                    switch flag

                        case 1
                            if e2 <= num_channels
                                cc{e1}=s{e1,e3}.stats_of_metrics(e4, e2, stat_to_get);
                            end
                        case 2
                            if e2 <= num_diff_channels
                                cc{e1}=s{e1,e3}.diff_stats_of_metrics(e4, e2, stat_to_get);
                            end
                        case 3
                            if e2 <= num_channels
                                cc{e1}=s{e1,e3}.stats_of_metrics(e4, e2, stat_to_get);
                            elseif e2-num_channels <= num_diff_channels
                                cc{e1}=s{e1,e3}.diff_stats_of_metrics(e4, e2-num_channels, stat_to_get);
                            end
                        otherwise
                            if e2 <= num_channels
                                cc{e1}=s{e1,e3}.stats_of_metrics(e4, e2, stat_to_get);
                            elseif e2-num_channels <= num_diff_channels
                                cc{e1}=s{e1,e3}.diff_stats_of_metrics(e4, e2-num_channels, stat_to_get);
                            end
                    end
                end

            end

            [buf2, num_files_not_empty]=splat_cell(cc);
            
            if ~isempty(buf2)
                switch stat_to_get2
                    case 1 
                        buf2=mean(buf2);
                    case 2 
                        [ buf2 ] = rmean(buf2, 0);
                        %buf2=LMSloc(buf2);
                    case 3
                        buf2=std(buf2); 
                    case 4
                        [buf2]=t_confidence_interval(buf2, 0.95);
                    case 5
                        buf2=median(buf2);
                    case 6
                        medianrt=median(buf2);
                        [mbuf buf2]=min(abs(buf2-medianrt));
                    case 7
                        buf2=min(buf2);
                    case 8
                        buf2=max(buf2);
                    otherwise
                        [ buf2 ] = rmean(buf2, 0);
                        %buf2=LMSloc(buf2);
                end

                
                if num_kinds >= e4 && logical(num_digits >= e4)
                    rk=round_kind(e4);
                    rd=round_digits(e4);
                else
                    rk=1;
                    rd=3;
                end


                if ismember(stat_to_get2, [3, 4])
                    rk=1;
                    rd=3;
                end


                if (isequal(flag, 2) || (isequal(flag, 3) && logical(e2 > num_channels))) && ismember(e4, ratio_metrics)
                    rk=1;
                    rd=3;
                end
                
                [A2, A_str]=m_round(buf2, rk, rd);
                
                mean_vals{e2, num_vars*(e4-1)+e3 }=A2;
                fprintf(fid, '%s\t', A_str{1,1});
            else
                fprintf(fid, '\t');
            end

        end

        fprintf(fid, '\t');

    end

    fprintf(fid, '%s\t', ['Number of files ' num2str(num_files_not_empty)]);
    fprintf(fid, '\r\n');

end

