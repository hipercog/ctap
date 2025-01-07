function [EEG, Cfg] = CTAP_parse_blocks(EEG, Cfg)
%CTAP_parse_blocks -  Parse block information if available.
%
% Description:
%   Obtains block information from Cfg.MC
%
% Syntax:
%   [EEG, Cfg] = CTAP_parse_blocks(EEG, Cfg)
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.parse_blocks:
%   .use_blocks string or [1 n] numeric, define which blocks to use, default: 'all'
%               [1], number of blocks starting from block 1
%               [i:k], range of blocks
%               [1 k<=n], some selection of blocks
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also: CTAP_load_data() 
%
% Copyright(c) 2018 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%FIXME: will casename also exist here when meas_info comes from raw files???
% EEG.CTAP.measurement.casename;
Arg.use_blocks = 'all';

% Override defaults with user parameters
if isfield(Cfg.ctap, 'parse_blocks')
    Arg = joinstruct(Arg, Cfg.ctap.parse_blocks);
end


%% Add block definitions if any
if isfield(Cfg, 'MC') && isfield(Cfg.MC, 'blocks')
%FIXME - diff block sources give markers in diff formats (string vs num, string correct)
%TODO - Throws error if measurement start event is not found?
    blocks = parse_blocks(EEG, Cfg.MC, EEG.CTAP.measurement.casename);

    varargin = {};
    if isfield(blocks, 'factorlabels') && ~isempty(blocks.factorlabels)
        % Reformat blocks struct into varargin format
        varargin = cell(1, length(blocks.factorlabels) * 2);
        for i = 1:2:length(blocks.factorlabels) * 2
            j = ceil(i / 2);
            varargin(i) = blocks.factorlabels(j); %Embed label
            varargin(i + 1) = {blocks.factors(:, j)}; %Embed matched factor values
        end
    end
% FIXME - CHECK DO THESE ADDED EVENTS OFFSET THE BLINK EVENTS?
    % Make block events, Add to EEG
    vblk = [{'duration'} {num2cell(blocks.limits_sample(:,2))} varargin];
    event = eeglab_create_event(blocks.limits_sample(:,1), 'block', vblk{:});
    EEG.event = eeglab_merge_event_tables(EEG.event, event, 'ignoreDiscontinuousT');

    % Make block_begin events, Add to EEG
    vbeg = [{'duration'} {num2cell(blocks.limits_sample(:,2) - 1)} varargin];
    event = eeglab_create_event(blocks.limits_sample(:,1) + 1, 'block_beg', vbeg{:});
    EEG.event = eeglab_merge_event_tables(EEG.event, event, 'ignoreDiscontinuousT');

    % Make block_end events, Add to EEG
    vend = [{'duration'} {num2cell(zeros(rows(blocks.limits_time), 1))} varargin];
    event = eeglab_create_event(blocks.limits_sample(:,2) - 1, 'block_end', vend{:});
    EEG.event = eeglab_merge_event_tables(EEG.event, event, 'ignoreDiscontinuousT');

else
    disp 'MC not specified in Cfg, or blocks not in MC. No blocks loaded.'
end


%% ERROR/REPORT
% Arg = joinstruct(Arg, params);
Cfg.ctap.parse_blocks = Arg;

msg = myReport({'Parse block specs for ' EEG.CTAP.measurement.casename}...
    , Cfg.env.logFile);

EEG.CTAP.history = create_CTAP_history_entry(msg, mfilename, Arg);
