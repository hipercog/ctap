function num = ten20biosemi( label )
% TEN20BIOSEMI - Convert 10-20 system channel labels to Biosemi 1-128 numbers
%
% Syntax:
%   num = ten20biosemi(label)
%
% Input:
%   label - 10-20 system channel label (string or char), or cell array of labels
%
% Output:
%   num - Biosemi channel number(s) corresponding to input label(s)
%         Returns NaN if label not found in map
%
% Examples:
%   num = ten20biosemi('Cz');        % Returns 1
%   nums = ten20biosemi({'Cz', 'Pz', 'Fz'});  % Returns [1, 19, 85]
%
% See also: biosemi1020

% Parse and validate input
p = inputParser();
addRequired(p, 'label', @(x) ischar(x) || isstring(x) || iscell(x));
parse(p, label);
label = p.Results.label;

% Define the same map as in biosemi1020
map = {
'Cz'
'CCPz'
'CPz'
'CPPz'
'P1'
'CPP3h'
'P3'
'PPO5h'
'PPO5'
'PO7'
'PO9h'
'PO9'
'I1'
'OI1'
'O1'
'POO3'
'PO3'
'PPO3h'
'Pz'
'PPOz'
'POz'
'POOz'
'Oz'
'OIz'
'Iz'
'I2'
'OI2'
'O2'
'POO4'
'PO4'
'PPO4h'
'P2'
'CCP2h'
'CP2'
'CPP4h'
'P4'
'PPO6h'
'PPO6'
'PO8'
'PO10h'
'PO10'
'P10h'
'P8'
'P8h'
'P6'
'TP8'
'TP8h'
'CP6'
'CP6h'
'CP4'
'CP4h'
'C2'
'C4h'
'C4'
'C6h'
'C6'
'T8h'
'T8'
'FT8'
'FT8h'
'FC6'
'FC6h'
'FC4'
'FCC4h'
'FCC2h'
'FCC2'
'FCC4h'
'F4'
'F6'
'F8h'
'F8'
'AF8'
'AFF6'
'AFF6h'
'FC2'
'F2'
'F4h'
'AFF4h'
'AF4'
'Fp2'
'Fpz'
'AFpz'
'AFz'
'AFFz'
'Fz'
'FFCz'
'FCz'
'FC1'
'F1'
'F3h'
'AFF3h'
'AF3'
'Fp1'
'AF7'
'AFF5'
'AFF5h'
'FCC1h'
'FCC1'
'FCC3h'
'F3'
'F5'
'F7h'
'F7'
'FT7'
'FT7h'
'FC5'
'FC5h'
'FC3'
'FCC3h'
'C1'
'CCP1h'
'CP1'
'CP3h'
'C3h'
'C3'
'C5h'
'C5'
'T7h'
'T7'
'TP7'
'TP7h'
'CP5'
'CP5h'
'CP3'
'P5'
'P7h'
'P7'
'P9h'};

% Handle cell array input
if iscell(label)
    num = zeros(size(label));
    for i = 1:numel(label)
        num(i) = findChannelNumber(label{i}, map);
    end
    return;
end

% Handle single label (string or char)
num = findChannelNumber(label, map);

end

function num = findChannelNumber(label, map)
% FINDCHANNELNUMBER - Find channel number for a given label
    
    % Convert to string for comparison
    if ischar(label)
        label = string(label);
    end
    
    % Search for label in map
    idx = find(strcmp(map, label), 1);
    
    if isempty(idx)
        warning('Channel label ''%s'' not found in Biosemi 10-20 map. Returning NaN.', label);
        num = NaN;
    else
        num = idx;
    end
end
