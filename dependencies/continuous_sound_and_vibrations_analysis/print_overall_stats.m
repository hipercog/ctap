function [fid]=print_overall_stats(fid, s, flag, mean_vals, max_num_channels, max_num_diff_channels, num_metrics, num_vars, stat_to_get2, ratio_metrics, round_kind, round_digits)
% % print_overall_stats: Print the overall statistics for the impulsive sound table
% % 
% % Syntax:
% % 
% % [fid]=print_overall_stats(fid, s, flag, mean_vals, max_num_channels, max_num_diff_channels, num_metrics, num_vars, stat_to_get2, ratio_metrics, round_kind, round_digits);
% % 
% % *****************************************************************
% %
% % Description:
% %
% % This is a sub program which calculates the overall descriptive 
% % ststistics across files for impulsive sound data output from
% % the Impulsive_Noise_Meter.  
% % 
% % The main program is make_table_compare_systems, which 
% % takes output from the Impulsive_Noise_Meter and makes a table 
% % with a stanadardized format.  
% %
% % Usually this program is only run as a sub program to the main program. 
% % The input and output variables are described below.
% % 
% % *****************************************************************
% %
% % Input Variables
% % 
% % fid=fopen('test.txt', 'w');
% %                         % is the file identifier for saving the table
% %                         % to a tab delimited text file.
% % 
% % s={}; load shock_tube;  % is the data structure created using the
% %                         % Impulsive_Noise_Meter.  
% %                         % default is load shock_tube.  
% %
% % flag=3;  % is a scalar which specifies which data are printed.  
% %          % The absolute values of teh metrics can be printed.
% %          % The difference in metrics between two channels can be
% %          % printed. 
% % 
% %      flag=1; print absolute stats only
% %      flag=2; print difference stats only
% %      flag=3; print both absolute and difference stats
% %      if flag does not equal 1, 2, or 3 then print both absolute and
% %      difference stats.
% % 
% % mean_vals=ones(num_channels, num_vars);
% %                 % is the mean values for each of the channels and
% %                 % variables.  
% % 
% % max_num_channels=1; % is the number of channels to be processed.
% %                 % The default is max_num_channels=1;
% % 
% % max_num_diff_channels=1; 
% %                 % The default is max_num_diff_channels=1; 
% %    
% % num_metrics=10; % is the number of metrics to be processed.
% %                 % The default is num_metrics=10; 
% % 
% % num_vars=1;     % is the number of variables to be processed.
% %                 % The default is num_vars=1; 
% % 
% % stat_to_get2=1;     % is a scalar or constant stipulating which 
% %                     % metrics to display in the table.
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
% %                     % default is stat_to_get2=1;  
% %                     % which returns teh arithmetic mean
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
% %
% % *****************************************************************
% %
% % Output Variables
% %
% % fid is the file identifier it is both an input and an output incase it
% %                changes during processing.
% %
% % *****************************************************************
% 
% Example='1';
%
% % This is an example using shock tube data! The data compares two
% % data acquisition rates.
%
% % An example which outputs the mean of the metrics.
%
% load shock_tube;
% stat_to_get=1;
% stat_to_get2=1;
% fileout='summary_metrics.txt';
% flag=3;
% ratio_metrics=[3, 4, 5];
% round_kind=1;
% round_digits=3;
% 
% make_summary_impls_stats_table(s, stat_to_get, stat_to_get2, fileout, flag, ratio_metrics, round_kind, round_digits);
% 
% 
% 
% Example='2';
% % An example which outputs all of the metrics.
%
% load shock_tube;
% stat_to_get=1:8;
% stat_to_get2=1:8;
% fileout='summary_metrics.txt';
% flag=3;
% ratio_metrics=[3, 4, 5];
% round_kind=1;
% round_digits=3;
% make_summary_impls_stats_table(s, stat_to_get, stat_to_get2, fileout, flag, ratio_metrics, round_kind, round_digits);
% 
% 
% % *****************************************************************
% % 
% % 
% % Subprograms
% % 
% % 
% % List of Dependent Subprograms for 
% % print_overall_stats
% % 
% % FEX ID# is the File ID on the Matlab Central File Exchange
% % 
% % 
% % Program Name   Author   FEX ID#
% %  1) fastlts		Peter J. Rousseeuw		NA	
% %  2) fastmcd		Peter J. Rousseeuw		NA	
% %  3) genHyper		Ben Barrowes		6218	
% %  4) m_round		Edward L. Zechmann			
% %  5) pow10_round		Edward L. Zechmann			
% %  6) rmean		Edward L. Zechmann			
% %  7) sd_round		Edward L. Zechmann			
% %  8) splat_cell		Edward L. Zechmann			
% %  9) t_alpha		Edward L. Zechmann			
% % 10) t_confidence_interval		Edward L. Zechmann			
% % 11) t_icpbf		Edward L. Zechmann					
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
% % modified 19 January     2009    Updated to include rounding. 
% % 
% % modified  6 October     2009    Updated comments
% % 
% % modified  5 Janaury     2012    Replace LMSloc with fastlts.  
% %                                 Updated comments
% % 
% %
% %
% % *****************************************************************
% %
% % Please feel free to modify this code.
% % 
% % See Also:  Impulsive_Noise_Meter, Continuous_Sound_and_Vibrations_Analysis
% %


if (nargin < 1 || isempty(fid)) || ~isnumeric(fid)
    fid=fopen('test.txt', 'w');
end

if (nargin < 2 || isempty(s)) || ~iscell(s)
    s={}; 
    load shock_tube;
end

if (nargin < 3 || isempty(flag)) || ~isnumeric(flag)
    flag=3;
end

if (nargin < 4 || isempty(mean_vals)) || ~iscell(mean_vals)
    mean_vals={1};
end

if (nargin < 5 || isempty(max_num_channels)) || ~isnumeric(max_num_channels)
    max_num_channels=0;
end

if (nargin < 6 || isempty(max_num_diff_channels)) || ~isnumeric(max_num_diff_channels)
    max_num_diff_channels=0;
end

if (nargin < 7 || isempty(num_metrics)) || ~isnumeric(num_metrics)
    num_metrics=0;
end

if (nargin < 8 || isempty(num_vars)) || ~isnumeric(num_vars)
    num_vars=0;
end
 
if (nargin < 9 || isempty(stat_to_get2)) || ~isnumeric(stat_to_get2)
    stat_to_get2=1;
end
 
if (nargin < 10 || isempty(ratio_metrics )) || ~isnumeric(ratio_metrics )
    ratio_metrics=1;
end

if (nargin < 11 || isempty(round_kind)) || ~isnumeric(round_kind)
    round_kind=1;
end

if (nargin < 12 || isempty(round_digits)) || ~isnumeric(round_digits)
    round_digits=3;
end


% Determine the length of the one-dimensional rounding arrays.
num_kinds=length(round_kind);
num_digits=length(round_digits);


% Print the Overall Mean value
if isequal(flag, 1)  || isequal(flag, 3)
    fprintf(fid, '%s\t\t',['          Overall ', s{1,1}.stats_description{stat_to_get2}]);
    fprintf(fid, '%s\t\t', 'Abs Channels');
end

num_channels=max_num_channels;




for e4=1:num_metrics; % Data Metrics
    
    for e3=1:num_vars; % Number of Variables (Number of Data Acquisition Systems)


        if isequal(flag, 1)  || isequal(flag, 3)
            dd=mean_vals(1:num_channels, num_vars*(e4-1)+e3 );
            [buf2, num_files_not_empty]=splat_cell(dd);
        else
            buf2=[];
        end

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
            
            [A2, A_str]=m_round(buf2, rk, rd);
            
            fprintf(fid, '%s\t', A_str{1,1});
        else
            fprintf(fid, '\t');
        end

    end
    fprintf(fid, '\t');
end

fprintf(fid, '\r\n');

if isequal(flag, 2)  || isequal(flag, 3)
    fprintf(fid, '%s\t\t',['          Overall ', s{1,1}.stats_description{stat_to_get2}]);
    fprintf(fid, '%s\t\t', 'Diff Channels');
end

for e4=1:num_metrics; % Data Metrics
    for e3=1:num_vars; % Number of Variables (Number of Data Acquisition Systems)
        
        num_channels=max_num_channels;
        num_diff_channels=max_num_diff_channels;
        sum_num_channels=num_channels+num_diff_channels;

        if isequal(flag, 2)
            dd=mean_vals(1:num_diff_channels, num_vars*(e4-1)+e3 );
            [buf2, num_files_not_empty]=splat_cell(dd);
        elseif isequal(flag, 3)
            dd=mean_vals((num_channels+1):sum_num_channels, num_vars*(e4-1)+e3 );
            [buf2, num_files_not_empty]=splat_cell(dd);
        else
            buf2=[];
        end

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
            
            
            if (num_kinds >= e4 && logical(num_digits >= e4)) 
                rk=round_kind(e4);
                rd=round_digits(e4);
            else
                rk=1;
                rd=3;
            end
            

            if isequal(flag, 2) || isequal(flag, 3) && ismember(e4, ratio_metrics)
                rk=1;
                rd=3;
            end
            
            
            if ismember(stat_to_get2, [3, 4])
                rk=1;
                rd=3;
            end
            
            [A2, A_str]=m_round(buf2, rk, rd);
            
            fprintf(fid, '%s\t', A_str{1,1});
        else
            fprintf(fid, '\t');
        end

    end
    fprintf(fid, '\t');
end

