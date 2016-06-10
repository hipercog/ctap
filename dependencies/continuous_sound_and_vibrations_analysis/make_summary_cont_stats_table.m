function make_summary_cont_stats_table(s, stat_to_get, stat_to_get2, fileout, data_type, flag, ratio_metrics, round_kind, round_digits)
% % make_summary_cont_stats_table: Makes a table of the output of the
% %
% % Syntax:
% %
% % make_summary_cont_stats_table(s, stat_to_get, stat_to_get2, fileout, data_type, flag);
% %
% % *****************************************************************
% %
% % Description:
% %
% % This program takes the output from the Impulsive_Noise_Meter
% % and displays the impulsive noise metrics in a table with a
% % stanadardized format.
% %
% % The input and output variables are described below.
% %
% % *****************************************************************
% %
% % Input Variables
% %
% % s={}; load shock_tube;  % is the data structure created using the
% %                         % Impulsive_Noise_Meter.
% %                         % default is load shock_tube.
% %
% % stat_to_get is a vector or constant stipulating which metrics to
% %                   display in the table.
% %
% % Any combination of the following stats can be displayed by placing the
% % index fo the stat in the desired order.
% %
% % stat_to_get=1;  % mean
% % stat_to_get=2;  % standard deviation
% % stat_to_get=3;  % 95% confidence interval
% % stat_to_get=4;  % median
% % stat_to_get=5;  % median index
% % stat_to_get=6;  % minimum
% % stat_to_get=7;  % maximum
% % 
% % stat_to_get=[1:7];  % return all of the stats, from mean to maximum!
% % 
% % stat_to_get2 similar to stat_to_get; however, stat_to_get2 determines 
% % which statistics to calculate overall for all files.  
% % 
% % fileout='Output_file_name.txt';
% %                 % fileout is the filenmae of the output file.
% %                 % The extension '.txt' is automatically added.
% %
% % data_type=1;    % sound
% % data_type=2;    % hand arm vibrations
% % data_type=3;    % whole body vibrations
% % data_type=4;    % motion sickness
% %
% % flag=1; print absolute stats only
% % flag=2; print difference stats only
% % flag=3; print both absolute and difference stats
% %
% % if flag does not equal 1, 2, or 3 then print both absolute and
% % difference stats.
% %
% %
% % *****************************************************************
%
%
% Example='1';
%
% % This is an example using shock tube data! The data compares two
% % data acquisition rates.
%
% % An example which outputs the mean of the metrics.
%
% load shock_tube_cont;
% stat_to_get=1;
% fileout='Compare_data_acquisition_sytems';
% flag=1;
% [bb_table, bb2]=make_summary_cont_stats_table(s, stat_to_get, fileout, 1, flag);
%
%
%
% % Example='2';
% % An example which outputs all of the metrics.
%
% load shock_tube_cont;
% stat_to_get=[1:7];
% fileout='Compare_data_acquisition_sytems2';
% flag=3;
% [bb_table, bb2]=make_summary_cont_stats_table(s, stat_to_get, fileout, 1, flag);
%
% % *****************************************************************
% %
% % Subprograms
% % 
% % 
% % 
% % List of Dependent Subprograms for 
% % make_summary_cont_stats_table
% % 
% % FEX ID# is the File ID on the Matlab Central File Exchange
% % 
% % 
% % Program Name   Author   FEX ID#
% %  1) fastlts		Peter J. Rousseeuw		NA	
% %  2) fastmcd		Peter J. Rousseeuw		NA	
% %  3) file_extension		Edward L. Zechmann			
% %  4) genHyper		Ben Barrowes		6218	
% %  5) m_round		Edward L. Zechmann			
% %  6) num_impulsive_samples		Edward L. Zechmann			
% %  7) pow10_round		Edward L. Zechmann			
% %  8) print_channel_stats		Edward L. Zechmann			
% %  9) print_overall_stats		Edward L. Zechmann			
% % 10) rmean		Edward L. Zechmann			
% % 11) sd_round		Edward L. Zechmann			
% % 12) splat_cell		Edward L. Zechmann			
% % 13) t_alpha		Edward L. Zechmann			
% % 14) t_confidence_interval		Edward L. Zechmann			
% % 15) t_icpbf		Edward L. Zechmann			
% % 16) table_append_channels		Edward L. Zechmann					
% %
% % 
% % 
% % *****************************************************************
% %
% % Written by Edward L. Zechmann
% %
% %     date  9 September   2008
% %
% % modified  1 November    2008
% %
% % modified 15 November    2008    Updated Comments.  Added more code.
% % 
% % modified 18 January     2009    Updated to include rounding. 
% %
% % modified  9 October     2009    Updated Comments
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


if (nargin < 1 || isempty(s)) || ~iscell(s)
    s={};
    load shock_tube_cont;
end

if (nargin < 2 || isempty(stat_to_get)) || ~isnumeric(stat_to_get)
    stat_to_get=[1:7];
end

if (nargin < 3 || isempty(stat_to_get2)) || ~isnumeric(stat_to_get2)
    stat_to_get2=[1:7];
end

if (nargin < 4 || isempty(fileout)) || ~ischar(fileout)
    fileout='Output_cont_stats.txt';
end

if (nargin < 5 || isempty(data_type)) || ~isnumeric(data_type)
    data_type=1;
end

if (nargin < 6 || isempty(flag)) || ~isnumeric(flag)
    flag=3;
end


if nargin < 7 || isempty(ratio_metrics) || ~isnumeric(ratio_metrics)
    switch data_type
        case 1
            ratio_metrics=[3, 4, 5, 20];
        case 2
            ratio_metrics=[3, 4, 5, 20];
        case 3
            ratio_metrics=[3, 4, 5, 20];
        case 4
            ratio_metrics=[3, 4, 5, 20];
        otherwise
            ratio_metrics=[3, 4, 5, 20];
    end
end




num_files=0;
num_vars=0;
num_accels=0;
num_postures=0;

switch data_type
    case 1
        [num_files, num_vars]=size(s);
    case 2
        [num_files, num_vars, num_accels]=size(s);
    case 3
        [num_files, num_vars, num_accels, num_postures]=size(s);
    case 4
        [num_files, num_vars, num_accels]=size(s);
    otherwise
        [num_files, num_vars]=size(s);
end

num_accels2=max([num_accels, 1]);
num_postures2=max([num_postures, 1]);

num_channels_array=zeros(num_files,1);
num_stats=length(stat_to_get);
sum_num_channels_a=zeros(num_files, num_vars);
num_channels_a=zeros(num_files, num_vars, num_postures2);
num_diff_channels_a=zeros(num_files, num_vars, num_postures2);

[num_samples_ca]=num_impulsive_samples(s);



% Determine the size of the concatenated metrics table
for e1=1:num_files;    % Data files



    for e2=1:num_vars; % Number of Variables (Number of Data Acquisition Systems)

        num_channels=0;
        num_stats2=0;
        num_diff_channels=0;
        num_diff_stats2=0;
                
        for e3=1:num_accels2;

            for e4=1:num_postures2;



                switch data_type

                    case 1
                        if ~isempty(s{e1,e2})

                            if isfield(s{e1,e2}, 'stats_of_metrics')
                                [num_metrics, num_channels, num_stats2]=size(s{e1,e2}.stats_of_metrics);
                            end

                            if isfield(s{e1,e2}, 'diff_stats_of_metrics')
                                [num_metrics, num_diff_channels, num_diff_stats2]=size(s{e1,e2}.diff_stats_of_metrics);
                            end

                            [num_channels_a, num_diff_channels_a, sum_num_channels_a, num_channels_array]=table_append_channels(num_channels_a, num_diff_channels_a, sum_num_channels_a, num_channels, num_diff_channels, num_channels_array, flag, e1, e2, e4);

                        end

                    case 2

                        if ~isempty(s{e1,e2,e3})

                            if isfield(s{e1,e2,e3}, 'stats_of_total_metrics')
                                [num_metrics, num_channels, num_stats2]=size(s{e1,e2,e3}.stats_of_total_metrics);
                            end

                            if isfield(s{e1,e2,e3}, 'diff_stats_of_total_metrics')
                                [num_metrics, num_diff_channels, num_diff_stats2]=size(s{e1,e2,e3}.diff_stats_of_metrics);
                            end

                            [num_channels_a, num_diff_channels_a, sum_num_channels_a, num_channels_array]=table_append_channels(num_channels_a, num_diff_channels_a, sum_num_channels_a, num_channels, num_diff_channels, num_channels_array, flag, e1, e2, e4);

                        end

                    case 3
                        if ~isempty(s{e1,e2,e3,e4})

                            if isfield(s{e1,e2,e3,e4}, 'stats_of_total_metrics')
                                [num_metrics, num_channels, num_stats2]=size(s{e1,e2,e3,e4}.stats_of_total_metrics);
                            end

                            if isfield(s{e1,e2}, 'diff_stats_of_total_metrics')
                                [num_metrics, num_diff_channels, num_diff_stats2]=size(s{e1,e2,e3,e4}.diff_stats_of_metrics);
                            end

                            [num_channels_a, num_diff_channels_a, sum_num_channels_a, num_channels_array]=table_append_channels(num_channels_a, num_diff_channels_a, sum_num_channels_a, num_channels, num_diff_channels, num_channels_array, flag, e1, e2, e4);

                        end

                    case 4
                        if ~isempty(s{e1,e2,e3})

                            if isfield(s{e1,e2,e3}, 'stats_of_total_metrics')
                                [num_metrics, num_channels, num_stats2]=size(s{e1,e2,e3}.stats_of_total_metrics);
                            end

                            if isfield(s{e1,e2,e3}, 'diff_stats_of_total_metrics')
                                [num_metrics, num_diff_channels, num_diff_stats2]=size(s{e1,e2,e3}.diff_stats_of_metrics);
                            end

                            [num_channels_a, num_diff_channels_a, sum_num_channels_a, num_channels_array]=table_append_channels(num_channels_a, num_diff_channels_a, sum_num_channels_a, num_channels, num_diff_channels, num_channels_array, flag, e1, e2, e4);

                        end

                    otherwise

                        if ~isempty(s{e1,e2})

                            if isfield(s{e1,e2}, 'stats_of_metrics')
                                [num_metrics, num_channels, num_stats2]=size(s{e1,e2}.stats_of_metrics);
                            end

                            if isfield(s{e1,e2}, 'diff_stats_of_metrics')
                                [num_metrics, num_diff_channels, num_diff_stats2]=size(s{e1,e2}.diff_stats_of_metrics);
                            end

                            [num_channels_a, num_diff_channels_a, sum_num_channels_a, num_channels_array]=table_append_channels(num_channels_a, num_diff_channels_a, sum_num_channels_a, num_channels, num_diff_channels, num_channels_array, flag, e1, e2, e4);

                        end

                end
            end
        end

    end

end


num_rows=sum(num_channels_array);
num_columns=num_vars*num_metrics;
bb2=zeros(num_rows, num_columns);
max_channels=max(num_channels_array);

num_rows=sum(num_channels_array)+num_files-1;
num_columns=num_vars*num_metrics+num_metrics-1;
bb=zeros(num_rows, num_columns);

% Initialize the concatenated metrics table
column_heading=cell(3, num_columns );
num_row_headings=4;
row_heading=cell(num_rows,num_row_headings);

% Create the files to save the sound and vibrations data
[fileout_base, ext]=file_extension(fileout);

% Open the output file
fid=fopen([fileout_base '.txt'], 'w');

% Fill in the concatenated metrics table
% Add row headings and column headings

for e8=1:num_stats;

    for e1=1:num_files;    % Data files

        for e11=1:num_postures2;

            for e2=1:num_vars; % Number of Variables (Number of Data Acquisition Systems)

                for e10=1:num_accels2;

                    switch data_type

                        case 1

                            if ~isempty(s{e1,e2})

                                num_channels=num_channels_a(e1, e2);
                                num_diff_channels=num_diff_channels_a(e1, e2);
                                sum_num_channels=sum_num_channels_a(e1, e2);

                                if sum_num_channels >= 1

                                    for e7=1:sum_num_channels; % Channels

                                        for e4=1:num_metrics; % Data Metrics

                                            e5=sum(num_channels_array(1:e1))-num_channels_array(e1)+e7;
                                            e6=num_vars*(e4-1)+e2;

                                            switch flag

                                                case 1
                                                    if e7 <= num_channels
                                                        bb2(e5, e6)=s{e1,e2}.stats_of_metrics(e4, e7, stat_to_get(e8));
                                                    end
                                                case 2
                                                    if e7 <= num_diff_channels
                                                        bb2(e5, e6)=s{e1,e2}.diff_stats_of_metrics(e4, e7, stat_to_get(e8));
                                                    end
                                                case 3
                                                    if e7 <= num_channels
                                                        bb2(e5, e6)=s{e1,e2}.stats_of_metrics(e4, e7, stat_to_get(e8));
                                                    elseif e7-num_channels <= num_diff_channels
                                                        bb2(e5, e6)=s{e1,e2}.diff_stats_of_metrics(e4, e7-num_channels, stat_to_get(e8));
                                                    end
                                                otherwise
                                                    if e7 <= num_channels
                                                        bb2(e5, e6)=s{e1,e2}.stats_of_metrics(e4, e7, stat_to_get(e8));
                                                    elseif e7-num_channels <= num_diff_channels
                                                        bb2(e5, e6)=s{e1,e2}.diff_stats_of_metrics(e4, e7-num_channels, stat_to_get(e8));
                                                    end
                                            end

                                            e5=e1-1+sum(num_channels_array(1:e1))-num_channels_array(e1)+e7;
                                            e6=(num_vars+1)*(e4-1)+e2;

                                            switch flag

                                                case 1
                                                    if e7 <= num_channels
                                                        bb(e5, e6)=s{e1,e2}.stats_of_metrics(e4, e7, stat_to_get(e8));
                                                    end
                                                case 2
                                                    if e2 <= num_diff_channels
                                                        bb(e5, e6)=s{e1,e2}.diff_stats_of_metrics(e4, e7, stat_to_get(e8));
                                                    end
                                                case 3
                                                    if e7 <= num_channels
                                                        bb(e5, e6)=s{e1,e2}.stats_of_metrics(e4, e7, stat_to_get(e8));
                                                    elseif e2-num_channels <= num_diff_channels
                                                        bb(e5, e6)=s{e1,e2}.diff_stats_of_metrics(e4, e7-num_channels, stat_to_get(e8));
                                                    end
                                                otherwise
                                                    if e7 <= num_channels
                                                        bb(e5, e6)=s{e1,e2}.stats_of_metrics(e4, e7, stat_to_get(e8));
                                                    elseif e7-num_channels <= num_diff_channels
                                                        bb(e5, e6)=s{e1,e2}.diff_stats_of_metrics(e4, e7-num_channels, stat_to_get(e8));
                                                    end
                                            end

                                            if e5 == 1
                                                if e2==1
                                                    column_heading{1, e6}=s{e1,e2}.metrics_description{1,e4};
                                                    if ismember(e4, ratio_metrics)
                                                       column_heading{2, e6}='ratio';
                                                    else
                                                        column_heading{2, e6}=s{e1,e2}.metrics_description{2,e4};
                                                    end
                                                end
                                                column_heading{3, e6}=['var ' num2str(e2)];
                                            end

                                            if e6 == 1
                                                if e7 == 1
                                                    row_heading{e5, 1}=s{e1,e2}.filename;
                                                end
                                            end

                                            if e4 == 1 && isequal(e2, 1)

                                                switch flag

                                                    case 1
                                                        if e7 <= num_channels
                                                            row_heading{e5, 3}=['Channel ' num2str(e7)];
                                                        end
                                                    case 2
                                                        if e7 <= num_diff_channels
                                                            row_heading{e5, 3}=['Diff Channel ' num2str(s{e1,e2}.diff_chan(2*e7-1)), ' - ', num2str(s{e1,e2}.diff_chan(2*e7))];
                                                        end
                                                    case 3
                                                        if e7 <= num_channels
                                                            row_heading{e5, 3}=['Channel ' num2str(e7)];
                                                        elseif e7-num_channels <= num_diff_channels
                                                            row_heading{e5, 3}=['Diff Channel ' num2str(s{e1,e2}.diff_chan(2*(e7-num_channels)-1)), ' - ', num2str(s{e1,e2}.diff_chan(2*(e7-num_channels)))];
                                                        end
                                                    otherwise
                                                        if e7 <= num_channels
                                                            row_heading{e5, 3}=['Channel ' num2str(e7)];
                                                        elseif e7-num_channels <= num_diff_channels
                                                            row_heading{e5, 3}=['Diff Channel ' num2str(s{e1,e2}.diff_chan(2*(e7-num_channels)-1)), ' - ', num2str(s{e1,e2}.diff_chan(2*(e7-num_channels)))];
                                                        end
                                                end
                                            end
                                        end

                                    end

                                end
                            end

                        case 2

                        case 3

                        case 4

                        otherwise

                    end

                end
            end
        end
    end

    % Round the data to 3 significant digits, then
    % convert the data array into cell array of strings
    [A2, A_str]=sd_round(bb, 3);

    % Concatenate the row_heading, column heading, and data text strings

    bb_table=cell(num_rows+3, num_columns+num_row_headings);

    bb_table(1:3, (num_row_headings+1):end)=column_heading;
    bb_table(4:end, 1:num_row_headings)=row_heading;

    bb_table(4:end, (num_row_headings+1):end)=A_str;

    % Output the name of the metric

    fprintf(fid, '%s\t\r\n', [s{1,1}.stats_description{stat_to_get(e8)}, ' For Each file']);

    %  Print the column headings
    for e1=1:3;

        for e2=1:(num_columns+num_row_headings);
            fprintf(fid, '%s\t', bb_table{e1, e2});
        end

        if isequal(e1,1)
            fprintf(fid, '\t%s', 'Number of Samples');
            for e3=1:(num_vars-1); % Number of Variables (Number of Data Acquisition Systems)
                fprintf(fid, '\t');
            end
            fprintf(fid, '\t');
        elseif isequal(e1,3)
            for e2=1:num_vars; % Number of Variables (Number of Data Acquisition Systems)
                fprintf(fid, '\t%s', ['var', num2str(e2)]);
            end
            fprintf(fid, '\t');
        else
            for e2=1:num_vars; % Number of Variables (Number of Data Acquisition Systems)
                fprintf(fid, '\t');
            end
            fprintf(fid, '\t');
        end

        fprintf(fid, '\r\n');

    end

    fprintf(fid, '\r\n');

    for e1=1:num_files;    % Data files

        %num_channels=num_channels_a(e1, e3);
        %num_diff_channels=num_diff_channels_a(e1, e3);

        for e2=1:num_channels_array(e1); % Channels

            e5=e1-1+sum(num_channels_array(1:e1))-num_channels_array(e1)+e2;

            % Print the row headings
            for e7=1:num_row_headings;
                fprintf(fid, '%s\t', bb_table{e5+3, e7});
            end

            % Print the data
            for e4=1:num_metrics; % Data Metrics
                for e3=1:num_vars; % Number of Variables (Number of Data Acquisition Systems)

                    num_channels=num_channels_a(e1, e3);
                    num_diff_channels=num_diff_channels_a(e1, e3);
                    sum_num_channels=sum_num_channels_a(e1, e3);

                    if ~isempty(s{e1,e3}) && logical(e2 <= sum_num_channels)
                        e6=(num_vars+1)*(e4-1)+e3;

                        fprintf(fid, '%s\t', bb_table{e5+3, e6+num_row_headings});
                    else
                        fprintf(fid, '\t');
                    end
                end
                fprintf(fid, '\t');

            end

            for e3=1:num_vars; % Number of Variables (Number of Data Acquisition Systems)

                switch flag

                    case 1
                        if e2 <= num_channels
                            fprintf(fid, '%i\t', num_samples_ca{e1, e3}(e2, 1));
                        end
                    case 2
                        if e2 <= num_diff_channels
                            fprintf(fid, '%i\t', num_samples_ca{e1, e3}(e2, 1));
                        end
                    case 3
                        if e2 <= num_channels
                            fprintf(fid, '%i\t', num_samples_ca{e1, e3}(e2, 1));
                        elseif e2-num_channels <= num_diff_channels
                            fprintf(fid, '%i\t', num_samples_ca{e1, e3}(e2-num_channels, 1));
                        end
                    otherwise
                        if e2 <= num_channels
                            fprintf(fid, '%i\t', num_samples_ca{e1, e3}(e2, 1));
                        elseif e2-num_channels <= num_diff_channels
                            fprintf(fid, '%i\t', num_samples_ca{e1, e3}(e2-num_channels, 1));
                        end
                end
            end

            fprintf(fid, '\r\n');
        end
        fprintf(fid, '\r\n');
    end

    fprintf(fid, '\r\n');

    for e9=1:length(stat_to_get2);
        [fid, mean_vals, max_num_channels, max_num_diff_channels]=print_channel_stats(s, fid, flag, max_channels, num_metrics, num_vars, num_files, stat_to_get(e8), stat_to_get2(e9), num_channels_a, sum_num_channels_a, num_diff_channels_a, round_kind, round_digits);
        fprintf(fid, '\r\n');
    end


    for e9=1:length(stat_to_get2);
        [fid]=print_overall_stats(fid, s, flag, mean_vals, max_num_channels, max_num_diff_channels, num_metrics, num_vars, stat_to_get2(e9), round_kind, round_digits);
        fprintf(fid, '\r\n');
    end

    fprintf(fid, '\r\n\r\n\r\n');

end





fclose(fid);
fclose('all');
