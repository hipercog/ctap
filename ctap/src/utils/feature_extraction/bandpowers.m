function [bp, labels, units] = bandpowers(psdArray, freq_res, bands, varargin)
% BANDPOWERS -Relative band powers from power spectra (single channel)
%
% Description:
%   Sums up PSD frequency components over desired bands and divides the
%   result with total PSD power. Calculations are done separately for each
%   PSD.
%
% Syntax:
%   [bp] = bandpowers(psdArray, freq_res, bands, varargin);
%
% Inputs:
%   psdArray    ncs-by-psdlen double, Power spectrum densities to be analyzed
%   freq_res    [1,1] double, Frequency resolution of the psdArray
%   bands       [k,2] double, Frequency bands in Hz
%                              fmin -> column 1, fmax-> column 2
%   varargin    Keyword-value pairs
%   Keyword             Type, description, values
%   'integrationMethod' string, Integration method to use when summing up
%                       band powers, default: 'trapez'
%                       'trapez' = trapezoidal integration using trapz()
%                       'sum' = plain sum
%   'valueType'         string, Type of power values, relative or absolute 
%                       powers, default: 'relative'
%                       'relative' = relative band power i.e.
%                       power_at_band_i/total_spectral_power
%                       'absolute' = absolute band power i.e. power at band
%                       i as is
%
% Outputs:
%   bp      [ncs,k] double, PSD band powers for each calculation
%                                segment and frequency band
%   labels  [1,k] cell of strings, PSD band power labels
%   units   [1,k] cell of strings, PSD band power units
%
% Jussi Korpela, 22.12.2006, TTL (last revision)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameter values
% Field names of 'Arg' can be used as keywords.
Arg.integrationMethod = 'trapez'; %'trapez','sum'
Arg.valueType = 'relative'; %'relative','absolute'

%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end

%% Initialize variables
bp = NaN(size(psdArray, 1), size(bands, 1));

%% Calculate relative band powers

% Total spectral power
if strcmp(Arg.integrationMethod,'trapez')
    bp_tot = freq_res * trapz(psdArray,2);
elseif strcmp(Arg.integrationMethod,'sum')
    bp_tot = freq_res * sum(psdArray, 2);
else
    msg = ['Unknown integration method. Found ''',...
        Arg.integrationMethod,...
        ''' but only ''trapez'' and ''sum'' allowed'];
    error('bandpowers:unknownVararginValue',msg);
end  

% Subband powers
for k = 1:size(bands, 1)
        i_min = round(bands(k,1)/freq_res);
        i_max = round(bands(k,2)/freq_res);
        
        if strcmp(Arg.integrationMethod,'trapez')
            if strcmp(Arg.valueType,'relative')       
                bp(:,k) = ((freq_res * trapz(psdArray(:, i_min:i_max),2))./bp_tot)';
            elseif strcmp(Arg.valueType,'absolute')
                bp(:,k) = (freq_res * trapz(psdArray(:, i_min:i_max),2))';           
            else
                msg = ['Unknown value ', Arg.valueType...
                    , ' for varargin ''valueType''. Allowed values: ''relative'' or ''absolute''.'];
                error('bandpowers:unknownValueType', msg);
            end

        elseif strcmp(Arg.integrationMethod,'sum')
            if strcmp(Arg.valueType,'relative')
                bp(:,k) = (freq_res * sum(psdArray(:, i_min:i_max), 2))./bp_tot;
            elseif strcmp(Arg.valueType,'absolute')
                bp(:,k) = freq_res * sum(psdArray(:, i_min:i_max), 2);
            else
                msg = ['Unknown value ', Arg.valueType...
                    , ' for varargin ''valueType''. Allowed values: ''relative'' or ''absolute''.'];
                error('bandpowers:unknownValueType', msg);
            end
        else
           msg = ['Unknown integration method. Found ''',...
                    Arg.integrationMethod,...
                    ''' but only ''trapez'' and ''sum'' allowed'];
           error('bandpowers:unknownVararginValue',msg);
        end
        
        
        % labels and units
        if strcmp(Arg.valueType,'relative')       
            labels(k) = {['P',num2varstr(bands(k,1)),'_',num2varstr(bands(k,2)),'_rel']};
            units(k) = {'nu'};
        elseif strcmp(Arg.valueType,'absolute')
            labels(k) = {['P',num2varstr(bands(k,1)),'_',num2varstr(bands(k,2)),'_abs']};
            units(k) = {'power'};
        else
            msg = ['Unknown value ', Arg.valueType,' for varargin ''valueType''. Allowed values: ''relative'' or ''absolute''.'];
            error('bandpowers:unknownValueType', msg);
        end
        
        clear('i_min', 'i_max');
end