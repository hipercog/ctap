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
%   .outdir     string, output directory, Default = Cfg.env.paths.exportRoot
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
Arg.outdir = Cfg.env.paths.exportRoot;

% Override defaults with user parameters
if isfield(Cfg.ctap, 'export_data')
    Arg = joinstruct(Arg, Cfg.ctap.export_data); %override w user params
end


%% ASSIST
if ~isfield(Arg, 'type')
    error('CTAP_export_data:bad_param', 'Need an export data-type to proceed')
end
Arg.type = strrep(Arg.type,'.','');

[outpath, outfolder, ~] = fileparts(Arg.outdir);
if ~isfolder(outpath) && isfield(Cfg.env.paths, outpath)
    Arg.outdir = fullfile(Cfg.env.paths.(outpath), outfolder);
end
if ~isfolder(Arg.outdir), mkdir(Arg.outdir); end


%% CORE
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
            'TYPE', upper(Arg.type),...
            'EVENT', EEG.event,...
            'Label', {EEG.chanlocs.labels},...
            'SPR', EEG.srate);
        
    case 'leda'
        data = eeglab2leda(EEG);
        savename = fullfile(Arg.outdir, [Arg.name '.mat']);
        save(savename, 'data');
        msg = myReport('Exporting EDA data to Ledalab', Cfg.env.logFile);

    case 'mul'
        if ~ismatrix(EEG.data)
            if ~ismember({EEG.event.type}, Arg.locking_event)
                error('CTAP_export_data:bad_event_name', ['Event name %s was'...
                    ' not found in the event structure: cannot export'])
            end
            msg = myReport(['Exporting a mul-file ERP for averaged data ''' ...
                '''time-locked to event ' Arg.locking_event], Cfg.env.logFile);
            %average data for locking_event event here
            %first 3 lines find epochs with wanted event - must be easier way?
            idx = squeeze(struct2cell(EEG.epoch));
            idx = squeeze(idx(ismember(fieldnames(EEG.epoch), 'eventtype'), :));
            idx = cell2mat(cellfun(@(x) any(strcmpi(x, Arg.locking_event)), idx, 'Un', 0));
            epx = EEG.data(get_eeg_inds(EEG, 'EEG'), :, idx);
            eegdata = mean(epx, 3)';
        else
            eegdata = EEG.data(get_eeg_inds(EEG, 'EEG'), :)';
        end
        %make structure to feed to matrixToMul
        mul = struct(...
            'data', eegdata,...
            'Npts', EEG.pnts,...
            'TSB', EEG.xmin * 1000,...
            'DI', 1000 / EEG.srate,...
            'Scale', 1.0,...
            'ChannelLabels', {{EEG.chanlocs(get_eeg_inds(EEG, 'EEG')).labels}});
        
        savename = fullfile(Arg.outdir, [Arg.name '_' Arg.locking_event '.mul']);
        matrixToMul(savename, mul, Arg.locking_event)
        
        % Write out separate event file: currently only supports a few
        % paradigms: CBRU's AV, multiMMN, and switching task
        %TODO : write general version of this, include in ctap/src/utils/IO!
        evtfname = fullfile(Arg.outdir, [Arg.name '_' Arg.locking_event '-recoded.evt']);
        if isfield(EEG.CTAP.err, 'preslog_evt') && ~EEG.CTAP.err.preslog_evt
            evtfname = [evtfname '-recoded_missingTriggers.evt'];
        end
        writeEVT(EEG.event, EEG.srate, evtfname, Arg.name)

end


%% ERROR/REPORT
Cfg.ctap.export_data = Arg;

if exist(savename, 'file')
    msg = myReport([msg '::Export successful'], Cfg.env.logFile);
else
    msg = myReport([msg '::Export unsuccessful'], Cfg.env.logFile);
end

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);


end % ctapeeg_export()
