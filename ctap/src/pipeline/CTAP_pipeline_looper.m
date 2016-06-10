function CTAP_pipeline_looper(Cfg, varargin)
%CTAP_pipeline_looper - Loops over the functions defined in Cfg.pipe.stepSets
%
% Description:
%   Input structs are documented in Google Docs:
%   https://docs.google.com/document/d/1nexEgDg0JzumWbl3-KJRUnq2_vf6Iiiei_wAd6zM9vo/
%
% Syntax:
%   CTAP_pipeline_looper(Cfg, varargin);
%
% Inputs:
%   'Cfg'       struct, pipe configuration structure, see specifications above
%
%   varargin    Keyword-value pairs
%   Keyword     Type, description, values
%   'debug'     boolean, runs pipe without try-catch wrapper. Errors from
%               core functions will crash the batch.
%               default = false
%   'overwrite' boolean, if false, checks each stepSet for existing .set file -
%               will skip a stepSet instead of overwriting older file.
%               default = false
%   'trackfail' boolean, if true, will save data from a failed stepSet, with 
%               file-suffix '_BAD_FILE', for later examination. Such files are
%               deleted on subsequent *successful* passes of this stepSet
%               default = false
%
% Outputs:
%
% Assumptions:
%
% References:
%
% Example:
%
% Notes: 
%
% See also: 
%
% Version History:
% 1.06.2014 Created (Jussi Korpela, FIOH)
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('Cfg', @isstruct);
p.addParameter('debug', false, @islogical);
p.addParameter('overwrite', false, @islogical);
p.addParameter('trackfail', false, @islogical);
p.parse(Cfg, varargin{:});
Arg = p.Results;

if ~Arg.debug
    warning('OFF', 'BACKTRACE')
end

%% Create needed directories
fnames = fieldnames(Cfg.env.paths);
for fn = 1:numel(fnames)
    if ~isdir(Cfg.env.paths.(fnames{fn}))
        mkdir(Cfg.env.paths.(fnames{fn}))
    end
end

myReport({
    sprintf('Begin analysis run at %s with stepSets:\n', datestr(now))
    sprintf('%s\n', char(Cfg.pipe.runSets)')},...
    Cfg.env.logFile);


%% Run step sets

% Find indices of sets to run
if strcmp(Cfg.pipe.runSets{1},'all')
    runSets = 1:numel(Cfg.pipe.stepSets);
else
    runSets = find(ismember({Cfg.pipe.stepSets.id}, Cfg.pipe.runSets));
end


%% Load and subset measurement config data
badFlag = {'_BAD_FILE'};
if runSets(1) > 1
    % Find loadable files at source directory
    Filt = dir(fullfile(sbf_get_src_subdir(Cfg, runSets(1)), '*.set'));
    if numel(Filt) == 0
       error('CTAP_pipeline_looper:inputError',...
        'RunSet source directory ''%s'' is either empty or does not exist. Please check.',...
        fullfile(sbf_get_src_subdir(Cfg, runSets(1)))); 
    end
    Filt = {Filt(cellfun(@isempty, strfind({Filt.name}, badFlag{1}))).name};
    [~, Filt, ~] = cellfun(@fileparts, Filt, 'UniformOutput', false);
    strucFilt.casename = intersect(Cfg.pipe.runMeasurements, Filt);
else
    strucFilt.casename = Cfg.pipe.runMeasurements;
end
MCSub = Cfg.MC;
MCSub.measurement = struct_filter(Cfg.MC.measurement, strucFilt);
numMC = numel(MCSub.measurement);
MCbad = false(numMC, 1);
if numMC == 0
   disp('No measurements matching the filter: ')
   disp(strucFilt)
   disp('Try specifying a different set of measurements.')
end
% get the index of the start stepSet - i.e. where the first data was loaded
% using this approach, runSets can jump around, jump around
idx_start_sets = find([Cfg.pipe.stepSets.save], 1, 'first');


%% Run sets
for n = 1:numMC %over measurements
    myReport(sprintf('\n================\nProcessing %s ...',...
        MCSub.measurement(n).casename), Cfg.env.logFile);
    Cfg.measurement = MCSub.measurement(n);
    SbjFilt.subject = Cfg.measurement.subject;
    Cfg.subject = struct_filter(Cfg.MC.subject, SbjFilt);
    tmp_Cfg = Cfg; %hold a copy of Cfg as it may be edited during Sets

    for i = runSets %over stepSets
        myReport(sprintf('\n\nSTEP SET %s', Cfg.pipe.stepSets(i).id),...
            Cfg.env.logFile);
        %respect prior run of this stepSet - don't overwrite (if save is true)
        if ~Arg.overwrite && Cfg.pipe.stepSets(i).save
            src_subdir = fullfile(Cfg.env.paths.analysisRoot...
                , Cfg.pipe.stepSets(i).id, [Cfg.measurement.casename, '.set']);
            if exist(src_subdir, 'file')
                myReport(sprintf('Overwrite is OFF and %s exists already.%s',...
                    src_subdir, ' Skipping this STEP SET'), Cfg.env.logFile);
                continue;
            end
        end
        i_ctap_hist_sz = 0;
        % Load source dataset
        if (i ~= idx_start_sets) %(i ~= 1) %
            i_EEG = pop_loadset(...
                'filepath', sbf_get_src_subdir(Cfg, i),...
                'filename', [Cfg.measurement.casename, '.set']);
        else
            i_EEG = struct();
        end

        % Perform analysis steps
        for k = 1:numel(Cfg.pipe.stepSets(i).funH) %over analysis steps
            if (i + k > idx_start_sets + 1)
                if ~is_valid_CTAPEEG(i_EEG)
                    warning('EEG file was not processed by CTAP pipe');
                    break;
                else
                    i_ctap_hist_sz = numel(i_EEG.CTAP.history);
                end
            end
            % Find the function in the Cfg.ctap struct
            funStr = func2str(Cfg.pipe.stepSets(i).funH{k});
            ctap = fieldnames(Cfg.ctap);
            ctapFun = get_similar_str(ctap, funStr);
            fun_args = Cfg.ctap.(ctapFun);
            % Check the cardinality of the discovered function arg struct
            num_ctapFun = numel(Cfg.ctap.(ctapFun));
            if num_ctapFun > 1
                i_tmp_ctap = Cfg.ctap.(ctapFun)(2:end);
                Cfg.ctap.(ctapFun) = Cfg.ctap.(ctapFun)(1);
            end
            % Call function vCTAP_reject_dataia handle
            if Arg.debug
                sbf_execute_pipefun
            else
                try
                    sbf_execute_pipefun
                catch ME,
                    % Error handling
                    myReport(sprintf([...
                        'WARN\n~~~~/#~~~~/#~~~~/#~~~~/#~~~~/#~~~~'...
                        '\nProcessing failed on %s \nbecause: %s \n@ %s : %s'...
                        '\n~~~~/#~~~~/#~~~~/#~~~~/#~~~~/#~~~~']...
                        , MCSub.measurement(n).casename...
                        , ME.message...
                        , Cfg.pipe.stepSets(i).id...
                        , funStr)...
                        , Cfg.env.logFile);
                    if isfield(i_EEG, 'CTAP')
                        i_EEG.CTAP.history(end+1) = create_CTAP_history_entry(...
                            ['FAIL_' Cfg.pipe.stepSets(i).id], funStr, fun_args);
                    end
                    MCbad(n) = true;
                    break;
                end
            end
            % Create CTAP history entry, if wrapper hasn't already done it
            [i_diff, ~] = struct_field_diff(Cfg, i_Cfg_tmp);
            if ~isempty(fieldnames(i_diff))
                fun_args = i_diff;
                Cfg = joinstruct(Cfg, i_Cfg_tmp);
            end
            if numel(i_EEG.CTAP.history) <= i_ctap_hist_sz
                i_EEG.CTAP.history(end+1) = create_CTAP_history_entry(...
                    ['Success_' Cfg.pipe.stepSets(i).id], funStr, fun_args);
            end
            % recover args for later use
            if num_ctapFun > 1
                Cfg.ctap.(ctapFun) = i_tmp_ctap;
            end
        end
        %make stepSet directory whatever happens
        i_sv = fullfile(Cfg.env.paths.analysisRoot, Cfg.pipe.stepSets(i).id);
        if ~isdir(i_sv), mkdir(i_sv); end
        % if stepSet loop didn't complete, measurement is no longer processed.
        if MCbad(n)
            if Arg.trackfail%if requested then save the unfinished EEG file
                pop_saveset(i_EEG, 'filepath', i_sv, 'filename'...
                    , [Cfg.measurement.casename, badFlag{1}, '.set']);
            end
            clear('i_*')%remove temp vars
            break;
            
        elseif Cfg.pipe.stepSets(i).save%save stepSet result
            i_savefile = fullfile(i_sv, [Cfg.measurement.casename, '.set']);
            i_EEG.CTAP = add_pipe_dataloc(i_EEG.CTAP,...
                                        Cfg.pipe.stepSets(i).id,...
                                        i_savefile);
            i_savefile = [Cfg.measurement.casename...
                , badFlag{MCbad(n) & Arg.trackfail}, '.set'];
            pop_saveset(i_EEG, 'filepath', i_sv, 'filename', i_savefile);
            
        else
            myReport(sprintf('\nSTEP SET %s SAID: "DON''T SAVE ME!!"\n'...
                , Cfg.pipe.stepSets(i).id), Cfg.env.logFile);
            
        end
        %cleanup: delete existing _BAD_FILEs, remove temp vars
        warning('OFF', 'MATLAB:DELETE:FileNotFound')
        delete(fullfile(i_sv, [Cfg.measurement.casename, badFlag{1}, '.*']));
        warning('ON', 'MATLAB:DELETE:FileNotFound')
        clear('i_*')
        
    end %over stepSets
    Cfg = tmp_Cfg; %reassign original ctap

    suxes = {'successfully! :)' 'unsuccessfully :('};
    myReport(sprintf(...
    '\n================\nMeasurement ''%s'' analyzed %s\n\n',...
        Cfg.measurement.casename, suxes{MCbad(n) + 1}), Cfg.env.logFile);

end %over measurements


%% END/REPORT
myReport(sprintf('\nAnalysis run ended at %s.\n', datestr(now, 30)),...
    Cfg.env.logFile);
if any(MCbad)
    myReport({'Analysis failed for: ' MCSub.measurement(MCbad).casename},...
        Cfg.env.logFile);
else
    myReport('All Analysis Successful!', Cfg.env.logFile);
end

% Report the detected badness per file
myReport(sprintf('\n================\nBADNESS SUMMARY:\n'), Cfg.env.logFile);
myReport(scrape_file_for_str(Cfg.env.logFile, 'Bad '), Cfg.env.logFile);


% Concatenate all the bad data tables and write as a single text file
if ismember('CTAP_reject_data', cellfun(@func2str...
        , [Cfg.pipe.stepSets(runSets).funH], 'UniformOutput', false))
    rejfiles = dir(fullfile(Cfg.env.paths.qualityControlRoot, '*rejections.mat'));
    if ~isempty(rejfiles)
        tmp = load(fullfile(Cfg.env.paths.qualityControlRoot, rejfiles(1).name));
        rejtab = tmp.rejtab;
        for rt = 2:numel(rejfiles)
            nxt = fullfile(Cfg.env.paths.qualityControlRoot, rejfiles(rt).name);
            tmp = load(nxt);
%TODO(feature-request)(BEN) join tables with non-matching rownames, use missing values
            try
                rejtab = join(rejtab, tmp.rejtab, 'Keys', 'RowNames');
            catch ME,
                fprintf('%s::%s misses rows, can''t join\n', ME.message, nxt)
            end
        end
        writetable(rejtab, fullfile(Cfg.env.paths.logRoot, 'all_rejections.txt')...
            ,  'WriteRowNames', true);
    end
end

fclose('all');
if ~Arg.debug
    warning('ON', 'BACKTRACE')
end

%% EMBEDDED FUNCTIONS

% embedded function calls the next pipe function
function sbf_execute_pipefun()
    switch funStr(1:5)
        case 'CTAP_'
            Cfg.pipe.current.set = i;
            Cfg.pipe.current.funAtSet = k;
            [i_EEG, i_Cfg_tmp] = Cfg.pipe.stepSets(i).funH{k}(i_EEG, Cfg);
        otherwise
            % Unpack Cfg to pass parameters to function via
            % varargin, as name, value pairs in cell array
            fun_varargs = [fieldnames(Cfg.ctap.(ctapFun))...
                struct2cell(Cfg.ctap.(ctapFun))]';
            [i_EEG, i_Cfg_tmp] = Cfg.pipe.stepSets(i).funH{k}(i_EEG...
                                                          , fun_varargs{:});
    end
end

% Add a new stepset data location to EEG.CTAP
function CTAP = add_pipe_dataloc(CTAP, stepSetID, file)
    entry = struct('id', stepSetID,...
                   'file', file);
    if ~isfield(CTAP.files, 'stepset')
        CTAP.files.stepset(1) = entry;
    else
        if ~ismember(stepSetID, {CTAP.files.stepset.id})
            CTAP.files.stepset(end+1) = entry;
        end
    end
end

% Get source directory of loadable files
function src_subdir = sbf_get_src_subdir(Cfg, idx)
    if ~isempty(Cfg.pipe.stepSets(idx).srcID)
        src_subdir = Cfg.pipe.stepSets(idx).srcID; 
    else
        %get first stepSet index with saved data
        idx = find([Cfg.pipe.stepSets(1:idx - 1).save], 1, 'last' );
        if isempty(idx)
            error('CTAP_pipeline_looper:badSaveSpec',...
            'NO SAVE POINT FOUND TO LOAD DATA - check your save specification');
        end
        src_subdir = Cfg.pipe.stepSets(idx).id;
    end
    src_subdir = fullfile(Cfg.env.paths.analysisRoot, src_subdir);

end

end% CTAP_pipeline_looper()
