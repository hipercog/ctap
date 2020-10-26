function [EEG, varargout] = ctapeeg_stats_table(EEG, varargin)
%CTAPEEG_STATS_TABLE make and save stats of EEG data
% 
% Description: 
% basic_stats() outputs:
%   rng         - range: signal maximum minus minimum
%   M           - mean
%   med         - median
%   SD          - standard deviation
%   vr          - variance
% STAT_stats() outputs:
%   sk          - skewness 
%   k           - kurtosis
%   lopc        - low 'percent/2'-Percentile ('percent/2'/100-Quantile)
%   hipc        - high 'percent/2'-Percentile ('percent/2'/100-Quantile)
%   tM          - trimmed mean, removing data < lopc and data > hipc
%   tSD         - trimmed standard dev, removing data < lopc and data > hipc
%   tidx        - index of the data retained after trimming - NOT USED
%   ksh         - output flag of the Kolmogorov-Smirnov test at level 'alpha' 
%                 0: data could be normally dist'd; 1: data not normally dist'd 
%                 -1: test could not be executed
%
% Syntax:
%   EEG = ctapeeg_stats_table(EEG, varargin)
%
% Input:
%   'EEG'         EEG file to process
% varargin:
%   'channels'    [1:k] _integer_, choose the channels to get stats 
%                 Default = channels of type=='EEG'
%   'latency'     scalar, start point of calculations in points, default=1
%   'duration'    scalar, end point of calculations in points, default=end
%   'outdir'      path string, output directory, default = none
%   'id'          string, output file id, default = none
%
% Output:
%   'EEG'         struct, modified input EEG
% varargout:
%   {1}           struct, the complete list of arguments actually used
%   {2}           table, channels x statistics
%
% NOTE
%
% CALLS
%
% REFERENCE:
%
% Version History:
% 02.12.2016 Created (Benjamin Cowley, FIOH)
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


Arg = sbf_check_input(); % parse the varargin, set defaults
idx = single(Arg.channels);
nchan = numel(idx);
%stats don't care about epoch boundaries, I think? so reshape to handy 2D
data = reshape(EEG.data(idx,:,:), nchan, EEG.pnts * EEG.trials);
data = data(:, ...
    single(Arg.latency):single(min(Arg.latency + Arg.duration - 1, EEG.pnts)));


%% get stats of each channel requested, build a matrix of stats
% basic = [rng, M, med, SD, ~]
% STATs = [sk, k, lopc, hipc, tM, tSD, ~, ksh]
t = NaN(nchan, 11);
for i = 1:nchan
    %get stats that Matlab can always handle
    [t(i,1), t(i,2), t(i,3), t(i,4), ~] = basic_stats(data(i, :));
    %get stats that requires fancy paid toolboxes for Matlab
    [t(i,5), t(i,6), t(i,7), t(i,8), t(i,9), t(i,10), ~, t(i,11)] =...
        STAT_stats(data(i, :), 'tailPrc', 0.05, 'alpha', 0.05);
end


%% create a table from the stats
colnames = {'range' 'M' 'med' 'SD'...
    'skew' 'kurt' 'lo_pc', 'hi_pc' 'trim_mean', 'trim_stdv', 'ks_norm'};
statab = array2table(t, 'RowNames', {EEG.chanlocs(idx).labels}'...
    , 'VariableNames', colnames); %#ok<*NASGU>


%% save table to per subject mat file, in peek directory
if ~isempty(Arg.outdir)
    save(fullfile(Arg.outdir, sprintf('signal_stats_%s.mat', Arg.id)), 'statab');
end


%% Report parameters used and result
varargout{1} = Arg;
varargout{2} = statab;


%% Subfunctions
    function Arg = sbf_check_input() % parse the varargin, set defaults
        % Unpack and store varargin
        if isempty(varargin)
            vargs = struct;
        elseif numel(varargin) > 1 %(assume parameter/name pairs)
            vargs = cell2struct(varargin(2:2:end), varargin(1:2:end), 2);
        else
            vargs = varargin{1}; %(assume a struct wrapped in a cell)
        end

        % If desired, the default values can be changed here:
        Arg.channels = get_eeg_inds(EEG, 'EEG');
        Arg.latency = 1;
        Arg.duration = EEG.pnts * EEG.trials;
        Arg.outdir = '';
        Arg.id = '';
        
        % Arg fields are canonical, vargs values are canonical: intersect-join
        Arg = intersect_struct(Arg, vargs);
    end

end