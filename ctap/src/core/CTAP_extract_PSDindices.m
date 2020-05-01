function [EEG, Cfg] = CTAP_extract_PSDindices(EEG, Cfg)
%CTAP_extract_PSDindices  - Extract PSD workload/engagement indices.
%
% Description:
%   Saves results into Cfg.env.paths.featuresRoot/PSDindices.
%
% Syntax:
%   [EEG, Cfg] = CTAP_extract_PSDindices(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.extract_PSDindices:
%   .eind       struct with fields specified by varargins of psd_eind() 
%   .eindcc     struct with fields specified by varargins of psd_eind_cc()
%   .entropy    struct with fields specified by varargins of psd_entropy()
%   
%   Example definitions:
% .eind 
%                  fmin: [1 4 8 13]
%                  fmax: [4 8 13 20]
%     integrationMethod: 'trapez'
%            bandLabels: {1x4 cell}
% .eindcc
%                 fzStr: 'Fz'
%                 pzStr: 'Pz'
%                  fmin: [1 4 8 13]
%                  fmax: [4 8 13 20]
%     integrationMethod: 'trapez'
%            bandLabels: {1x4 cell}
% .entropy
%     fmin: [1 1 1 1 1 3.5 5 4 8 2 3 6 10]
%     fmax: [7 15 25 35 45 45 15 8 12 45 45 45 45]
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also: psd_entropy(), psd_eind(), psd_eind_cc()
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Set optional arguments
Arg = struct;
Arg.eind.bandLabels = {'delta' 'theta' 'alpha' 'beta'};
Arg.eindcc.bandLabels = {'delta' 'theta' 'alpha' 'beta'};
Arg.eindcc.fzStr = get_channel_name_by_description(EEG,'frontal');
Arg.eindcc.pzStr = get_channel_name_by_description(EEG,'vertex');
Arg.extra_path = '';

% Override defaults with user parameters
if isfield(Cfg.ctap, 'extract_PSDindices')
    Arg = joinstruct(Arg, Cfg.ctap.extract_PSDindices); %override w user params
end


%% Gather measurement metadata (subject and measurement specific information)
INFO = gather_measurement_metadata(Cfg.subject, Cfg.measurement); %#ok<*NASGU>


%% Gather cseg metadata (calculation segment specific information)
SEGMENT = gather_cseg_metadata(EEG, Cfg.event.csegEvent);


%% Calculate spectral entropies
disp('Extracting spectral entropies...');
varg = struct2varargin(Arg.entropy);
[resENTROPY, Sinfo] = psd_entropy(EEG.CTAP.PSD, varg{:}); %#ok<*ASGLU>


%% Calculate spectral indices
disp('Extracting single-channel workload/engagement indices...');
varg = struct2varargin(Arg.eind);
[resEIND, EINDinfo] = psd_eind(EEG.CTAP.PSD, varg{:});


%% Calculate spectral indices - multichannel
disp('Extracting multi-channel workload/engagement indices...');
varg =  struct2varargin(Arg.eindcc);
[resEINDM, EINDMinfo] = psd_eind_cc(EEG.CTAP.PSD,...
              EEG.chanlocs(get_refchan_inds(EEG, 'frontal')).labels,...
              EEG.chanlocs(get_refchan_inds(EEG, 'parietal')).labels,...
              varg{:});


%% Save
savepath = fullfile(Cfg.env.paths.featuresRoot, 'PSDindices', Arg.extra_path);
if isfield(Cfg, 'export'), Cfg.export.featureSavePoints{end + 1} = savepath; end
if ~isfolder(savepath), mkdir(savepath); end
savename = sprintf('%s_PSDindices.mat', Cfg.measurement.casename);
save(fullfile(savepath, savename)...
    , 'INFO', 'SEGMENT', 'resENTROPY', 'resEIND', 'resEINDM');


%% ERROR/REPORT
Cfg.ctap.extract_PSDindices = Arg;

msg = myReport(sprintf('Extracted engagement/workload indices from PSD.')...
    , Cfg.env.logFile);

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);

end
