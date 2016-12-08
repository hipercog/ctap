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

% Remove channel baselines
[EEG.data, ~] = rmbase(EEG.data);

result = struct('method_data', '', 'scores', []);
epochs = 1:numel(EEG.epoch);

%% call the method to do BAD EPOCH removal.
%   bad_eps_match = k epochs classified as bad, integer array, k <= EEG.trials
%   badelec = electrodes contributing to bad epochs (when reported), 
%               [eps_match; 1:EEG.nbchan] integer matrix
switch Arg.method
    case 'faster'
        % latent parameters: any|all, metric
        epbad = epoch_properties(EEG, Arg.channels, epochs);
        [~, all_bad, ~] = min_z(epbad, struct('z', Arg.bounds(2)));
        bad_eps_match = epochs(all_bad');
        result.scores =...
            table(epbad(:,1), epbad(:,2), epbad(:,3)...
            , 'RowNames', cellstr(num2str(epochs'))...
            , 'VariableNames', {'ampRange' 'variance' 'chanDev'});
        
    case 'recufast'
        recu_out = recufast_badness_detector(...
                  EEG, struct(), Arg.channels, Arg.bounds, Arg.iters, 'chan',...
                  'outdir', Arg.outdir, 'report', Arg.report);
        bad_eps_match = recu_out.bad_bin(2,:) > 0;
        result.scores = table(recu_out.bad_bin(2, :)' ...
            , 'RowNames', cellstr(num2str(epochs'))...
            , 'VariableNames', {'recursiveFASTER'});

    case 'eegthresh'
        % NOTE: 'bad_eps_match' contains indices of epochs that have an 
        % exceeding amplitude in one or more electrodes.
        % 'badelec' is a zero-one matrix of size [nchan, numel(bad_eps_match)].
        % Epochs without large amplitudes are not reported.
        [~, bad_eps_match, ~, badelec] = eegthresh(...
            EEG.data, EEG.pnts, Arg.channels,...
            Arg.uV_thresh(1), Arg.uV_thresh(2),...
            [EEG.xmin EEG.xmax],...
            Arg.sec_lim(1), Arg.sec_lim(2) );
        
        scores = zeros(numel(Arg.channels), EEG.trials);
        if ~isempty(badelec)
            scores(Arg.channels, bad_eps_match) = badelec;
        end
        
        result.scores = array2table(scores...
            , 'RowNames', {EEG.chanlocs(Arg.channels).labels}...
            , 'VariableNames', strcat({'ep'}, strtrim(cellstr(num2str((1:EEG.trials)'))) ) );


    case 'rejspec'
        [~, bad_eps_match] = pop_rejspec(EEG, 1, 'elecrange', Arg.channels,...
            'threshold',Arg.dB_thresh, 'freqlimits',Arg.freq_lim,...
            'method',Arg.spec_meth, 'eegplotreject',0);
        result.scores = table({'no scores available'}...
            , 'RowNames', {'ALL'}...
            , 'VariableNames', {'spectralThresh'});
        
    case 'hasEvent'
        
        % Identify epochs with blinks
        if iscell(EEG.epoch(1).eventtype)
            epoch_eventtypes = {EEG.epoch(:).eventtype};
        else
           % if EEG.epoch.eventtype is not cell array things get complicated
           % this is a very rare occasion ...
           % make epoch_eventtypes a cell array of cell arrays of strings.
           for i=1:numel(EEG.epoch)
               epoch_eventtypes{i} = {EEG.epoch(i).eventtype};
           end
        end

        bl_ind_cell = cellfun( @(x) ismember(Arg.event, x),...
                                epoch_eventtypes,...
                                'UniformOutput',false);
        bad_eps_match = cellfun(@(x) x==true, bl_ind_cell);

        result.scores = array2table(bad_eps_match...
            , 'RowNames', {EEG.chanlocs(Arg.channels).labels}...
            , 'VariableNames', strcat({'ep'}, strtrim(cellstr(num2str((1:EEG.trials)')))) );
       
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
            if numel(Arg.channels) > 32, Arg.method = 'recufast';
            else Arg.method = 'rejspec';
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
%                sds = 5; %we use 5 std devs from the mean as uV thresholds
%                [~,y,z] = size(EEG.data);
%                vecData = reshape(mean(EEG.data(Arg.channels,:,:)), 1, y*z);
%                Arg.uV_thresh = [mean(vecData) - std(vecData) * sds ...
%                                 mean(vecData) + std(vecData) * sds];
                Arg.sec_lim = [EEG.xmin EEG.xmax];
                Arg.uV_thresh = [-120 120];

            case 'rejspec'
                Arg.freq_lim = [0 2; 20 40];
                Arg.dB_thresh = [-50 50; -100 55];
                Arg.spec_meth = 'multitaper';
                
            case 'hasEvent'
                Arg.event = '';
                
            otherwise
                error('ctapeeg_detect_bad_epochs:bad_method',...
                    'Method %s not recognised, aborting', Arg.method)
        end
        
        % Arg fields are canonical, vargs values are canonical: intersect-join
        Arg = intersect_struct(Arg, vargs);
    end

end % ctapeeg_detect_bad_epochs()
