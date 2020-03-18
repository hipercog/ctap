function [EEG, Cfg] = CTAP_parse_blocks(EEG, Cfg)
%CTAP_parse_blocks -  Parse block information if available.
%
% Description:
%   Obtains block information from Cfg.MC, which can read get it from .
%
% Syntax:
%   [EEG, Cfg] = CTAP_parse_blocks(EEG, Cfg)
%
% Inputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, CTAP configuration structure
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


%% Set optional arguments
% TODO: where should casename come from? Unknown...
Arg.casename = '';

% Override defaults with user parameters
if isfield(Cfg.ctap, 'parse_blocks')
    Arg = joinstruct(Arg, Cfg.ctap.parse_blocks);
end


%% Add block definitions if any
if isfield(Cfg, 'MC') && isfield(Cfg.MC, 'blocks')
% TODO: This loads data again from source file. Could be based on
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
%TODO: Assumes one block per measurement. Quite a restriction.
           error('CTAP_load_data:block_fail', 'dimension err: check Cfg.MC.blocks');
        end
        
        %Remove unnecessary parts of data
        EEG = eeg_eegrej(EEG, regions);

        % time_specs: { file start time string,
        %               measurement start time string,
        %               measurement start offset from file start in samples}
        time_specs = { datestr(result.time{1},30),...
                       datestr(datenum(result.time{1}) + ...
                                (regions(1,2)/EEG.srate)/(24*60*60), 30),...
                       regions(1,2)};
else
    disp 'MC not specified in Cfg, or blocks not in MC. No blocks loaded.';
    time_specs = { datestr(result.time{1},30),...
                   datestr(result.time{1},30),...
                   0};
end

EEG.CTAP.time.fileStart = time_specs{1};
EEG.CTAP.time.dataStart = time_specs{2};
EEG.CTAP.time.dataStartOffsetSamp = time_specs{3};


%% ERROR/REPORT
Arg = joinstruct(Arg, params);
Cfg.ctap.parse_blocks = Arg;

msg = myReport({'Parse block specs for ' Arg.physiodata}, Cfg.env.logFile);

EEG.CTAP.history = create_CTAP_history_entry(msg, mfilename, Arg);
