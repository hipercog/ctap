function [overlap_idx, OVR1, OVR2] = range_overlap(ranges1, ranges2)
% RANGE_OVERLAP - Quantify overlap between sets of (time) ranges
%
% Description:
%
% Algorithm:
%
% Syntax:
%   [overlap_idx, OVR1, OVR2] = range_overlap(ranges1, ranges2);
%
% Inputs:
%   ranges#     [m#, 2] integer, Set of integer ranges to compare,
%               m# ranges per set 
%
%   varargin    Keyword-value pairs
%   Keyword         Type, description, values
%
% Outputs:
%   overlap_idx     integer vector, a vector of indices that show an
%                   overlap
%   OVR#            struct, Overlap results for each range set separately
%                   Field descriptions:% 
%       .overlapPrc: # of overlapping indices / # of indices covered 
%       .nIdxCovered: # of indices covered 
%       .rangeIdxArr:  row numbers of _sorted_ ranges<x> for which 
%                      overlaps happen
%
% Assumptions:
%
% References:
%
% Example:
%   ranges1 = [1 2; 4 6; 8 15]
%   ranges2 = [3 5; 7 9; 17 20]
%   [overlap_idx, OVR1, OVR2] = range_overlap(ranges1, ranges2)
%
% Notes: 
%
% See also: range_has_point.m
%
%
% Copyright 2017- Jussi Korpela, FIOH, jussi.korpela@ttl.fi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Validate inputs
if ~sbf_ranges_logical(ranges1)
   error('range_overlap:badInput', '''ranges1'' are not valid.'); 
end

if ~sbf_ranges_logical(ranges2)
   error('range_overlap:badInput', '''ranges2'' are not valid.'); 
end

if sum(sum( ranges1 <= 0 )) > 0
   error('range_overlap:badInput', 'Negative or zero elements in ''ranges1'' .');
end

if sum(sum( ranges2 <= 0 )) > 0
   error('range_overlap:badInput', 'Negative or zero elements in ''ranges2'' .');
end

% sort
ranges1 = sortrows(ranges1, 1);
ranges2 = sortrows(ranges2, 1);


%% Create masks
max_idx = max(max(ranges1(:,2)), max(ranges2(:,2)));
tf1 = NaN(max_idx, 1);
tf2 = tf1;

for i = 1:size(ranges1, 1)
   tf1(ranges1(i,1):ranges1(i,2)) = i; 
end

for i = 1:size(ranges2, 1)
   tf2(ranges2(i,1):ranges2(i,2)) = i; 
end


%% Compute overlaps
ovrl_match = ~isnan(tf1) & ~isnan(tf2);

OVR1 = sbf_compute_stats(tf1, ovrl_match);
OVR2 = sbf_compute_stats(tf2, ovrl_match);
overlap_idx = find(ovrl_match);


%% Helper functions

    % Check that range limits are such that start < stop
    function rl = sbf_ranges_logical(ranges)
        test = ranges(:,2) < ranges(:,1);
        if sum(test) == 0
            rl = true;
        else
            rl = false;
        end
    end

    % Compute range list specific statistics
    function R = sbf_compute_stats(tf, ovrl_match)
        
        % # of overlapping indices / # of indices covered
        R.overlapPrc = sum(ovrl_match) / sum(~isnan(tf));
        
        % # of indices covered
        R.nIdxCovered = sum(~isnan(tf));
        
        % row numbers of sorted ranges<x> for which overlaps happen
        R.rangeIdxArr = unique(tf(ovrl_match)); 
    end

end