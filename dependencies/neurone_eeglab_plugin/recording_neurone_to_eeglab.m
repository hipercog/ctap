function EEG = recording_neurone_to_eeglab(recording)
%RECORDING_NEURONE_TO_EEGLAB Convert recording structure to EEGLab EEG data structure.
%
%  Input  : A recording structure from module_read_neurone.
%  Output : An EEGLab EEG data structure.

%  Example: recording = module_read_neurone('/NeurOne/data_01/')
%           EEG = recording_neurone_to_eeglab(recording)
%
%  Dependencies: none
%
%  ========================================================================
%  COPYRIGHT NOTICE
%  ========================================================================
%  Copyright 2012 - 
%  Andreas Henelius (andreas.henelius@ttl.fi)
%  Finnish Institute of Occupational Health (http://www.ttl.fi/)
%  and
%  Mikko Venäläinen, Mega Electronics Ltd
%  (mega@megaemg.com, http://www.megaemg.com)
%  ========================================================================
%  This file is part of NeurOne EEGLab Plugin.
% 
%  NeurOne EEGLab Plugin is free software: you can redistribute it
%  and/or modify it under the terms of the GNU General Public License as
%  published by the Free Software Foundation, either version 3 of the
%  License, or (at your option) any later version.
%
%  NeurOne EEGLab Plugin is distributed in the hope that it will be
%  useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with NeurOne EEGLab Plugin.
%  If not, see <http://www.gnu.org/licenses/>.
%  ========================================================================
%  See version_history.txt for details.
%  ========================================================================

EEG = {};

nChannels = numel(recording.signalTypes);
nSamples  = recording.properties.nSamplesPerChannel;

% =========================================================================
% Collect the data
% =========================================================================

EEG.data = zeros(nChannels, nSamples);

for i = 1:numel(recording.signalTypes)
    EEG.data(i,:) = recording.signal.(recording.signalTypes{i}).data;
end

% =========================================================================
% Collect the events
% =========================================================================

nEvents   = numel(recording.markers.type);
EEG.event = {};

for i = 1:nEvents
    EEG.event(i).type     = strtrim(num2str(recording.markers.code(i)));
    EEG.event(i).latency  = recording.markers.index(i);
    EEG.event(i).duration = 0;
end

% =========================================================================
% Create EEGLab EEG structure
% =========================================================================
% General fields
EEG.srate  = recording.properties.samplingRate;
EEG.pnts   = nSamples;
EEG.xmin   = 0;
EEG.xmax   =(EEG.pnts-1) / EEG.srate;
EEG.trials = 1;
EEG.nbchan = nChannels;
EEG.ref    = 'common';

% Description fields
EEG.subject  = recording.Session.TablePerson.PersonID;
% EEG.setname  = recording.Session.TableSession.ProtocolName;
EEG.setname  = [recording.Session.TablePerson.PersonID '_' recording.DataSetSession.TableSession.ExamCode];
EEG.comments = sprintf('Protocol %s measured on %s with device: %s %s'...
    , EEG.setname...
    , recording.properties.start.time...
	, recording.device.type...
    , recording.device.version);

EEG.filepath = '';
EEG.filename = '';

% Set channel location information
EEG.chanlocs = struct('labels', recording.signalTypes);

% Additional fields
EEG.icawinv    = [];
EEG.icaweights = [];
EEG.icasphere  = [];
EEG.icaact     = [];

% =========================================================================
% EEGLab data consistency check
% =========================================================================

EEG = eeg_checkset(EEG);
EEG = eeg_checkset(EEG, 'eventconsistency');
EEG = eeg_checkset(EEG, 'makeur');

% =========================================================================
end
