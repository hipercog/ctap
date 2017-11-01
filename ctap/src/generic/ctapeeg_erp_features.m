function [FACTORS, ERP, ERPAREA] = ctapeeg_erp_features(EEG, search_limits, erp_direction, labels, blocks, varargin)
%PEAK_STATS_STACKED - Calculate ERP variables and assing into data structures
%
% Description:
%   Calculates ERP peak statistics from epoched EEG data and stores the 
%   results in ATTK data structure format.
%   Calculates also reaction times, if isfield(EEG.event, Arg.rtFieldName)
%   returns true. Reaction time values will be the same for all ERP
%   components (thus creating redundant data).
%   Input variable 'blocks' can be used to analyze subsets of epochs
%   separately.
%   Stores results from different ERP components into different rows of 
%   .data in ERP and FACTORS. Use peak_stats.m to store all ERP components
%   into the same row (and code labels into variable names).
%   Tested briefly with live data.
%
% Syntax:
%   [FACTORS, ERP] = peak_stats_stacked(EEG, search_limits, labels, blocks, varargin);
%
% Inputs:
%   EEG             struct, EEGLAB data struct with _epoched_ data
%   search_limits   [k,2] numeric, ERP peak search limits for different ERP
%                   components in ms
%   erp_direction   [1,k] cell of strings, Flag indicating which one to
%                   look for: maximun or minimum, allowed values {'neg','pos'}
%   labels          [1,k] cell of strings, Search limit labels of ERP 
%                   components, stored into FACTORS as column "erpcomp".
%                   e.g. {'N100','P300'}
%   blocks          [1,n] or empty cell of strings, Measurement blocks for
%                   which the analysis is to be done separately. If 
%                   blocks={}, data from all blocks will be included at
%                   once. 
%
%   varargin    Keyword-value pairs
%   Keyword         Type, description, value
%   'sourcepath'    str, EEG sourcefile path, [{cd()}, <str>]
%   'save'          str, Save results or not, [{no}, yes]
%   'savepath'      str, Savepath for results, [{cd()}, <str>]
%
% Outputs:
%   FACTORS     struct, ATTK data structure component
%   ERP         struct, ATTK data structure component
%
% Assumptions:
%
% References:
%
% Example: [segment, erp] = peak_stats_stacked(eeg, [50, 100; 220, 500],...
%                           {'N100','P300'}, {'blockA','blockB'})
%
% Notes: 
%   Modified from peak_stats_stacked.m.
%
% See also: peak_stats, eeglab_erp_peak
%
% Version History:
% 13.3.2009 Created (Jussi Korpela, TTL)
%
% Copyright 2009- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Parse inputs
p = inputParser;
p.addRequired('EEG', @isstruct);
p.addRequired('search_limts', @isnumeric);
p.addRequired('erp_direction', @iscell);
p.addRequired('labels', @iscell);
p.addRequired('blocks', @iscell);
p.addParameter('blockFieldName', '', @isstr);
p.addParameter('rtFieldName', '', @isstr);
p.addParameter('rtStatFunctions', {@mean, @std}, @iscell);
p.addParameter('dbplot', 'no', @isstr);

p.parse(EEG, search_limits, erp_direction, labels, blocks, varargin{:});
Arg = p.Results;


%% Initialize output variables
% FACTORS
FACTORS.labels = {'block','erpcomp'};
FACTORS.units = {'n/a','n/a'};

% ERP
ERP.labels = {};
ERP.units = {};
for k = 1:size(EEG.data,1)
    ERP.(EEG.chanlocs(k).labels).data = [];
end
ERP.sublevels.n = 1;
ERP.sublevels.labels = {'channel'};

Arg.EEG = 'not included due to space limitations';
ERP.parameters = Arg;


%% Assign results for each block and search limit -combination
N_erp_components = size(search_limits,1);

if isempty(blocks)
    %% Search peaks, all data
    for k = 1:N_erp_components
        ERP = stats2ERP(EEG, ERP, {}, search_limits(k,:), erp_direction{k});
        FACTORS.data(k,1) = {'all'};
        FACTORS.data(k,2) = {labels{k}};
    end  
    
    ERPAREA = eeglab_erp_area(EEG, search_limits, {});
else
    %% Search peaks, block wise search
    for n = 1:length(blocks)
        for k = 1:N_erp_components
            ERP = stats2ERP(EEG, ERP, blocks(n), search_limits(k,:), erp_direction{k});      
            FACTORS.data((n-1)*N_erp_components+k,1) = {blocks{n}};
            FACTORS.data((n-1)*N_erp_components+k,2) = {labels{k}};
        end %end for: over different ERP components
    end %end for: over different blocks   
end %end if



%% Helper functions
function ERP = stats2ERP(EEG, ERP, block, limits, erpdir)
    % Calculate statistics and append into ERP
    % Appends ROWS to .data -fields, does not create new COLUMNS
    %
    % Inputs:
    % EEG       struct, EEGLAB EEG struct
    % ERP       struct, ATTK data sructure variable
    % block     string, Block to analyze, possibly empty
    % limits    [1,2] numeric, ERP component search limits
    
    %% Calculate statistics
    % ERP component statistics
    [Min, Max, N] = eeglab_erp_peak(EEG, limits, block);
    %if block is empty cell -> select all data

    
    % ERP reaction time
    if isfield(EEG.event, Arg.rtFieldName)
        hasRT = true;
        TrgEvent = eeg_trigger_events(EEG); %select only triggering events
        
        if isempty(block)
            match = true(1, length(TrgEvent)); 
        else
            match = strcmp({TrgEvent(:).(Arg.blockFieldName)}, block);
        end
        [rtstat_arr, rtstat_labels, rtstat_units] = ...
            rtstats(TrgEvent(match), Arg.rtStatFunctions);
        
    else
        hasRT = false;
        rtstat_labels = {};
        rtstat_units = {};
    end
    
    
    %% Assign data     
    % Header
    ERP.labels = horzcat({'amp','lat','n'}, rtstat_labels);
    ERP.units = horzcat({'muV','ms','pcs'}, rtstat_units);
    
    % Data
    nrows = size(ERP.(EEG.chanlocs(1).labels).data,1);
    for m = 1:size(EEG.data,1) %over channels
        % Add ERP component statistics
        if strcmp(erpdir, 'pos')
            ERP.(EEG.chanlocs(m).labels).data(nrows+1,1) = Max.amplitude(m);
            ERP.(EEG.chanlocs(m).labels).data(nrows+1,2) = Max.latency(m);
        elseif strcmp(erpdir, 'neg')
            ERP.(EEG.chanlocs(m).labels).data(nrows+1,1) = Min.amplitude(m);
            ERP.(EEG.chanlocs(m).labels).data(nrows+1,2) = Min.latency(m);
        else
            msg = ['Unknown value ', erpdir,' for ''erp_direction''. Cannot compute.'];
            error('peak_stats_stacked:badInputValue', msg);
        end
        
        ERP.(EEG.chanlocs(m).labels).data(nrows+1,3) = N;
        
        % Add reaction time
        if hasRT
            for p = 1:length(rtstat_arr)
                ERP.(EEG.chanlocs(m).labels).data(nrows+1,3+p) = rtstat_arr(p);
            end
        end
    end

end %of stats2ERP

function [stat_arr, labels, units] = rtstats(Event, fhandle_arr)
    % Calculate statistics on EEG.event.(Arg.rtFieldName)
    %
    % Inputs:
    % Event         struct, EEG event struct
    % fhandle_arr   [1,I] cell array of function handles, Functions have to take
    %               numeric vector as input and return [1,1] numeric
    % Outputs:
    %stat_arr   [1,I] numeric, Function call results
    %labels     [1,I] cell of strings, Result labels
    %units      [1,I] cell of strings, Result units
    
    
    stat_arr = NaN(1, length(fhandle_arr));
    labels = cell(1, length(fhandle_arr));
    units = cell(1, length(fhandle_arr));
    
    for i=1:length(fhandle_arr)
        stat_arr(i) = fhandle_arr{i}([Event(:).(Arg.rtFieldName)]);
        labels(i) = {[Arg.rtFieldName,'_',func2str(fhandle_arr{i})]};
    end
    units(:) = {'s'}; %mark_resp2stim.m has calculated rt.
    % TODO: Mieti jokin robustimpi tapa m��ritt�� RT:n yksikk�

end %end of rtstats

end %of peak_stats_stacked