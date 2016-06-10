function [h, h2, wb_th_array]=plot_snd_vibs(SP, F_SP, vibs, F_vibs, Tool_Name, filename1, indices2, SP_local_max2, same_ylim, plot_str, dB_scale  )
% % plot_snd_vibs(: plots sound and vibrations data in the time domain
% %
% % Syntax:
% %
% % [h, h2, wb_th_array]=plot_snd_vibs(SP, F_SP, vibs, F_vibs, Tool_Name, filename1, indices2, SP_local_max2, same_ylim, plot_str  );
% %
% % *********************************************************************
% %
% % Description
% %
% % This progam plots the time record and appends a circle at points
% % specified by indices2.  for sound and vibrations data and
% % returns a handle to the figure and an array of handles to the subaxes.
% %
% % *********************************************************************
% %
% % Input Arguments
% %
% % SP=rand(1, 50000);          % Pa sound pressure time record  waveform
% %
% % F_SP=50000;                 % Hz sampling rate
% %
% % vibs=rand(1, 50000);        % m/s^2 acceleration time record  waveform
% %
% % F_vibs=50000;               % Hz sampling rate
% %
% % Tool_Name='Hammer Drill';   % string input to determine the Name of the
% %                             % test device.  Tool_Name=1; will cause the
% %                             % program to seach a variable named Description
% %                             % for the Tool_Name.
% %
% % filename1='data_1.txt';     % filename that appears in the plot title
% %
% % indices2={};                % indices to append circles to indicate the
% %                             % locations of the impulsive peaks.
% %
% % SP_local_max2={};           % sound pressures of the impulsive peaks
% %
% % same_ylim=1;                % 1 will set all of the ylimits of each of the
% %                             % channels to the same value.
% %
% % plot_str={'Protected', 'Unprotected'};
% %                             % Add a string to each subaxes indicating the
% %                             % meaning of the data.  For hearing protector
% %                             % research one microphone is under the
% %                             % hearing protector so it is 'Protected'
% %                             % and the other microphone is exposed so it is
% %                             % 'Unprotected'.
% %
% % dB_scale=0;         % 1 use a dB scale to plot Y-sxis time record
% %                     % 0 use a linear scale to plot Y-sxis time record
% %                     %
% %                     % default is dB_scale=0;
% %
% % *********************************************************************
% %
% %
% % Output Variables
% %
% % h is the handle for the figure.
% %
% % h2 is the array of handles for the subaxes.
% %
% % wb_th_array is the array of handles for the text descriptions of the
% % sensors.
% %
% %
% % *********************************************************************
%
% Example='1';
%
% SP=rand(1, 50000);        % Pa sound pressure time record  waveform
%
% F_SP=50000;               % Hz sampling rate
%
% vibs=rand(1, 50000);      % m/s^2 acceleration time record  waveform
%
% F_vibs=50000;             % Hz sampling rate
%
% Tool_Name='Hammer Drill'; % string input to determine the Name of the
%                           % test device.  Tool_Name=1; will cause the
%                           % program to seach a variable named Description
%                           % for the Tool_Name.
%
% filename1='data_1.txt';   % filename that appears in the plot title
%
% indices2={};              % indices to append circles to indicate the
%                           % locations of the impulsive peaks.
%
% SP_local_max2={};         % sound pressures of the impulsive peaks
%
% same_ylim=1;              % 1 will set all of the ylimits of each of the
%                           % channels to the same value.
%
% plot_str={'Protected', 'Unprotected'};
%                           % Add a string to each subaxes indicating the
%                           % meaning of the data.  For hearing protector
%                           % research one microphone is under the
%                           % hearing protector so it is 'Protected'
%                           % and the other microphone is exposed so it is
%                           % 'Unprotected'.
%
% dB_scale=0;               % 1 use a dB scale to plot Y-sxis time record
%                           % 0 use a linear scale to plot Y-sxis time record
%                           %
%                           % default is dB_scale=0;
%
% [h, h2, wb_th_array]=plot_snd_vibs(SP, F_SP, vibs, F_vibs, Tool_Name, filename1, indices2, SP_local_max2, same_ylim, plot_str, dB_scale  );
%
%
%
%
% % *********************************************************************
% %
% %
% % Subprograms
% %
% %
% %
% % List of Dependent Subprograms for
% % plot_snd_vibs
% %
% % FEX ID# is the File ID on the Matlab Central File Exchange
% %
% %
% % Program Name   Author   FEX ID#
% % 1) convert_double		Edward L. Zechmann
% % 2) fix_YTick		Edward L. Zechmann
% % 3) parseArgs		Malcolm Wood		10670
% % 4) psuedo_box		Edward L. Zechmann
% % 5) resample_plot		Edward L. Zechmann
% % 6) subaxis		Aslak Grinsted		3696
% %
% % *********************************************************************
% %
% % Program Written by Edward L. Zechmann
% %
% %     date 10 August      2007
% %
% % modified 19 December    2007    Added Comments
% %
% % modified  7 January     2008    Fixed a big in initializing
% %                                 plot_str
% %                                 made input arguments optional
% %                                 added additional comments
% %
% % modified  5 September   2008    Updated Comments
% %
% % modified 22 March       2009    Added db_scale to select dB or linear
% %                                 scale for plotting the sound time
% %                                 record.
% %                                 Updated Comments
% %
% % modified 10 August      2010    Fixed bug in plotting location of peaks
% %                                 Updated comments
% %
% % modified  6 October     2009    Updated comments
% %
% % modified 12 October    2010    Fixed bug in error handling filename1
% %                                 input.  Updated comments
% %
% %
% %
% % *********************************************************************
% %
% % Please feel free to modify this code.
% %

if nargin < 1
    SP=randn(2, 50000);
end

if nargin < 2 || isempty(F_SP) || ~isnumeric(F_SP)
    F_SP=50000;
end

if nargin < 3
    vibs=randn(2, 50000);
end

if nargin < 4 || isempty(F_vibs) || ~isnumeric(F_vibs)
    F_vibs=50000;
end

if nargin < 5 || isempty(Tool_Name) || ~ischar(Tool_Name)
    Tool_Name='';
end

if nargin < 6 || isempty(filename1) || ~ischar(filename1)
    filename1='';
end

if nargin < 7 || isempty(indices2) || ~iscell(indices2)
    indices2={};
end

if nargin < 8 || isempty(SP_local_max2) || ~iscell(SP_local_max2)
    SP_local_max2={};
end

if nargin < 9 || isempty(same_ylim) || ~isnumeric(same_ylim)
    same_ylim=0;
end

if nargin < 10 || isempty(plot_str) || ~iscell(plot_str)
    plot_str=[];
end

if nargin < 11 || isempty(dB_scale) || ~isnumeric(dB_scale)
    dB_scale=0;
end

if ~isequal(dB_scale,1)
    dB_scale=0;
end

% make sure that input data is double precision.
[SP, vibs, F_SP, F_vibs]=convert_double(SP, vibs, F_SP, F_vibs);

% The amount of space between the margin and the waveform
per_mar=0.16;

% initilize the figure margins, spacings, and dimensions
sh=0.0;
sv=0.0;
ml=0.14;
mr=0.1;
mt=0.08;
mb=0.12;

% determine the number of sub plots
[m1, n1]=size(SP);
if m1 > n1
    SP=SP';
    [m1 n1]=size(SP);
end

[m2, n2]=size(vibs);
if m2 > n2
    vibs=vibs';
    [m2 n2]=size(vibs);
end

t_SP=1/F_SP*(0:(n1-1));
t_vibs=1/F_vibs*(0:(n2-1));

last_x_axis=m1+m2;


if m1 > 0 && m2 > 0
    nn=m1+m2+1;
else
    nn=m1+m2;
end

% initialize the figures
h=figure(1);
delete(h);
h=figure(1);
h1=[];
h2=[];
wb_th_array=zeros(1, m1+m2);

% determine the y-axis limits
% the uppeer and lower limits are the same
if same_ylim == 1
    ylim1=per_mar*ceil( 10*(max(max(abs(SP)))) );
end

% determine the x-axis limits
min_t=min([min(t_SP'), min(t_vibs')]);
max_t=max([max(t_SP'), max(t_vibs')]);

% determine whether to resample the plot or not
% data processing becomes too slow when the number of data points
% becomes too high.
% 1,000,000 data points is the cutoff for implementing thr resampling
% routine
tot_num_samples=m1*n1+m2*n2;
flag_rs=0;
if tot_num_samples > 1000000
    flag_rs=1;
end


% if the plot_str is too small then add more emmpty string elements
if (length(plot_str) < last_x_axis) || isempty(plot_str)

    % initialize the plot_str
    plot_str2=cell(last_x_axis, 1);
    for e1=1:last_x_axis;

        if e1 <= length(plot_str)
            plot_str2{e1,1}=plot_str{e1};
        else
            plot_str2{e1,1}='';
        end

    end

    plot_str=plot_str2;

end



% plot the sound data
for e2=1:m1;


    subaxis(nn, 1, e2, 'sh', sh, 'sv', sv , 'pl', 0, 'pr', 0, 'pt', 0, 'pb', 0, 'ml', ml, 'mr', mr, 'mt', mt, 'mb', mb);
    
    t_SP_rs=[];
    SP_rs=[];
    if flag_rs == 1
        [t_SP_rs, SP_rs]=resample_plot(t_SP, SP(e2, :));
        plot(t_SP_rs, SP_rs');
        clear('t_SP_rs');
        clear('SP_rs');
    else
        plot(t_SP, SP(e2, :)');
    end
    hold on;
    h1=gca;
    h2=[h2 h1];

    if e2 == floor((m1+1)/2)
        if isequal( dB_scale, 0)
            ylabel('Sound (Pa)', 'Fontsize', 16);
        else
            ylabel('Sound (dB ref. 20 \muPa rms)', 'Fontsize', 16);
        end

    end

    if same_ylim ~= 1
        ylim1=per_mar*ceil( 10*(max(max(abs(SP(e2, :))))) );
    end

    ylim(ylim1*[-1 1]);
    xlim([min_t max_t]);
    set(gca, 'Fontsize', 12, 'box', 'off' );
    hold on;
    if e2 == 1
        title( [Tool_Name, ', ', filename1], 'Interpreter', 'none', 'Fontsize', 15 );
    end

    if e2 ~= last_x_axis
        set(gca, 'xtick', [], 'XTickLabel', '');
    end

    [ytick_m, YTickLabel1, ytick_good, ytick_new, yticklabel_new]=fix_YTick(dB_scale, dB_scale);

    wb_th=text( max_t-0.02*(max_t-min_t), -0.98*ylim1, ['Mic ', num2str(e2), ' ', plot_str{e2}], 'Fontsize', 10, 'Color', [0 0 0], 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', 'BackgroundColor', 'none', 'Interpreter', 'none' );

    wb_th_array(e2)=wb_th;

    % number the peaks
    if nargin >= 8
        if max(size(indices2)) >= e2 && max(size(SP_local_max2)) >= e2

            plot((t_SP(2)-t_SP(1))*(-1+indices2{e2}), SP_local_max2{e2}, 'ok', 'linestyle', 'none', 'markersize', 7, 'LineWidth', 2);

            for e1=1:length(indices2{e2});
                if mod(e1, 2) > 0
                    signum1=1;
                    text((t_SP(2)-t_SP(1))*indices2{e2}(e1), 0.98*ylim1, num2str(e1), 'color', [0 0 0], 'Fontsize', 12, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'Interpreter', 'none');
                else
                    signum1=-1;
                end
            end

        end
    end

end

% add the lines around the perimeter of the plot
if length(h2) >= 1
    psuedo_box(h2);
end

if same_ylim == 1
    ylim2=per_mar*ceil( 10*(max(max(abs(vibs)))) );
end


% plot the vibrations data
for e2=1:m2;

    if same_ylim ~= 1
        ylim2=per_mar*ceil( 10*(max(max(abs(vibs(e2, :))))) );
    end


    if m1 < 1
        subaxis(nn, 1, e2,      'sh', sh, 'sv', sv , 'pl', 0, 'pr', 0, 'pt', 0, 'pb', 0, 'ml', ml, 'mr', mr, 'mt', mt, 'mb', mb);
    else
        subaxis(nn, 1, m1+e2+1, 'sh', sh, 'sv', sv , 'pl', 0, 'pr', 0, 'pt', 0, 'pb', 0, 'ml', ml, 'mr', mr, 'mt', mt, 'mb', mb);
    end


    t_vibs_rs=[];
    vibs_rs=[];

    if flag_rs == 1
        [t_vibs_rs, vibs_rs]=resample_plot(t_vibs, vibs(e2, :));
        plot(t_vibs_rs, vibs_rs');
        clear('t_vibs_rs');
        clear('vibs_rs');
    else
        plot(t_vibs, vibs(e2, :)');
    end
    h2=[h2 gca];

    if e2 == floor((m2+1)/2)
        ylabel('Vibs (m/s^2)', 'Fontsize', 16);
    end

    hold on;
    if m1+e2 == 1
        title( [Tool_Name, ' Filename ', filename1], 'Interpreter', 'none', 'Fontsize', 15 );
    end

    ylim(ylim2*[-1 1]);
    xlim([min_t max_t]);
    set(gca, 'Fontsize', 12, 'box', 'off' );
    if m1+e2 ~= last_x_axis
        set(gca, 'xtick', [], 'XTickLabel', '');
    end

    [ytick_m, YTickLabel1, ytick_good, ytick_new, yticklabel_new]=fix_YTick(0, 0);

    wb_th=text( max_t-0.02*(max_t-min_t), -0.98*ylim2, ['Accel Channel ', num2str(e2), ' ', plot_str{m1+e2}], 'Fontsize', 10, 'Color', [0 0 0], 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', 'BackgroundColor', 'none', 'Interpreter', 'none' );
    wb_th_array(m1+e2)=wb_th;

    % number the peaks
    if nargin >= 8

        if max(size(indices2)) > e2 && max(size(SP_local_max2)) > e2
            plot((t_vibs(2)-t_vibs(1))*(-1+indices2{e2}), SP_local_max2{e2}, 'ok', 'linestyle', 'none', 'markersize', 7);


            for e1=1:length(indices2{e2});
                if mod(e1, 2) > 0
                    signum1=1;
                    text((t_SP(2)-t_SP(1))*indices2{e2}(e1), 0.98*ylim2, num2str(e1), 'color', [0 0 0], 'Fontsize', 12, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'Interpreter', 'none');
                else
                    signum1=-1;
                end
            end
        end
    end

end

% add the lines around the perimeter of the plot
if length(h2(m1+(1:m2))) >= 1
    psuedo_box(h2(m1+(1:m2)));
end

% set the x_label for the plot
xlabel('Time (seconds)', 'Fontsize', 16);


