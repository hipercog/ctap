% Export EEG events
% Arguments:
%    datapath_eeg    : Directory containing EEGLAB .set files
%    datpath_db      : Full path to a file where the database (sqlite) is
%                      The contents of the file will be deleted!
%    event_type      : The type of event to export
%    event_type_zero : the event in the original recording that is used as
%                      the "zero-event" (reference point) for the events
%                      in the EEG structure.
%   event_type_zero_occurrence : integer denoting the order of
%   event_type_zero, e.g. 2 to mean the second event of that type etc.
%
% Requirements: mksqlite, neurone tools for matlab. Add these to the matlab
%               path.
% Author: Andreas Henelius <andreas.henelius@ttl.fi>
%
%
%
function export_eeg_events(datapath_eeg, datapath_db, event_type, event_type_zero, event_type_zero_occurrence)


%% Get all set files containing the events
%  and loop over them
eeg_set_files = dir([datapath_eeg '*.set']);

for (file_ind = 1:numel(eeg_set_files))
    disp(['processing ' num2str(file_ind) ' / ' num2str(numel(eeg_set_files))])
    fname     = fullfile(datapath_eeg, eeg_set_files(file_ind).name);
    EEG    = read_set_file(fname);
    EEG = EEG.EEG;
    fname_raw = EEG.CTAP.files.eegFile;
    
    % get starting event (from recording) and all events (from EEG)
    zerotime = get_zerotime(fname_raw, event_type_zero, event_type_zero_occurrence);
    events = get_events(EEG, event_type);
    
    % export events
    if file_ind == 1
        clean_db = 1;
    else
        clean_db = 0;
    end
    
    export_events(datapath_db, zerotime, events, EEG, clean_db);
    
end


%% read set file
    function EEG = read_set_file(fname)
        EEG = load(fname, '-mat');
    end

%% get events of a particular type
    function events = get_events(EEG, event_type)
        ind = strmatch(event_type, {EEG.event.type});
        events = EEG.event(ind);
    end

%% get part of a struct
    function s = get_struct_part(x, ind)
        s = {};
        fn = fieldnames(x);
        for (i = 1:numel(fn))
            tmp = x.(fn{i});
            s.(fn{i}) = tmp(ind);
        end
    end

%% get the zerotime: [type, sample, time_in_seconds]
    function x = get_zerotime(fname, event_type, occurrence)
        recording   = module_read_neurone(fname, 'headerOnly', true);
        fs          = recording.properties.samplingRate;
        events      = module_read_neurone_events([fname '1/'], fs);
        events_zero = find(events.code == event_type);
        zi          = events_zero(occurrence);
        x           = get_struct_part(events, zi);
        x.recording_start = recording.properties.start;
    end

%% populate the database
% dbfile     : filename
% table_name : the name of the table
% data       : data as a
    function populate_db(dbfile, table_name, column_names, data, fmt)
        qs1  = ['INSERT INTO ' table_name ' (' strjoin(repmat({'%s'}, 1, numel(column_names)), ','), ') '];
        qs2  = ['VALUES (', fmt ,') '];
        qs1 = sprintf(qs1, column_names{:});
        qs = [qs1 qs2];
        
        dbid = mksqlite('open', dbfile);
        msg = mksqlite(dbid, 'BEGIN TRANSACTION'); %#ok<*NASGU>
        
        for ii = 1:size(data, 3)
            mksqlite(dbid, sprintf(qs, data{:, :, ii}));
        end
        
        msg = mksqlite(dbid, 'END TRANSACTION');
        mksqlite(dbid, 'close');
    end


%% export events
    function export_events(dbpath, zerotime, events, EEG, clean_db)
        %% check out code in
        % :~/work/utils/utils_matlab/attk_data_struct
        % function for export to sqlite
        % add subject etc definitions
        % convert events to a cell
        
        % --- casename
        subject  = EEG.CTAP.measurement.subject;
        casename = EEG.CTAP.measurement.casename;
        datafile = EEG.CTAP.files.eegFile;
        
        % --- subject
        header_subject = {'subject', 'subjectnr', 'sex', 'age'};
        subject_info = {subject, EEG.CTAP.measurement.subjectnr, EEG.CTAP.subject.sex, EEG.CTAP.subject.age};
        
        % --- meaasurement
        header_measurement = {'casename', 'measurement', 'session', 'description'};
        measurement_info = {casename, EEG.CTAP.measurement.measurement, EEG.CTAP.measurement.session, 'missing description'};
        
        % --- mc
        header_mc = {'casename', 'subject', 'recording', 'include'};
        mc_info   = {casename, subject, datafile, 1};
        
        % --- event
        % dynamic fields
        events = arrayfun(@(x) setfield(x, 'casename', casename), events);
        events = arrayfun(@(x) setfield(x, 'latency', x.latency + zerotime.index), events);
        events = arrayfun(@(x) setfield(x, 'starttime', x.latency ./ EEG.srate), events);
        events = arrayfun(@(x) setfield(x, 'stoptime', (x.latency + x.duration) ./ EEG.srate), events);
        events = arrayfun(@(x) setfield(x, 'starttype', 'time'), events);
        events = arrayfun(@(x) setfield(x, 'stoptype', 'time'), events);
        
        for iii = 1:numel(events)
            events(iii).blockid = iii;
            events(iii).tasktype = 'wcst';
        end
        
        event_labels = fieldnames(events);
        [event_fmt, event_types] = get_format_string(struct2cell(events(1)));
        
        % static fields
        %events = arrayfun(@(x) setfield(x, 'id', 'NULL'), events);
        events = arrayfun(@(x) setfield(x, 'subjectnr', EEG.CTAP.measurement.subjectnr), events);
        events = arrayfun(@(x) setfield(x, 'measurement', EEG.CTAP.measurement.measurement), events);
        
        events_c = struct2cell(events);
        events_c(cellfun(@(x) any(isnan(x)), events_c)) = {'NaN'};
        
        
        % === create the database
        create_event_db(dbpath, 'blocks', event_labels, event_types, clean_db);
        
        % === populate the database
        populate_db(dbpath, 'subject', header_subject, subject_info, get_format_string(subject_info));
        populate_db(dbpath, 'measurement', header_measurement, measurement_info, get_format_string(measurement_info));
        populate_db(dbpath, 'mc', header_mc, mc_info, get_format_string(mc_info));
        populate_db(dbpath, 'blocks', fieldnames(events), events_c, get_format_string(events_c(:,:,1)));
        
    end
end