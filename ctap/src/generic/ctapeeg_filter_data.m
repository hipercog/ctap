function [EEG, varargout] = ctapeeg_filter_data(EEG, varargin)
%CTAPEEG_FILTER_DATA Filtering the dataset - by default performs two
% filters in turn, highpass and then lowpass.
%
% SYNTAX
%   EEG = ctapeeg_filter_data(EEG, varargin)
%
% INPUT
%   'EEG'       :   eeglab data struct
%
% VARARGIN
%   'detrend'   : detrend EEG. Set as 'before' to detrend before filtering,
%                 or set as 'after' to detrend after filtering.
%                 Default=no detrending.
%   'filt'      : use EEGLAB's IIR filter. Control behaviour with 1d vector, 
%                 e.g. high=[x NaN], low=[NaN y], band(high then low)=[x y], 
%                 Default=[0.5 45]
%               OR pass a predesigned filter readable by Matlab's filter()
%                 function (use e.g. 'designfilt' or FDATool).
%
%   IF using Matlab's filter() function, use the following parameters
%   'design'    : if passing a pre-designed filter, pass design parameters
%                   for the history struct
%
%   IF using the EEGLAB filtering, use the following parameters
%   'order'     : filter order, 
%                   default=3*fix(srate/locutoff)
%   'notch'     : use a notch filter (vector elements must be 0<x>Nyquist),
%                   default=false
%   'causal'    : use causal instead of fir filtering, 
%                   default=false
%   'firtype'   : FIR filter design method, use this to override default
%                 choice of IIR; note: 'fir1s' is preferred
%                   default=IIR filter is used instead
%   'fft'       : use FFT instead of FIR, 
%                   default=false
%   'pltfrq'    : plot the frequency response of filter, 
%                   default=false
%
% OUTPUT
%   'EEG'       : struct, modified input EEG
% VARARGOUT
%   {1}         : struct, the complete list of arguments actually used
%   {2}         : 
%
% NOTE
%   pop_eegfilt() will crash silently if any contiguous data range between
%   two consecutive boundary events is shorter than the filter length. Look
%   for a line "Filter error: continuous data portion too narrow 
%   (DC removed if highpass only)".
%
%   pop_eegfilt() also crashes silently if the latency of the first boundary
%   event is less than 1.49 and 'firtype' is mispelled. Oddly enough, the
%   if correct options 'firls' or 'fir1' are used for 'firtype', the 
%   filtering succeeds and does not filter the range from first sample to 
%   first boundary event! 
%
% CALLS    eeglab functions
%
% Version History:
% 20.10.2014 Created (Benjamin Cowley, FIOH)
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


Arg = sbf_check_input(); % parse the varargin, set defaults


%% detrend if requested
if strcmpi(Arg.detrend,'before')
    for i = 1:EEG.nbchan
        EEG.data(i,:) = detrend(EEG.data(i,:));
    end
end


%% APPLY FILTER
% is it a vector of band limits, or a pre-designed filter?
if isnumeric(Arg.filt)% use the EEGLAB-provided filter function
    
    % default choice is an IIR zero-phase filter
    if isempty(Arg.firtype)
        if Arg.notch
            EEG = pop_iirfilt(EEG, Arg.filt(1), Arg.filt(2), ...
                Arg.order, 1, Arg.causal);
            % from EEGLAB iirfilt plugin
        else
            % check if the limits were specified before running the filter.
            if ~isnan(Arg.filt(1)) && Arg.filt(1)~=0
                EEG = pop_iirfilt(EEG, Arg.filt(1), 0, ...
                    Arg.order, 0, Arg.causal);
            end
            if ~isnan(Arg.filt(2)) && Arg.filt(2)~=0
                EEG = pop_iirfilt(EEG, 0, Arg.filt(2), ...
                    Arg.order, 0, Arg.causal);
            end
        end
    else
        if Arg.notch
            EEG = pop_eegfilt(EEG, Arg.filt(1), Arg.filt(2),...
                Arg.order, 1, Arg.fft, Arg.pltfrq, Arg.firtype, Arg.causal);
        else
            % check if the limits were specified before running the filter.
            if ~isnan(Arg.filt(1)) && Arg.filt(1)~=0
                EEG = pop_eegfilt(EEG, Arg.filt(1), 0,...
                    Arg.order, 0, Arg.fft, Arg.pltfrq, Arg.firtype, Arg.causal);
            end
            if ~isnan(Arg.filt(2)) && Arg.filt(2)~=0
                EEG = pop_eegfilt(EEG, 0, Arg.filt(2),...
                    Arg.order, 0, Arg.fft, Arg.pltfrq, Arg.firtype, Arg.causal);
            end
        end
    end
else
    % Apply one channel at a time
    for i = 1:EEG.nbchan
        if EEG.trials>1
            EEG.data(i,:,:) = filter(Arg.filt,squeeze(EEG.data(i,:,:))')';
        else
            EEG.data(i,:) = filter(Arg.filt,EEG.data(i,:));
        end
    end
end


%% detrend if requested
if strcmpi(Arg.detrend,'after')
    for i = 1:EEG.nbchan
        EEG.data(i,:) = detrend(EEG.data(i,:));
    end
end

varargout{1} = Arg;


%% Sub-functions
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
        Arg.detrend = '';
        % filter-specific parameters
        try Arg.filt = vargs.filt;
        catch
            Arg.filt = [0.5 45];
        end
        if isnumeric(Arg.filt)% use the EEGLAB-provided filter function
            Arg.order = [];
            Arg.causal = false;
            Arg.notch = false;
            try vargs.firtype;
                Arg.firtype = vargs.firtype;
                Arg.fft = false;
                Arg.pltfrq = false;
            catch
                Arg.firtype = [];
            end
        else
            Arg.design = 'No design given';
        end
        
        % Arg fields are canonical, vargs data is canonical: intersect-join
        Arg = intersect_struct(Arg, vargs);
    end

end % ctapeeg_filter_data()
