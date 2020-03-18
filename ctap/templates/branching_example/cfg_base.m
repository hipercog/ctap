function [Cfg, out] = cfg_base(project_root_folder)
% A base config that defines stuff that does not depend on pipes

%% Define hierarchy
% Analysis branch ID
% Important as this id is used to separate analysis branches with different
% configurations. Defined here to keep it with the configs.
Cfg.id = 'ctapmanu_branch';

Cfg.srcid = {''};


%% Cross-platform stuff (not part of CTAP)
Cfg.env.paths.projectRoot = project_root_folder;


%% Define important directories and files
Cfg.env.paths.branchSource = ''; %since this pipe starts from raw EEG data
Cfg.env.paths.ctapRoot = fullfile(cd(), 'example-project', Cfg.id);
% note: .ctapRoot is here set one directory level deeper than in cfg_manu.m
% to create a clearer directory structure.

%Cfg.env.paths.analysisRoot is set later


%% Define important directories and files

% Note: other canonical locations are added in ctap_auto_config.m
% You should use it in your analysis batch file.

% Location of measurement config file
% If you have made your own measurement config file, you can store the
% location here. The example uses autogeneration.
% Cfg.env.measurementInfo = fullfile(...);

% Channel location file
% For demonstration purposes this is in ctap repo folder "res", 
% which should be in your path and therefore accessible without full path
Cfg.eeg.chanlocs = 'chanlocs128_biosemi.elp';

                
%% Define other important stuff
Cfg.eeg.reference = {'L_MASTOID' 'R_MASTOID'};
%data is average referenced -> change to this reference

% EOG channel specification for artifact detection purposes
% Allowed values: {},{'chname'},{'chname1','chname2'}
% In case of two channel names their abs(ch1-ch2) is used as the signal.
Cfg.eeg.veogChannelNames = {'C17'};
Cfg.eeg.heogChannelNames = {'HEOG1','HEOG2'};

%Cfg.event.csegEvent = 'correctAnswerBlock';
% type of events that define data segments from which features are extracted

%% Configure output
% Should plots be generated
Cfg.grfx.on = true;

% Result export
% Metadata variable names to include in the export
Cfg.export.csegMetaVariableNames = {'timestamp','latency','duration'};

%% Dummy
out = struct([]);