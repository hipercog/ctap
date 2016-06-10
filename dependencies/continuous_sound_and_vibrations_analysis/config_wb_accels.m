function [ wb_chan2, wb_axes2, wb_accels2, num_wb_accels2]=config_wb_accels(ax_string, num_accels, accel_num_chan, axis_chan_ix, chann_p_accel )
% % config_wb_accels: Configures the axis directions and channels for accelerometers measuring whole body vibrations 
% % 
% % Syntax;
% % 
% % [ wb_chan2, wb_axes2, wb_accels2, num_wb_accels2]=config_wb_accels(ax_string, num_accels, accel_num_chan, axis_chan_ix, chann_p_accel );
% % 
% % ********************************************************************
% % 
% % Description
% % 
% % The program configures the axis directions and channels for
% % accelerometers measuring whole body vibrations.  A list dialog box is
% % used to determine the accelerometers and channels which were used to 
% % measure whole body vibrations.  
% % 
% % ********************************************************************
% % 
% % Input Variables
% % 
% % ax_string='xyz';    % contains the letters associated with the 
% %                     % directions of the triaxial accelerometer.  
% %                     % default is ax_string='xyz';
% %
% % num_accels=1;       % The number of accelerometers.
% %                     % default is num_accels=1;
% % 
% % accel_num_chan=[1; 1; 1;]; 
% %                     % A row vector which contains the accelerometer
% %                     % number for each channel;
% %                     % default is accel_num_chan=[1; 1; 1;]; 
% %                     
% % axis_chan_ix=[1;2;3;];
% %                     % A row vector which contains an index for the axis  
% %                     % for each accelerometer channel.  
% %                     % default is axis_chan_ix=[1;2;3] 
% %                     % meaninng of default value
% %                     % channel 1 is in the x-direction 
% %                     % channel 2 is in the y-direction 
% %                     % channel 3 is in the z-direction 
% % 
% % chann_p_accel=3;    % A row vector containing the number of channels 
% %                     % for each acceleromter;
% % 
% % ********************************************************************
% % 
% % Output Variables
% % 
% % wb_chan2 is a row vector containing the accelerometer number of each 
% %                 accelerometer which measured whole body vibrations.  
% % 
% % wb_axes2 is a cell array of row vectors each cell contains the 
% %                 numeric axis designations for the direction of each
% %                 channel for the accelerometer.  There is one cell for
% %                 each accelerometer. 
% % 
% % wb_accels2 is a cell array of row vectors each cell contains the 
% %                 channel designations for accelerometer channel.
% %                 There is one cell for each accelerometer. 
% % 
% % num_wb_accels2 is the number of acceleromters which measured whole body
% %                 vibrations.  
% % 
% % ********************************************************************
% 
% 
% Example='1';
% 
% % For whole body vibrations measurements with two triaxial accelerometer
% 
% m2=6;
% ax_string='xyz';
%  
% [num_accels, accel_num_chan, axis_chan_ix,chann_p_accel]=config_accels(m2, ax_string);
% [ wb_chan2, wb_axes2, wb_accels2, num_wb_accels2]=config_wb_accels( ax_string, num_accels, accel_num_chan, axis_chan_ix, chann_p_accel );
% 
% 
% Example='2';
% 
% % For whole body vibrations measurements with one triaxial accelerometer
%
% m2=3;
% ax_string='xyz';
% 
% [num_accels, accel_num_chan, axis_chan_ix,chann_p_accel]=config_accels(m2, ax_string);
% [ wb_chan2, wb_axes2, wb_accels2, num_wb_accels2]=config_wb_accels( ax_string, num_accels, accel_num_chan, axis_chan_ix, chann_p_accel );
% 
% 
% % ********************************************************************
% % 
% %
% % Program written by Edward Zechmann 
% % 
% %     date  5 August      2007
% % 
% % modified  3 september   2008    Updated Comemnts
% %           
% % modified 21 January     2009    Split the seated posture into two cases 
% %                                 Seated (Health) and Seated (Comfort). 
% %                                 Only documentation needed adjustment.
% %
% % modified  9 October     2009    Updated Comments
% %
% % 
% %
% % ********************************************************************
% %
% %
% % Please Feel Free to Modify This Program
% %
% % See Also: whole_Body_Filter, Vibs_calc_whole_body
% %

if (nargin < 1 || isempty(ax_string)) || isnumeric(ax_string) 
    ax_string='xyz';
end

if (nargin < 2 || isempty(num_accels)) || ~isnumeric(num_accels) 
    num_accels=1; 
end

if (nargin < 3 || isempty(accel_num_chan)) || ~isnumeric(accel_num_chan) 
    accel_num_chan=[1; 1; 1;]; 
end

if (nargin < 4 || isempty(axis_chan_ix)) || ~isnumeric(axis_chan_ix) 
    axis_chan_ix=[1;2;3;]; 
end

if (nargin < 5 || isempty(chann_p_accel)) || ~isnumeric(chann_p_accel) 
    chann_p_accel=3;
end



% Prompt the user to declare which accelerometers 
% measured whole body vibrations.
str={};
for e3=1:num_accels;
    str{e3} = ['Accelerometer ' num2str(e3)];
end
                
prompt={'Which accelerometers measured Whole-Body Vibrations', 'Select all Applicable Accels',' Whole-Body Vibrations'};
[wb_accels,ok] = listdlg('Name', 'Whole-Body Vibrations', 'PromptString', prompt,'SelectionMode','multiple','ListString',str, 'ListSize', [500, 500]);
                
% 
%wb_accels                         % list of the Hand-Arm accels
%wb_accels2                        % list of the Hand-Arm accels
num_wb_accels=length(wb_accels);   % number of accelerometers for measuring whole body vibrations
wb_num_axes_p_accel=[];            % number of channels for each accelerometer
wb_axes={};                        % designation of the direction (axis) for each channel
wb_chan={};                        % designation the channel number for each accel and axis
wb_axes2={};                       % designation of the direction (axis) for each channel after correction
wb_chan2={};                       % designation the channel number for each accel and axis after correction
channel_num_array=[];              % list of all channel numbers
                
%How many channels per accelerometer were for whole body vibrations
% which axes are for whole body vibrations
for e2=1:num_wb_accels;
    wb_num_axes_p_accel(e2)=chann_p_accel(wb_accels(e2));
    wb_axes{e2}=axis_chan_ix(find(accel_num_chan==wb_accels(e2)));
    wb_chan{e2}=find(accel_num_chan==wb_accels(e2));
end
                
yn = questdlg('Did all of the channels for each of the Whole-Body Accelerometers measure Whole-Body Vibrations?','Whole-Body Channels');
tf=strcmp(yn, 'Yes');
% if true determine which channels to keep.
                
if tf == 0
    prompt={'Which accelerometer channels measured Whole-Body vibrations', 'Select all Applicable channels','Whole-Body Vibrations Analysis.'};
    str={};
    buf=0;
    for e2=1:num_wb_accels;
        for e3=1:length(wb_axes{e2})
            buf=buf+1;
            channel_num=length(find(accel_num_chan < wb_accels(e2)))+wb_axes{e2}(e3);
            channel_num_array=[channel_num_array channel_num];
            str{buf}=['Channel, ',  num2str(channel_num), ' , Accel ', num2str(wb_accels(e2)), ', Axis ' ax_string(wb_axes{e2}(e3)) ];
        end
    end
    [wb_chan_list,ok] = listdlg('Name', 'Whole-Body Vibrations', 'PromptString', prompt, 'SelectionMode', 'multiple', 'ListString', str, 'ListSize', [500 500]);
                

    % Figure out which channels to delete
                
    % How many channels per accelerometer were for whole body vibrations
    % which axes are for whole body vibrations
    num_wb_chans=buf;
    wb_chan2={};
    wb_axes2={};
    wb_chan22={};
    wb_axes22={};
                    
    for e2=1:length(wb_chan_list);
        e3=0;
        buf2=[];
        buf3=0;
        % determine the accelerometer and channel for each selected channel
        while e3 < num_wb_accels && e3 < max(channel_num_array) && length(buf2) < 1
            e3=e3+1;
            buf2=find(wb_chan{e3} == channel_num_array(wb_chan_list(e2)));
            if length(wb_chan2) >= e3
                buf3=length(wb_chan2{e3});
            else
                buf3=0;
            end
                            
        end
        %  e3 is the accelerometer number
        %  buf 2 is the index of the channel number
                        
        wb_chan2{e3}(buf3+1)=wb_chan{e3}(buf2);
        wb_axes2{e3}(buf3+1)=wb_axes{e3}(buf2);
                        
    end

    % Check the number of whole body accelerometers
    num_wb_accels2=0;
    for e2=1:num_wb_accels;
        buf2=length(wb_chan2{e2});
        if buf2 > 0
            num_wb_accels2=num_wb_accels2+1;
                            
            wb_accels2(num_wb_accels2)=wb_accels(e2);
            wb_chan22(num_wb_accels2)=wb_chan2(e2);
            wb_axes22(num_wb_accels2)=wb_axes2(e2);
        end
    end
                    
    wb_chan2=wb_chan22;
    wb_axes2=wb_axes22;
                    
else
           
    num_wb_accels2=num_wb_accels;
    wb_accels2=wb_accels;
    wb_chan2=wb_chan;
    wb_axes2=wb_axes;
                    
end

