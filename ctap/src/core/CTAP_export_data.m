function [EEG, Cfg] = CTAP_export_data(EEG, Cfg)
%CTAP_EXPORT_DATA export EEGLAB-format data as some given type on disk
%
% Description:
%
% SYNTAX
%   [EEG, Cfg] = CTAP_export_data(EEG, Cfg)
%
% INPUT
%   'EEG'       eeglab data struct
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.export_data:
%   .outdir     string, output directory, Default = pwd
%   .name       string, name of file, default = EEG.setname
%   .type       string, file type to save as, NO Default:
%                      - 'set', 'gdf','edf','bdf','cfwb','cnt', 'leda', 'mul'
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
Arg.name = EEG.CTAP.measurement.casename;
Arg.outdir = pwd;

% Override defaults with user parameters
if isfield(Cfg.ctap, 'export_data')
    Arg = joinstruct(Arg, Cfg.ctap.export_data); %override w user params
end

if ~isfield(Arg, 'type')
    error('CTAP_export_data:bad_param', 'Need an export data-type to proceed')
end
if ~isfolder(Arg.outdir), mkdir(Arg.outdir); end


%% ...operation
switch Arg.type
    case 'set'
        savename = fullfile(Arg.outdir, [Arg.name '.set']);
        pop_saveset(EEG, 'filename', [Arg.name '.set'], 'filepath', Arg.outdir);
        
    case 'bva'
        savename = fullfile(Arg.outdir, Arg.name);
        pop_writebva(EEG, savename);
        
    case {'gdf','edf','bdf','cfwb','cnt'}
        savename = fullfile(Arg.outdir, [Arg.name '.' Arg.type]);
        writeeeg(savename,...
            EEG.data, EEG.srate,...
            'TYPE', upper(strrep(Arg.type,'.','')),...
            'EVENT', EEG.event,...
            'Label', {EEG.chanlocs.labels},...
            'SPR', EEG.srate);
        
    case 'leda'
        data = eeglab2leda(EEG);
        savename = fullfile(Arg.outdir, [Arg.name '.mat']);
        save(savename, 'data');
        
    case 'mul'
        if ~ismatrix(EEG.data)
            error('CTAP_export_data:epoched', 'Can''t export epoched data to Besa mul')
        end
        %make structure to feed to matrixToMul
        mul = struct(...
            'data', EEG.data',...
            'Npts', EEG.pnts,...
            'ChannelLabels', {EEG.chanlocs(get_eeg_inds(EEG, 'EEG')).labels},...
            'TSB', -1000,...
            'DI', 1000 / EEG.srate,...
            'Scale', 1.0);
        
        savename = fullfile(Arg.outdir, [Arg.name '.mul']);
        matrixToMul(savename, mul, EEG.CTAP.measurement.measurement)
        %must write out separate event file: currently only supports a few
        %paradigms: CBRU's AV, multiMMN, and switching task
        %TODO : write general version of this, include in ctap/src/utils/IO!
        evtfname = fullfile(Arg.outdir...
            , [EEG.CTAP.measurement.casename '-recoded.evt']);
        if isfield(EEG.CTAP.err, 'preslog_evt') && ~EEG.CTAP.err.preslog_evt
            evtfname = [evtfname '-recoded_missingTriggers.evt'];
        end
        writeEVT(EEG.event, EEG.srate, evtfname, EEG.CTAP.measurement.measurement)
        
end


%% ERROR/REPORT
Cfg.ctap.export_data = params;

if exist(savename, 'file')
    msg = myReport('Export successful', Cfg.env.logFile);
else
    msg = myReport('Export unsuccessful', Cfg.env.logFile);
end

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, params);


end % ctapeeg_export()
