function [spect_data, spect_labels, Info] = engagement_indices(psdArray, freq_res, BandDef, varargin)
% ENGAGEMENT_INDICES - Calculate engagement indices from PSD data
%
% Description:
%   Calculates engagement indices from PSD data. Only single derivation
%   indices can be calculated.
%
%   Does not contain runtime constants not defined by function arguments.
%
% Syntax:
%   [spect_data, spect_labels] = engagement_indices(psdArray, freq_res,...
%   BandDef);
%
% Inputs:
%   psdArray    ncs-by-psdlen double, Power spectrum densities to be analyzed
%   freq_res    1-by-1 double, Frequency resolution of the 'psdArray'
%   BandDef     struct, Defines the frequency bands used
%               .fmin   1-by-m double, lower bounds in Hz
%               .fmax   1-by-m double, upper bounds in Hz
%               .bandnames 1-by-m cell, bandnames as string, Use only the
%               exact strings: 'delta', 'theta', 'alpha', 'beta'
%   varargin    Keyword-value pairs
%   Keyword             Type, description, values
%   'integrationMethod' string, Integration method to use when summing up
%                       band powers, default: "trapez"
%                       "trapez" = trapezoidal integration using trapz()
%                       "sum" = plain sum
%
% Outputs:
%   spect_data     ncs-by-m double, Calculated engagement indices
%   spect_labels   1-by-m cell, The names of the indices
%
% Jussi Korpela, TTL, 22.12.2006 (last revision)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameter values
% Field names of 'Arg' can be used as keywords.
Arg.integrationMethod = 'trapez'; %'sum','trapez'

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end

%% Check inputs
if sum(strcmp(Arg.integrationMethod, {'trapez','sum'}))==0
    msg = ['Unknown integration method. Found ''', Arg.integrationMethod,
           ''' but only ''trapez'' and ''sum'' allowed'];
    error('bandpowers:unknownVararginValue',msg);
    
end

%% Initialize variables
ncs = size(psdArray,1);
spect_data = NaN(ncs, 3);
spect_labels = cell(1,3);


%% Find out band order in 'BandDef'
kVector = 1:1:length(BandDef.fmin);
kDelta = kVector(strArrayFind(BandDef.bandnames, {'delta'}));
kTheta = kVector(strArrayFind(BandDef.bandnames, {'theta'}));
kAlpha = kVector(strArrayFind(BandDef.bandnames, {'alpha'}));
kBeta = kVector(strArrayFind(BandDef.bandnames, {'beta'}));

if isempty(kDelta) || isempty(kTheta) || isempty(kAlpha) || isempty(kBeta)
    msg = 'Frequency band name mathcing failed. Cannot continue.';
    error('engagement_indices:bandNameMismatch',msg);
end


%% Start going through calculation segments

i_psd_bp_rel = NaN(1,length(BandDef.fmax));
i_psd_bp_abs = NaN(1,length(BandDef.fmax));
for i = 1:ncs %over calculation segments
    i_psd_abs = psdArray(i,:);
    
    %% Normalizing PSD data from i:th calc seg
    if strcmp(Arg.integrationMethod, 'sum')
        i_psd_totpower = sum(psdArray(i,:)); 
    else
        i_psd_totpower = trapz(psdArray(i,:),2);
    end  
    i_psd_rel = i_psd_abs/i_psd_totpower;
   

    %% Summing up the PSD values that belong to each of the frequency bands
    for k = 1:length(BandDef.fmax)
        k_min = round(BandDef.fmin(k)/freq_res);
        k_max = round(BandDef.fmax(k)/freq_res);
        
        if strcmp(Arg.integrationMethod, 'sum')
            i_psd_bp_rel(k) = sum(i_psd_rel(k_min:k_max));
            i_psd_bp_abs(k) = sum(i_psd_abs(k_min:k_max));
        else
            i_psd_bp_rel(k) = trapz(i_psd_rel(k_min:k_max),2);
            i_psd_bp_abs(k) = trapz(i_psd_abs(k_min:k_max),2);
        end
        clear('k_*')
    end

    %% Creating engagement indices
    theta_rel = i_psd_bp_rel(kTheta);
    alpha_rel = i_psd_bp_rel(kAlpha);
    beta_rel = i_psd_bp_rel(kBeta); 
    
    spect_data(i,1)=beta_rel/(alpha_rel + theta_rel);
    spect_data(i,2)=beta_rel/alpha_rel;
    spect_data(i,3)=1/alpha_rel;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    theta_abs = i_psd_bp_abs(kTheta);
    alpha_abs = i_psd_bp_abs(kAlpha);
    beta_abs = i_psd_bp_abs(kBeta);
    
    spect_data(i,4)=beta_abs/(alpha_abs + theta_abs);
    spect_data(i,5)=beta_abs/alpha_abs;
    spect_data(i,6)=1/alpha_abs;
    spect_data(i,7)=theta_abs/alpha_abs;
    
    clear('i_*', 'theta', 'alpha', 'beta');
end

%% Metadata
spect_labels(1)= {'eind_b_ta_rel'};
spect_labels(2)= {'eind_b_a_rel'};
spect_labels(3)= {'eind_1_a_rel'};

spect_labels(4)= {'eind_b_ta_abs'};
spect_labels(5)= {'eind_b_a_abs'};
spect_labels(6)= {'eind_1_a_abs'};
spect_labels(7)= {'eind_t_a_abs'};

% Initialize Info
Info.Variable = spect_labels;
Info.Type = cell(1,length(spect_labels));
Info.Unit = cell(1,length(spect_labels));
Info.Values = cell(1,length(spect_labels));

% Assign data to Info
Info.Type(:) = {'numeric'};
Info.Unit(:) = {'dimensionless'};
Info.Values(:) = {'NA'};
Info.Description(1) = {'EEG PSD engagement index: beta/(alpha+theta) (rel)'};
Info.Description(2) = {'EEG PSD engagement index: beta/alpha (rel)'};
Info.Description(3) = {'EEG PSD engagement index: 1/alpha (rel)'};
Info.Description(4) = {'EEG PSD engagement index: beta/(alpha+theta) (abs)'};
Info.Description(5) = {'EEG PSD engagement index: beta/alpha (abs)'};
Info.Description(6) = {'EEG PSD engagement index: 1/alpha (abs)'};
Info.Description(7) = {'EEG PSD engagement index: theta/alpha (abs)'};