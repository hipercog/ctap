function result = recufast_badness_detector(...
    ineeg, result, index, bounds, recuLim, datatype, varargin)
%RECUFAST_BADNESS_DETECTOR recursively looks for bad channels/epochs/components
% 
% Description:
%   takes an input EEG data struct and calculates the bad data, for either
%   channels, epochs or Independent Components, depending on the flag
%   'datatype'. Each datatype uses a similar method, relying on z-score
%   comparison of a set of metrics: if the value of ANY metric crosses a
%   threshold, that data point (channel, epoch or component) is marked bad.
%   Uses metrics derived from the FASTER toolbox (see citation below):
%   channels - correlation between all channels
%   channels - variance relative to mean
%   channels - Hurst exponent
%   epochs - Epoch's mean deviation from channel means
%   epochs - Epoch variance
%   epochs - Max amplitude difference
%   component - Median gradient value, for high frequency stuff
%   component - Mean slope around the LPF band (spectral)
%   component - Kurtosis of spatial map
%   component - Hurst exponent
%   component - Eyeblink correlations
% 
% Algorithm:
%   By passing recuLim > 0, the function takes on recursive behaviour:
%   after running once, it checks the outcome: if nothing was found, it
%   calls itself, adjusting the bounds to be slightly 'tighter'.
%   If more than one bad channel is found, it calls itself with unchanged
%   parameters. recuLim decrements with every call, process ends at 0
% 
% 
% Syntax:
%	result = recufast_badness_detector(
%                       ineeg, result, index, bounds, recuLim, datatype, ...)
%
% Inputs:
%   'ineeg'         struct, input EEG data
%   'result'        struct, pass an intially empty struct to aggregate results
%   'index'         vector, EITHER: channel indices for datatype = chan,
%                       OR: epoch indices for datatype = epoch,
%                       OR: independent component indices for datatype = comp
%   'bounds'        vector, [lower upper] bound for z-score threshold
%   'recuLim'       integer, recursion limit, set = 0 for no recursion
%   'datatype'      string, either 'chan', 'epoc', 'comp'
%
%   varargin        Keyword-value pairs
%   Keyword         Type, description, values
%   'indexby'       string, 'all'|'any': ALL or ANY metrics must be exceeded
%                   default = 'any'
%   'epchans'       vector, indices of channels included in bad epoch detection
%                   default = type 'EEG'
%   'outdir'        string, name of output folder for reporting log and figures
%                   default = ''
%   'report'        boolean, set true to report log text & figures
%                   default = false
%   'blinks'        boolean, set true to test ICs for blinks from EOG channels
%                   default = true
%
% Outputs:
%   'result'        struct, two vectors
%                   - logical array of given data indices which are bad
%                   - badness score for given data indices
%
% Assumptions:      
%       uses channels of type "EEG". These are taken as specified
%       in the channel location structure/file (anything not labeled EEG is 
%       considered non-EEG). It is highly recommended that you define a channel 
%       type for each channel, when you define your channel location file.
%
%
% References:
%
% Example: 
%
% Notes: 
%
% See also: channel_properties, epoch_properties, component_properties, min_z
%
% Version History:
% 1.09.2015 Created (Benjamin Cowley, FIOH)
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Checks
% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('ineeg', @isstruct);
p.addRequired('result', @isstruct);
p.addRequired('index', @ismatrix);
p.addRequired('bounds', @ismatrix);
p.addRequired('recuLim', @isscalar);
p.addRequired('datatype', @ischar);

p.addParameter('indexby', @all, @(f) isa(f, 'function_handle'));
p.addParameter('epchans', get_eeg_inds(ineeg, {'EEG'}), @isvector);
p.addParameter('outdir', '', @ischar);
p.addParameter('report', false, @islogical);
p.addParameter('blinks', true, @islogical);

p.parse(ineeg, result, index, bounds, recuLim, datatype, varargin{:});
Arg = p.Results;


%% set up variables
cecidx = strcmpi({'chan' 'epoch' 'comp'}, datatype);
if ~any(cecidx)
    error('recufast_badness_detector:bad_datatype',...
        'Arg datatype ''%s'' is bad; enter ''chan'', ''epoch'', or ''comp''.'...
        , datatype)
end
type = {'channel' 'epoch' 'component'};
type = type{cecidx};


%% this will only happen on first pass - set up to store the detected bad data
if ~isfield(result, 'bad_bin')
    if iscolumn(index), index = index'; end
    [x, y] = size(index);
    result.bad_bin = [index; zeros(x, y)];
end
result.success = 0;


%% reporting
if Arg.report
    myReport(sprintf('@ T-%d; Thresholds: %d %d ...bad %ss by FASTER :'...
        , recuLim, bounds(1), bounds(2), type), Arg.outdir);
end


%% FASTER-toolbox based bad channels
[badnew, badcnt] = FASTER_badness(ineeg...
    , index, bounds, recuLim, find(cecidx)...
    , Arg.indexby, Arg.epchans, Arg.blinks, Arg.outdir, Arg.report);
idx = ismember(result.bad_bin(1, :), badnew);
result.bad_bin(2, idx) = result.bad_bin(2, idx) + badcnt;


%% FINAL CHECK
% Handle iterations recursively - when no new bad 'data points' were found,
% reduce the thresholds and try again with all channels received. 
% If more than 1 is found, keep same thresholds but pass only 'data points'
% that were not marked bad. Reduce recursion limit every time.
if recuLim > 0
    if isempty(badnew)
        th = 1.5;
        threshneg = abs((bounds(1) + th) / recuLim);
        threshpos = abs((bounds(2) - th) / recuLim);
        result = recufast_badness_detector(...
            ineeg, result, index,...
            [bounds(1) + threshneg bounds(2) - threshpos],...
            recuLim - 1, datatype,...
            varargin{:});
        
    elseif length(badnew) > 1
        goodness = index(~ismember(index, badnew));
        result = recufast_badness_detector(...
            ineeg, result, goodness, bounds, recuLim - 1, datatype,...
            varargin{:});
        
    end
end
result.success = 1;

end % recufast_badness_detector()




%% FASTER_BADNESS
%   
%   Calculates a set of bad chans/epochs/comps based on FASTER metrics
%
function [chk_bad, bad_count] = FASTER_badness(...
    EEG, index, bounds, recLim, cecidx, indexby, epchans, blinks, outdir, report)

switch cecidx
    case 1
        badness = channel_properties(EEG, index, 1);

    case 2
        badness = epoch_properties(EEG, epchans, index);
        
    case 3
        EOG = [];
        if blinks, EOG = get_eeg_inds(EEG, {'EOG'}); end
        badness = component_properties(EEG, EOG, 1, index);
        
end

badtest = min_z(badness, indexby, struct('z', bounds));
chk_bad = index( badtest );
% sum count of indices on which channel has failed, 
% and multiply by the z-score bound which was exceeded.
%TODO: ACCOUNT FOR BOTH LOWER AND UPPER BOUND NOW BEING USED IN min_z()
bad_count = sum(all_bad, 2) .* bounds(2);
bad_count(bad_count == 0) = [];
chk_bad = chk_bad(:)'; %turn column into row
bad_count = bad_count(:)'; %turn column into row


%% reporting
if report
    if cecidx == 1
        tmp = {EEG.chanlocs(chk_bad).labels};
        reportmat = cell2mat(cellfun(@(x) [x ' '], tmp, 'UniformOutput',false));
    else
        reportmat = chk_bad;
    end
    myReport({sprintf('N = %d :', numel(chk_bad)) reportmat}, outdir);
% {
    recLim = ['@ T-' num2str(recLim)];

    % generate a badass badness figure
    fig = report_badness(badness, chk_bad, index, bounds, recLim, cecidx);
    if cecidx == 1
    	newXTickLabels( gca, {EEG.chanlocs(index).labels} );
    end
    % Save the figure to an image file
    if exist(fullfile(outdir, EEG.setname), 'dir')~=7
        mkdir(fullfile(outdir, EEG.setname));
    end
    print( fig, '-dpng', fullfile(outdir, EEG.setname, recLim) );
    close(fig);
%}
end

end % FASTER_badness()



%% REPORT_BADNESS
%   make pictures of the FASTER metrics
%
function fig = report_badness(props, hits, index, bounds, iter, cecidx)

    data = length(index);
    if data > 20
        set(0,'Units','pixels');
        lbwh = get(0,'ScreenSize');
        lbwh(1) = 10;   lbwh(2) = 50;   
        lbwh(3) = lbwh(3) - lbwh(1) - 50; 
        lbwh(4) = lbwh(4) - lbwh(2) - 100;
        fig = figure('Position', lbwh, 'Visible', 'off');
    else
        fig = figure('Visible', 'off');
    end
    
    plot((props(:,1)-mean(props(:,1)))/std(props(:,1)),'r','linewidth',2);
    hold on;
    plot((props(:,2)-mean(props(:,2)))/std(props(:,2)),'b','linewidth',2);
    plot((props(:,3)-mean(props(:,3)))/std(props(:,3)),'g','linewidth',2);
    if cecidx == 3
        plot((props(:,4)-mean(props(:,4)))/std(props(:,4)),'y','linewidth',2);
        plot((props(:,5)-mean(props(:,5)))/std(props(:,5)),'p','linewidth',2);
    end

    plot(1:data, bounds(2) * ones(1,data), 'k-.', 'linewidth', 2);
    plot(1:data, bounds(1) * ones(1,data), 'k-.', 'linewidth', 2);
    
    bds=bounds(1):bounds(2);
    for i=1:length(hits)
       plot(hits(i)*ones(1,length(bds)),bds,'m-','linewidth',1);
    end
    
    switch cecidx
        case 1
            legend('Mean correlation','Channel variance','Hurst exponent',...
                'Threshold');

        case 2
            legend('Mean deviation','Epoch variance','Max amplitude diff',...
                'Threshold');
            
        case 3
            legend('Temporal:median gradient','Mean LPF slope','Kurtosis',...
                'Hurst exponent','Eyeblink correlations','Threshold');
    end
    
    ylabel('Z-score');
    datatype = {'channel' 'epoch' 'component'};
    title({['Iteration: ' iter]...
        sprintf('%ss: %d - %d', datatype{cecidx}, index(1), index(end))});
    grid off;

end % report_badness()
