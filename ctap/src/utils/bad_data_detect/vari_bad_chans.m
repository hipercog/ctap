function result = vari_bad_chans(EEG, EEGchan, bounds, varargin)
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
%   result = vari_bad_chans(EEG, EEGchan, bounds)
%
% Inputs:
%   'EEG'       struct, Input EEG data
%   'EEGchan'   vector, indices of channels to check for badness
%   'bounds'    [1,1] or [1;2] or [1,2] numeric, Thresholds for the
%               log relative channel variance.
%               [1,2] -> lower and higher log-rel-variance bounds
%               [1,1] or [1;2] -> distance in MADs from median, +- or as given
% Varargin:
%   take_worst_n    scalar, if >0, return those n channels with highest
%                   max abs variance, even if no channels exceed threshold.
%                   To ensure no channels are marked bad, enter bounds = NaN,
%                   and the whole set of 1-n highest abs variance channels
%                   will be marked bad. Otherwise, n becomes only a limit on
%                   number of bad channels
%                   default=0
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
p.addRequired('bounds', @ismatrix);
p.addParameter('take_worst_n', 0, @isscalar);
p.addParameter('plot', true, @islogical);
p.parse(EEG, EEGchan, bounds, varargin{:});
Arg = p.Results;


%% Calculate normalized channel variance
eegchs = numel(find(EEGchan)); % find() in case some fool uses logical indexing
chanVar = repmat(NaN, 1, eegchs); %#ok<*RPMTN>
chanVarNorm = repmat(NaN, 1, eegchs);

chanVar = var(EEG.data(EEGchan, :), 0, 2);
chanVarNorm = log(chanVar / median(chanVar));


%% Check for loose and dead channels
if isscalar(bounds) || iscolumn(bounds)
    % use the MAD approach
    th = [NaN NaN];
    nmad = bounds;
else
    % use fixed thresholds
    th = bounds;
    nmad = NaN;
end

Res = thresholdNplot(chanVarNorm, th, nmad, Arg.plot);

%if user wants to kill worst n channels, or set n as limit of bad channels
if Arg.take_worst_n > 0
    [~, ix] = sort(abs(chanVarNorm), 'descend');
    if all(Res.isInRange)
        Res.isInRange(ix(1:Arg.take_worst_n)) = false;
        tmp = chanVarNorm > nansumedian(chanVarNorm);
        Res.isAbove(ix(1:Arg.take_worst_n)) = tmp(ix(1:Arg.take_worst_n));
        Res.isBelow(ix(1:Arg.take_worst_n)) = ~tmp(ix(1:Arg.take_worst_n));
    else
        % use n as limit by 'cleaning' all channels less variant than channel.n
        Res.isInRange(ix(Arg.take_worst_n + 1:end)) = true;
        Res.isAbove(ix(Arg.take_worst_n + 1:end)) = false;
        Res.isBelow(ix(Arg.take_worst_n + 1:end)) = false;
    end
end


%% return logical checks and normalized variance
% backward compatibility
result.dead = Res.isBelow;
result.loose = Res.isAbove;
result.variance = chanVarNorm;

result.th = Res; %the standard output for any thresholding function
result.th.figtitle = 'log relative channel variance';

end % vari_bad_chans()
