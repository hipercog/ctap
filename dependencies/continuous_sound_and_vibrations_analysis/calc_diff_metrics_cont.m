function [s]=calc_diff_metrics_cont(s, diff_chan, flag, ratio_metrics, round_kind, round_digits, abs_other)
% % calc_diff_metrics_cont: Calculates the differences in metrics between pairs of channels: Impulsive Noise Meter
% %
% % Syntax:
% %
% % [s]=calc_diff_metrics_cont(s, diff_chan, flag)
% %
% % *****************************************************************
% %
% % Description:
% %
% % This program takes the output from the Impulsive_Noise_Meter and
% % calculates the differences in metrics between pairs of channels:
% % Impulsive Noise Meter.
% %
% % This program is specifically for analyzing hearing protection for
% % impulsive noise.
% %
% % *****************************************************************
% %
% % Input Variables
% %
% % s is the data structure created using the Impulsive_Noise_Meter.
% %
% % diff_chan=[1,2];    % A paired column vector of channel numbers.
% %                     %
% %                     % The odd and even elements of the vector are
% %                     % paired for calculating differences
% %                     % in metrics across channels.
% %                     %
% %                     % default is diff_chan=(1:2)';
% % 
% % flag=1;             % flag selects the data type to be analyzed
% %                     % 1 is for Sound data
% %                     % 2 is for Hand Arm 
% %                     % 3 is for Whole Body
% %                     % 4 is for Motion Sicknes
% %                     % 
% %                     % The default value is 1
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
% % s is the data structure created using the
% %      Continuous_Sound_and_Vibrations_Analysis program.
% %      The data type of s is determined by the input parameter flag.  
% %      
% % This program modifies s by adding the following variables
% %      diff_chan
% %      diff_metrics
% %      diff_stats_of_metrics
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
% load shock_tube_cont;
% stat_to_get=1;
% fileout='analysis1';
% [bb_table, bb2]=make_table_compare_systems_cont(s, stat_to_get, fileout);
%
%
% % An example which outputs all of the metrics.
%
% load shock_tube_cont;
% stat_to_get=[1:8];
% fileout='analysis2';
% [bb_table, bb2]=make_table_compare_systems_cont(s, stat_to_get, fileout);
% 
% 
% 
% % ********************************************************************
% %
% %
% % Subprograms
% %
% %
% % 
% % List of Dependent Subprograms for 
% % calc_diff_metrics_cont
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
% %  8) t_alpha		Edward L. Zechmann			
% %  9) t_confidence_interval		Edward L. Zechmann			
% % 10) t_icpbf		Edward L. Zechmann			
% %
% %
% % *****************************************************************
% %
% % Written by Edward L. Zechmann
% %
% %     date   1 November   2008
% %
% % modified 15 January     2009    Updated the descriptive statistics to 
% %                                 include the arthimetic mean.  
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
% % See Also:  calc_diff_metrics, make_table_compare_systems, Impulsive_Noise_Meter, Continuous_Sound_and_Vibrations_Analysis
% %


if nargin < 1 || isempty(s) || ~iscell(s)
    load('shock_tube_cont');
    warning('Loading and analyzing the default shock tube data.');
end

if nargin < 2 || isempty(diff_chan) || ~isnumeric(diff_chan)
    diff_chan=(1:2)';
end

if nargin < 3 || isempty(flag) || ~isnumeric(flag)
    flag=1;
end

flag=round(flag);
if flag < 1
    flag=1;
end

if flag > 4 
    flag=4;
end

if nargin < 4 || isempty(ratio_metrics) || ~isnumeric(ratio_metrics)
    ratio_metrics=[3, 4, 5, 20];
end

if nargin < 5 || isempty(round_kind) || ~isnumeric(round_kind)
    round_kind=1;
end


if nargin < 6 || isempty(round_digits) || ~isnumeric(round_digits)
    round_digits=3;
end




num_files=0;
num_vars=0;
num_accels=0;
num_postures=0;

switch flag

    case 1
        % snd
        % Sound
        [num_files, num_vars]=size(s);
        num_channels_array=zeros(num_files,1);
    case 2
        % vibras_ha
        % Hand Arm Vibrations
        [num_files, num_vars, num_accels]=size(s);
        num_channels_array=zeros(num_files,1);
    case 3
        % vibras_wb
        % Whole Body Vibrations
        [num_files, num_vars, num_accels, num_postures]=size(s);
        num_channels_array=zeros(num_files,1);
    case 4
        % vibras_ms
        % Motion Sickness
        [num_files, num_vars, num_accels]=size(s);
        num_channels_array=zeros(num_files,1);
    otherwise
        % snd
        % Sound
        [num_files, num_vars]=size(s);
        num_channels_array=zeros(num_files,1);
end


% Determine the size of the concatenated metrics table
for e1=1:num_files;    % Data files

    num_channels=[];

    for e2=1:num_vars; % Number of Variables (Number of Data Acquisition Systems

        switch flag

            case 1
                if ~isempty(s{e1,e3})
                    [num_metrics, num_channels, num_stats2]=size(s{e1,e2}.stats_of_metrics);
                    if num_channels >= 1
                        num_channels_array(e1)=max([num_channels, num_channels_array(e1)]);
                    end
                end
            case 2
                for e3=1:num_accels;
                    if ~isempty(s{e1,e3})
                        [num_metrics, num_channels, num_stats2]=size(s{e1,e2,e3}.stats_of_total_metrics);
                        if num_channels >= 1
                            num_channels_array(e1)=max([num_channels, num_channels_array(e1)]);
                        end
                    end
                end
            case 3
                for e3=1:num_accels;
                    for e4=1:num_postures;
                        if ~isempty(s{e1,e3})
                            [num_metrics, num_channels, num_stats2]=size(s{e1,e2,e3,e4}.stats_of_total_metrics);
                            if num_channels >= 1
                                num_channels_array(e1)=max([num_channels, num_channels_array(e1)]);
                            end
                        end
                    end
                end
            case 4
                for e3=1:num_accels;
                    if ~isempty(s{e1,e3})
                        [num_metrics, num_channels, num_stats2]=size(s{e1,e2,e3}.stats_of_total_metrics);
                        if num_channels >= 1
                            num_channels_array(e1)=max([num_channels, num_channels_array(e1)]);
                        end
                    end
                end
            otherwise
                if ~isempty(s{e1,e3})
                    [num_metrics, num_channels, num_stats2]=size(s{e1,e2}.stats_of_metrics);
                    if num_channels >= 1
                        num_channels_array(e1)=max([num_channels, num_channels_array(e1)]);
                    end
                end

        end

    end

end



num_kinds=length(round_kind);
num_digits=length(round_digits);


num_diff_chan=floor(length(diff_chan)/2);

num_accels2=max([num_accels,1]);
num_postures2=max([num_postures,1]);

% Fill in the concatenated metrics table
% Add row headings and column headings

for e1=1:num_files;    % Data files

    for e2=1:num_vars; % Number of Variables (Number of Data Acquisition Systems)

        for e3=1:num_accels2;

            for e4=1:num_postures2;


                switch flag
                    case 1
                        [num_metrics, num_channels, num_stats2]=size(s{e1,e2}.stats_of_metrics);
                    case 2
                        [num_metrics, num_channels, num_stats2]=size(s{e1,e2,e3}.stats_of_total_metrics);
                    case 3
                        [num_metrics, num_channels, num_stats2]=size(s{e1,e2,e3,e4}.stats_of_total_metrics);
                    case 4
                        [num_metrics, num_channels, num_stats2]=size(s{e1,e2,e3}.stats_of_total_metrics);
                    otherwise
                        [num_metrics, num_channels, num_stats2]=size(s{e1,e2}.stats_of_metrics);
                end

                if num_channels >= 1

                    switch flag
                        case 1
                            s{e1,e2}.diff_chan=diff_chan;
                        case 2
                            s{e1,e2,e3}.diff_chan=diff_chan;
                        case 3
                            s{e1,e2,e3,e4}.diff_chan=diff_chan;
                        case 4
                            s{e1,e2,e3}.diff_chan=diff_chan;
                        otherwise
                            s{e1,e2}.diff_chan=diff_chan;
                    end

                    % calculate the differences, then the statistics then
                    % save them to the structure s.
                    for e5=1:num_diff_chan; % Channels

                        for e6=1:num_metrics; % Data Metrics

                            switch flag
                                case 1
                                    buf1=s{e1,e2}.metrics{diff_chan(2*e5-1), 1}(:, e6);
                                    buf2=s{e1,e2}.metrics{diff_chan(2*e5), 1}(:, e6);
                                case 2
                                    buf1=s{e1,e2,e3}.total_metrics{diff_chan(2*e5-1), 1}(:, e6);
                                    buf2=s{e1,e2,e3}.total_metrics{diff_chan(2*e5), 1}(:, e6);
                                case 3
                                    buf1=s{e1,e2,e3,e4}.total_metrics{diff_chan(2*e5-1), 1}(:, e6);
                                    buf2=s{e1,e2,e3,e4}.total_metrics{diff_chan(2*e5), 1}(:, e6);
                                case 4
                                    buf1=s{e1,e2,e3}.total_metrics{diff_chan(2*e5-1), 1}(:, e6);
                                    buf2=s{e1,e2,e3}.total_metrics{diff_chan(2*e5), 1}(:, e6);
                                otherwise
                                    buf1=s{e1,e2}.metrics{diff_chan(2*e5-1), 1}(:, e6);
                                    buf2=s{e1,e2}.metrics{diff_chan(2*e5), 1}(:, e6);
                            end
                            
                            [m1_buf1, n1_buf1]=size(buf1);
                            [m1_buf2, n1_buf2]=size(buf2);

                            m1_buf3=min([m1_buf1 m1_buf2]);
                            n1_buf3=min([n1_buf1 n1_buf2]);

                            
                            
                            if num_kinds >= (e6)
                                rk=round_kind(e6);
                            else
                                rk=1;
                            end


                            if num_digits >= round_digits(e6)
                                rd=round_digits(e6);
                            else
                                rd=3;
                            end
                            
                            % Determine whether to compute a difference or
                            % ratio.  Calculate a ratio for metrics  that
                            % are a member of ratio_metrics.
                            if ismember(e6, ratio_metrics) 
                                rk=1;
                                rd=3;
                                buf3=abs(buf1(1:m1_buf3,1:n1_buf3))./abs(buf2(1:m1_buf3,1:n1_buf3));
                            else
                                buf3=abs(buf1(1:m1_buf3,1:n1_buf3))-abs(buf2(1:m1_buf3,1:n1_buf3));
                            end
                            

                            
                            switch flag
                                case 1
                                    s{e1,e2}.diff_metrics{e5,1}(:,e6)=m_round(buf3, rk, rd);
                                case 2
                                    s{e1,e2,e3}.diff_total_metrics{e5,1}(:,e6)=m_round(buf3, rk, rd);
                                case 3
                                    s{e1,e2,e3,e4}.diff_total_metrics{e5,1}(:,e6)=m_round(buf3, rk, rd);
                                case 4
                                    s{e1,e2,e3}.diff_total_metrics{e5,1}(:,e6)=m_round(buf3, rk, rd);
                                otherwise
                                    s{e1,e2}.diff_total_metrics{e5,1}(:,e6)=m_round(buf3, rk, rd);
                            end
                            
                            % Calculate the Arithmetic Mean
                            bmean_avg1=mean(buf3);
                            
                            % Calculate the Robust Mean
                            [ bmean_avg2 ] = rmean(buf3(:), 0);
                            %bmean_avg2=LMSloc(buf3);

                            % Calculate standard deviation
                            stdrt=std(buf3);             

                            % Calculate 95% confidence interval of
                            [ci_int]=t_confidence_interval(buf3, 0.95); 

                            % the standard error of the
                            % t-distribution with a two-sided test.
                            medianrt=median(buf3);
                            
                            % Calculate teh MEdian Index
                            [mbuf ix]=min(abs(buf3-medianrt));
                            
                            % Calculate the Minimum
                            minrt=min(buf3);
                            
                            % Calculate the Maximum
                            maxrt=max(buf3);

                            
                            switch flag
                                case 1
                                    s{e1,e2}.diff_stats_of_metrics(e6, e5, 1)=m_round(bmean_avg1, rk, rd);
                                    s{e1,e2}.diff_stats_of_metrics(e6, e5, 2)=m_round(bmean_avg2, rk, rd);
                                    s{e1,e2}.diff_stats_of_metrics(e6, e5, 3)=m_round(stdrt, 1, 3);
                                    s{e1,e2}.diff_stats_of_metrics(e6, e5, 4)=m_round(ci_int, 1, 3);
                                    s{e1,e2}.diff_stats_of_metrics(e6, e5, 5)=ix;
                                    s{e1,e2}.diff_stats_of_metrics(e6, e5, 6)=m_round(medianrt, rk, rd);
                                    s{e1,e2}.diff_stats_of_metrics(e6, e5, 7)=m_round(minrt, rk, rd);
                                    s{e1,e2}.diff_stats_of_metrics(e6, e5, 8)=m_round(maxrt, rk, rd);
                                case 2
                                    s{e1,e2,e3}.diff_stats_of_total_metrics(e6, e5, 1)=m_round(bmean_avg1, rk, rd);
                                    s{e1,e2,e3}.diff_stats_of_total_metrics(e6, e5, 2)=m_round(bmean_avg2, rk, rd);
                                    s{e1,e2,e3}.diff_stats_of_total_metrics(e6, e5, 3)=m_round(stdrt, rk, rd);
                                    s{e1,e2,e3}.diff_stats_of_total_metrics(e6, e5, 4)=m_round(ci_int, 1, 3);
                                    s{e1,e2,e3}.diff_stats_of_total_metrics(e6, e5, 5)=ix;
                                    s{e1,e2,e3}.diff_stats_of_total_metrics(e6, e5, 6)=m_round(medianrt, rk, rd);
                                    s{e1,e2,e3}.diff_stats_of_total_metrics(e6, e5, 7)=m_round(minrt, rk, rd);
                                    s{e1,e2,e3}.diff_stats_of_total_metrics(e6, e5, 8)=m_round(maxrt, rk, rd);
                                case 3
                                    s{e1,e2,e3,e4}.diff_stats_of_total_metrics(e6, e5, 1)=m_round(bmean_avg1, rk, rd);
                                    s{e1,e2,e3,e4}.diff_stats_of_total_metrics(e6, e5, 2)=m_round(bmean_avg2, rk, rd);
                                    s{e1,e2,e3,e4}.diff_stats_of_total_metrics(e6, e5, 3)=m_round(stdrt, rk, rd);
                                    s{e1,e2,e3,e4}.diff_stats_of_total_metrics(e6, e5, 4)=m_round(ci_int, 1, 3);
                                    s{e1,e2,e3,e4}.diff_stats_of_total_metrics(e6, e5, 5)=ix;
                                    s{e1,e2,e3,e4}.diff_stats_of_total_metrics(e6, e5, 6)=m_round(medianrt, rk, rd);
                                    s{e1,e2,e3,e4}.diff_stats_of_total_metrics(e6, e5, 7)=m_round(minrt, rk, rd);
                                    s{e1,e2,e3,e4}.diff_stats_of_total_metrics(e6, e5, 8)=m_round(maxrt, rk, rd);
                                case 4
                                    s{e1,e2,e3}.diff_stats_of_total_metrics(e6, e5, 1)=m_round(bmean_avg1, rk, rd);
                                    s{e1,e2,e3}.diff_stats_of_total_metrics(e6, e5, 2)=m_round(bmean_avg2, rk, rd);
                                    s{e1,e2,e3}.diff_stats_of_total_metrics(e6, e5, 3)=m_round(stdrt, rk, rd);
                                    s{e1,e2,e3}.diff_stats_of_total_metrics(e6, e5, 4)=m_round(ci_int, 1, 3);
                                    s{e1,e2,e3}.diff_stats_of_total_metrics(e6, e5, 5)=ix;
                                    s{e1,e2,e3}.diff_stats_of_total_metrics(e6, e5, 6)=m_round(medianrt, rk, rd);
                                    s{e1,e2,e3}.diff_stats_of_total_metrics(e6, e5, 7)=m_round(minrt, rk, rd);
                                    s{e1,e2,e3}.diff_stats_of_total_metrics(e6, e5, 8)=m_round(maxrt, rk, rd);
                                otherwise
                                    s{e1,e2}.diff_stats_of_metrics(e6, e5, 1)=m_round(bmean_avg1, rk, rd);
                                    s{e1,e2}.diff_stats_of_metrics(e6, e5, 2)=m_round(bmean_avg2, rk, rd);
                                    s{e1,e2}.diff_stats_of_metrics(e6, e5, 3)=m_round(stdrt, rk, rd);
                                    s{e1,e2}.diff_stats_of_metrics(e6, e5, 4)=m_round(ci_int, 1, 3);
                                    s{e1,e2}.diff_stats_of_metrics(e6, e5, 5)=ix;
                                    s{e1,e2}.diff_stats_of_metrics(e6, e5, 6)=m_round(medianrt, rk, rd);
                                    s{e1,e2}.diff_stats_of_metrics(e6, e5, 7)=m_round(minrt, rk, rd);
                                    s{e1,e2}.diff_stats_of_metrics(e6, e5, 8)=m_round(maxrt, rk, rd);
                            end
                            
                        end
                    end
                end
            end
        end
    end
end



