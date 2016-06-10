function [comb_data_buf2]=combine_accel_directions_wb(data_buf2, type)
% % combine_accel_directions_wb: Calculates overall whole body vibrations acceleration metrics from multiple axis accelerometers. 
% % 
% % Syntax;
% % 
% % [comb_data_buf2]=combine_accel_directions_wb(data_buf2);
% %
% % ********************************************************************
% %
% % 
% % 
% % Description
% % 
% %
% % 
% % Calculates overall whole body acceleration metrics from multiple axis
% % accelerometers. 
% % 
% % 
% % 
% % ********************************************************************
% %
% %
% % 
% % Input Variables
% %
% %
% % 
% % data_buf2 is the acceleration metrics data from the program 
% %           Vibs_calc_whole_body combined for each of the axes on one 
% %           multiple axis accelerometer.
% %           default is data_buf2=zeros(1, 93);
% % 
% % type is an integer form 1 to 7 describing he the posture of the 
% %           person who is being measured whole_Body_Filter.  
% %           default is type=1;
% %
% %
% % ********************************************************************
% %
% %
% % 
% % Output Variables
% %
% %
% % 
% % comb_data_buf2 is the array of overall whole body acceleration 
% % metrics for the accelerometer.  
% %
% % ********************************************************************
% %
% %
% % 
% % Program Written by Edward L. Zechmann
% %
% %     date  8 August      2007
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

if (nargin < 1 || isempty(data_buf2)) || ~isnumeric(data_buf2)
    data_buf2=zeros(1, 93);
end

if (nargin < 2 || isempty(type)) || ~isnumeric(type)
    type=1;
end
    
        
if type < 7
    comb_data_buf2=sqrt(sum(data_buf2.^2, 1));
    comb_data_buf2(7)=max(data_buf2(:, 7));
    comb_data_buf2(7)=max(data_buf2(:, 15));
    
else
    comb_data_buf2=sqrt(sum(data_buf2.^2, 1));
    comb_data_buf2(7)=max(data_buf2(:, 7));
    comb_data_buf2(7)=max(data_buf2(:, 16));
    
end