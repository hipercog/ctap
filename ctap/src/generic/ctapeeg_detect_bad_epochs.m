function [EEG, varargout] = ctapeeg_detect_bad_epochs(EEG, varargin)
%CTAPEEG_DETECT_BAD_EPOCHS use given method to find bad epochs
%
% SYNTAX
%   EEG = ctapeeg_detect_bad_epochs(EEG, varargin)
%
% INPUT
%   'EEG'       : EEG file to process
% VARARGIN
%   'report'    : false (def) or true, produce/save visuals of FASTER iters
%   'channels'  : chose the channels to measure for badness (def= type:EEG)
%   'method'    : choose method from options (default depends on channel 
%                 count, count<32=rejspec, count>32=recufast) -
%                 'recufast' - recursive use of FASTER indices
%                 'eegthresh' - EEGLAB's func, detecting outlier values
%                 'rejspec' - EEGLAB's func, detect abnormal spectra
%
%   FOR 'faster' = plain FASTER
%   'bounds'    : sigma thresholds for bad epoch detection.
%                 Default=[-2 2]
%
%   FOR 'recufast' recursive FASTER method
%   'bounds'    : sigma thresholds for bad epoch detection with 'recufast'.
%                 Default=[-3 3]
%   'iters'     : number of iterations to use in 'recufast' method.
%
%   FOR 'eegthresh' reject amplitude threshold method
%   'uV_thresh' : [lower upper] uV amplitude limit(s).
%                 Default=[-75 75]
%   'sec_lim'   : [lower upper] time limit(s) in seconds.
%                 Default=[EEG.xmin EEG.xmax]
%
%   FOR 'rejspec' reject channel spectra method
%   'freq_lim'  : [lower upper] frequency limit(s) in Hz. Rows denote
%                 multiple frequency bands.
%                 Default=[0 2; 20 40]
%   'dB_thresh' : [lower upper] threshold limit(s) in dB. Can be in rows.
%                 Default=[50 -50; 25 -100]
%   'spec_meth' : ['fft'|'multitaper'] method to compute spectrum
%                 Default='multitaper'
%
%   FOR 'hasEvent' method that rejects epoch that contain a certain type of
%   event in EEG.epoch.eventtype.
%   'event'     : string, Event type string of event to use a the rejection
%                 trigger
%
%   Functionality to add:
%
%   FOR 'hasEventProperty' method that rejects epochs based on trigger
%   event properties in EEG.event.
%   'eventPropertyName'  : string, EEG.event field name
%   'eventPropertyValue' : cell array of eventProperty field values that trigger
%                          the exclusion of the epoch i.e. mark it as bad
%               
%
% OUTPUT
%   'EEG'       : struct, modified input EEG
% VARARGOUT
%   {1}         : struct, the complete list of arguments actually used
%   {2}         : struct, 3 fields: 
%                 .epochs - logical vector of bad epoch indices
%                 .scores - table with scores for badness of epochs
%                 .method_data - optional method specific data
%
%
% NOTE
%
% CALLS    eegthresh, pop_rejspec, recurse_bad_epoch
%
% REFERENCE:
%   Delorme, A., Sejnowski, T., & Makeig, S. (2007). Enhanced detection of 
%   artifacts in EEG data using higher-order statistics and independent 
%   component analysis. NeuroImage, 34(4), 1443-9.
%
% Version History:
% 20.10.2014 Created (Benjamin Cowley, FIOH)
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


sbf_check_input() % parse the varargin, set defaults

% Subset to required channels for:
% faster, recufast, eegthresh, rejspec
if ~ismember(Arg.method, {'hasEvent','hasEventProperty'})
    EEGtmp = pop_select(EEG, 'channel', Arg.channels);
    Arg.channels = get_eeg_inds(EEGtmp, {'EEG'});
else
    EEGtmp = EEG;
end
% Remove channel baselines
[EEGtmp.data, ~] = rmbase(EEGtmp.data);

result = struct('method_data', '', 'scores', []);
epochs = 1:numel(EEGtmp.epoch);


%% call the method to do BAD EPOCH removal.
%   bad_eps_match = k epochs classified as bad, integer array, k <= EEG.trials
%   badelec = electrodes contributing to bad epochs (when reported), 
%               [eps_match; 1:EEG.nbchan] integer matrix
switch Arg.method
    case 'faster'
        % latent parameters: any|all, metric
        epbad = epoch_properties(EEGtmp, Arg.channels, epochs);
        [~, all_bad, ~] = min_z(epbad, struct('z', Arg.bounds(2)));
        bad_eps_match = epochs(all_bad');
        result.scores =...
            table(epbad(:,1), epbad(:,2), epbad(:,3)...
            , 'RowNames', cellstr(num2str(epochs'))...
            , 'VariableNames', {'ampRange' 'variance' 'chanDev'});
        
    case 'recufast'
        recu_out = recufast_badness_detector(EEGtmp...
                                            , struct()...
                                            , Arg.channels...
                                            , Arg.bounds...
                                            , Arg.iters...
                                            , 'chan'...
                                            , 'outdir'...
                                            , Arg.outdir...
                                            , 'report'...
                                            , Arg.report);
        bad_eps_match = recu_out.bad_bin(2,:) > 0;
        result.scores = table(recu_out.bad_bin(2, :)' ...
            , 'RowNames', cellstr(num2str(epochs'))...
            , 'VariableNames', {'recursiveFASTER'});

    case 'eegthresh'
        % NOTE: 'bad_eps_match' contains indices of epochs that have an 
        % exceeding amplitude in one or more electrodes.
        % 'badelec' is a zero-one matrix of size [nchan, numel(bad_eps_match)].
        % Epochs without large amplitudes are not reported.
        [~, bad_eps_match, ~, badelec] = eegthresh(EEGtmp.data...
                                         , EEGtmp.pnts...
                                         , Arg.channels...
                                         , Arg.uV_thresh(1), Arg.uV_thresh(2)...
                                         , [EEGtmp.xmin EEGtmp.xmax]...
                                         , Arg.sec_lim(1), Arg.sec_lim(2) );
        
        scores = zeros(numel(Arg.channels), EEGtmp.trials);
        if ~isempty(badelec)
            scores(Arg.channels, bad_eps_match) = badelec;
        end
        
        result.scores = array2table(scores...
            , 'RowNames', {EEGtmp.chanlocs(Arg.channels).labels}...
            , 'VariableNames'...
            , strcat({'ep'}, strtrim(cellstr(num2str((1:EEGtmp.trials)'))) ) );


    case 'rejspec'
        [~, bad_eps_match] = pop_rejspec(EEGtmp, 1 ...
                             , 'elecrange', Arg.channels...
                             , 'threshold', Arg.dB_thresh...
                             , 'freqlimits', Arg.freq_lim...
                             , 'method', Arg.spec_meth...
                             , 'eegplotreject', 0);
        result.scores = table({'no scores available'}...
            , 'RowNames', {'ALL'}...
            , 'VariableNames', {'spectralThresh'});
        
    case 'hasEvent'
        % Identify epochs with blinks
        if iscell(EEGtmp.epoch(1).eventtype)
            epoch_eventtypes = {EEGtmp.epoch(:).eventtype};
        else
           % if EEG.epoch.eventtype is not cell array things get complicated
           % this is a very rare occasion ...
           % make epoch_eventtypes a cell array of cell arrays of strings.
           epoch_eventtypes = cell(1, numel(EEGtmp.epoch));
           for i=1:numel(EEGtmp.epoch)
               epoch_eventtypes{i} = {EEGtmp.epoch(i).eventtype};
           end
        end

        bl_ind_cell = cellfun( @(x) ismember(Arg.event, x),...
                                epoch_eventtypes,...
                                'UniformOutput',false);
        bad_eps_match = cellfun(@(x) x==true, bl_ind_cell);

        result.scores = array2table(bad_eps_match...
            , 'RowNames', {sprintf('hasEvent_%s', catcellstr(Arg.event))}...
            , 'VariableNames'...
            , strcat({'ep'}, strtrim(cellstr(num2str((1:EEGtmp.trials)')))) );
        
    case 'hasEventProperty'
        % Mark as bad epochs whose trigger event has a certain property in
        % EEG.event
        
        % Get a subset of event table with only epoch trigger events,
        % Note: numel(trigger_event) == numel(EEG.epoch) and the order is
        % the same.
        trigger_event = eeg_trigger_events(EEGtmp);
        
        % Find epochs that have unwanted event properties
        bad_eps_match = ismember({trigger_event.(Arg.eventPropertyName)},...
                                 Arg.eventPropertyValue);
        
        result.scores = array2table(bad_eps_match...
            , 'RowNames', {sprintf('unwantedEventProperty_%s'...
                                        , catcellstr(Arg.eventPropertyName))}...
            , 'VariableNames'...
            , strcat({'ep'}, strtrim(cellstr(num2str((1:EEGtmp.trials)')))) );
end


%% convert output to access results.
if ~isempty(bad_eps_match)
    if ~isrow(bad_eps_match)
        if ~iscolumn(bad_eps_match)
            bad_eps_match = bad_eps_match(1,:);
        else
            bad_eps_match = bad_eps_match';
        end
    end
end


%% check and return results.
if islogical(bad_eps_match)
    result.epochs = find(bad_eps_match);
else
    result.epochs = bad_eps_match;
end
if ~istable(result.scores)
    error('ctapeeg_detect_bad_epochs:bad_output',...
        'Bad epoch scores by ''%s'' must be in table format', Arg.method)
end

varargout{1} = Arg;
varargout{2} = result;


%% Sub-functions
    function sbf_check_input() % parse the varargin, set defaults
        % Unpack and store varargin
        if isempty(varargin)
            vargs = struct;
        elseif numel(varargin) > 1 %(assume parameter/name pairs)
            vargs = cell2struct(varargin(2:2:end), varargin(1:2:end), 2);
        else
            vargs = varargin{1}; %(assume a struct wrapped in a cell)
        end
        
        % If desired, the default values can be changed here:
        try Arg.channels = vargs.channels;
        catch
            Arg.channels = get_eeg_inds(EEG, {'EEG'});
        end
        try Arg.method = vargs.method;
        catch
            if numel(Arg.channels) > 32, Arg.method = 'faster';
            else, Arg.method = 'rejspec';
            end
        end

        switch Arg.method
            case 'recufast'
                Arg.report = false;
                Arg.bounds = [-3 3];
                Arg.iters  = 10;
                Arg.outdir = '';
                
            case 'faster'
                Arg.bounds = [-2 2];

            case 'eegthresh'
                Arg.sec_lim = [EEG.xmin EEG.xmax];
                Arg.uV_thresh = [-120 120];
%MAYBEDO: Use data-driven approach??
%                sds = 5; %we use 5 std devs from the mean as uV thresholds
%                [~,y,z] = size(EEG.data);
%                vecData = reshape(mean(EEG.data(Arg.channels,:,:)), 1, y*z);
%                Arg.uV_thresh = [mean(vecData) - std(vecData) * sds ...
%                                 mean(vecData) + std(vecData) * sds];

            case 'rejspec'
                Arg.freq_lim = [0 2; 20 40];
                Arg.dB_thresh = [-50 50; -100 55];
                Arg.spec_meth = 'multitaper';
                
            case 'hasEvent'
                Arg.event = ''; %will be replaced by varargin
                
            case 'hasEventProperty'
                Arg.eventPropertyName = ''; %will be replaced by varargin
                Arg.eventPropertyValue = ''; %will be replaced by varargin
                
            otherwise
                error('ctapeeg_detect_bad_epochs:bad_method',...
                    'Method %s not recognised, aborting', Arg.method)
        end
        
        % Arg fields are canonical, vargs values are canonical: intersect-join
        Arg = intersect_struct(Arg, vargs);
    end

end % ctapeeg_detect_bad_epochs()
