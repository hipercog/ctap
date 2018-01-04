function [EEG, Cfg] = CTAP_load_data(~, Cfg)
%CTAP_load_data -  Load data into CTAP
%
% Description:
%   Uses ctapeeg_load_data() to check and load a file.
%   Information in Cfg.measurement (created by looper) defines which raw data
%   file is loaded.
%   See ctapeeg_load_data() for a list of supported file types.
%
% Syntax:
%   [EEG, Cfg] = CTAP_load_data(~, Cfg)
%
% Inputs:
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.load_data:
%   .type   string, Data type, default: '' which uses filename extension as
%           the data type. Use .type='neurone' if MC.physiodata contains
%           NeurOne data folders instead of traditional files. 
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also: ctapeeg_load_data() 
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments
if isfield(Cfg, 'measurement')
    Arg = Cfg.measurement;
    Arg.type = ''; %by default guesses file type from MC.physiodata file extension
else
    error('CTAP_load_data:no_measurement', 'Cfg.measurement MUST exist!');
end

% Override defaults with user parameters
if isfield(Cfg.ctap, 'load_data')
    Arg = joinstruct(Arg, Cfg.ctap.load_data);
end


%% CORE
% if isfield(Arg, 'type')
%     [EEG, params, result] = ctapeeg_load_data(Arg.physiodata,'type', Arg.type);
% else
[EEG, params, result] = ctapeeg_load_data(Arg.physiodata, Arg);
% end


%% MISC
try result.meta; catch, result.meta = 'No meta data'; end
try result.time; catch, result.time = {now()}; end

% Add block definitions if any
% TODO: this step is rather non-general. A basic implementation could be
% here, users should implement their own custom selections if needed.
if isfield(Cfg, 'MC')
    if isfield(Cfg.MC, 'blocks')
        % todo: This loads data again from source file. Could be based on
        % MC and EEG alone. Different block sources give markers in
        % different formats (string vs numeric, string correct).
        blocks = parse_blocks(Cfg.MC, Arg.casename);
        %Throws error if measurement start event is not found.
        
        % Regions of unnecessary data
        if size(blocks.limits_sample, 1) == 1
            %Data before start
            regions(1,1) = 1;
            regions(1,2) = max(2, blocks.limits_sample(1)-1);
            %Data after end
            regions(2,1) = min(EEG.pnts-1, blocks.limits_sample(2)+1);
            regions(2,2) = EEG.pnts;
        else
           %todo: Assumes one block per measurement. Quite a restriction.
           error('CTAP_load_data:block_fail', 'dimension err: check Cfg.MC.blocks');
        end
        
        %Remove unnecessary parts of data
        EEG = eeg_eegrej(EEG, regions);

        % time_specs: { file start time string,
        %               measurement start time string,
        %               measurement start offset from file start in samples}
        time_specs = { datestr(result.time{1},30),...
                       datestr(...
                            datenum(result.time{1})+...
                            (regions(1,2)/EEG.srate)/(24*60*60), 30),...
                       regions(1,2)};
    else
        disp 'No blocks defined.';
        time_specs = { datestr(result.time{1},30),...
                   datestr(result.time{1},30),...
                   0};
    end
else
    disp 'MC not specified in Cfg. No blocks loaded.';
    time_specs = { datestr(result.time{1},30),...
                   datestr(result.time{1},30),...
                   0};
end

% Add dummy event to avoid problems with functions that assume events exist
if (isempty(EEG.event))
   EEG.event(1).type = 'dummy_event';
   EEG.event(1).latency = 1;
   EEG.event(1).duration = 0;
else
    %set EEG event type field to be char, to avoid mixing data format and
    %crashing, e.g. pop_epoch()
    for idx = 1:numel(EEG.event) 
        if isnumeric(EEG.event(idx).type) 
            EEG.event(idx).type = num2str(EEG.event(idx).type);
        end 
    end
end


%% ERROR/REPORT
Arg = joinstruct(Arg, params);
Cfg.ctap.load_data = Arg;

msg = myReport({'Load data, add CTAP, for ' Arg.physiodata}, Cfg.env.logFile);

EEG = add_CTAP(EEG, Cfg,...
    'time', time_specs,...
    'meta', result);

EEG.CTAP.history = create_CTAP_history_entry(msg, mfilename, Arg);
