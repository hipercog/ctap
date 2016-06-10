function chinds = get_eeg_inds(EEG, chloc_cellstr)
% GET_EEG_INDS return channel indices equal to a type or label cell string array
%
% Description:
%   * find EEG.chanlocs fields matching to chlocstr, testing first against
%       EEG.chanlocs.type; if empty tests EEG.chanlocs.labels
%       If the number of indices returned is equal to the size of the first
%       dimension of EEG.data, the return value is [1:size(EEG.data,1)]
%       Thus we cannot index data rows which are not there if the chanlocs
%       structure doesn't match
%
% Syntax:
%   chinds = get_eeg_inds(EEG, chlocstr)
%
% Inputs:
%   EEG             struct, EEGLAB struct
%   chloc_cellstr   cell string array, type or label of channels to get indices.
%                   Channels must be defined in chanlocs
%
%
% Outputs:
%   chinds      vector, channel indices that correspond to actual EEG.data rows
%
%
% Copyright 2015 Benjamin Cowley, FIOH, Benjamin.Cowley@ttl.fi
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Parse input arguments and set varargin defaults
p = inputParser;

p.addRequired('EEG', @isstruct);
p.addRequired('chloc_cellstr', @iscellstr);

p.parse(EEG, chloc_cellstr);

chinds = find(ismember({EEG.chanlocs.type}, chloc_cellstr));

if isempty(chinds)
    chinds = find(ismember({EEG.chanlocs.labels}, chloc_cellstr));
end

channels = size(EEG.data, 1);
if numel(chinds) == channels
    chinds = 1:channels;
elseif max(chinds) > channels
    error('get_eeg_inds:bad_indices',...
        'Some chanlocs indices are outside the range of the dataset')
end

end
