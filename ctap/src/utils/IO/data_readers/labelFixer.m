function newLabel = labelFixer(label)
%LABELFIXER Fix naming of channel labels.
%
% Input:
%   label       : String with label
%
% Output        : String with new label, where the naming has been fixed.
%
% Fixing labels means, that certain labels are changed to other labels,
% for greater consistency.
%
%
% Examples:
%               newLabel = labelFixer('EKG')
%               --> newLabel now contains the string 'ECG'.
%
% See also: read_data_gen
%
% Author: Andreas Henelius 2009

newLabel = label;

switch lower(label)
    case {'ekg','ecg'}
        newLabel = 'ECG';
    case {'hengitys','resp'}
        newLabel = 'Resp';
    case {'Pleth','pleth','plety','ppg'}
        newLabel = 'PPG';
    case {'veogy'}
        newLabel = 'VEOGU';
    case {'veoga'}
        newLabel = 'VEOGD';
    case {'heogv'}
        newLabel = 'HEOGL';
    case {'heogo'}
        newLabel = 'HEOGR';
    case {'verenpaine','portapres','porta'}
        newLabel = 'Porta';
end
end
