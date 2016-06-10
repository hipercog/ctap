function result = vari_bad_chans(EEG, EEGchan, bound)
%VARI_BAD_CHANS detects bad channels by variance
% 
% Description:
%   vari_bad_chans takes an input EEG data struct and calculates the 
%   base e logarithmic variance relative to the median channel average. Channels
%   are then compared with the bounds given to recognize "dead" (normalized 
%   variance below the lower limit) and "loose" (above higher limit) channels.
%   Found channels are marked as dead or loose the EEG.chanlocs struct
%
% Syntax:
%   result = vari_bad_chans(EEG, EEGchan, bound)
%
% Inputs:
%   'EEG'       struct, Input EEG data
%   'EEGchan'   vector, indices of channels to check for badness
%   'bound'     vector, Lower and higher variance bounds for dead & loose channels
%                   (eg. [-2 1] - NaN or 0 can be used to skip channel checks)
%                   (base e logarithm relative to median)
% 
% Outputs:
%   'result'    struct, dead = logical []
%
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley, Jari Torniainen (Jari.Torniainen@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('EEG', @isstruct);
p.addRequired('EEGchan', @ismatrix);
p.addRequired('bound', @ismatrix);
p.parse(EEG, EEGchan, bound);


%% Calculate normalized channel variance
eegchs = numel(find(EEGchan)); % find() in case some fool uses logical indexing
chanVar = repmat(NaN, 1, eegchs); %#ok<*RPMTN>
chanVarNorm = repmat(NaN, 1, eegchs);
chanVar(EEGchan) = var(EEG.data(EEGchan, :), 0, 2);
chanVarNorm(EEGchan) = log(chanVar(EEGchan) / median(chanVar(EEGchan)));


%% Check for loose and dead channels
dead = chanVarNorm < bound(1);
loose = chanVarNorm > bound(2);


%% return logical checks and normalized variance
result.dead = dead;
result.loose = loose;
result.variance = chanVarNorm;


end % vari_bad_chans()
