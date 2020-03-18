function [S, Sinfo] = psd_entropy(PSD, varargin)
% EEG_ENTROPY - PSD spectral entropy calculation
%
% Description:
%   Extract PSD spectral entropies from a PSD struct with multiple channels.
%   PSD struct is an output of eeglab_psd.m and stored usually in
%   EEG.CTAP.PSD.
%
%   Spectral entropy values follow the naming convention:
%   S<start frq>_<end frq>, where
%   <start frq> is the spectral band start frequency in Hz
%   <end frq> is the spectral band stop frequency in Hz
%
%   The entropies are computed using entropy_ilkka(). See the m-file for
%   details.
%
% Syntax:
%   [BP, BPinfo] = psd_bandpowers(PSD, varargin);
%
% Inputs:
%   PSD     struct, PSD struct, output of eeglab_psd.m
%
%   varargin    Keyword-value pairs
%   Keyword         Type, description, values
%   Several paramters to be passed on to bandpowers.m.
%   See "Default parameter values" for details.
%
% Outputs:
%   BP          struct, BWRC data struct containing PSD band powers
%   BPinfo      struct, Struct documenting the variables in BP. Can be
%               used e.g. to create automatic documentation or lists of 
%               calculated variables. 
%
% Notes:
%
% See also: eeglab_psd, bandpowers
%
% Copyright 2008- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameter values
% Field names of 'Arg' can be used as keywords.
Arg.chansToAnalyze = PSD.chanvec;
Arg.fmin = [1 1  1  1  1  3.5 5  4 8  2  3  6  10]; %Lower frequency limits for entropy calculation, in Hz     
Arg.fmax = [7 15 25 35 45 45  15 8 12 45 45 45 45]; %Upper frequency limits for entropy calculation, in Hz    
Arg.entropyUnit = 'NA';

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end

%% Set internal helper variables
chinds = find(strArrayFind(PSD.chanvec, Arg.chansToAnalyze));
chnames = PSD.chanvec;

fmin_cstr = cellfun(@int2str, num2cell(Arg.fmin), 'uniformOutput', false);
fmax_cstr = cellfun(@int2str, num2cell(Arg.fmax), 'uniformOutput', false);
bandlab_cstr = strcat({'S'}, fmin_cstr,{'_'}, fmax_cstr);

%% Loop over channels and segments
for k = 1:length(chinds) %over channels 
     
    % Select PSD data from k:th channel
    k_psd_data = squeeze(shiftdim(PSD.data(chinds(k),:,:),1)); %[ncs, psdlen]

    % Spectral entropies: [ncs, nbands] double
    k_valid_ch_name = strrep(chnames{chinds(k)},'-','_');
    S.(k_valid_ch_name).data = entropies(k_psd_data,...
                                PSD.freqRes,...
                                Arg.fmin, Arg.fmax);
                            
    %{
    %MAYBEDO: Add this feature if necessary
    % Joint spectral entropies
    jointSArray = joint_entropy(psdArray, PSDinfo.freqRes, ENTROPY.joint(1).fmin, ENTROPY.joint(1).fmax);
    %} 

    clear('k_*');   
end

%% Create output
% ATTK data structure
S.labels = bandlab_cstr;
S.units = cell(1,length(S.labels));
S.units(:) = {Arg.entropyUnit};
S.parameters = Arg;
S.sublevels.n = 1;
S.sublevels.labels = {'channel'};

% Initialize BPinfo
Sinfo.Variable = bandlab_cstr;
Sinfo.Type = cell(1,length(bandlab_cstr));
Sinfo.Unit = cell(1,length(bandlab_cstr));
Sinfo.Values = cell(1,length(bandlab_cstr));

% Assign data to Sinfo
Sinfo.Type(:) = {'numeric'};
Sinfo.Unit(:) = {Arg.entropyUnit};
Sinfo.Values(:) = {'NA'};

Sinfo.Description=strcat('PSD spectral entropy, band: ',...
                        fmin_cstr,'-',fmax_cstr,' Hz.');