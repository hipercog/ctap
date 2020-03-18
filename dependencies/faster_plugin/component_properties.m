function list_properties=component_properties(EEG,blink_chans,lpf_band,comps)
%% COMPONENT_PROPERTIES computes metrics of ICA component goodness
%   edited by Ben Cowley, 28.06.2014, to allow specification of which
%   components to select for metric calculations
%
% Copyright (C) 2010 Hugh Nolan, Robert Whelan and Richard Reilly, Trinity College Dublin,
% Ireland
% nolanhu@tcd.ie, robert.whelan@tcd.ie
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


% checks and balances
if isempty(EEG.icaweights)
    fprintf('No ICA data.\n');
    return;
end

comps = comps(:);

if ~exist('lpf_band','var') || length(lpf_band)~=2 || ~any(lpf_band)
    ignore_lpf=1;
else
    ignore_lpf=0;
end

delete_activations_after=0;
if ~isfield(EEG,'icaact') || isempty(EEG.icaact)
    delete_activations_after=1;
    EEG.icaact = eeg_getica(EEG);
end

% begin to compute measures
numcom = numel(comps);
% numeps=size(EEG.icaact,2);
% spectra=zeros(numcom,numeps);

for u = 1:numcom
    [spectra(u,:), freqs] = pwelch(EEG.icaact(comps(u),:),[],[],(EEG.srate),EEG.srate); %#ok<AGROW>
end

list_properties = zeros(numcom, 5); % 5 measurements are made.
a_msr = 0;
for u = 1:numcom
    % TEMPORAL PROPERTIES

    % 1 Median gradient value, for high frequency stuff
    a_msr = 1;
    list_properties(u, a_msr) = median(diff(EEG.icaact(comps(u),:)));

    % 2 Mean slope around the LPF band (spectral)
    a_msr = a_msr + 1;
    if ignore_lpf
        list_properties(u, a_msr) = 0;
    else
        list_properties(u, a_msr) = mean(diff(10*log10(spectra(u,...
            find(freqs>=lpf_band(1),1):find(freqs<=lpf_band(2),1,'last')))));
    end

    % SPATIAL PROPERTIES

    % 3 Kurtosis of spatial map (if v peaky, i.e. one or two points high
    % and everywhere else low, then it's probably noise on a single
    % channel)
    a_msr = a_msr + 1;
    list_properties(u, a_msr) = kurt(EEG.icawinv(:,comps(u)));

    % OTHER PROPERTIES

    % 4 Hurst exponent
    a_msr = a_msr + 1;
    list_properties(u, a_msr) = hurst_exponent(EEG.icaact(comps(u),:));

    % 5 Eyeblink correlations
    a_msr = a_msr + 1;
    if (exist('blink_chans','var') && ~isempty(blink_chans))
        x=zeros(length(blink_chans),1);
        for v = 1:length(blink_chans)
            if ~(max(EEG.data(blink_chans(v), :)) == 0 &&...
                    min(EEG.data(blink_chans(v), :)) == 0)
                f = corrcoef(EEG.icaact(comps(u),:),EEG.data(blink_chans(v),:));
                x(v) = abs(f(1,2));
            else
                x(v) = v;
            end
        end
        list_properties(u, a_msr) = max(x);
    end
end

for u = 1:a_msr
    list_properties(isnan(list_properties(:, u)), u) = nanmean(list_properties(:, u));
    list_properties(:, u) = list_properties(:, u) - median(list_properties(:, u));
end

if delete_activations_after
    EEG.icaact=[];
end