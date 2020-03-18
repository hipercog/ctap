function [rejval, rejbin] = reject_extreme_values(EEG, frame_size, thr, comp_list)
% REJECT_EXTREME_VALUES reject components based on (binned) standard deviation.
%
% Description:
%   rejbin indicates whether each bin of frame_size for each component exceeded
%   the given standard deviation thresholds (below or above). rejval then
%   gives the proportion of each component that is deviant, from 0-1
%   
% 
% Syntax: 
%   rejbin = reject_extreme_values(EEG, frame_size, thr, comp_list)
% 
% Inputs:
%   'EEG'           struct, EEG-file to process
%   'frame_size'    integer, samples per bin
%   'thr'           vector, std thresholds [min max]
%   'comp_list'     vector, list of compononents to process (1:N)
% 
% Outputs:
%   'rejval'        vector, proportion of all bins == 1
%   'rejbin'        logical, bins exceeding std thresholds as a logical matrix
%
% See also: eeg_getdatact
%
% Version history
% 8.12.2014 Created (Jari Torniainen, FIOH)
% 20.11.2015 updated (B. Cowley, FIOH)
%
% Copyright 2014- Jari Torniainen, jari.torniainen@ttl.fi
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Calculate activations
com = eeg_getdatact(EEG, 'component', comp_list);

if ismatrix(EEG.data)
    % Reshape component matrix
    com(:, 1 + end - mod(size(com, 2), frame_size):end) = [];
    com = reshape(com, [size(com, 1), frame_size, size(com, 2) / frame_size]);
end
% Calculate standard deviation over frames
com = squeeze(std(com, 0, 2));

% Compare to thresholds
rejbin = (com < thr(1)) | (com > thr(2));
% get proportion
rejval = mean(rejbin, 2);

end
