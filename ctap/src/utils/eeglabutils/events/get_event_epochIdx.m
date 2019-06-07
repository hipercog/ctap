function idx = get_event_epochIdx(EEG, event)
%GET_EVENT_EPOCHIDX: find epochs with wanted event
% 3 lines to GET AN INDEX - must be easier way?

    if isempty(EEG.epoch)
        error('get_event_epochIdx:bad_EEG', 'EEG must be epoched!')
    end
    idx = squeeze(struct2cell(EEG.epoch));
    idx = squeeze(idx(ismember(fieldnames(EEG.epoch), 'eventtype'), :));
    idx = cell2mat(cellfun(@(x) any(strcmpi(x, event)), idx, 'Un', 0));
    
end