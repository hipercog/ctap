function evlist = eeglab_validate_evlist(EEG, evlist, match)


switch match
    case 'contains'
        evidx = contains({EEG.event.type}, evlist);
        
    case 'starts'
        evidx = startsWith({EEG.event.type}, evlist);
        
    case 'ends'
        evidx = endsWith({EEG.event.type}, evlist);
        
    otherwise %'exact'
        evidx = ismember({EEG.event.type}, evlist);
%         evidx = cellfun(@(x) any(strcmp(evlist, x)), {EEG.event.type});
end
if ~any(evidx)
    evlist = {};
else
    evlist = unique({EEG.event(evidx).type});
end

end%eeglab_validate_evlist()