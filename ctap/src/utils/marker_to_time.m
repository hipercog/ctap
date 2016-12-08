function [time, sample] = marker_to_time(mark, markers)
% MARKER_TO_TIME - Given a marker, provide the time and sample
%                  of when the marker appears.
%
% Description:
%
% Syntax:
%   [time, sample] = marker_to_time(mark, markers)
%
% Inputs:
%   mark : A string in the format "code_order", where code is, e.g., an eight-bit
%          marker from a measurement device. Order designates the occurrence order
%          of the marker, i.e., '123_2' means the second instance of the code 123 etc.
%          The shorthand '123' can be used to represent '123_1'.
%
%  markers : The marker structure associated with a recording.
%
% Outputs:
%   time   : the time when the marker appears
%   sample : the sample when the marker appears
%
%
% See also: parse_blocks, read_data_gen
%
% Author: Andreas Henelius (FIOH, 2014)
% -------------------------------------------------------------------------

% Determine if this is an ordered marker
sep = '_';

if numel(findstr(sep, mark))
    %todo: assumes mark string to be of type 'xxx_y' and outputs numeric
    %values when actually neither is currently used
    mrk_tmp = strsplit(mark, sep);
    mrk     = zeros(2,1);
    mrk(1)  = str2num(mrk_tmp{1});
    mrk(2)  = str2num(mrk_tmp{2});
    ind = find(markers.code == mrk(1), mrk(2)); %old markers struct
else
    mrk = {mark, 1}; %assumes mark to be 'xxx'
    ind = find(ismember(markers.type, mrk{1}), mrk{2}); %new markers struct
end

% Determine the location of the marker
if ~isempty(ind)
    ind = ind(end);
else
    error('marker_to_time:markerNotFound',...
        sprintf('Marker ''%s'' not found.',mark));
end

time   = markers.time(ind);
sample = markers.index(ind);

end
% -------------------------------------------------------------------------
