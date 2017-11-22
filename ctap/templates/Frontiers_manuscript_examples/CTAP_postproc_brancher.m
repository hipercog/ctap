function CTAP_postproc_brancher(Cfg, Filt, pipeArr, first, last)
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

        % define the measurements
        k_Cfg.pipe.runMeasurements = get_measurement_id(Cfg.MC, Filt);
        
        % Run the required post-processing function
        sbf_sccn_erps(k_Cfg) % TODO: REPLACE WITH A DYNAMIC FUNCTION ARGUMENT

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


%% Plot ERPs of saved .sets
function [] = sbf_sccn_erps(Cfg)

    setpth = fullfile(Cfg.env.paths.analysisRoot, Cfg.pipe.runSets{end});
    
    fnames = strcat(Cfg.pipe.runMeasurements, '.set');
    
    %%%%%%%% define subject-wise ERP data structure: 
    %%%%%%%%  of known size for subjects,conditions
    erps = cell(numel(fnames), 4);
    cond = {'short' 'long'};
    codes = 100:50:250;
    for i = 1:numel(fnames)
        eeg = ctapeeg_load_data(fullfile(setpth, fnames{i}) );
        eeg.event(isnan(str2double({eeg.event.type}))) = [];

        for c = 1:2
            stan = pop_epoch(eeg, cellstr(num2str(codes(3:4)' + (c-1))), [-1 1]);
            devi = pop_epoch(eeg, cellstr(num2str(codes(1:2)' + (c-1))), [-1 1]);

            erps{i, c * 2 - 1} = ctap_get_erp(stan);
            erps{i, c * 2} = ctap_get_erp(devi);
            ctaptest_plot_erp([erps{i, c * 2 - 1}; erps{i, c * 2}]...
                , stan.pnts, eeg.srate...
                , {[cond{c} ' standard'] [cond{c} ' deviant']}...
                , fullfile(Cfg.env.paths.exportRoot, sprintf(...
                    'ERP%s-%s_%s.png', fnames{i}, cond{c}, 'tones')))

        end
    end

    %%%%%%%% Obtain condition-wise grand average ERP and plot %%%%%%%%
    for c = 1:2:4
        ERP_std = mean(cell2mat(erps(:,c)), 1);
        ERP_dev = mean(cell2mat(erps(:,c + 1)), 1);
        ctaptest_plot_erp([ERP_std; ERP_dev], numel(ERP_std), eeg.srate...
            , {[cond{ceil(c/2)} ' standard'] [cond{ceil(c/2)} ' deviant']}...
            , fullfile(Cfg.env.paths.exportRoot...
                , sprintf('ERP%s-%s_%s.png', 'all', cond{ceil(c/2)}, 'tones')))
    end

end