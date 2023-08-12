function [evCA, evLabels]=list_events(EEG, from, to, varargin)
% A helper function to make inspection of EEG.event a bit less pain in the
% ass.
%
% Example:
% list_events(EEG)
% list_events(EEG, 1, 100)
% list_events(EEG,[],[],'type',{'254','255'})
% list_events(EEG,[],10,'fields',{'type','latency'})


%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('EEG', @isstruct);
p.addOptional('from', 1, @isnumeric);
p.addOptional('to', NaN, @isnumeric);
p.addParameter('type', unique({EEG.event.type}), @iscellstr);
p.addParameter('fields', fieldnames(EEG.event), @iscellstr);
p.addParameter('silent', false, @islogical);
p.addParameter('latencyUnit', 'samples', @ischar);

p.parse(EEG, from, to, varargin{:});
Arg = p.Results;

if isempty(Arg.from) || isnan(Arg.from)
    Arg.from=1;
end

match = ismember({EEG.event.type}, Arg.type);
evCA = struct2table(EEG.event(match));
rows = height(evCA);
evCA.IX = num2cell(1:rows)';
evLabels = evCA.Properties.VariableNames;

if rows == 0
   error('list_events:noEventsFound',...
         'Found no events of type ''%s''.', catcellstr(Arg.type)); 
end

fieldIdx = find(ismember(evLabels, Arg.fields));

if isempty(Arg.to) || isnan(Arg.to) || Arg.to >= rows
    Arg.to = rows;
end
if Arg.from >= rows
    Arg.from = rows;
end

dspCA = evCA(Arg.from:Arg.to, fieldIdx);

% Change latency units
if ismember('latency', Arg.fields)
   latidx = find(ismember(evLabels, 'latency'));
   dspidx = find(ismember(fieldIdx, latidx));
   
   tmp = table2array(dspCA(2:end, dspidx)); %to matrix, excluding header
   switch Arg.latencyUnit
       case 'samples'
           
       case 'min'
            dspCA(2:end,dspidx) = num2cell((tmp ./ EEG.srate) ./ 60);
       otherwise
           error('list_events:inputError', 'Supported latency units are {''samples'',''min''}.');
   end
    
end

% Show results
if ~Arg.silent
    dspCA
end

evCA = evCA(:, fieldIdx);
evLabels = evLabels(fieldIdx);


