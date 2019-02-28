function [EEG, Cfg] = CTAP_plot_ERP(EEG, Cfg)
%CTAP_plot_erp - Plot ERP of epoched data and export data to HDF5
%
% Description:
%
%
% Syntax:
%   [EEG, Cfg] = CTAP_plot_ERP(EEG, Cfg)
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct should be updated with parameter values
%                       actually used
%
% Notes: 
%
% See also: eeglab_writeh5_erp  
%
% Copyright(c) 2016:
% Benjamin Cowley (Ben.Cowley@helsinki.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% create Arg and assign any defaults to be chosen at the CTAP_ level
Arg = struct;
Arg.channels = {EEG.chanlocs(get_eeg_inds(EEG, 'EEG')).labels};
% check and assign the defined parameters to structure Arg, for brevity
if isfield(Cfg.ctap, 'plot_ERP')
    Arg = joinstruct(Arg, Cfg.ctap.plot_ERP);%override with user params
end


%% ASSIST
outdir = get_savepath(Cfg, mfilename, 'fig');


%% CORE
% Plot ERP
figH = plot_epoched_EEG({EEG},...
            'channels', Arg.channels,...
            'ylim', Arg.ylim,...
            'visible', 'off');
savename = sprintf('%s_%s_ERP.png', EEG.CTAP.measurement.casename,...
                   EEG.CTAP.ERP.id);
savefile = fullfile(outdir, savename);
print(figH, '-dpng', savefile);
close(figH);


%% Export ERP data to HDF5 (single trial and raw)
savename = sprintf('%s_%s_ERPdata.h5', EEG.CTAP.measurement.casename,...
                   EEG.CTAP.ERP.id);
h5file = fullfile(outdir, savename);
eeglab_writeh5_erp(h5file, EEG);


%% Export some statistics to function data database
dbid = sbf_fundb_open(Cfg.env.funDataDB);
stpf = sprintf('set%d_fun%d',...
                Cfg.pipe.current.set,...
                Cfg.pipe.current.funAtSet);
sqlq = sprintf('INSERT OR REPLACE INTO ctap_plot_erp (casename,erpid,stepsetfun,variable,value) VALUES (''%s'',''%s'',''%s'',''%s'',%f)',...
               EEG.CTAP.measurement.casename, EEG.CTAP.ERP.id, stpf,...
               'ntrials', size(EEG.data,3));
mksqlite(dbid, sqlq);
mksqlite(dbid, 'close');
% mksqlite('select * from ctap_plot_erp')


%% Export average ERP in HDF5 format - old style, here for old R code to work...
%{
savename = sprintf('%s_%s_ERPdata.h5', EEG.CTAP.measurement.casename,...
                   EEG.CTAP.ERP.id);
h5file = fullfile(outdir, savename);
if exist(h5file, 'file') ~= 0
    delete(h5file);
end

h5create(h5file, '/ERP', fliplr([size(EEG.data, 1), size(EEG.data, 2)])); %Note: dimensions need to be flipped
h5write(h5file, '/ERP', mean(EEG.data, 3)'); %Note: dimensions need to be transposed
h5writeatt(h5file,'/ERP','d1ID', strjoin({EEG.chanlocs.labels}, ';'));
h5writeatt(h5file,'/ERP','d2ID', EEG.times);
%}
    
%handle(Arg);
%handle(result);


%% ERROR/REPORT
%... the complete parameter set from the function call ...
Cfg.ctap.plot_ERP = Arg;
%log outcome to console and to log file
msg = myReport(sprintf('ERP plotted for measurement %s.',...
    EEG.CTAP.measurement.casename), Cfg.env.logFile);
%create an entry to the history struct
EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);



%% Helper functions
function dbid = sbf_fundb_open(dbfile)

    dbid = mksqlite(0, 'open', dbfile); %creates if does not exist
 
    % Create table if necessary
    S = mksqlite(dbid, 'show tables');
    if isempty(S)
        sqlq = 'CREATE TABLE ctap_plot_erp (casename TEXT NOT NULL, erpid TEXT NOT NULL, stepsetfun TEXT NOT NULL, variable TEXT NOT NULL, value REAL, PRIMARY KEY (casename, erpid, stepsetfun, variable))';
        mksqlite(dbid, sqlq);
    else
        if (~ismember('ctap_plot_erp', {S.tablename}))
            sqlq = 'CREATE TABLE ctap_plot_erp (casename TEXT NOT NULL, erpid TEXT NOT NULL, stepsetfun TEXT NOT NULL, variable TEXT NOT NULL, value REAL, PRIMARY KEY (casename, erpid, stepsetfun, variable))';
            mksqlite(dbid, sqlq);
        end
    end
end


end