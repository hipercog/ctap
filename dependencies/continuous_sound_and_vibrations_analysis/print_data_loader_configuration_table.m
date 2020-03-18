function [out]=print_data_loader_configuration_table(default_mat_config_out)
% % print_data_loader_configuration_table: Prints the variable configuration to a table
% % 
% % Syntax:
% % 
% % [out]=print_data_loader_configuration_table(default_mat_config_out)
% % 
% % ********************************************************************
% % 
% % Description
% % 
% % Prints the variable configuration to a table for viewing.
% % 
% % ********************************************************************
% % 
% % Input Variables
% %  
% % default_mat_config_out is a cell array containing all the information
% % for the configuration of the variabales.  
% %  
% % ********************************************************************
% %
% % Output Variables
% %
% % out is a handle to the table figure. 
% % 
% % ********************************************************************
% %
% % Subprograms
% % 
% % List of Dependent Subprograms for 
% % print_data_loader_configuration_table
% % 
% % FEX ID# is the File ID on the Matlab Central File Exchange
% % 
% % 
% % Program Name   Author   FEX ID#
% % 1) tableGUI		Joaquim Luis		10045	
% % 
% % 
% % ********************************************************************
% % 
% % Program Written by Edward L. Zechmann
% % 
% %     date  8 September   2008  
% % 
% % modified 11 November    2008    Added an additional line below the 
% %                                 both variables in the configuration
% %                                 Table.
% % 
% % modified  6 October     2009    Updated comments
% % 
% % 
% % 
% % ********************************************************************
% %
% % Please Feel Free to Modify This Program
% % 
% % See Also: data_loader2, Load, Save, uigetfile
% % 



% number of variables
num_snd_vars=length(default_mat_config_out{1,1});
num_vibs_vars=length(default_mat_config_out{2,1});
num_both_vars=length(default_mat_config_out{3,1});

% variable names
snd_vars=default_mat_config_out{1,1};
vibs_vars=default_mat_config_out{2,1};
both_vars=default_mat_config_out{3,1};

% corresponding tosr variables
snd_tosr_var=default_mat_config_out{1,2};
vibs_tosr_var=default_mat_config_out{2,2};
both_tosr_var=default_mat_config_out{3,2};


Fs_SP=default_mat_config_out{1,2};
Fs_vibs=default_mat_config_out{2,2};
Fs_both=default_mat_config_out{3,2};
                        
snd_tosr_bool=default_mat_config_out{1,3};
vibs_tosr_bool=default_mat_config_out{2,3};
both_tosr_bool=default_mat_config_out{3,3};

% This is the breakdown of the sound and vibrations by channel
both_snd_ch=default_mat_config_out{3,4};
both_vibs_ch=default_mat_config_out{3,5};



num_rows=6+num_snd_vars+num_vibs_vars+num_both_vars;
num_cols=6;

t_cell=cell(num_rows, num_cols);

t_cell{1,1}='Sound Variables';
t_cell{1,2}='Time Increment';
t_cell{1,3}='Sampling Rate';
t_cell{1,4}='Constant Sampling Rate';
for e1=1:num_snd_vars;
    t_cell{1+e1,1}=snd_vars{e1};
    if isnumeric(snd_tosr_var{e1,1})
        t_cell{1+e1,4}=num2str(snd_tosr_var{e1,1});
    else
        if isequal(snd_tosr_bool{e1}, 1)
            t_cell{1+e1,2}=snd_tosr_var{e1,1};
        else
            t_cell{1+e1,3}=snd_tosr_var{e1,1};
        end
    end
end

t_cell{num_snd_vars+3,1}='Vibrations Variables';
t_cell{num_snd_vars+3,2}='Time Increment';
t_cell{num_snd_vars+3,3}='Sampling Rate';
t_cell{num_snd_vars+3,4}='Constant Sampling Rate';
for e1=1:num_vibs_vars;
    t_cell{3+num_snd_vars+e1,1}=vibs_vars{e1};
    if isnumeric(vibs_tosr_var{e1,1})
        t_cell{3+num_snd_vars+e1,4}=num2str(vibs_tosr_var{e1,1});
    else
        if isequal(vibs_tosr_bool{e1}, 1)
            t_cell{3+num_snd_vars+e1,2}=vibs_tosr_var{e1,1};
        else
            t_cell{3+num_snd_vars+e1,3}=vibs_tosr_var{e1,1};
        end
    end
end


t_cell{num_snd_vars+num_vibs_vars+5, 1}='Both Variables';
t_cell{num_snd_vars+num_vibs_vars+5, 2}='Time Increment';
t_cell{num_snd_vars+num_vibs_vars+5, 3}='Sampling Rate';
t_cell{num_snd_vars+num_vibs_vars+5, 4}='Constant Sampling Rate';
t_cell{num_snd_vars+num_vibs_vars+5, 5}='Sound Channels';
t_cell{num_snd_vars+num_vibs_vars+5, 6}='Vibrations Channels';
for e1=1:num_both_vars;
    t_cell{5+num_snd_vars+num_vibs_vars+e1, 1}=both_vars{e1};
    if isnumeric(both_tosr_var{e1,1})
        t_cell{5+num_snd_vars+num_vibs_vars+e1, 4}=num2str(both_tosr_var{e1,1});
    else
        if isequal(vibs_tosr_bool{e1}, 1)
            t_cell{5+num_snd_vars+num_vibs_vars+e1, 2}=both_tosr_var{e1,1};
        else
            t_cell{5+num_snd_vars+num_vibs_vars+e1, 3}=both_tosr_var{e1,1};
        end
    end
    t_cell{5+num_snd_vars+num_vibs_vars+e1, 5}=num2str(both_snd_ch{e1});
    t_cell{5+num_snd_vars+num_vibs_vars+e1, 6}=num2str(both_vibs_ch{e1});
end

out = tableGUI('array', t_cell, 'ColWidth', 180, 'RowHeight', 30, 'HorAlin', 'center', 'modal', '');

