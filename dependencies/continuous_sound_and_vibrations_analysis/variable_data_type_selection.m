function [ data_type ] = variable_data_type_selection(var_names )
% % channel_data_type_selection
% %
% %
% %

num_var_names=length(var_names);

def2=zeros(num_var_names, 2);


for e1=1:num_var_names;
    buf10 = strfind(var_names{e1}, 'v');
    def2(e1, 1)=e1;
    if isempty(buf10)
        def2(e1, 2)=1;
    else
        def2(e1, 2)=2;
    end
end



sel = selectdlg2({var_names, {'sound', 'vibrations', 'both sound and vibrations'}, cell(num_var_names, 3)},'Choose 1 item per col',ones(num_var_names,1), def2);

[buf, ix]=sort(sel(:, 1));
data_type=sel(ix, 2);
