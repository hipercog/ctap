function CTAP_postproc_brancher(Cfg, pipeArr, first, last)
%CTAP_postproc_brancher - Applies a post-processing function to pipes in pipeArr
%
% Description:
%
% Syntax:
%   CTAP_postproc_brancher(Cfg, Filt, pipeArr, first, last)
%
% Inputs:
%   'Cfg'       struct, pipe configuration structure, see specifications above
%   'Filt'      struct,
%   'pipeArr'   function handle array, specifies the pipe-config funtions
%   'first'     scalar, index of first pipe to process
%   'last'      scalar, index of last pipe to process
%
%
% Version History:
% 1.01.2017 Created (Benjamin Cowley, FIOH)
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


Cfg.pipe.totalSets = 0;
for i = 1:first - 1
    [i_Cfg, ~] = pipeArr{i}(Cfg);
    Cfg.pipe.totalSets = sbf_get_total_sets(i_Cfg);
end

for i = first:last
    
    % Set Cfg
    [i_Cfg, i_ctap_args] = pipeArr{i}(Cfg);
    Cfg.pipe.totalSets = sbf_get_total_sets(i_Cfg);

    for k = 1:length(i_Cfg.srcid)
        
        k_Cfg = i_Cfg;
        if isnan(k_Cfg.srcid{k}), continue, end %skip empty sources

        k_Cfg.env.paths = cfg_create_paths(Cfg.env.paths.ctapRoot, k_Cfg.id...
            , k_Cfg.srcid{k}, length(k_Cfg.srcid) > 1);
        % Assign arguments to the selected functions, perform various checks
        k_Cfg = ctap_auto_config(k_Cfg, i_ctap_args);
        k_Cfg.MC = Cfg.MC;
        
        % Run the required post-processing function
        oddball_erps(k_Cfg, 'C20') % TODO: REPLACE WITH A DYNAMIC FUNCTION ARGUMENT?

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
