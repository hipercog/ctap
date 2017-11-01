function result = recurse_variance_bad_chans(...
    EEG, result, recuLim, varargin)
%RECURSE_VARIANCE_BAD_CHANS attempts to remove bad channels by variance
% 
% Description:
%   recurse_variance_bad_chans takes an input EEG data struct and calculates the 
%   base e logarithmic variance relative to the median channel average. Channels
%   are then compared with the bounds given to recognize "dead" (normalized 
%   variance below the lower limit) and "loose" (above higher limit) channels.
%   Found channels are marked as dead or loose the EEG.chanlocs struct
% 
%   By passing recuLim > 0, the function takes on recursive behaviour:
%   after running once, it checks the outcome: if nothing was found, it
%   calls itself, adjusting the variance bounds to be slightly 'tighter'.
%   If more than one bad channel is found, it calls itself with unchanged
%   parameters. recuLim decrements with every call, process ends at 0
%   NOTE: the behaviour of variance detection under recursion is
%   unpredictable, depending on the state of the data. Use with caution.
%
%
% Syntax:
%   result = recurse_variance_bad_chans(EEG, result, channels, bound, recuLim,...)
%
% Inputs:
%   'EEG'       struct, Input EEG data
%   'result'    struct, an intially empty struct to aggregate over recursive calls
%   'recuLim'   integer, recursion limit
%
%   varargin        Keyword-value pairs
%   Keyword         Type, description, values
%   'bound'     vector, Lower and higher variance bounds for dead & loose channels
%                   (eg. [-2 1] - NaN or 0 can be used to skip channel checks)
%                   (base e logarithm relative to median)
%               default = [-2 2]
%   'channels'  vector, indices of channels to check for badness
%               default = indices of channels with label 'EEG'
%   'outdir'    string, name of output folder
%               default = ''
% 
% Outputs:
%   'result'    [2, n] array, where n = number of channels, top row = channel 
%               indices, lower row = number of times channel was marked dead
%               or loose
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
p.addRequired('result', @isstruct);
p.addRequired('recuLim', @isscalar);
p.addParameter('bound', [-2 2], @ismatrix);
p.addParameter('channels', get_eeg_inds(EEG, {'EEG'}), @ismatrix);
p.addParameter('outdir', '', @ischar);
p.parse(EEG, result, recuLim, varargin{:});

EEGchan = p.Results.channels;
bound = p.Results.bound;
outdir = p.Results.outdir;

if ~isfield(result, 'badchbin')
    if iscolumn(EEGchan), EEGchan = EEGchan'; end
    [x, y] = size(EEGchan);
    result.badchbin = [EEGchan; zeros(x, y)];
end

%% - THIS CODE NOW REPRODUCED BY vari_bad_chans()
% %% Calculate normalized channel variance
% eegchs = numel(find(EEGchan)); % find() in case some fool uses logical indexing
% chanVar = repmat(NaN, 1, eegchs); %#ok<*RPMTN>
% chanVarNorm = repmat(NaN, 1, eegchs);
% chanVar(EEGchan) = var(EEG.data(EEGchan, :), 0, 2);
% chanVarNorm(EEGchan) = log(chanVar(EEGchan) / median(chanVar(EEGchan)));
% 
% 
% %% Check for loose and dead channels
% num_dead = 0;
% dead = false(1, eegchs);
% num_loose = 0;
% loose = false(1, eegchs);
% for j = 1:eegchs
%     if(chanVarNorm(j) < bound(1)) % Dead channels
%         dead(j) = true;
%         num_dead = num_dead + 1;
%     end
%     if(chanVarNorm(j) > bound(2)) % Loose channels
%         loose(j) = true;
%         num_loose = num_loose + 1;
%     end
% end

%% Calculate normalized channel variance, Check for loose and dead channels
rez = vari_bad_chans(EEG, EEGchan, bound);
num_dead = sum(rez.dead);
num_loose = sum(rez.loose);

result.badchbin(2, (rez.dead | rez.loose)) =...
    result.badchbin(2, (rez.dead | rez.loose)) + 1;

myReport(['Channels marked dead:  ' cell2mat(cellfun(@(x) [x ' '],...
    {EEG.chanlocs(rez.dead).labels},'UniformOutput',false))], outdir);
myReport(['Channels marked loose: ' cell2mat(cellfun(@(x) [x ' '],...
    {EEG.chanlocs(rez.loose).labels},'UniformOutput',false))], outdir);


%% Handle iterations recursively - when no new bad channels were found,
% reduce the thresholds and try again. If more than 1 is found, try
% again with same thresholds. Reduce recursion limit every time.
if recuLim > 0
    if num_dead + num_loose == 0
        th = 1;
        threshneg = abs((bound(1) + th) / recuLim);
        threshpos = abs((bound(2) - th) / recuLim);
        result = itervari_bad_chans(EEG, result, EEGchan,...
            [bound(1) + threshneg bound(2) - threshpos],...
            recuLim - 1, varargin{:});
    elseif num_dead + num_loose > 1
        result = itervari_bad_chans(EEG, result, EEGchan,...
            bound, recuLim - 1, varargin{:});
    end
end

end % recurse_variance_bad_chans()
