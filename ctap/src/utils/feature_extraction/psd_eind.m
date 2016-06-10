function [EIND, EINDinfo] = psd_eind(PSD, varargin)
% PSD_EIND - PSD spectral index calculation
%
% Description:
%   Extract PSD band power indices from a PSD struct with multiple channels.
%   PSD struct is an output of eeglab_psd.m and stored usually in
%   EEG.CTAP.PSD.
%   
%   The computed indices are:
%   'eind_b_ta_<{rel,abs}>': b/(t+a)
%   'eind_b_a_<{rel,abs}>': b/a
%   'eind_1_a_<{rel,abs}>': 1/a
%   'eind_t_a_<{rel,abs}>': t/a, where
%   b="beta band power", a="alpha ...", t="theta ..." and b="beta ..."
%
%   'rel' stands for relative, meaning that the band powers have been 
%   relative i.e. divided by total PSD power.
%   'abs' stands for absolute, meaning that the band powers have been 
%   used as is.
%
% Syntax:
%   [EIND, EINDinfo] = psd_eind(PSD, varargin);
%
% Inputs:
%   PSD     struct, PSD struct, output of eeglab_psd.m
%
%   varargin    Keyword-value pairs
%   Keyword         Type, description, values
%   Several paramters to be passed on to engagement_indices.m.
%   See "Default parameter values" for details.
%
% Outputs:
%   EIND        struct, ATTK data struct containing engagement index
%               results
%   EINDinfo    struct, Struct documenting the variables in EIND. Can be
%               used e.g. to create automatic documentation or lists of 
%               calculated variables. 
%
% Notes:
%
% See also: eeg_psd, engagement_indices
%
% Copyright 2008- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameter values
% Field names of 'Arg' can be used as keywords.
Arg.chansToAnalyze = PSD.chanvec;
Arg.fmin = [2  4  8  13]; %Lower frequency limits for eng. ind. calculation, in Hz   
Arg.fmax = [4  8  13 20]; %Upper frequency limits for eng. ind. calculation, in Hz 
Arg.bandLabels = {'delta', 'theta', 'alpha', 'beta'};
Arg.eindUnit = 'n/a';
Arg.integrationMethod = 'trapez'; %'sum','trapez'

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end


%% Set internal helper variables
chinds = find(strArrayFind(PSD.chanvec, Arg.chansToAnalyze));
chnames = PSD.chanvec;
BandDef.fmin = Arg.fmin;
BandDef.fmax = Arg.fmax;
BandDef.bandnames = Arg.bandLabels;

%% Loop over channels and segments
for k = 1:length(chinds) %over channels 
     
    % Select PSD data from k:th channel
    k_psd_data = squeeze(shiftdim(PSD.data(chinds(k),:,:),1)); %[ncs, psdlen]

    % EEG indices (engagement indices)
    k_valid_ch_name = strrep(chnames{chinds(k)},'-','_');
    [EIND.(k_valid_ch_name).data, EIND.labels, Info] = ...
        engagement_indices(k_psd_data, PSD.freqRes, BandDef,...
        'integrationMethod', Arg.integrationMethod);

    clear('k_*');   
end

%% Create output
% ATTK data structure
EIND.units = cell(1,length(EIND.labels));
EIND.units(:) = {Arg.eindUnit};
EIND.parameters = Arg;
EIND.sublevels.n = 1;
EIND.sublevels.labels = {'channel'};

% Create BPinfo
EINDinfo = Info;