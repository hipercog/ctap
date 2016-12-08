function [artICs, horiz, verti, blink, disco] = ctapeeg_ADJUST(EEG, varargin)
%CTAPEEG_ADJUST - Automatic EEG artifact Detector with Joint Use of Spatial 
%               and Temporal features
%
% Usage:
%   >> [artICs] = ctapeeg_ADJUST(EEG);
%
% Inputs:
%   EEG - current dataset structure or structure array (has to be epoched)
% 
% Varargin
%   'detect'    cell, array of strings indexing the artefacts to target:
%               'horiz' - Horizontal eye movement
%               'verti' - Vertical eye movement
%               'blink' - blinks
%               'disco' - Discontinuities
%   'logidx'    boolean, 1=output as logical, 0=output as index values,
%               default = 1
%   'icomps'    vector, indices of ICs, default = 1:size(EEG.icawinv,1)
%
% Outputs:
%   artICs - List of artifacted ICs
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% ADJUST
% Automatic EEG artifact Detector with Joint Use of Spatial and Temporal
% features
% Developed May2007 - October2008
% Andrea Mognon and Marco Buiatti
% CIMeC - Center for Mind/Brain Science, University of Trento
% Last update: 26/11/2009 by Andrea Mognon
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% Reference paper:
% Mognon, Jovicich, Bruzzone, Buiatti, ADJUST: An Automatic EEG artifact 
% Detector based on the Joint Use of Spatial and Temporal features. Reviewed
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (C) 2009 Andrea Mognon and Marco Buiatti, 
% Center for Mind/Brain Sciences, University of Trento, Italy
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VERSIONS LOG
% 
% 
%   THIS VERSION ADAPTED BY BENJAMIN COWLEY, MAY 2013
%
% 
% V2 (07 OCTOBER 2010) - by Andrea Mognon
% Added input 'nchannels' to compute_SAD and compute_SED_NOnorm;
% this is useful to differentiate the number of ICs (n) and the number of
% sensors (nchannels);
% bug reported by Guido Hesselman on October, 1 2010.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    

%% Check the paramters
p = inputParser;
p.addRequired('EEG', @isstruct);
p.addParameter('detect', {'horiz' 'verti' 'blink' 'disco'}, @iscell);
p.addParameter('logidx', 1, @islogical);
p.addParameter('icomps', 1:size(EEG.icawinv,1), @isnumeric);
% additional parameters can be defined here
p.parse(EEG, varargin{:});
Arg = p.Results;


%% Initialise
% ----------------------------------------------------
% |  Initial message to user:                        |
% ----------------------------------------------------
fprintf('ADJUST detecting bad ICA components in dataset: %s\n', EEG.filename)
fprintf('Extracting features for: %s\n', cellstr2str(Arg.detect, 'sep', '    '))
% ----------------------------------------------------
% |  Collect useful data from EEG structure          |
% ----------------------------------------------------
%number of time points = size(EEG.data,2);
numICs = numel(Arg.icomps);
if length(size(EEG.data)) == 3
    num_epoch = size(EEG.data,3);
else
    num_epoch = 1;
end

detect = ismember({'horiz' 'verti' 'blink' 'disco'}, Arg.detect);
horiz = false(1, numICs);
verti = false(1, numICs);
blink = false(1, numICs);
disco = false(1, numICs);
artICs = false(1, numICs);


%% Check the presence of ICA activations
if isempty(EEG.icaact)
    disp('EEG.icaact not present. Recomputed from data.');
    EEG.icaact = eeg_getica(EEG);
end

topografie = EEG.icawinv'; %computes IC topographies


%% Topographies and time courses normalization
disp('Normalizing topographies...Scaling time courses...')

for i = 1:size(EEG.icawinv, 2) % number of ICs
    ScalingFactor = norm(topografie(i,:));
    topografie(i,:) = topografie(i,:) / ScalingFactor;
    if length(size(EEG.data)) == 3
        EEG.icaact(i,:,:) = ScalingFactor * EEG.icaact(i,:,:);
    else
        EEG.icaact(i,:) = ScalingFactor * EEG.icaact(i,:);
    end
end


%% Feature extraction

%SED - Spatial Eye Difference
disp('SED - Spatial Eye Difference...');
[SED, med_L, med_R] = computeSED_NOnorm(...
    topografie,...
    EEG.chanlocs(ismember({EEG.chanlocs.type}, {'EEG' 'EOG'})),...
    size(EEG.icawinv,2)); 

%SAD - Spatial Average Difference
disp('SAD - Spatial Average Difference...');
[SAD, var_front, var_back, ~, ~] = computeSAD(...
    topografie,...
    EEG.chanlocs(ismember({EEG.chanlocs.type}, {'EEG' 'EOG'})),...
    size(EEG.icawinv,2), size(EEG.icawinv,1));

%SVD - Spatial Variance Difference between front zone and back zone
diff_var = var_front - var_back;

%epoch dynamic range, variance and kurtosis
K = zeros(num_epoch, size(EEG.icawinv, 2)); %kurtosis
Vmax = zeros(num_epoch, size(EEG.icawinv, 2)); %variance
disp('Computing variance and kurtosis of all epochs...')

for i = 1:size(EEG.icawinv, 2) % number of ICs
    for j = 1:num_epoch
        Vmax(j,i) = var(EEG.icaact(i,:,j));
        %K(j,i) = kurtosis(EEG.icaact(i,:,j)); %stats toolbox
        K(j,i) = kurt(EEG.icaact(i,:,j)); %eeglab
    end
end

%MEV - Maximum Epoch Variance
disp('Maximum epoch variance...')
maxvar = zeros(1, size(EEG.icawinv,2));
meanvar = zeros(1, size(EEG.icawinv,2));

for i = 1:size(EEG.icawinv,2)
    if num_epoch>100
        maxvar(1,i) = trim_and_max(Vmax(:,i)');
        meanvar(1,i) = trim_and_mean(Vmax(:,i)');
    else 
        maxvar(1,i) = max(Vmax(:,i));
        meanvar(1,i) = mean(Vmax(:,i));
    end
end

% MEV in reviewed formulation:
nuovaV = maxvar ./ meanvar;


%% Thresholds computation
disp('Computing EM thresholds...')
if detect(1)
    thr_SED = EM(SED);
end
if any(detect([1 2 4]))
    thr_V = EM(nuovaV);
end
if any(detect([2 3]))
    thr_SAD = EM(SAD);
end
if detect(3)
    disp('Temporal Kurtosis...')
    meanK = zeros(1, size(EEG.icawinv, 2));
    for i = 1:size(EEG.icawinv,2)
        if num_epoch > 100
            meanK(1,i) = trim_and_mean(K(:,i)); 
        else
            meanK(1,i) = mean(K(:,i));
        end
    end
    % Thresholds computation
    thr_K = EM(meanK);
end
if detect(4)
    %GDSF - General Discontinuity Spatial Feature
    disp('GDSF - General Discontinuity Spatial Feature...');
    GDSF = compute_GD_feat(...
        topografie,...
        EEG.chanlocs(ismember({EEG.chanlocs.type}, {'EEG' 'EOG'})),...
        size(EEG.icawinv,2)...
        );
    thr_GDSF = EM(GDSF);
end


%% Horizontal eye movements (HEM)
if detect(1)
    disp('Evaluating Horizontal movements...')
    horiz = (SED >= thr_SED) & (med_L.*med_R < 0) & (nuovaV >= thr_V);
    artICs = horiz;
end


%% Vertical eye movements (VEM)
if detect(2)
    disp('Evaluating Vertical movements...')
    verti = (SAD >= thr_SAD) & (med_L.*med_R > 0) & (diff_var > 0) &...
        (nuovaV >= thr_V);
    artICs = artICs | verti;
end


%% Eye Blink (EB)
if detect(3)
    disp('Evaluating Blinks...')
    blink = (SAD >= thr_SAD) & (med_L.*med_R > 0) & (meanK >= thr_K) &...
        (diff_var > 0);
    artICs = artICs | blink;
end


%% Generic Discontinuities (GD)
if detect(4)
    disp('Evaluating Discontinuities...')
    disco = (GDSF >= thr_GDSF) & (nuovaV >= thr_V);
    artICs = artICs | disco;
end


%% compute output variables in index terms - artifact ICs
if ~Arg.logidx
    horiz = find(horiz);
    verti = find(verti);
    blink = find(blink);
    disco = find(disco);
    artICs = find( artICs )';
end

end
