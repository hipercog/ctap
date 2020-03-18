function [EEG, Cfg] = CTAP_run_ica(EEG, Cfg)
%CTAP_run_ida - Run ICA decompositions
%
% Description:
%
%
% Syntax:
%   [EEG, Cfg] = CTAP_run_ica(EEG, Cfg;
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.run_ica:
%   .method         string, ICA method to use, default: 'fastica'
%   .channelTypes   cellstring, List of channel types to include,
%                   default:  {'EEG'  'EOG'}
%   .overwrite      logical, Should existing ICA decomposition be overwritten?
%                   default: true
%   .plot           logical, Should quality control figures be plotted,
%                   default: Cfg.grfx.on
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also:  
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments
Arg.method = 'fastica';
Arg.channelTypes = {'EEG' 'EOG'};
Arg.overwrite = true;
Arg.plot = Cfg.grfx.on; % plot settings follow the global flag, unless specified by user!

% Override defaults with user parameters
if isfield(Cfg.ctap, 'run_ica')
    Arg = joinstruct(Arg, Cfg.ctap.run_ica);
end


%% ASSIST
if Arg.overwrite && ~isempty(EEG.icaweights)
    EEG.icaweights = [];
    EEG.icasphere = [];
    EEG.icawinv = [];
    EEG.icachansind = [];
end


%% CORE
    
% call the CHOSEN method
switch Arg.method
    case 'fastica'
        if ~exist('fastica', 'file')
            error('CTAP_run_ica:bad_method',...
                    'FastICA method not found on path, aborting')
        end
        EEG = pop_runica(EEG, 'icatype', 'fastica',...
                        'chanind', Arg.channelTypes );
               
        
    case 'infomax'
        EEG = pop_runica(EEG, 'chanind', Arg.channelTypes,...
                        'extended', 1,...
                        'interupt', 'on',...
                        'stop', 1E-7);
                    
    case 'binary'
        warning('Method not yet available.'); %#ok<WNTAG>
%         [wts,sph]=binica( EEG.data(chIwant,:,:), 'extended', 1 );
%         EEG = pop_editset(EEG, 'icasphere', sph);
%         EEG = pop_editset(EEG, 'icaweights', wts);

    case 'jade'
        EEG = pop_runica( EEG, 'icatype', 'jader',...
            'chanind', Arg.channelTypes,...
            'extended', 1,...
            'interupt', 'on',...
            'stop', 1E-7 );
        
    case 'otherwise'
        error('CTAP_run_ica:bad_method',...
                    'Method %s not recognised, aborting', Arg.method)
end


%% ERROR/REPORT
Cfg.ctap.run_ica = Arg;

msg = myReport( {'Made ICA components for -' EEG.setname '- by ' Arg.method}...
    , Cfg.env.logFile );

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);


%% QUALITY CONTROL
if Arg.plot
    %% Plot scalp maps of all components for reference
    titleStr = sprintf('%s--independent components', EEG.setname);
    comps = 1:size(EEG.icawinv, 2);
    chans = get_eeg_inds(EEG, 'EEG');

    figH = ctap_ic_topoplot(EEG, comps...
        , 'savepath', get_savepath(Cfg, mfilename, 'qc')...
        , 'savename', EEG.CTAP.measurement.casename...
        , 'topotitle', titleStr...
        , 'topoplot', {'plotchans', chans}...
        , 'visible', 'off'); %#ok<NASGU>
end
