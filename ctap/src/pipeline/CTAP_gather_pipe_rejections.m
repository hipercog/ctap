function MrT = CTAP_gather_pipe_rejections(Cfg, varargin)
% CTAP_GATHER_PIPE_REJECTIONS: Get all per-subject bad data rejection tables 
% 
% Description: for a given pipe, gather all the subject-wise bad-data .mat
%              rejection files, aggregate to one super table, & write to file
% 
% Input:
%   Cfg     struct, configuration struct from a pipeline
% 
% Varargin:
%   write   logical, write the table to a file
%           Default: true
% 
% Output:
%   MrT     table, aggregated bad-data rejections
% 
% Copyright(c) 2018 :
% Benjamin Cowley (ben.cowley@helsinki.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Parse input arguments and set varargin defaults
p = inputParser;
p.KeepUnmatched = true;

p.addRequired('Cfg', @isstruct)

p.addParameter('write', true, @islogical)

p.parse(Cfg, varargin{:})
Arg = p.Results;


%% Gather the bad-data rejection files, aggregate to one table
MrT = [];
pth = Cfg.env.paths.qualityControlRoot;
rejfiles = dir(fullfile(pth, '*rejections.mat'));
rejmethods = {'badchans', 'badepochs', 'badsegev', 'badcomps'};

if ~isempty(rejfiles)
    % Sub-divide into classes of rejctions
    for rmi = rejmethods
        idx = startsWith({rejfiles.name}, rmi);
        if any(idx)
            idx = find(idx);
            tmp = load(fullfile(pth, rejfiles(idx(1)).name));
            T = tmp.rejtab;
            for rix = 2:numel(idx)
                nxt = fullfile(pth, rejfiles(idx(rix)).name);
                tmp = load(nxt);
                % Combine vertically by rows
                try
                    T = [T; tmp.rejtab]; %#ok<AGROW>
                catch err
                    fprintf('%s::%s has incompatible cols, can''t append\n'...
                        , err.message, nxt)
                end
            end
            % Combine horizontally by columns
            if isempty(MrT)
                MrT = T;
            else
                try
                    MrT = join(MrT, T, 'Keys', 'RowNames');
                catch err
                    fprintf('%s::%s misses rows, can''t join\n'...
                        , err.message, nxt)
                end
            end
        end
    end
end


%% Write to file if requested
if Arg.write && ~isempty(rejtab)
    writetable(rejtab...
        , fullfile(Cfg.env.paths.logRoot, 'all_rejections.txt')...
        ,  'WriteRowNames', true);
end

end %CTAP_gather_pipe_rejections()