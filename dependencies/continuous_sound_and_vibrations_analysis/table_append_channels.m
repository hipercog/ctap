function [num_channels_a, num_diff_channels_a, sum_num_channels_a, num_channels_array]=table_append_channels(num_channels_a, num_diff_channels_a, sum_num_channels_a, num_channels, num_diff_channels, num_channels_array, flag, e1, e2, e3)
% % table_append_channels: caculates the number of channels of data for making a table
% % 
% % 
% % Edward Zechmann
% % 
% %     date  2 November    2008
% % 
% % modified 17 November    2008
% % 
% % 
% % 
% % 
% % 

if num_channels >= 1 || logical(num_diff_channels >= 1)

    switch flag
        case 1
            num_channels_a(e1, e2, e3)=num_channels_a(e1, e2, e3)+num_channels;
            num_diff_channels_a(e1, e2, e3)=0;
            sum_num_channels_a(e1, e2, e3)=sum_num_channels_a(e1, e2, e3)+num_channels;
            num_channels_array(e1)=max([num_channels, num_channels_array(e1)]);
        case 2
            num_channels_a(e1, e2, e3)=0;
            num_diff_channels_a(e1, e2, e3)=num_diff_channels_a(e1, e2, e3)+num_diff_channels;
            sum_num_channels_a(e1, e2, e3)=sum_num_channels_a(e1, e2, e3)+num_diff_channels;
            num_channels_array(e1)=max(sum_num_channels_a(e1, :, :));
        case 3
            num_channels_a(e1, e2, e3)=num_channels_a(e1, e2, e3)+num_channels;
            num_diff_channels_a(e1, e2, e3)=num_diff_channels_a(e1, e2, e3)+num_diff_channels;
            sum_num_channels_a(e1, e2, e3)=sum_num_channels_a(e1, e2, e3)+num_diff_channels_a(e1, e2, e3);
            num_channels_array(e1)=max(sum_num_channels_a(e1, :, :));
        otherwise
            num_channels_a(e1, e2, e3)=num_channels_a(e1, e2, e3)+num_channels;
            num_diff_channels_a(e1, e2, e3)=num_diff_channels_a(e1, e2, e3)+num_diff_channels;
            sum_num_channels_a(e1, e2, e3)=sum_num_channels_a(e1, e2, e3)+num_channels+num_diff_channels;
            num_channels_array(e1)=max(sum_num_channels_a(e1, :, :));
    end

end


