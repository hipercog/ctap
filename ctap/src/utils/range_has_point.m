function [has_point, point_idx] = range_has_point(ranges, points)
% range_has_point - Reports which value ranges contain certain value point 
%
% Description:
% Checks which value ranges in ''ranges'' are such that one (or more)
% value point in ''points'' are contained in the range.
%
% Original use case is to find out which events contain a
% boudary event in EEGLAB data. In this case ranges are event extends
% [latency, latency+duration] and points are latencies of boundary events.
%
% Algorithm:
%   ASSUMES RANGES AND POINTS ARE SORTED.
%   Loops over ranges and searches for points.
%   Tries to be efficient by not looping only once on both ranges and
%   points.
%
% Syntax:
%   has_point = range_has_point(ranges, points);
%
% Inputs:
%   ranges  [m,2] numeric, value ranges as [start, stop]
%           ranges(:,1) needs to be sorted and stop-start>=0
%   points  [n,1] numeric, value points
%
% Outputs:
%   has_point   [m,1] logical, indicator of which rows of ranges have some
%               point in points falling into them.
%   point_idx   [m,1] interger, index of the first point that falls into
%               the range m. Possible further points ignored!
%
% Assumptions:
%   Assumes the input data structures are sorted!
%
% Example:
%
% ranges = [1 5; 2 6; 8 10]
% points = [1,3,4,7,12,20]
% range_has_point(ranges,points)
% ans =
% 
%   3×1 logical array
% 
%    1
%    1
%    0
%
% Notes:
%
% See also: eeglab_event_overlap.m
%
% Copyright 2017- Jussi Korpela, FIOH, jussi.korpela@ttl.fi


% Check that assumptions are met

% Range limits sensible?
if ~all( (ranges(:,2)-ranges(:,1)) >= 0 )
   error('range_has_point:inputError','For some ranges stop-start<0.'); 
end

% Ranges sorted?
if ~issorted(ranges(:,1))
    error('range_has_point:inputError','Rows of ranges are not sorted.');
end

% Points sorted?
if ~issorted(points)
    error('range_has_point:inputError','Points are not sorted.');
end


% Initialize
cpi = 1; %current point index, share between functions
has_point = false(size(ranges,1), 1);
point_idx = NaN(size(ranges,1), 1);


% For each range check for points that lie inside the range
for n = 1:size(ranges,1) %over rows of ranges
    if cpi <= numel(points)
        % if points left test range n
        [has_point(n,1), point_idx(n,1)] = sf_hasPointInRange( ranges(n,:) );
        
        %debug:
        %if cpi <= numel(points)
        %    fprintf('n:%d, cpi:%d, pval:%d \n', n, cpi, points(cpi));
        %end
    end
end

    % Test if current range cr = [start, stop] contains a point in points
    % starting from points(cpi)
    function [tf, idx] = sf_hasPointInRange(cr)
        tf = false;
        idx = NaN;
        done = false;
        
        while ~done
            if (points(cpi) < cr(1))
                cpi = cpi + 1; %move on
            elseif (  (cr(1) <= points(cpi)) && (points(cpi) <= cr(2)) ) 
                % current range has at least one point -> return
                tf = true;
                idx = cpi;
                done = true;
                % do no increment cpi as other ranges may have this point
                % as well
            else
                done = true;
                % current point over current range end -> return
            end

            if ( numel(points) < cpi )
                % run out of points -> return
                done = true; 
           end
        end
    end


end