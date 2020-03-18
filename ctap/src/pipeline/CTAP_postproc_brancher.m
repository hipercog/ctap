% TODO: UPDATE ARGUMENTS TO TAKE RUNPIPES, NOT FIRST/LAST
function CTAP_postproc_brancher(Cfg, dynFunc, dfArgs, pipeArr, varargin)
%CTAP_postproc_brancher - Applies a post-processing function to pipes in pipeArr
%
% Description:
%
% Syntax:
%   CTAP_postproc_brancher(Cfg, dynFunc, dfArgs, pipeArr, first, last, dbg)
%
% Inputs:
%   'Cfg'       struct, pipe configuration structure, see specifications above
%   'dynFunc'   function handle, specifies the user-defined function to
%                               execute at each pipe in pipeArr. Must
%                               implement the interface dynFunc(Cfg, varargin)
%   'dfArgs'    cell array, name-value pair arguments to pass to 'dynFunc'
%   'pipeArr'   function handle array, specifies the pipe-config funtions
% 
% Varargin:
%   'runPipes'  [1 n] numeric, indices of pipes to process, default = 1:end
%   'dbg'       boolean, see CTAP_pipeline_looper
%
%
% Version History:
% 1.01.2017 Created (Benjamin Cowley)
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


p = inputParser;
p.KeepUnmatched = true;%unspecified varargin name-value pairs go in p.Unmatched

p.addRequired('Cfg', @isstruct)
p.addRequired('dynFunc', @(f) isa(f, 'function_handle'))
p.addRequired('dfArgs', @iscell)
p.addRequired('pipeArr', @iscell)

p.addParameter('runPipes', 1:numel(pipeArr), @isnumeric)
p.addParameter('dbg', false, @islogical)

p.parse(Cfg, dynFunc, dfArgs, pipeArr, varargin{:});
Arg = p.Results;


%% Set up to run pipes
%Ensure runPipes makes sense
tmp = ~ismember(Arg.runPipes, 1:numel(pipeArr));
if any(tmp)
    error('CTAP_pipeline_brancher:bad_param',...
        '''runPipes'' value(s) %d NOT in ''pipeArr''!', Arg.runPipes(tmp))
end
Arg.runPipes = sort(Arg.runPipes);

% Get the number of sets called before the current first one
Cfg.pipe.totalSets = 0;
for i = 1:Arg.runPipes(1) - 1
    [i_Cfg, ~] = pipeArr{i}(Cfg);
    Cfg.pipe.totalSets = sbf_get_total_sets(i_Cfg);
end


%% Run the pipes
for i = Arg.runPipes
    % Set Cfg
    [i_Cfg, i_ctap_args] = pipeArr{i}(Cfg);
    if ~iscell(i_Cfg.srcid), i_Cfg.srcid = {i_Cfg.srcid}; end
    Cfg.pipe.totalSets = sbf_get_total_sets(i_Cfg);
    myReport(sprintf('Post-processing pipe ''%s'' at %s with function:%s ''%s'''...
        , i_Cfg.id, datestr(now), newline, func2str(dynFunc)));

    for k = 1:length(i_Cfg.srcid)
        
        k_Cfg = i_Cfg;
        if isnan(k_Cfg.srcid{k}), continue, end %skip empty sources

        k_Cfg.env.paths = cfg_create_paths(Cfg.env.paths.ctapRoot, k_Cfg.id...
                                                            , k_Cfg.srcid, k);
        % Assign arguments to the selected functions, perform various checks
        k_Cfg = ctap_auto_config(k_Cfg, i_ctap_args);
        k_Cfg.MC = Cfg.MC;
        
        % Run the required post-processing function
        try
            dynFunc(k_Cfg, dfArgs{:})
        catch ME
            if Arg.dbg
                error('CTAP_postproc_brancher:dyn_function', '%s', ME.message)
            else
                warning('CTAP_postproc_brancher:dyn_function', '%s', ME.message)
            end
        end

        clear('k_*');
    end
    % Cleanup
    clear('i_*');
end

    function ts = sbf_get_total_sets(conf)
        if strcmp(conf.pipe.runSets{1}, 'all')
            conf.pipe.runSets = {conf.pipe.stepSets(:).id};
        end
        ts = conf.pipe.totalSets + sum(~cellfun(@isempty, conf.pipe.runSets));
    end

end %CTAP_postproc_brancher()
