function [rejval, rejbin] = reject_component_spectrum(EEG, varargin)
% REJECT_COMPONENT_SPECTRUM reject components based on spectral properties.
%
% Syntax:
%   [rejval, rejbin] = reject_component_spectrum(EEG, ...)
% 
% Inputs:
%   'EEG'           struct, EEG-file to process
% 
%   varargin        Keyword-value pairs
%   Keyword         Type, description, values
%   'frame_size'    integer, samples/bin (if EEG epoched, uses epochs instead!)
%                   default = EEG.srate
%   'thr'           vector, Spectral thresholds per frequency band
%                   default = [-5, 5; -3, 3]
%   'freq_lims'     vector, frequency bands in Hz, limit values are inclusive.
%                   default = [4, 5; 10, 15]
%   'comp_list'     vector, list of compononents to process (1:N)
%                   default = 1:numel(EEG.icachansind)
%   'method'        string, "fft" | "multitaper"
%                   default = "multitaper"
% 
% Outputs:
%   'rejval'        vector [1:numel(comp_list)], number bins x bands > threshold
%   'rejbin'        logical, bins exceeding std thresholds as a logical matrix, 
%                   with 3rd dimension if more than 1 frequency band given
%
%
% Version history
% 8.12.2014 Created (Jari Torniainen, FIOH)
% 20.11.2015 updated (B. Cowley, FIOH)
%
% Copyright 2014- Jari Torniainen, jari.torniainen@ttl.fi
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    %% Checks
    % Parse input arguments and set varargin defaults
    p = inputParser;
    p.addRequired('EEG', @isstruct);
    
    p.addParameter('frame_size', EEG.srate, @isnumeric);
    p.addParameter('thr', [-5 5; -3 3], @isnumeric);
    p.addParameter('freq_lims', [2 6; 20 30], @isnumeric);
    p.addParameter('comp_list', 1:numel(EEG.icachansind), @isnumeric);
    p.addParameter('method', 'multitaper', @ischar);
    
    p.parse(EEG, varargin{:});
    Arg = p.Results;
    

    %% bin data, calculate spectrum, compare with thresholds
    if ismatrix(EEG.data)
        EEG = eeg_regepochs(EEG, 'recurrence', Arg.frame_size / EEG.srate);
    else
        fprintf(1, 'Using existing epochs!');
    end

    com = eeg_getdatact(EEG, 'component', Arg.comp_list);
    [specdata, freqs] = calculate_spectrum(com, EEG.srate, Arg.method);
    rejbin = [];

    for f =  1:size(Arg.freq_lims, 1)
        freq_idx = Arg.freq_lims(f, 1) >= freqs & freqs <= Arg.freq_lims(f, 2);
        tmpdata = specdata(:, freq_idx, :);
        tmpval = tmpdata < Arg.thr(f,1) | tmpdata > Arg.thr(f,2);
        rejbin = cat(3, rejbin, squeeze(sum(tmpval, 2) > 0));
    end

    rejval = sum(sum(rejbin, 3), 2);
end

% Auxiliary function copied from EEGLAB function pop_rejspec.m
function [specdata, freqs] = calculate_spectrum(data, srate, method)

    if strcmpi(method, 'fft')  % FFT (doesn't work very well)
        sizewin = size(data, 2);
        freqs = srate*[1, sizewin] / sizewin / 2;
        specdata = fft(data - repmat(mean(data, 2), [1, size(data, 2), 1]), ...
                         sizewin, 2);
        specdata = specdata(:, 2:sizewin / 2 + 1, :);
        specdata = 10 * log10(abs(specdata).^2);
        specdata  = specdata - repmat(mean(specdata, 3), [1, 1, size(data, 3)]);

    elseif strcmpi(method, 'multitaper')  % Multitaper
        if ~license('checkout', 'Signal_Toolbox')
            error('Your PEASANTLAB does not have signal processing toolbox!');
        end
        [~, freqs] = pmtm(data(1, :, 1), [], [], srate);
        fprintf('Computing spectrum (using slepian tapers; done only once):\n');
        for idx = 1:size(data, 1)
            fprintf('%d ', idx);    
            for idx_tr = 1:size(data, 3)
                [tmpspec(idx, :, idx_tr), freqs] =...
                    pmtm(data(idx, :, idx_tr), [], [], srate); %#ok<AGROW>
            end
        end
        tmpspec  = 10 * log(tmpspec);
        specdata  = tmpspec - repmat(mean(tmpspec, 3), [1, 1, size(data, 3)]);

    else  % Other
        fprintf(1, 'Method '' %s'' not implemented yet!\n', method);
        specdata = [];
    end

end
