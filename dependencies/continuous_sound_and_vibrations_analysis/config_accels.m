function [num_accels, accel_num_chan, axis_chan_ix, chann_p_accel]=config_accels(m2, ax_string)
% % config_accels: Configures the accelerometer channels using an input dialog box.  
% % 
% % Syntax;
% % 
% % [num_accels, accel_num_chan, axis_chan_ix, chann_p_accel]=config_accels(m2, ax_string);
% % 
% % ********************************************************************
% % 
% % Description
% %  
% % The program configures the accelerometer channels using an input dialog box. 
% %  
% % The program requires two inputs: the number of channels and a 
% % string containing the letter designations of the directions of 
% % each of the axes.  
% % 
% % For each line in the input dialog box there 
% % is a number and letter designating the accelerometer number and axis
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
% % 
% % ********************************************************************
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
% 
% % ********************************************************************
% %
% % Program Written by Edward L. Zechmann
% %
% % date 23 July 2007
% % 
% % modified  3 September   2008  Updated Comments
% %
% % modified  9 October     2009    Updated Comments
% %
% % 
% % ********************************************************************
% %
% %
% % Please Feel Free to Modify This Program
% %
% % See Also: hand_arm_fil2 Vibs_calc_hand_arm
% %

if (nargin < 1 || isempty(m2)) || ~isnumeric(m2) 
    m2=3;
end

if (nargin < 2 || isempty(ax_string)) || isnumeric(ax_string) 
    ax_string='xyz';
end


for e2=1:m2;
    prompt{e2}= ['Channel ', num2str(e2), ', Enter Accelerometer Number, and Axis Direction'];
    if m2 < 3
        defAns{e2}=[num2str(e2), ', z' ];
    else
        defAns{e2}=[num2str(ceil(e2/3)), ',' ax_string( mod(e2+2,3)+1 ) ];
    end
end
                
dlg_title='Configurations of the Accelerometers for each Channel';
num_lines=1;
                
options.Resize='on';
options.WindowStyle='normal';
options.Interpreter='tex';
                
axes_config = inputdlg(prompt,dlg_title,num_lines,defAns,options);
                
[num_accels, accel_num_chan, axis_chan_ix, chann_p_accel]=accel_config(axes_config, m2, ax_string);
                
