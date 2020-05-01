function Psd = eeglab_psd(EEG, csegEvent, varargin)
%% EEGLAB_PSD - Estimate PSD from segmented EEG (EEGLAB compatible)
%
% Description:
%   Estimates Power Spectrum Density (PSD) from _segmented_ EEGLAB EEG
%   dataset.
%   A segmented EEG dataset has some events in EEG.event that can
%   be used as calculation segments. Events defining a calculation segment
%   must have a unique event type string so that they can be easily 
%   identified within EEG.event.type (see varargin 'csegEvent').
%
% Syntax:
%   EEG = eeglab_psd(EEG, varargin);
%
% Inputs:
%   EEG     struct, EEGLAB EEG struct containing segmented EEG
%          
%
%   varargin    Keyword-value pairs
%   Keyword             Type, description, values
%   chansToAnalyze      [nchan, 1] cell of strings, Names of channels to analyze,
%                       default: {EEG.chanlocs(:).labels}
%   csegEvent          string, Event type string (EEG.event.type) for
%                       events that define calculation segments,
%                       default: 'cseg' 
%   psdEstimationMethod string, PSD estimation method to use,
%                       values: ['welch', 'welch-matlab']
%                       default: 'welch-matlab'
%   nfft                [1,1] integer, FFT length in [samples], [2^n],
%                       value should be a power of two, default: next power
%                       of two higher than Arg.m*EEG.srate
%   m                   [1,1] numeric, Welch segment length in seconds, 
%                       default: 1/4 of the calculation segment length
%                       (aims at having 8 periodograms to average for each
%                       calculation segment)
%   overlap             [1,1] numeric, Welch segment overlap, "percentage" value 
%                       [0...1], default: 0.5 
%
% Outputs:
%   EEG     struct, EEGLAB EEG struct containing PSD values in Psd
%           Psd has fields:
%       .data    [nchan, ncs, nfft/2] numeric, PSD values
%       .fvec    [nfft/2, 1] numeric, Frequency vector in Hz
%    .freqRes    [1,1] numeric, Frequency resolution Hz/bin
%    .chanvec    [1,nchan] cell of strings, Channel labels
%
% Assumptions:
%
% References:
%
% Example:
%
% Notes:
%
% See also: psdest_welch, psdest_welch_matlab
%
% Copyright 2008- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('EEG', @isstruct);
p.addRequired('csegEvent',@ischar);

p.addParameter('chansToAnalyze', {EEG.chanlocs(:).labels}, @iscellstr);
p.addParameter('psdEstimationMethod', 'welch-matlab', @ischar);
p.addParameter('nfft', NaN, @isnumeric); %int, FFT length in [samples] or 
% NaN for automatic selection
% Currently this should hold Arg.nfft > Arg.m*EEG.srate for psdest_welch.m
% to function.
p.addParameter('m', NaN, @isnumeric); %in [s] or NaN for automatic selection
p.addParameter('overlap', 0.5, @isnumeric);% "percentage" value from interval [0,1]

p.parse(EEG, csegEvent, varargin{:});
Arg = p.Results;


%% Default parameter values
%{
% Field names of 'Arg' can be used as keywords.
Arg.chansToAnalyze = {EEG.chanlocs(:).labels};
Arg.csegEvent = 'cseg'; %str, Event type (EEG.event.type) for events that define calculation segments
Arg.psdEstimationMethod = 'welch-matlab'; %str: 'welch', 'welch-matlab'

Arg.nfft = NaN; %int, FFT length in [samples] or NaN for automatic selection
% Currently this should hold Arg.nfft > Arg.m*EEG.srate for psdest_welch.m
% to function.
Arg.m = NaN; %in [s] or NaN for automatic selection
Arg.overlap = 0.5; % "percentage" value from interval [0,1]


%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end
%}


%% Initialize variables
% Find channel positions
chaninds = find(ismember({EEG.chanlocs.labels}, Arg.chansToAnalyze));
if isempty(chaninds)
    msg = 'Channels to analyze not found. Cannot estimate PSD.';
    error('eeglab_psd:chansMissing', msg); 
end

% Read calculation segment positions into array
try
    segs = fix(eeglab_event2arr(EEG, Arg.csegEvent));
    % Ordered according to  matches of Arg.csegEvent in EEG.event - 
    % this should be a an ascending order in latency but is there a 
    % guarantee for this in EEGLAB?
catch ME
    if strcmp(ME.identifier, 'eegseg2arr:eventsMissing')
        msg=['Found no events of type ''',Arg.csegEvent...
            ,'''. Cannot estimate PSD. Check calculation segment rejections.']; 
        error('eeglab_psd:calcSegsMissing', msg);
    else
        msg='Cannot convert calculation segments to array. Aborting.'; 
        error('eeglab_psd:calcSegError', msg);
    end
end


%% Check inputs

% Set m if needed
cs_length_mode = mode((segs(:,2)-segs(:,1))/EEG.srate); %in sec
if isnan(Arg.m)
    Arg.m = floor(cs_length_mode/4);
    % aiming at 8 50% overlapped periodograms per calculation segment
end

% Set nfft if needed
if isnan(Arg.nfft)
    Arg.nfft = 2^ceil(log2(Arg.m*EEG.srate));

    if Arg.nfft == Arg.m*EEG.srate
        Arg.nfft = 2*Arg.nfft;
        % currently psdest_welch() returns error if there is no room for
        % zeropadding...
    end
end

% Check that nfft is a power of two
if mod(Arg.nfft,2) ~= 0
    msg = 'Varargin ''nfft'' is not even. Please select a power of two as ''nfft''.'; 
    error('eeglab_psd:inputError', msg);
    % if nfft is not even, there will be errors and performance issues
end


%% Preallocate memory space
disp('Estimating PSD...');
segs = uint32(segs);
Psd.data = NaN(length(chaninds), size(segs, 1), Arg.nfft/2+1);
Psd.fvec = NaN(Arg.nfft/2+1, 1);
Psd.freqRes = NaN;


%% Loop over channels and segments
for k = 1:length(chaninds) %over channels 
    for i=1:size(segs,1) %over calculation segments        
        low = segs(i,1); up = segs(i,2);
        
        switch Arg.psdEstimationMethod
            case 'welch'
                % PSD estimation using jkor's own version of Welch's method
                [Psd.data(k,i,:), ~] = psdest_welch(...
                    EEG.data(chaninds(k),low:up),...
                    uint32(fix(Arg.m*EEG.srate)), Arg.overlap, Arg.nfft);
                if i==1 && k==1
                    report_parameters(...
                        cs_length_mode, Arg.m, Arg.nfft, Arg.overlap);
                end
            
            case 'welch-matlab'
                % PSD estimation using Matlab's version of Welch's method
                [Psd.data(k,i,:), ~] = psdest_welch_matlab(...
                    EEG.data(chaninds(k),low:up)...%data
                    , uint32(fix(Arg.m*EEG.srate))...%subsegment length, samples
                    , Arg.overlap, Arg.nfft);
                if i==1 && k==1
                    report_parameters(...
                        cs_length_mode, Arg.m, Arg.nfft, Arg.overlap);
                end

                if sum(sum(sum(isnan(Psd.data(k,i,:))))) > 0
                    warning('eeglab_psd:psdNaN', 'PSD contains NaNs.');
                end
            
            case 'periodogram'
                % PSD estimation using one periodogram from Welch's method.
                % Achieved calling psdest_welch() with such parameters that 
                % allow only one periodogram to be formed i.e. m >= length(x)
                [Psd.data(k,i,:), ~] = psdest_welch(...
                    EEG.data(chaninds(k),low:up),...
                    up-low+1, 0, Arg.nfft);
                if i==1 && k==1
                    report_parameters(cs_length_mode, NaN, Arg.nfft, 0);
                end
            
            otherwise
                error('eeg_script:PsdEstimationError',...
                    'Unknown PSD estimation method.'); 
        end

        clear('low','up');
    end
end

%% Refactored for clarity (...trying to understand the process). Not tested
% switch Arg.psdEstimationMethod
%     case 'welch'
%         % PSD estimation using jkor's own version of Welch's method
%         psd_func_hdl = @psdest_welch;
%         psdm = uint32(fix(Arg.m * EEG.srate));%subsegment length, samples
%         rptm = Arg.m;
%         ol = Arg.overlap;
% 
%     case 'welch-matlab'
%         % PSD estimation using Matlab's version of Welch's method
%         psd_func_hdl = @psdest_welch_matlab;
%         psdm = uint32(fix(Arg.m * EEG.srate));
%         rptm = Arg.m;
%         ol = Arg.overlap;
% 
%     case 'periodogram'
%         % PSD estimation using one periodogram from Welch's method.
%         % Achieved calling psdest_welch() with such parameters that 
%         % allow only one periodogram to be formed i.e. m >= length(x)
%         psd_func_hdl = @psdest_welch;
%         psdm = up - low + 1;
%         rptm = NaN;
%         ol = 0;
% 
%     otherwise
%         error('eeg_script:PsdEstimationError',...
%             'Unknown PSD estimation method.'); 
% end
% 
% for k = 1:length(chaninds) %over channels 
%     for i=1:size(segs,1) %over calculation segments        
%         low = segs(i,1); up = segs(i,2);
%         eegdata = EEG.data(chaninds(k), low:up);
%         
%         % PSD estimation using defined method & parameters
%         [Psd.data(k, i, :), ~] = psd_func_hdl(eegdata, psdm, ol, Arg.nfft);
%         if i==1 && k==1
%             report_parameters(cs_length_mode, rptm, Arg.nfft, ol);
%         end
% 
%         clear('low','up');
%     end
% end
% if strcmp(Arg.psdEstimationMethod, 'welch-matlab') &&...
%         any(any(any(isnan(Psd.data))))
%     warning('eeglab_psd:psdNaN', 'PSD contains NaNs.');
% end

Psd.chanvec = {EEG.chanlocs(chaninds).labels};
Psd.freqRes = EEG.srate/Arg.nfft; % Hz
Psd.fvec = (0:1:Arg.nfft/2)' * Psd.freqRes; %Hz


% Add cseg metadata to Psd
CsegMeta = gather_cseg_metadata(EEG, Arg.csegEvent);
% note: 
% "CsegMeta" latencies include boundary event durations
% "cseg" contains latencies without boundary event durations

tsind = find(ismember(CsegMeta.labels, 'timestamp'));
if  issorted(segs(:,1)) && ...
    issorted( datenum(CsegMeta.data(:,tsind),'yyyymmddTHHMMSS') )
    Psd.csvec = CsegMeta.data(:,tsind);
else
    error('eeglab_psd:eventsNotSorted',...
        'Events ''%s'' not sorted in EEG.event. Please fix.', Arg.csegEvent);
end


%% Subfunctions

function report_parameters(cseg, m, nfft, overlap)
    % Function for displaying estimation parameters
    % Explicitely displaying these parameters potentially improves analysis
    % quality as the actual PSD estimation procedure becomes more
    % transparent.
    % Inputs:
    % cseg in seconds
    % m in seconds
    % nfft in samples
    % overlap [0,...,1]
    
    disp(['eeglab_psd: cseg is ',...
            num2str(cseg),' seconds == ',...
            num2str(EEG.srate*cseg),' samples.']);
    disp(['eeglab_psd: m is ',...
            num2str(m),' seconds == ',...
            num2str(EEG.srate*m),' samples.']); 
    disp(['eeglab_psd: nfft is ', num2str(nfft),...
        ' samples.']);     
    disp(['eeglab_psd: overlap is ', num2str(overlap),...
        ' .']); 

end

end
