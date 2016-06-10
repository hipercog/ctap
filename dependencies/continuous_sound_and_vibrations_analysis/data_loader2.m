function [SP, vibs, Fs_SP, Fs_vibs, default_wav_settings_out, default_mat_config_out]=data_loader2(filename, default_wav_settings_in, default_mat_config_in)
% % data_loader2:  Loads data specified as sound or vibrations and further specified as data, time increment or sampling rate  
% % 
% % Syntax;
% % 
% % [SP, vibs, Fs_SP, Fs_vibs, default_wav_settings_out, default_mat_config_out]=data_loader2(filename, default_wav_settings_in, default_mat_config_in)
% % 
% % ********************************************************************
% % 
% % Description
% % 
% % data_loader2.m loads data stored in a matlab file or a wave file
% %
% % If the file is a wave file it is loaded 
% % Then the user is prompted to specify which tracks are sound and
% % which are vibrations.  
% % 
% % Then the user is prompted for the calibration sensitivies for each
% % channel listed by accelerometer channels and microphone channels. 
% %  
% %
% % This program finds the numeric variables stored in the 
% % specified data file then prompts the user to select the data variables 
% % 
% % Then the user is prompted to specify whether each variable is by
% % typing a single letter for each variable in the dialog box input
% % 
% % s for sound 
% % v for vibrations
% % b for both 
% % n for neither
% % 
% % In the case of both sound and vibrations the user is prompted to
% % specify which channels are sound and which channels are vibrations 
% % 
% % Then the program prompts the user to select the time or sampling rate
% % variables.  These variables are used to specify the sampling rate for
% % each data variable.
% % 
% % The user is prompted to relate each data variable to the corresponding
% % time or sampling rate variable.  
% % 
% % If there are no time or sampling rate variables then the program 
% % prompts the user to enter the sampling rates for each data variable.  
% %
% % 
% % 
% % ********************************************************************
% % 
% % Input Variables
% % 
% % 
% % filename='test.mat';        % Character Array, (String) including the 
% %                             % extension.  The program will terminate 
% %                             % if the extension is needed and missing.
% % 
% % default_wav_settings_in 
% %                             % used to automatically select sensor types
% %                             % and specify the calibration sensitivities
% %                             % default is to set the values to
% %                             % the user entered data from the dialog
% %                             % boxes then use the code
% %                             % see the example for more details
% % 
% % default_mat_config_in
% %                             % used to automatically match the data variables
% %                             % with the sensor types 
% %                             % specify the time or sampling rate
% %                             % variables
% %                             % match the data variables with the 
% %                             % time or sampling rate
% %                             % The best way to set the valeus is to 
% %                             % run the file through the program then  
% %                             % run the code
% %                             % see the example for more details
% %  
% %  
% % ********************************************************************
% %
% % Output Variables
% %
% % SP={};        % Pa Sound pressure
% % vibs={};      % m/s^2 acceleration
% % Fs_SP={};     % Hz smpling rate of sound pressure
% % Fs_vibs={};   % Hz smpling rate of acceleration
% %
% % 
% % default_wav_settings_out={};
% %
% %                             % used to automatically select sensor types
% %                             % and specify the calibration sensitivities
% %                             % default is to set the values to
% %                             % the user entered data from the dialog
% %                             % boxes then use the code
% % 
% % default_wav_settings_in=default_wav_settings_out;
% %
% % default_mat_config_out=cell(4, 5);
% % 
% %                             % used to automatically match the data variables
% %                             % with the sensor types 
% %                             % specify the time or sampling rate
% %                             % variables
% %                             % match the data variables with the 
% %                             % time or sampling rate
% %                             % The best way to set the valeus is to 
% %                             % run the file through the program then  
% %                             % run the code
% %
% % default_mat_config_in=default_mat_config_out;
% %
% % ********************************************************************
% % 
% 
% Example=''; % for matlab data
% filename='data.mat';       % filename of the matlab file to open
% default_wav_settings_in={[1 0 ], [40.1], [10.1]};
%
%                               % used to automatically select sensor types
%                               % and specify the calibration sensitivities
%                               % default is empty cell array.
%                               % default is to prompt the user with
%                               % dialog boxes.
%                               %
% default_mat_config_in={{'SP'}, {'Fs_SP'}; {'vibs'}, {'Fs_vibs'}; {}, {}; {1}, {};};
%                               %
%                               % used to automatically select sensor types
%                               % and specify the calibration sensitivities
%                               % default is empty cell array.
%                               % default is to prompt the user with
%                               % dialog boxes.
% 
% % 
% % ********************************************************************
% % 
% % Subprograms
% % 
% % List of Dependent Subprograms for 
% % data_loader2
% % 
% % FEX ID# is the File ID on the Matlab Central File Exchange
% % 
% % 
% % Program Name   Author   FEX ID#
% % 1) channel_data_type_selection		Edward L. Zechmann			
% % 2) convert_double		Edward L. Zechmann			
% % 3) file_extension		Edward L. Zechmann			
% % 4) print_data_loader_configuration_table		Edward L. Zechmann			
% % 5) selectdlg2		Mike Thomson			
% % 6) tableGUI		Joaquim Luis		10045	
% % 7) variable_data_type_selection		Edward L. Zechmann			
% % 
% % ********************************************************************
% %
% %
% % Program Written by Edward L. Zechmann
% %
% %     Date 18 December    2007
% % 
% % modified 21 December    2007    updated comments
% %                                 added use default settings
% %                                 for reading wave files
% %
% % modified  2 January     2008    added option to select the data 
% %                                 variable and time or frequency variable
% % 
% % modified  4 January     2008    added more code to find and select 
% %                                 the data variables and time or sampling
% %                                 variables.
% % 
% % modified  6 January     2008    finished the variable selection code
% %                                 and updated comments
% % 
% % modified  7 January     2008    fixed variaous bugs when configuring
% %                                 data for both sound and vibrations 
% %                                 fixed bugs for specifying sampling rates
% % 
% % modified 13 January     2008   
% % 
% % modified 13 January     2008    added the uigetfile program to take 
% %                                 care of the problem of a lack of files 
% %                                 to open.
% %                                 
% % modified  3 September   2008    Updated Comments
% % 
% % modified  6 October     2009    Updated comments
% % 
% % modified  8 April       2011    Uses a radio button array to select 
% %                                 the data type for each data variable.  
% %                                 Uses a radio button array to select the 
% %                                 data type for each channel if both 
% %                                 sound and vibrations are in a data 
% %                                 variable or if a wav file is selected.  
% %                                 Updated comments.  
% % 
% % 
% % ********************************************************************
% %
% % Please Feel Free to Modify This Program
% % 
% % See Also: Load, Save, uigetfile
% % 

if logical(nargin < 1) || logical(length(filename ) < 1)
    [filename, pathname] = uigetfile( {  '*.mat','*.wav'},  'Select the files To Process', 'MultiSelect', 'on');
    cd(pathname);
end

% Make sure that the configuration variables exist for the wav file
if nargin < 2 || isempty(default_wav_settings_in)
    default_wav_settings_in=cell(4,1);
end

default_wav_settings_out=default_wav_settings_in;

% configuring the matlab variables is quite invovled and requires
% checking initializiing the configuration variables

% Make sure that the configuration variables exist
if nargin < 3 || isempty(default_mat_config_in)
    default_mat_config_in=cell(4,5);
end

[cfm1 cfn1]=size(default_mat_config_in);

% Make sure input automated configuration meets the minimum size
% requirements
for e1=1:4;
    for e2=1:5;
        if logical(e1 > cfm1) || logical(e2 > cfn1)
            default_mat_config_in{e1, e2}={};
        end
    end
end

default_mat_config_out=default_mat_config_in;



% Make sure that the output variables exist
SP=[];
vibs=[];
Fs_SP=[];
Fs_vibs=[];

[filename_base, ext]=file_extension(filename);

fexist=exist(filename);

if isequal(fexist, 2) && ~isempty(ext)

    switch ext

        case {'mat', 'mat.mat'}

            keep_config=2;

            if ~isequal(default_mat_config_in{4,1}, 1)

                while keep_config == 2

                    % listing of some variables in the matlab file
                    SP=[];
                    vibs=[];
                    Fs_SP=[];
                    Fs_vibs=[];
                    t_SP=[];
                    t_vibs=[];
                    F_SP=[];
                    F_vibs=[];

                    % determine the variable names in the data file
                    % The case of a data structure has not been programmed
                    % yet
                    bb=whos( '-file', filename);

                    cl_n={'single', 'double', 'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'int64', 'uint64'};
                    
                    % make a list of the data variable names which are
                    % structures
                    %
                    % struct_vars=[];
                    % for e1=1:length(bb);
                    %     data_class=bb(e1).class;                 
                    %     bb4=strmatch(data_class, 'istruct', 'exact');
                    %     struct_vars=[struct_vars e1];
                    % end                                      
                    % 
                    % Generalizing the program for structures was abandoned
                    % becasue there are many possible configurations when
                    % using data structures.
                    %
                    % It is better for the Matlab user to write their own
                    % data loader program if they are using structures.
                    
                    data_vars=[];
                    % make a list of the data variable names containing
                    % numeric data
                    for e1=1:length(bb);
                        data_class=bb(e1).class;

                        % make sure the data variables are numeric
                        bb3=strmatch(data_class, cl_n, 'exact');

                        % make sure the data variables are not empty
                        data_not_empty=(max(bb(e1).size) > 0);

                        if ~isempty(bb3) && data_not_empty
                            data_vars=[data_vars e1];
                        end
                        
                    end

                    % get the data variable names
                    if ~isempty(data_vars)
                        num_data_vars=length(data_vars);
                        var_names=cell(num_data_vars, 1);

                        % var_names is a cell array of the data variable
                        % names.
                        for e1=1:num_data_vars;
                            var_names{e1}=bb(data_vars(e1)).name;
                        end
                        prompt_string1={'Select (highlight) all of the Data Variables', 'Only Select Variables containing Sound and Vibrations', 'Do not choose the Time Increment or Sampling Rate variables'};
                        [data_var_ix,ok] = listdlg('Name', 'Select the Data Variables', 'PromptString', prompt_string1, 'SelectionMode', 'multiple', 'ListSize', [500, 500],'ListString', var_names);

                        if isequal(ok, 1)

                            select_data_var=data_vars(data_var_ix);

                            % update the data_vars2 array
                            ix_set=setdiff(1:num_data_vars, data_var_ix);
                            data_vars2=data_vars(ix_set);

                            num_data_vars2=length(data_vars2);
                            var_names2=cell(num_data_vars2, 1);

                            % update the var_names2
                            for e1=1:num_data_vars2;
                                var_names2{e1}=bb(data_vars2(e1)).name;
                            end

                        else
                            select_data_var=[];
                            var_names2=var_names;
                            data_vars2=data_vars;
                        end

                        [ data_type ] = variable_data_type_selection(var_names(data_var_ix));
                        

                        snd_var=select_data_var(find(data_type == 1));
                        vibs_var=select_data_var(find(data_type == 2));
                        both_var=select_data_var(find(data_type == 3));

                        num_snd_vars=length(snd_var);
                        num_vibs_vars=length(vibs_var);
                        num_both_vars=length(both_var);

                        % store the sound variables in the configuration
                        % cell array
                        snd_var_name=cell(num_snd_vars, 1);
                        for e1=1:num_snd_vars;
                            snd_var_name{e1, 1}=bb(snd_var(e1)).name;
                        end

                        % cell array of sound variable names
                        default_mat_config_out{1,1}=snd_var_name;

                        vibs_var_name=cell(num_vibs_vars, 1);
                        for e1=1:num_vibs_vars;
                            vibs_var_name{e1, 1}=bb(vibs_var(e1)).name;
                        end

                        % cell array of vibs variable names
                        default_mat_config_out{2,1}=vibs_var_name;

                        both_var_name=cell(num_both_vars, 1);
                        for e1=1:num_both_vars;
                            both_var_name{e1, 1}=bb(both_var(e1)).name;
                        end

                        % cell array of both variable names
                        default_mat_config_out{3,1}=both_var_name;

                    end


                    % For the data variables that have both microphone and
                    % accelerometer data.  Each channel can only be a 
                    % microphone or an accelerometer.  Teh user will input 
                    % whether a channel is a microphone or an 
                    % accelerometer.  The channels which are microphones 
                    % will be grouped together.  The channels which are 
                    % accelerometers will be grouped together.  
                    % 
                    both_snd_ch=cell(num_both_vars, 1);
                    both_vibs_ch=cell(num_both_vars, 1);


                    if num_both_vars > 0
                        for e1=1:num_both_vars;
                            buf=bb(both_var(e1)).size;
                            bvm1=buf(1);
                            bvn1=buf(2);
                            num_channels=min(bvm1, bvn1);

                            % The variable contains both sound and
                            % vibrations data; however, the sensor is
                            % either a microphone or an accelerometer.
                            % 
                            % prompt the user for which channels are microphones and
                            % accelerometers
                            
                            [ data_type ] = channel_data_type_selection(num_channels );

                            % Calculate the number of microphones and accelerometers
                            both_snd_ch{e1, 1}=find(data_type == 1);
                            both_vibs_ch{e1, 1}=find(data_type == 2);

                        end
                    end

                    default_mat_config_out{3,4}=both_snd_ch;
                    default_mat_config_out{3,5}=both_vibs_ch;

                    % Get the Time Increment or Sampling Rate variable 
                    % names.
                    % 
                    % tosr is an acronym for Time increment Or Sampling
                    % Rate
                    
                    num_data_vars2=length(data_vars2);
                    var_names2=cell(num_data_vars2, 1);

                    for e1=1:num_data_vars2;
                        var_names2{e1}=bb(data_vars2(e1)).name;
                    end
                    
                    prompt_string2={'Select the Time Increment and Sampling Rate Variables:', 'Time Increment is the delta t (s)', 'Time Increment can be constant delta t or a vector of constant delta t', 'Sampling rate is a constant 1/delta t (Hz)', 'If Sampling rate is a vector, then the difference in the first two elements is used'};
                    % tosr acronym for (time or sampling rate)
                    [tosr_var, ok] = listdlg('Name', 'Choose the Time Increment or Rate Variables.', 'PromptString', prompt_string2, 'SelectionMode', 'multiple', 'ListSize', [500, 500], 'ListString', var_names2);

                    % If there are not any time or frequency variables prompt user
                    % to input the sampling rate for each data variable.  
                    if isempty(tosr_var) || isequal(ok, 0)
                        
                        snd_tosr_bool={};
                        Fs_SP={};
                        vibs_tosr_bool={};
                        Fs_vibs={};
                        both_tosr_bool={};
                        Fs_both={};
                            
                        % Enter the sampling rates for the sound variables
                        if num_snd_vars > 0
                            prompt=cell(num_snd_vars,1);
                            defAns=cell(num_snd_vars,1);
                            snd_tosr_bool=cell(num_snd_vars,1);
                            for e1=1:num_snd_vars;
                                snd_tosr_bool{e1}=0;
                                prompt{e1, 1}=['Enter the Sampling Rate (Hz) for the Sound Variable Named "', default_mat_config_out{1,1}{e1,1}, '"'];
                                defAns{e1, 1}='50000';
                            end
                            dlg_title='Enter the Sampling Rate (Hz) for each Sound Variable.';
                            num_lines=1;

                            Fs_SP_var=inputdlg(prompt,dlg_title,num_lines,defAns);
                            num_Fs_SP=length(Fs_SP_var);
                            Fs_SP=cell(num_Fs_SP, 1);
                            for e1=1:num_Fs_SP;
                                Fs_SP{e1}=str2double(Fs_SP_var{e1});
                            end
                        end
                        
                        % Enter the sampling rates for the vibrations variables
                        if num_vibs_vars > 0
                            prompt=cell(num_vibs_vars,1);
                            defAns=cell(num_vibs_vars,1);
                            vibs_tosr_bool=cell(num_vibs_vars,1);
                            for e1=1:num_vibs_vars;
                                vibs_tosr_bool{e1}=0;
                                prompt{e1, 1}=['Enter Sampling Rate (Hz) for the Vibrations Variable Named "', default_mat_config_out{2,1}{e1,1}, '"'];
                                defAns{e1, 1}='5000';
                            end
                            dlg_title='Enter the Sampling Rate (Hz) for each Vibrations Variable';
                            num_lines=1;

                            Fs_vibs_var=inputdlg(prompt,dlg_title,num_lines,defAns);
                            num_Fs_vibs=length(Fs_vibs_var);
                            Fs_vibs=cell(num_Fs_vibs, 1);
                            for e1=1:num_Fs_vibs;
                                Fs_vibs{e1}=str2double(Fs_vibs_var{e1});
                            end
                        end
                        
                        % Enter the sampling rates for the both sound and vibrations variables
                        if num_both_vars > 0
                            prompt=cell(num_both_vars,1);
                            defAns=cell(num_both_vars,1);
                            both_tosr_bool=cell(num_both_vars,1);
                            for e1=1:num_both_vars;
                                both_tosr_bool{e1}=0;
                                prompt{e1, 1}=['Enter the Sampling Rate (Hz) for the Variable Named "', default_mat_config_out{3,1}{e1,1}, '"'];
                                defAns{e1, 1}='50000';
                            end
                            dlg_title='Enter Sampling Rates (Hz) for the Variables with Both Sound and Vibrations';
                            num_lines=1;

                            Fs_both_var=inputdlg(prompt,dlg_title,num_lines,defAns);
                            num_Fs_both=length(Fs_both_var);
                            Fs_both=cell(num_Fs_both, 1);
                            for e1=1:num_Fs_both;
                                Fs_both{e1}=str2double(Fs_both_var{e1});
                            end
                            
                        end
                        
                        % Store sampling rate arrays to the
                        % configuration cell array
                        default_mat_config_out{1,2}=Fs_SP;
                        default_mat_config_out{2,2}=Fs_vibs;
                        default_mat_config_out{3,2}=Fs_both;
                        
                        default_mat_config_out{1,3}=snd_tosr_bool;
                        default_mat_config_out{2,3}=vibs_tosr_bool;
                        default_mat_config_out{3,3}=both_tosr_bool;
                        
                    else

                        num_tosr_var=length(tosr_var);
                        tosr_var_names=cell(num_tosr_var, 1);

                        for e1=1:num_tosr_var;
                            tosr_var_names{e1}=var_names2{tosr_var(e1)};
                        end

                        % determine if the variables are time or sampling rate variables.
                        % tosr_bool1: 1 is time increment otherwise is sampling rate
                        % default is time increment
                        tosr_bool1=ones(num_tosr_var, 1);
                        for e1=1:num_tosr_var;
                            tosr_bool1(e1) = menu(['Is the variable Named "', tosr_var_names{e1} ,'" a Time Increment or Sampling Rate?'], 'Time Increment', 'Sampling Rate');
                        end

                        % determine the correspondence between data variables and
                        % Time or Sampling Rate variables
                        snd_tosr_var=cell(num_snd_vars, 1);
                        snd_tosr_bool=cell(num_snd_vars, 1);
                        for e1=1:num_snd_vars;
                            prompt_string3={['For the Sound Variable Named "', default_mat_config_out{1,1}{e1,1}, '"'] , 'Choose the corresponding Time increment or Sampling Rate Variable', 'Time Increment is the delta t (s), can be constant or vector', 'Sampling rate is a constant 1/ delta t (Hz)', 'If Sampling rate is a vector, then the difference in the first two elements is used'};
                            [buf,ok] = listdlg('Name', 'Choose the corresponding Time Increment or Sampling Rate Variable', 'PromptString', prompt_string3, 'SelectionMode', 'single', 'ListSize', [500, 500], 'ListString',  tosr_var_names);
                            if ok
                                snd_tosr_var{e1}=tosr_var_names{buf};
                                snd_tosr_bool{e1}=tosr_bool1(buf);
                            else
                                snd_tosr_var{e1}={};
                                snd_tosr_bool{e1}=[];
                            end
                        end

                        vibs_tosr_var=cell(num_vibs_vars, 1);
                        vibs_tosr_bool=cell(num_vibs_vars, 1);
                        for e1=1:num_vibs_vars;
                            prompt_string3={['For the Vibrations Variable Named "', default_mat_config_out{2,1}{e1,1}, '"'] , 'Choose the Corresponding Time Increment or Sampling Rate Variable', 'Time Increment is the delta t (s), can be constant or vector', 'Sampling rate is a constant 1/ delta t (Hz)', 'If Sampling rate is a vector, then the difference in the first two elements is used'};
                            [buf,ok] = listdlg('Name', 'Choose the Corresponding Time Increment or Sampling Rate Variable', 'PromptString', prompt_string3, 'SelectionMode', 'single', 'ListSize', [500, 500], 'ListString',  tosr_var_names);
                            if ok
                                vibs_tosr_var{e1}=tosr_var_names{buf};
                                vibs_tosr_bool{e1}=tosr_bool1(buf);
                            else
                                vibs_tosr_var{e1}={};
                                vibs_tosr_bool{e1}=[];
                            end
                        end

                        both_tosr_var=cell(num_both_vars, 1);
                        both_tosr_bool=cell(num_both_vars, 1);
                        for e1=1:num_both_vars;
                            prompt_string3={['For the Variable for both Sound and Vibrations Named "', default_mat_config_out{3,1}{e1,1}, '"'] , 'Choose the Corresponding Time Increment or Sampling Rate Variable', 'Time Increment is the delta t (s), can be constant or vector', 'Sampling rate is a constant 1/ delta t (Hz)', 'If Sampling rate is a vector, then the difference in the first two elements is used'};
                            [buf,ok] = listdlg('Name', 'Choose the Corresponsing Time Increment or Sampling Rate Variable', 'PromptString', prompt_string3, 'SelectionMode','single', 'ListSize', [500, 500],'ListString',  tosr_var_names);
                            if ok
                                both_tosr_var{e1}=tosr_var_names{buf};
                                both_tosr_bool{e1}=tosr_bool1(buf);
                            else
                                both_tosr_var{e1}={};
                                both_tosr_bool{e1}=[];
                            end
                        end

                        default_mat_config_out{1,2}=snd_tosr_var;
                        default_mat_config_out{2,2}=vibs_tosr_var;
                        default_mat_config_out{3,2}=both_tosr_var;

                        default_mat_config_out{1,3}=snd_tosr_bool;
                        default_mat_config_out{2,3}=vibs_tosr_bool;
                        default_mat_config_out{3,3}=both_tosr_bool;
                    end


                    % Print the variable configuration Here
                    [out]=print_data_loader_configuration_table(default_mat_config_out);
                    
                    
                    keep_config=menu('Was the Variable Configuration Entered Correctly?', 'Keep Configuration', 'Redo Variable Configuration' );
                    close (out);
                    
                end

                automatic_cal=menu('Use Variable Name Configuration into Sound and Vibration data, Time Increment and Sampling Rate Variables for all files?', 'Yes', 'No');

                default_mat_config_out{4,1}=automatic_cal;
            end

            % load matlab file
            load(filename);

            % check the configuration of the data
            bool_config=ones(3,2);
            bool_config2=ones(3, 1);
            for e1=1:3;
                for e2=1:3;
                    if iscell(default_mat_config_out{e1,e2})
                        if  length(default_mat_config_out{e1,e2}) < 1
                            bool_config(e1, e2)=0;
                        else
                            if iscell(default_mat_config_out{e1,e2}{1,1})
                                if  length(default_mat_config_out{e1,e2}{1,1}{1,1}) < 1
                                    bool_config(e1, e2)=0;
                                else
                                    if iscell(default_mat_config_out{e1,e2}{1,1}{1,1})
                                        bool_config(e1, e2)=0;
                                    else
                                        if ~isempty(default_mat_config_out{e1,e2}{1,1}{1,1})
                                            bool_config(e1, e2)=1;
                                        else
                                            bool_config(e1, e2)=0;
                                        end
                                    end
                                end
                            else
                                if ~isempty(default_mat_config_out{e1,e2}{1,1})
                                    bool_config(e1, e2)=1;
                                else
                                    bool_config(e1, e2)=0;
                                end
                            end
                        end
                    else
                        if ~isempty(default_mat_config_out{e1,e2})
                            bool_config(e1, e2)=1;
                        else
                            bool_config(e1, e2)=0;
                        end
                    end
                end
                bool_config2(e1, 1)=prod(bool_config(e1, :));
            end


            % Transfer the data from the variables with the original names 
            % to cell array with a preprogrammed name.  

            % Determine the number of sound variables that can be loaded
            % correctly

            % Append the sound data to a cell array
            % Append the sound sampling rates to a cell array
            SP_var={};
            Fs_SP_var={};

            if isequal(bool_config2(1,1), 1)

                num_snd_vars=length(default_mat_config_out{1,1});
                num_snd_tosr_vars=length(default_mat_config_out{1,2});
                num_snd_tosr_bools=length(default_mat_config_out{1,3});
                num_snd_vars=min([num_snd_vars, num_snd_tosr_vars, num_snd_tosr_bools]);

                SP_var=cell(num_snd_vars, 1);
                Fs_SP_var=cell(num_snd_vars, 1);

                for e1=1:num_snd_vars;

                    SP_var_buf=eval(default_mat_config_out{1,1}{e1,1});

                    [svb_m1, svbn1]=size(SP_var_buf);
                    if svb_m1> svbn1
                        SP_var_buf=SP_var_buf';
                        [svb_m1, svbn1]=size(SP_var_buf);
                    end
                    SP_var{e1}=SP_var_buf;

                    if ischar(default_mat_config_out{1,2}{e1,1})
                        Fs_buf=eval(default_mat_config_out{1,2}{e1,1});
                    else
                        Fs_buf=default_mat_config_out{1,2}{e1,1};
                    end

                    if max(size(Fs_buf)) > 1
                        Fs_buf=Fs_buf(2)-Fs_buf(1);
                    else
                        Fs_buf=Fs_buf(1);
                    end

                    if isequal(default_mat_config_out{1,3}{e1, 1}, 1)
                        Fs_SP_var{e1}=1./Fs_buf;
                    else
                        Fs_SP_var{e1}=Fs_buf;
                    end

                end

            end

            % Append the vibrations data to a cell array
            % Append the vibrations sampling rates to a cell array
            vibs_var={};
            Fs_vibs_var={};

            if isequal(bool_config2(2,1), 1)

                num_vibs_vars=length(default_mat_config_out{2,1});
                num_vibs_tosr_vars=length(default_mat_config_out{2,2});
                num_vibs_tosr_bools=length(default_mat_config_out{2,3});
                num_vibs_vars=min([num_vibs_vars, num_vibs_tosr_vars, num_vibs_tosr_bools]);


                vibs_var=cell(num_vibs_vars, 1);
                Fs_vibs_var=cell(num_vibs_vars, 1);

                for e1=1:num_vibs_vars;

                    vibs_var_buf=eval(default_mat_config_out{2,1}{e1,1});

                    [vvb_m1, vvbn1]=size(vibs_var_buf);
                    if vvb_m1> vvbn1
                        vibs_var_buf=vibs_var_buf';
                        [vvb_m1, vvbn1]=size(vibs_var_buf);
                    end
                    vibs_var{e1}=vibs_var_buf;

                    if ischar(default_mat_config_out{2,2}{e1,1})
                        Fs_buf=eval(default_mat_config_out{2,2}{e1,1});
                    else
                        Fs_buf=default_mat_config_out{2,2}{e1,1};
                    end

                    if max(size(Fs_buf)) > 1
                        Fs_buf=Fs_buf(2)-Fs_buf(1);
                    else
                        Fs_buf=Fs_buf(1);
                    end

                    if isequal(default_mat_config_out{2,3}{e1, 1}, 1)
                        Fs_vibs_var{e1}=1./Fs_buf;
                    else
                        Fs_vibs_var{e1}=Fs_buf;
                    end

                end

            end


            % Append the both data to a cell array
            % Append the both sampling rates to a cell array
            if isequal(bool_config2(3,1), 1)

                num_both_vars=length(default_mat_config_out{3,1});
                num_both_tosr_vars=length(default_mat_config_out{3,2});
                num_both_tosr_bools=length(default_mat_config_out{3,3});
                num_both_vars=min([num_both_vars, num_both_tosr_vars, num_both_tosr_bools]);

                for e1=1:num_both_vars;

                    both_var=eval(default_mat_config_out{3,1}{e1,1});

                    [bv_m1, bvn1]=size(both_var);
                    if bv_m1 > bvn1
                        both_var=both_var';
                        [bv_m1, bvn1]=size(both_var);
                    end

                    if ischar(default_mat_config_out{3,2}{e1,1})
                        Fs_buf=eval(default_mat_config_out{3,2}{e1,1});
                    else
                        Fs_buf=default_mat_config_out{3,2}{e1,1};
                    end

                    if max(size(Fs_buf)) > 1
                        Fs_buf=Fs_buf(2)-Fs_buf(1);
                    else
                        Fs_buf=Fs_buf(1);
                    end

                    if isequal(default_mat_config_out{3,3}{e1, 1}, 1)
                        Fs_both_var=1./Fs_buf;
                    else
                        Fs_both_var=Fs_buf;
                    end

                    both_snd_ch=default_mat_config_out{3,4}{e1,1};

                    if length(both_snd_ch) > 1

                        buf=(both_snd_ch > 0);

                        if isequal(all(buf), 1)
                            SP_m1=length(SP_var);
                            SP_var{SP_m1+1}=both_var(both_snd_ch, :);
                            Fs_SP_var{SP_m1+1}=Fs_both_var;
                        end
                    end

                    both_vibs_ch=default_mat_config_out{3,5}{e1,1};

                    if length(both_vibs_ch) > 1

                        buf=(both_vibs_ch > 0);

                        if isequal(all(buf), 1)
                            vibs_m1=length(vibs_var);
                            vibs_var{vibs_m1+1}=both_var(both_vibs_ch, :);
                            Fs_vibs_var{vibs_m1+1}=Fs_both_var;
                        end
                    end

                end

            end
            
            % Data may be stored in single precision or other formats
            % and must be changed to double precision to be processed 
            % by Matlab. 
            
            SP=cell(length(SP_var), 1);
            for e1=1:length(SP_var);
                [buf]=convert_double(SP_var{e1});
                SP_var{e1}=[];
                SP{e1}=buf;
            end

            vibs=cell(length(vibs_var), 1);
            for e1=1:length(vibs_var);
                [buf]=convert_double(vibs_var{e1});
                vibs_var{e1}=[];
                vibs{e1}=buf;
            end

            Fs_SP=cell(length(Fs_SP_var), 1);
            for e1=1:length(Fs_SP_var);
                [buf]=convert_double(Fs_SP_var{e1});
                Fs_SP_var{e1}=[];
                Fs_SP{e1}=buf;
            end

            Fs_vibs=cell(length(Fs_vibs_var), 1);
            for e1=1:length(Fs_vibs_var);
                [buf]=convert_double(Fs_vibs_var{e1});
                Fs_vibs_var{e1}=[];
                Fs_vibs{e1}=buf;
            end
            

        case {'wav', 'wav.wav'}
            % Read the wave file
            % y is the data
            % fs is the sampling rate
            [y, fs, nbits, opts] = wavread(filename);

            [num_data, num_channels]=size(y);

            cal_snd=[];
            cal_vibs=[];
            Fs_SP=fs;
            Fs_vibs=fs;
            keep_config=2;

            % Determine whether to use the automated configuration
            if ~isequal(default_wav_settings_in{4,1}, 1)

                while keep_config == 2

                    % prompt the user for which channels are microphones and
                    % accelerometers
                    
                    [ data_type ] = channel_data_type_selection(num_channels );
                    

                    % Calculate the number of microphones and accelerometers
                    num_snd=length(data_type(data_type==1));
                    num_vibs=length(data_type(data_type==2));

                    if num_snd+num_vibs < num_channels
                        data_type=ones(num_channels, 1);
                        num_vibs=0;
                        num_snd=num_channels;
                    end

                    % get the calibration sensitivities for each sound channel
                    if num_snd > 0
                        prompt=cell(num_snd, 1);
                        defAns=cell(num_snd, 1);

                        for e1=1:num_snd;
                            prompt{e1, 1}=['Mic ', num2str(e1), ', Scale factor from Wave File to Pa, (WaveScale/Pa)'];
                            defAns{e1, 1}=num2str(40.00, 1);
                        end

                        dlg_title='For the Sound Sensor, Enter the scale factor to convert from wave file scale to Pa.';
                        num_lines=1;

                        cal_snd_str=inputdlg(prompt,dlg_title,num_lines,defAns);
                        cal_snd=ones(num_snd, 1);

                        for e1=1:num_snd;
                            cal_snd(e1)=str2double(cal_snd_str{e1});
                        end
                    end

                    % get the calibration sensitivities for each accelerometer
                    % channel

                    if num_vibs > 0
                        prompt=cell(num_vibs, 1);
                        defAns=cell(num_vibs, 1);

                        for e1=1:num_vibs;
                            prompt{e1, 1}=['Accel ', num2str(e1), ', Scale factor from Wave File to g''s, (WaveScale/g)'];
                            defAns{e1, 1}=num2str(10.00, 1);
                        end

                        dlg_title='For the Accelerometer Enter the Scale factor to convert from the Wave file scale to g''s, (WaveScale/g).  The program converts from g''s to to m/s^2 ';
                        num_lines=1;

                        % The inputdlg prompts the user to specify the calibration
                        % sensitivities
                        cal_vibs_str=inputdlg(prompt,dlg_title,num_lines,defAns);
                        cal_vibs=ones(num_vibs, 1);

                        for e1=1:num_vibs;
                            cal_vibs(e1)=str2double(cal_vibs_str{e1});
                        end
                    end

                    keep_config=menu('Keep Sensor Scale Factors Configuration for each variable', 'Yes', 'No');
                end

                automatic_cal=menu('Use Variable Configuration for each of the data files', 'Yes', 'No');

            else

                % Apply the input settings
                data_type=default_wav_settings_in{1, 1};
                cal_snd=default_wav_settings_in{2, 1};
                cal_vibs=default_wav_settings_in{3, 1};
                automatic_cal=default_wav_settings_in{4, 1};

                % Calculate the number of microphones and accelerometers
                num_snd=length(data_type(data_type==1));
                num_vibs=length(data_type(data_type==2));

            end

            % Set the output settings
            default_wav_settings_out{1,1}=data_type;
            default_wav_settings_out{2,1}=cal_snd;
            default_wav_settings_out{3,1}=cal_vibs;
            default_wav_settings_out{4,1}=automatic_cal;

            [cal_snd_a]=meshgrid(cal_snd, 1:num_data );
            [cal_vibs_a]=meshgrid(cal_vibs, 1:num_data );

            % Calibrate the wave files and convert to engineering units
            if num_snd > 0
                SP=1./cal_snd_a.*y(:, data_type==1);            % Pa
            else
                SP=[];                                          % Pa
            end

            if num_vibs > 0
                vibs=9.806./cal_vibs_a.*y(:, data_type==2);     % m/s^2
            else
                vibs=[];                                         % m/s^2
            end

        otherwise

    end

end

[m1 n1]=size(SP);

if m1 > n1
    SP=SP';
    [m1 n1]=size(SP);
end

[m1 n1]=size(vibs);

if m1 > n1
    vibs=vibs';
    [m1 n1]=size(vibs);
end

