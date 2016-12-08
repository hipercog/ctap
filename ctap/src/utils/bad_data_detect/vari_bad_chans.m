function result = vari_bad_chans(EEG, EEGchan, bound)
%VARI_BAD_CHANS detects bad channels by variance
% 
% Description:
%   vari_bad_chans takes an input EEG data struct and calculates the 
%   base e logarithmic variance relative to the median channel average.
%   Channels are then compared with the bounds given to recognize 
%   "dead" (normalized variance below the lower limit) and "loose" 
%   (above higher limit) channels.
%   Found channels are marked as dead or loose the EEG.chanlocs struct
%
% Syntax:
%   result = vari_bad_chans(EEG, EEGchan, bound)
%
% Inputs:
%   'EEG'       struct, Input EEG data
%   'EEGchan'   vector, indices of channels to check for badness
%   'bound'     [1,2] or [1,1] numeric, Thresholds for the log relative
%               channel variance.
%               [1,2] -> lower and higher log-rel-variance bounds
%               [1,1] -> number of MADs from median to use in both
%               directions
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

if numel(bound)==1
    % use the MAD approach
    th = [NaN NaN];
    nmad = bound;
else
    % use fixed thresholds
    th = bound;
    nmad = NaN;
end

%% Calculate normalized channel variance
eegchs = numel(find(EEGchan)); % find() in case some fool uses logical indexing
chanVar = repmat(NaN, 1, eegchs); %#ok<*RPMTN>
chanVarNorm = repmat(NaN, 1, eegchs);
chanVar(EEGchan) = var(EEG.data(EEGchan, :), 0, 2);
chanVarNorm(EEGchan) = log(chanVar(EEGchan) / median(chanVar(EEGchan)));


%% Check for loose and dead channels

Res = threshold(chanVarNorm, th, nmad);
%dead = chanVarNorm < th(1);
%loose = chanVarNorm > th(2);


%% return logical checks and normalized variance
% backward compatibility
result.dead = Res.isBelow;
result.loose = Res.isAbove;
result.variance = chanVarNorm;

result.th = Res; %the standard output for any thresholding function
result.th.figtitle = 'log relative channel variance';

end % vari_bad_chans()
