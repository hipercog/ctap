function [segArr] = generate_segments(dlen, window, overlap)
%GENERATE_SEGMENTS - Create calculation segment indices using overlapping windows
%
% Description:
%   Creates a data segmentation using overlapping windows.
%   Last segment ends before data length
%
% Syntax:
%   [segArr] = generate_segments(dlen, window, overlap);
%
% Inputs:
%   dlen        [1,1] integer, Length of the data vector to be 
%               segmented [in samples]
%   window      [1,1] integer, Length of the segmentation window
%               [in samples]
%   overlap     [1,1] numeric, Percent of overlap between adjacent
%               segments, values range [0,1], e.g. 50% => 0.5
%
% Outputs:
%   segArr      [n,2] integer, Segment start and stop [in samples]
%               col 1 = segment start, col 2 = segment stop
%
% References:
%
% Example:
% generate_segments(10,3,0.33)
% 
% ans =
%      1     3
%      3     5
%      5     7
%      7     9
%
% See also:
%
% Version History:
% Created based on create_segments.m (1.10.2008, Jussi Korpela, TTL)
% Updated to meet the recent quality standards (9/2014, Jussi Korpela, BWRC)
%
% Copyright 2008- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Parse input arguments
p = inputParser;
p.addRequired('dlen', @isnumeric);
p.addRequired('window', @isnumeric);
p.addRequired('overlap', @isnumeric);
p.parse(dlen, window, overlap);
%Arg = p.Results;

%% Test input
if dlen <= 0 || isnan(dlen)
   error('generate_segments:invalidInputError',...
         'Input variable ''dlen'' is not valid.'); 
end

%% Generate segments
segArr(:,1) = (1:floor((1-overlap)*window):dlen-window+1)';
segArr(:,2) = segArr(:,1)+window-1;
%EOF