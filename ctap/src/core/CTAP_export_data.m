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
%                       set, gdf, edf, bdf, cfwb, cnt, leda, mul, hdf5
%   .lock_event string, name of event type to time-lock an ERP average when
%                       exporting a .mul file
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
savename = '';
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
        
    case 'hdf5'
        [idx, lock_evname] = get_event_epochIdx(EEG, Arg.lock_event);
        if any(idx)
            EEGev = pop_select(EEG, 'trial', find(idx));
            savename = fullfile(Arg.outdir, sprintf('%s_%s_ERPdata.h5'...
                            , EEG.CTAP.measurement.casename, lock_evname));
            eeglab_writeh5_erp(savename, EEGev);
            msg = ['Export ERP of ' lock_evname ' epochs to HDF5'];
        else
            msg = ['WARN No epochs found containing ' lock_evname];
        end
        
    case 'leda'
        data = eeglab2leda(EEG);
        savename = fullfile(Arg.outdir, [Arg.name '.mat']);
        save(savename, 'data');
        msg = myReport('Exporting EDA data to Ledalab', Cfg.env.logFile);

    case 'mul'
        mul = eeglab2mul(EEG, Arg.lock_event);
        msg = myReport(['Exporting a mul-file ERP for averaged data ' ...
            'time-locked to event ' Arg.lock_event], Cfg.env.logFile);
        % Make a name suitable for CBRU mul-plugin
        %TODO: export_name_root is hacked into Cfg in the pipebatch script
        %specific to NeuroEnhance project - make sure it is provided in
        %other contexts, or find a more general solution here?
        Arg.name = [Cfg.MC.export_name_root regexprep(Arg.name, '\D', '')];
        savename = fullfile(Arg.outdir, [Arg.name '_' Arg.lock_event '.mul']);
        matrixToMul(savename, mul, Arg.lock_event)

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
