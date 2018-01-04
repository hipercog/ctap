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
% Varargin:
%   'first'     scalar, index of first pipe to process
%   'last'      scalar, index of last pipe to process
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
p.addRequired('Cfg', @isstruct)
p.addRequired('dynFunc', @(f) isa(f, 'function_handle'))
p.addRequired('dfArgs', @iscell)
p.addRequired('pipeArr', @iscell)
p.addParameter('first', 1, @isnumeric)
p.addParameter('last', numel(pipeArr), @isnumeric)
p.addParameter('dbg', false, @islogical)
p.parse(Cfg, dynFunc, dfArgs, pipeArr, varargin{:});
Arg = p.Results;


Cfg.pipe.totalSets = 0;
for i = 1:Arg.first - 1
    [i_Cfg, ~] = pipeArr{i}(Cfg);
    Cfg.pipe.totalSets = sbf_get_total_sets(i_Cfg);
end

for i = Arg.first:Arg.last
    
    % Set Cfg
    [i_Cfg, i_ctap_args] = pipeArr{i}(Cfg);
    Cfg.pipe.totalSets = sbf_get_total_sets(i_Cfg);
    myReport(sprintf('Post-processing pipe ''%s'' at %s with function:%s ''%s'''...
        , i_Cfg.id, datestr(now), newline, func2str(dynFunc)));

    for k = 1:length(i_Cfg.srcid)
        
        k_Cfg = i_Cfg;
        if isnan(k_Cfg.srcid{k}), continue, end %skip empty sources

        k_Cfg.env.paths = cfg_create_paths(Cfg.env.paths.ctapRoot, k_Cfg.id...
            , k_Cfg.srcid{k}, length(k_Cfg.srcid) > 1);
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
