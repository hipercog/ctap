function [out, nrow, nvar] = ctap_compare_stat(stab1, stab2, varargin)
%CTAP_COMPARE_STAT compare two stat tables
% 
% Description:
%   takes two of the statistic tables produced by ctapeeg_stats_table(), 
%   and provides a comparison based on the logic that stab1 comes from
%   an earlier stage of the data, and stab2 from a later stage. 
%   The quality of preprocessing 


p = inputParser;
p.addRequired('stab1', @istable);
p.addRequired('stab2', @istable);
p.addParameter('rowi', {''}, @iscellstr);

p.parse(stab1, stab2, varargin{:});
Arg = p.Results;


%% PREP AND CHECK
vnmi = stab1.Properties.VariableNames;
if ~strcmp(vnmi, stab2.Properties.VariableNames)
    error('ctap_compare_stat:unmatched_vars', 'Unmatched Variables:\n%s\n%s'...
        , strjoin(vnmi), strjoin(stab2.Properties.VariableNames))
end
nvar = numel(vnmi);

if isempty(Arg.rowi{:})
    Arg.rowi = intersect(stab1.Properties.RowNames...
                        , stab2.Properties.RowNames, 'stable');
end
nrow = numel(Arg.rowi);

stab1 = stab1(Arg.rowi, :);
stab2 = stab2(Arg.rowi, :);


%% SIMPLE COMPARISONS
% range, mean, med, SD, skew, kurt, lo_pc, hi_pc, trim_mean, trim_sd, normality
res = cell(1, numel(vnmi));
res{1} = stab1.range - stab2.range;
res{2} = abs(stab1.M) - abs(stab2.M);
res{3} = abs(stab1.med) - abs(stab2.med);
res{4} = stab1.SD - stab2.SD;
res{5} = abs(stab1.skew) - abs(stab2.skew);
res{6} = abs(stab1.kurt - 3) - abs(stab2.kurt - 3); %FIXME - SUBTRACT 3?
res{7} = abs(stab1.lo_pc) - abs(stab2.lo_pc);
res{8} = abs(stab1.hi_pc) - abs(stab2.hi_pc);
res{9} = abs(stab1.trim_mean) - abs(stab2.trim_mean);
res{10} = abs(stab1.trim_stdv) - abs(stab2.trim_stdv);
res{11} = stab2.ks_norm - stab1.ks_norm;

res = cellfun(@(x) center_scale(x, 'center', false, 'scalebound', -121), res, 'Un', 0);

out = array2table(cell2mat(res)...
            , 'RowNames', Arg.rowi...
            , 'VariableNames', vnmi);

end