function [ ha_chan2, ha_axes2, ha_accels2, num_ha_accels2]=config_ha_accels( ax_string, num_accels, accel_num_chan, axis_chan_ix, chann_p_accel )
% % config_ha_accels: Configures the axis directions and channels for accelerometers measuring hand arm vibrations 
% % 
% % Syntax;
% % 
% % [ ha_chan2, ha_axes2, ha_accels2, num_ha_accels2]=config_ha_accels( ax_string, num_accels, accel_num_chan, axis_chan_ix, chann_p_accel );
% % 
% % ********************************************************************
% % 
% % 
% % 
% % Description
% % 
% % 
% % 
% % The program configures the axis directions and channels for
% % accelerometers measuring hand-arm vibrations.  A list dialog box is
% % used to determine the accelerometers and channels which were used to 
% % measure hand arm vibrations.  
% % 
% % 
% % 
% % ********************************************************************
% % 
% % 
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
% % 
% % 
% % Output Variables
% % 
% % 
% % 
% % ha_chan2 is a row vector containing the accelerometer number of each 
% %                 accelerometer which measured hand arm vibrations.  
% % 
% % ha_axes2 is a cell array of row vectors each cell contains the 
% %                 numeric axis designations for the direction of each
% %                 channel for the accelerometer.  There is one cell for
% %                 each accelerometer. 
% % 
% % ha_accels2 is a cell array of row vectors each cell contains the 
% %                 channel designations for accelerometer channel.
% %                 There is one cell for each accelerometer. 
% % 
% % num_ha_accels2 is the number of acceleromters which measured hand arm
% %                 vibrations.  
% % 
% % 
% % 
% % ********************************************************************
% % 
% 
% Example='1';
% 
% % For hand arm vibrations measurements with a triaxial accelerometer
% % on both hands
% 
% m2=6;
% ax_string='xyz';
%  
% [num_accels, accel_num_chan, axis_chan_ix,chann_p_accel]=config_accels(m2, ax_string);
% [ ha_chan2, ha_axes2, ha_accels2, num_ha_accels2]=config_ha_accels( ax_string, num_accels, accel_num_chan, axis_chan_ix, chann_p_accel );
% 
% 
% Example='2';
% 
% % For hand arm vibrations measurements with a triaxial accelerometer
% % on one hands
%
% m2=3;
% ax_string='xyz';
% 
% [num_accels, accel_num_chan, axis_chan_ix,chann_p_accel]=config_accels(m2, ax_string);
% [ ha_chan2, ha_axes2, ha_accels2, num_ha_accels2]=config_ha_accels( ax_string, num_accels, accel_num_chan, axis_chan_ix, chann_p_accel );
% 
% 
% % ********************************************************************
% %
% % 
% % 
% % Program written by Edward Zechmann 
% % 
% %     date  5 August      2007
% % 
% % modified  3 september   2008    Updated Comments
% %
% % modified  9 October     2009    Updated Comments
% %
% %
% % ********************************************************************
% % 
% % 
% % 
% % Please Feel Free to Modify This Program
% % 
% % See Also: hand_arm_fil2 Vibs_calc_hand_arm
% % 
% % 
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
% measured hand-arm vibrations.
str={};
for e3=1:num_accels;
    str{e3} = ['Accelerometer ' num2str(e3)];
end
                
prompt={'Which accelerometers measured hand-arm vibrations', 'Select all Applicable Accels',' For Hand-Arm Vibrations'};
[ha_accels,ok] = listdlg('Name', 'Hand-Arm Vibrations', 'PromptString', prompt,'SelectionMode','multiple','ListString',str, 'ListSize', [500, 500]);
                
% 
%ha_accels                         % list of the Hand-Arm accels
%ha_accels2                        % list of the Hand-Arm accels
num_ha_accels=length(ha_accels);   % number of accelerometers for measuring hand-arm vibrations
ha_num_axes_p_accel=[];            % number of channels for each accelerometer
ha_axes={};                        % designation of the direction (axis) for each channel
ha_chan={};                        % designation the channel number for each accel and axis
ha_axes2={};                       % designation of the direction (axis) for each channel after correction
ha_chan2={};                       % designation the channel number for each accel and axis after correction
channel_num_array=[];              % list of all channel numbers
                
%How many channels per accelerometer were for hand-arm vibrations
% which axes are for hand-arm vibrations
for e2=1:num_ha_accels;
    ha_num_axes_p_accel(e2)=chann_p_accel(ha_accels(e2));
    ha_axes{e2}=axis_chan_ix(find(accel_num_chan==ha_accels(e2)));
    ha_chan{e2}=find(accel_num_chan==ha_accels(e2));
end
                
yn = questdlg('Did all of the channels for each of the Hand-Arm Accelerometers measure Hand-Arm Vibrations?','Hand-Arm Channels');
tf=strcmp(yn, 'Yes');
% if true determine which channels to keep.
                
if tf == 0
    prompt={'Which accelerometer channels measured hand-arm vibrations', 'Select all Applicable channels','Hand-Arm Vibrations Analysis.'};
    str={};
    buf=0;
    for e2=1:num_ha_accels;
        for e3=1:length(ha_axes{e2})
            buf=buf+1;
            channel_num=length(find(accel_num_chan < ha_accels(e2)))+ha_axes{e2}(e3);
            channel_num_array=[channel_num_array channel_num];
            str{buf}=['Channel, ',  num2str(channel_num), ' , Accel ', num2str(ha_accels(e2)), ', Axis ' ax_string(ha_axes{e2}(e3)) ];
        end
    end
    [ha_chan_list,ok] = listdlg('Name', 'Hand-Arm Vibrations', 'PromptString', prompt,'SelectionMode','multiple','ListString',str, 'ListSize', [500 500]);
                

    % Figure out which channels to delete
                
    % How many channels per accelerometer were for hand-arm vibrations
    % which axes are for hand-arm vibrations
    num_ha_chans=buf;
    ha_chan2={};
    ha_axes2={};
    ha_chan22={};
    ha_axes22={};
                    
    for e2=1:length(ha_chan_list);
        e3=0;
        buf2=[];
        buf3=0;
        % determine the accelerometer and channel for each selected channel
        while e3 < num_ha_accels && e3 < max(channel_num_array) && length(buf2) < 1
            e3=e3+1;
            buf2=find(ha_chan{e3} == channel_num_array(ha_chan_list(e2)));
            if length(ha_chan2) >= e3
                buf3=length(ha_chan2{e3});
            else
                buf3=0;
            end
                            
        end
        %  e3 is the accelerometer number
        %  buf2 is the index of the channel number
                        
        ha_chan2{e3}(buf3+1)=ha_chan{e3}(buf2);
        ha_axes2{e3}(buf3+1)=ha_axes{e3}(buf2);
                        
    end

    % Check the number of hand-arm accelerometers
    num_ha_accels2=0;
    for e2=1:num_ha_accels;
        buf2=length(ha_chan2{e2});
        if buf2 > 0
            num_ha_accels2=num_ha_accels2+1;
                            
            ha_accels2(num_ha_accels2)=ha_accels(e2);
            ha_chan22(num_ha_accels2)=ha_chan2(e2);
            ha_axes22(num_ha_accels2)=ha_axes2(e2);
        end
    end
                    
    ha_chan2=ha_chan22;
    ha_axes2=ha_axes22;
                    
else
           
    num_ha_accels2=num_ha_accels;
    ha_accels2=ha_accels;
    ha_chan2=ha_chan;
    ha_axes2=ha_axes;
                    
end

