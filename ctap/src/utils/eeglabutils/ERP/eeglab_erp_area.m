function ERPAREA = eeglab_erp_area(EEG, limits, blocks, varargin)
%EEGLAB_ERP_AREA - Calculate time range based ERP features (EEGLAB compatible)
%
% Description:
%   Calculates _time range_ based ERP features:
%       * ERP area under curve
%       * mean peak amplitude
%       * (partial) signal power
%   from epoched EEG data and stores the results in ATTK data structure 
%   format. 
%   Input variable 'blocks' can be used to analyze only a subset of epochs.
%
% Syntax:
%   ERPAREA = eeglab_erp_area(EEG, limits, blocks, varargin)
%
% Inputs:
%   EEG             struct, EEGLAB data struct with _epoched_ data
%   limits          [m,2] numeric, ERP area calculation limits in ms
%   blocks          [1,n] or empty cell of strings, Measurement blocks for
%                   analyzing a subset of epochs. All epochs for which
%                   ismember({EEG.epoch(:).(Arg.blockFieldName)}, blocks) 
%                   holds true are included. If blocks = {} | {''} | {'all'}
%                   all ERPs are included.
%
%   varargin    Keyword-value pairs
%   Keyword             Type, description, value
%   'blockFieldName'    string, Name of the field in EEG.epoch that should be
%                       matched against 'blocks'
%                       values: {'range' (default), <str>}
%
% Outputs:
%   ERPAREA         struct, ATTK data structure component, Contains peak area
%               under curve as returned by trapz.m. Values contain peak
%               direction information i.e. negative values
%               represent negative ERPs. 
%
% Assumptions:
%
% References:
%
% Example: [ERPAREA] = eeglab_erp_area(eeg, [50, 100], {})
%
% Notes: 
%
% See also: peak_stats, eeg_erppeak
%
% Version History:
% 19.11.2012 Added mean peak amplitude -calculation (jkor, TTL)   
% 1.6.2009 Created (Jussi Korpela, TTL)
%
% Copyright 2009- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Parse inputs
p = inputParser;
p.addRequired('EEG', @isstruct);
p.addRequired('limits', @isnumeric);
p.addRequired('blocks', @iscell);
p.addParameter('blockFieldName', '', @isstr);

p.parse(EEG, limits, blocks, varargin{:});
Arg = p.Results;


%% Initialize output variables
% ERPAREA
for k = 1:size(EEG.data,1)
    ERPAREA.(EEG.chanlocs(k).labels).data = NaN(size(limits,1), 3);
end
ERPAREA.sublevels.n = 1;
ERPAREA.sublevels.labels = {'channel'};

Arg.EEG = 'not included due to space limitations';
ERPAREA.parameters = Arg;


%% Select epochs to include
if isempty(blocks)
    epoch_match = true(1,size(EEG.data, 3));
else
    if (length(blocks)==1) && ...
        (isempty(blocks{1}) || strcmp(blocks{1},'all'))
        epoch_match = true(1,size(EEG.data, 3));
    else 
        trigevents = eeg_trigger_events(EEG); %length(trigevents)==length(EEG.epoch)
        epoch_match = ismember({trigevents(:).(Arg.blockFieldName)}, blocks);
    end
end
erp_array = mean(EEG.data(:,:,epoch_match),3);


%% Calculate area under curve for each set of limits
for i = 1:size(limits, 1)
    %% Select time range
    i_limit_match = (limits(i,1) <= EEG.times) & (EEG.times <= limits(i,2));
    % EEG.times expressed in ms (at least for epoched data) 


    %% Calculate peak area under curve
    i_area_array = 1000*(1/EEG.srate)*trapz(erp_array(:,i_limit_match),2);
    % trapz assumes unit increments between Y -values. The result is scaled
    % with the actual time (in ms) between successive samples. This will
    % then yield comparable results even between measurements with
    % differing sample rates.
    
    %% Calculate average peak amplitude
    % When it comes to relative differences between channels this the
    % average peak amplitude contains about the same information as peak area.
    % However, the conversion from area units to muV is not self evident
    % and hence the average amplitude is computed as well.
    % Used e.g. in MMN analysis.
    i_avepeak_array = mean(erp_array(:,i_limit_match),2);
    
    %% Calculate signal power
    i_pwr_array = pwr(erp_array(:,i_limit_match));

    %% Assign results
    for k = 1:size(i_area_array,1) %over channels
       ERPAREA.(EEG.chanlocs(k).labels).data(i,:) = ...
               [i_area_array(k,1), i_avepeak_array(k,1), i_pwr_array(k,1)];
    end
    
    clear('i_*');
end %of over limits

ERPAREA.labels = {'peakArea','peakMean','peakPWR'};
ERPAREA.units = {'\muV*ms','\muV','\muV^2'};

end %of peak_area.m