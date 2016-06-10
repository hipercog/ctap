function [ data_type ] = channel_data_type_selection(num_channels )
% % channel_data_type_selection
% % 
% % 
% % 



def2=zeros(num_channels, 2);

channel_names2=cell(num_channels, 1);

for e1=1:num_channels;
    def2(e1, 1)=e1;
    def2(e1, 2)=1;
    channel_names2{e1, 1}=['Channel ', num2str(e1)];
end


sel = selectdlg2({channel_names2, {'sound', 'vibrations'}, cell(num_channels, 2)},'Choose 1 item per col',ones(num_channels,1), def2);

[buf, ix]=sort(sel(:, 1));
data_type=sel(ix, 2);
