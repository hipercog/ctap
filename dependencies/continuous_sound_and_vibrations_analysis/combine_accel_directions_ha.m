function [comb_data_buf2]=combine_accel_directions_ha(data_buf2)
% % combine_accel_directions_ha: Calculates overall hand arm vibrations acceleration metrics from multiple axis accelerometers. 
% % 
% % Syntax;
% % 
% % [comb_data_buf2]=combine_accel_directions_ha(data_buf2);
% %
% % ********************************************************************
% %
% %
% % 
% % Description
% % 
% % Calculates overall acceleration metrics from multiple axis
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
% % Vibs_calc_hand_arm combined for each of the axes on one multiple
% % axis accelerometer.
% %
% % ********************************************************************
% %
% %
% % 
% % Output Variables
% %
% %
% % 
% % comb_data_buf2 is the array of overall hand arm acceleration metrics 
% % for the accelerometer.  
% %
% % ********************************************************************
% %
% %
% % 
% % Program Written by Edward L. Zechmann
% %
% % date 16 July 2007
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
% % See Also: hand_arm_fil2, Vibs_calc_hand_arm
% %
% %
% % 


if (nargin < 1 || isempty(data_buf2)) || ~isnumeric(data_buf2)
    data_buf2=zeros(1, 93);
end

    

comb_data_buf2=sqrt(sum(data_buf2.^2, 1));
comb_data_buf2(8)=max(data_buf2(:, 9));
comb_data_buf2(3)=31.8*(comb_data_buf2(2))^(-1.06);
comb_data_buf2(4)=31.8*(0.5*comb_data_buf2(2))^(-1.06);
comb_data_buf2(7)=31.8*(comb_data_buf2(6))^(-1.06);
comb_data_buf2(8)=31.8*(0.5*comb_data_buf2(6))^(-1.06);

comb_data_buf2(20)=max(data_buf2(:, 20));
comb_data_buf2(14)=31.8*(comb_data_buf2(13))^(-1.06);
comb_data_buf2(15)=31.8*(0.5*comb_data_buf2(13))^(-1.06);
comb_data_buf2(18)=31.8*(comb_data_buf2(17))^(-1.06);
comb_data_buf2(19)=31.8*(0.5*comb_data_buf2(17))^(-1.06);

