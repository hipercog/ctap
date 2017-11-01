function [EINDM, EINDMinfo] = psd_eind_cc(PSD, fzStr, pzStr, varargin)
% PSD_EIND_CC - PSD cross-channel spectral index calculation
%
% Description:
%   Extract PSD cross-channel band power indices from a PSD struct with
%   multiple channels.
%   PSD struct is an output of eeglab_psd.m and stored usually in
%   EEG.CTAP.PSD.
%
%   The computed indices are:
%   'BB_<{rel,abs}>': t_Fz/a_Pz
%   'FzBB_<{rel,abs}>': t_Fz/a_Fz, where
%   a="alpha band power" and b="beta ..."
%
%   'rel' stands for relative, meaning that the band powers have been 
%   relative i.e. divided by total PSD power.
%   'abs' stands for absolute, meaning that the band powers have been 
%   used as is.
%
% Syntax:
%   [EIND, EINDinfo] = psd_eind_cc(PSD, varargin);
%
% Inputs:
%   PSD     struct, PSD struct, output of eeglab_psd.m
%
%   varargin    Keyword-value pairs
%   Keyword         Type, description, values
%   Several paramters to be passed on to engagement_indices_cc.m.
%   See "Default parameter values" for details.
%
% Outputs:
%   EINDM       struct, ATTK data struct containing engagement index
%               results
%   EINDMinfo   struct, Struct documenting the variables in EINDM. Can be
%               used e.g. to create automatic documentation or lists of 
%               calculated variables. 
%
% Notes:
%
% See also: eeg_psd, engagement_indices_cc
%
% Copyright 2008- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameter values
% Field names of 'Arg' can be used as keywords.
Arg.fmin = [2  4  8  13]; %Lower frequency limits for eng. ind. calculation, in Hz   
Arg.fmax = [4  8  13 20]; %Upper frequency limits for eng. ind. calculation, in Hz 
Arg.bandLabels = {'Delta', 'Theta', 'Alpha', 'Beta'};
Arg.eindUnit = 'n/a';
Arg.integrationMethod = 'trapez'; %'sum','trapez'

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end


%% Set internal helper variables
BandDef.fmin = Arg.fmin;
BandDef.fmax = Arg.fmax;
BandDef.bandLabels = Arg.bandLabels;
BandDef.freqRes = PSD.freqRes;

%% Select Fz and Pz PSD data

% Select PSD data from Fz
fzmatch = strArrayFind(PSD.chanvec, fzStr);
psd_fz = squeeze(shiftdim(PSD.data(fzmatch,:,:),1)); %[ncs, psdlen]
if sum(fzmatch)==0
   error('eeg_eind_cc:channelNotFound',['Channel ''',fzStr,''' not present. Cannot compute.']); 
end

% Select PSD data from Pz
pzmatch = strArrayFind(PSD.chanvec, pzStr);
psd_pz = squeeze(shiftdim(PSD.data(pzmatch,:,:),1)); %[ncs, psdlen]
if sum(pzmatch)==0
   error('eeg_eind_cc:channelNotFound',['Channel ''',pzStr,''' not present. Cannot compute.']); 
end

%% Calculate indices
[EINDM.data, EINDM.labels, EINDMinfo] = engagement_indices_cc(psd_fz, psd_pz, BandDef,...
                                        'integrationMethod', Arg.integrationMethod);


%% Create output
% ATTK data structure
EINDM.units = cell(1,length(EINDM.labels));
EINDM.units(:) = {Arg.eindUnit};
EINDM.parameters = Arg;
EINDM.sublevels.n = 0;