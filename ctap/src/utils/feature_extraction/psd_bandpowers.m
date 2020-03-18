function [BP, BPinfo] = psd_bandpowers(PSD, varargin)
% PSD_BANDPOWERS - PSD band power calculation (multichannel)
%
% Description:
%   Extract PSD band powers from a PSD struct with multiple channels.
%   PSD struct is an output of eeglab_psd.m and stored usually in
%   EEG.CTAP.PSD.
%
%   Band power values follow the naming convention:
%   P<start frq>_<end frq>_<{rel, abs}>, where
%   <start frq> is the band start frequency in Hz
%   <end frq> is the band stop frequency in Hz
%   <{rel, abs}> is one string from the list {rel, abs} specifying the type
%       of band power, relative or absolute, computed
%
%   Band powers can be absolute or relative. If psd is a vector containing
%   the whole spectrum, then absolute bandpower from a to b is sum(psd(a:b))
%   and relative power sum(psd(a:b))/sum(psd).
%   The default option is to use trapezoidal integration instead of sum()
%   but the difference migth be insignificant in practice.
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
Arg.fmin = [2  4  8  10 13]; %Lower frequency limits, in Hz   
Arg.fmax = [4  8  10 13 18]; %Upper frequency limits, in Hz 
Arg.integrationMethod = 'trapez'; %'trapez','sum'
Arg.valueType = 'relative'; %'relative','absolute'

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end


%% Set internal helper variables
chinds = find(strArrayFind(PSD.chanvec, Arg.chansToAnalyze));
chnames = PSD.chanvec;

%% Loop over channels and segments
for k = 1:length(chinds) %over channels 
     
    % Select PSD data from k:th channel
    k_psd_data = squeeze(shiftdim(PSD.data(chinds(k),:,:),1)); %[ncs, psdlen]

    % Bandpowers: [ncs, nbands] double
    k_valid_ch_name = strrep(chnames{chinds(k)},'-','_');
    [BP.(k_valid_ch_name).data, labels, units] = ...
                bandpowers( k_psd_data,...
                            PSD.freqRes,...
                            horzcat(Arg.fmin', Arg.fmax'),...
                            'integrationMethod', Arg.integrationMethod,...
                            'valueType', Arg.valueType);
    clear('k_*');   
end

%% Create output
% BWRC data structure
BP.labels = labels;
BP.units = units;
BP.parameters = Arg;
BP.sublevels.n = 1;
BP.sublevels.labels = {'channel'};

% Initialize BPinfo
BPinfo.Variable = BP.labels;
BPinfo.Type = cell(1,length(BP.labels));
BPinfo.Unit = cell(1,length(BP.labels));
BPinfo.Values = cell(1,length(BP.labels));

% Assign data to BPinfo
BPinfo.Type(:) = {'numeric'};
BPinfo.Unit = BP.units;
BPinfo.Values(:) = {'NA'};

fmin_cstr = cellfun(@num2str, num2cell(Arg.fmin), 'uniformOutput', false);
fmax_cstr = cellfun(@num2str, num2cell(Arg.fmax), 'uniformOutput', false);
BPinfo.Description=strcat('EEG spectral band power, band: ',fmin_cstr,'-',fmax_cstr,' Hz.');
