function [num_accels, accel_num_chan, axis_chan_ix, chann_p_accel]=accel_config(axes_config, m2, ax_string)
% % accel_config: Configures the accelerometer channels given the cell array axes_config
% % 
% % Syntax;
% % 
% % [num_accels, accel_num_chan, axis_chan_ix, chann_p_accel]=accel_config(axes_config, m2, ax_string);
% % 
% % ********************************************************************
% % 
% % Description
% % 
% % Extracts the configuration for a set of accelerometer channels given 
% % the accelerometer number and direction are contained in a cell array
% % of strings axes_config.  For each cell in axes_config there is a 
% % number and letter designating the accelerometer number and axis
% % direction for each channel respectively. 
% %  
% % The program outputs: the number of accelerometers, the accelerometer 
% % number for each channel, the index of each axis, and the number of 
% % channels per accelerometer.  
% % 
% % ********************************************************************
% %
% % Input Variables
% % 
% % axes_config={'1,x'; '1,y'; '1,z';};
% %                     % A cell array of strings.  There is one cell for
% %                     % each accelerometer channel.   
% %                     % Each cell contains a number and a letter in 
% %                     % any order.    
% %                     % The number is the number of the accelerometer.
% %                     % The letter is the direction or axis of the 
% %                     % accelerometer channel.
% %                     % The program searches for a number to get the
% %                     % accelerometer number.
% %                     % The program searches for a match to a single 
% %                     % letter ax_string to get the axis direction.  
% %                     % 
% %                     % default is axes_config={'1,x'; '1,y'; '1,z';};
% %                        
% % m2=3;               % The number of accelerometer channels
% %                     % default is m2=3;
% % 
% % ax_string='xyz';    % contains the letters associated with the 
% %                     % directions of the triaxial accelerometer.  
% %                     % default is ax_string='xyz';
% % 
% % ********************************************************************
% % 
% % Output Variables
% % 
% % num_accels is the number of accelerometers.
% % 
% % accel_num_chan is a row vector which contains the accelerometer number 
% %                for each channel;
% % 
% % axis_chan_ix is a row vector which contains an index for the axis of 
% %                each accelerometer channel.  
% %                For example: axis_chan_ix=[1;2;3] 
% %                means channel 1 is in the x-direction 
% %                means channel 2 is in the y-direction 
% %                means channel 3 is in the z-direction 
% % 
% % chann_p_accel is a row vector containing the number of channels for
% %                each acceleromter;
% % 
% % ********************************************************************
% 
% Example='1';
% 
% % For hand arm vibrations measurements with a triaxial accelerometer
% % on both hands
% 
% axes_config2={'1,x'; '1,y'; '1,z'; '2,x'; '2,y'; '2,z'; };
% m2=6;
% ax_string='xyz';
%  
% [num_accels, accel_num_chan, axis_chan_ix, chann_p_accel]=accel_config(axes_config, m2, ax_string);
% 
% Example='2';
% 
% % For hand arm vibrations measurements with a triaxial accelerometer
% % on one hands
%
% axes_config2={'1,x'; '1,y'; '1,z'; };
% m2=3;
% ax_string='xyz';
% 
% [num_accels, accel_num_chan, axis_chan_ix, chann_p_accel]=accel_config(axes_config, m2, ax_string);
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
% % accel_config
% % 
% % FEX ID# is the File ID on the Matlab Central File Exchange
% % 
% % 
% % Program Name   Author   FEX ID#
% % 1) find_nums		Edward L. Zechmann					
% %
% %
% % ********************************************************************
% %
% % Program Written by Edward L. Zechmann
% %
% %     date 23 July        2007
% % 
% % modified  3 September   2008    Updated Comments
% % 
% % modified  3 September   2008    Updated Comments
% %
% % modified  9 October     2009    Updated Comments
% %
% % ********************************************************************
% %
% %
% % Please Feel Free to Modify This Program
% %
% % See Also: hand_arm_fil2, Vibs_calc_hand_arm
% %

if (nargin < 1 || isempty(axes_config)) 
    axes_config={'1,x'; '1,y'; '1,z';};
end
    
if (nargin < 2 || isempty(m2)) || ~isnumeric(m2) 
    m2=3;
end

if (nargin < 3 || isempty(ax_string)) || isnumeric(ax_string) 
    ax_string='xyz';
end



accel_num_chan=1:m2;
axis_chan_ix=1:m2;
                
for e2=1:m2;
    [nums]=find_nums(axes_config{e2}, 2);
    accel_num_chan(e2)=nums(1);
end
                
for e2=1:m2;
                    
    buf=1;
    for e3=1:3;
        if (findstr(axes_config{e2}, ax_string(e3)) > 0);
            buf = [buf e3];
        end
    end
                    
    axis_chan_ix(e2)=max(buf);
                    
end
                
num_accels=max(accel_num_chan);
                
chann_p_accel=1:num_accels;
for e2=1:num_accels;
    chann_p_accel(e2)=length(find(accel_num_chan == e2));
end
