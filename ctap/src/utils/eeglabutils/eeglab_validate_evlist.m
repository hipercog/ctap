function evlist = eeglab_validate_evlist(EEG, evlist, match, varargin)


%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('EEG', @isstruct)
p.addRequired('evlist', @(x) ischar(x) || iscellstr(x)) %#ok<ISCLSTR>
p.addRequired('match', @ischar)
p.addParameter('field', 'type', @ischar)

p.parse(EEG, evlist, match, varargin{:});
Arg = p.Results;


%%
switch match
    case 'contains'
        evidx = contains({EEG.event.(Arg.field)}, evlist);
        
    case 'starts'
        evidx = startsWith({EEG.event.(Arg.field)}, evlist);
        
    case 'ends'
        evidx = endsWith({EEG.event.(Arg.field)}, evlist);
        
    otherwise %'exact'
        evidx = ismember({EEG.event.(Arg.field)}, evlist);
%    evidx = cellfun(@(x) any(strcmp(evlist, x)), {EEG.event.(Arg.field)});
end
if ~any(evidx)
    evlist = {};
else
    evlist = unique({EEG.event(evidx).(Arg.field)});
end

end%eeglab_validate_evlist()