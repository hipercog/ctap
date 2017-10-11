% function [Cfg, out] = cfg_HYDRAKING(idstr)
% 
% if nargin<1
%     idstr = 'syntest';
% end

%% Load basic config
if strcmp(computer,'GLNXA64')
    Cfg.env.paths.serverRoot = '/home/uni';
else
    Cfg.env.paths.serverRoot = 'T:\';
end
Cfg.env.paths.projectRoot = fullfile(...
    Cfg.env.paths.serverRoot,'ctaptest','testruns','run4',DATA_STR);

% output folder(s)
Cfg.env.paths.analysisRoot = fullfile(...
    Cfg.env.paths.serverRoot,'ctaptest',OUTPUT,batch_id);

Cfg.env.paths.exportRoot = fullfile(...
    Cfg.env.paths.analysisRoot,'export');

[ctapath, ~, ~] = fileparts(mfilename('fullpath'));
Cfg.eeg.chanlocs = fullfile(ctapath,'..','..','res',...
                    'chanlocs128_biosemi.elp');
Cfg.eeg.reference = {'EEG'};

Cfg.grfx.on = false;

%% Configure analysis functions
% Passing cells into the struct() constructor creates a struct array, so
% only do this if you want to have multiple calls to this function in 
% the pipe. Otherwise, pass as individual assignments.
method = {...
    {'variance' 'eegthresh' 'xtreme_vals'}...%basic - extreme values
    {'rejspec' 'rejspec' 'comp_spectra'}...%best of eeglab - reject spectra
    {'faster' 'faster' 'faster'}...%state of the art - FASTER
    {'recufast' 'recufast' 'recufast'}...%homegrown - recursive FASTER
    };

% Note: default parameters for recufast in all cases result in basic FASTER
% functionality, i.e. a single pass with z-score bounds = [-2 2]
% (two sigma should be ~95% of samples).
% 
% To alter this to get recursive functionality for the fourth variant, 
% pass  NAME,   VALUE parameters as follows:
%       iters,  8
%       bounds, [-3 3]

%For all 'detect_bad_x' you should specify at least a method
switch batch_id
    case 'cereberus'
        my_args.detect_bad_channels = struct('method', method{1}{1});

        my_args.detect_bad_epochs = struct('method', method{1}{2});
        
        my_args.detect_bad_comps = struct('method', method{1}{3});
    case 'medusa'
        my_args.detect_bad_channels = struct('method', method{2}{1});

        my_args.detect_bad_epochs = struct('method', method{2}{2});
        
        my_args.detect_bad_comps = struct('method', method{2}{3});
    case 'harpy'
        my_args.detect_bad_channels = struct('method', method{3}{1},...
            'refChannel', 'C21',... %should be 'C21' alias 'Fz'
            'channelType', {'EEG'});

        my_args.detect_bad_epochs = struct('method', method{3}{2});
        
        my_args.detect_bad_comps = struct('method', method{3}{3});
    case 'cyclops'
        my_args.detect_bad_channels = struct(...
            'method', method{4}{1},...
            'refChannel', 'C21',... %should be 'C21' alias 'Fz'
            'channelType', {'EEG'});

        my_args.detect_bad_epochs = struct(...
            'method', method{4}{2});
        
        my_args.detect_bad_comps = struct(...
            'blinks', true,...
            'method', method{4}{3});
end

my_args.epoch_data = struct(...
    'method', 'regep');

my_args.filter_data = struct(...
    'locutoff', 1,...
    'hicutoff', 45);

my_args.load_data = struct(...
    'type', 'set');%also requires data path from Cfg.MC

my_args.reject_data = struct(...%reads from EEG.CTAP-created by detect functions
    'plot', false);

my_args.run_ica = struct(...
    'method', 'fastica');
my_args.run_ica.channels = {'EEG' 'EOG'};

my_args.tidy_chanlocs.types = {{'1:128' 'EEG'}, {'129:132' 'EOG'},...
    {'133:134' 'REF'}};
