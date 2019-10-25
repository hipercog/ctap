function eeglab2edf(EEG, savename, varargin)
%EEGLAB2EDF - convert a given EEGLAB structure to EDF format and save
%
% Description:
%   converts an EEGLAB struct to EDF-format and saves to a file
%
% Syntax:
%   eeglab2edf(EEG, savename)
%
% Inputs:
%   'EEG'       struct, EEGLAB structure
%   'savename'  string, path to directory and name of file
% 
% varargin      Keyword-value pairs
%   'chan'      scalar, channel indices to extract as EDF
%               Default = 1:EEG.nbchan
%   'evnames'   cell array, fieldnames of EEG.event struct fields to include 
%               in EDF header.annotation field
%               Default = {}
%   
% Outputs:
%
%
% See also:  lab_write_edf, eeglab2leda
%
% Copyright(c) 2019:
% Benjamin Cowley (Ben.Cowley@helsinki.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('EEG', @isstruct)
p.addRequired('savename', @ischar)

p.addParameter('chan', 1:EEG.nbchan, @isscalar)
p.addParameter('evnames', {}, @iscell)

p.parse(EEG, savename, varargin{:})
Arg = p.Results;

if any(Arg.chan < 1) || any(Arg.chan > EEG.nbchan)
    error('eeglab2edf:badparam', 'Badly chosen channel index %d. Aborting'...
        , Arg.chan);
end

%% BUILD HEADER STRUCTURE
header = struct;
%LAB_WRITE_EDF VERSION
header.numtimeframes = EEG.pnts;
header.samplingrate = EEG.srate;
header.numchannels = numel(Arg.chan);
header.channels = {EEG.chanlocs.labels};
header.ID = EEG.setname;
if isfield(EEG, 'subject')
    header.subject.ID = EEG.subject;
else
    header.subject.ID = EEG.setname;
end
header.events.POS = [EEG.event.latency];
header.events.TYP = {EEG.event.type};
if isfield(EEG.event, 'duration')
    header.events.DUR = [EEG.event.duration];
else
    header.events.DUR = zeros(1, numel(EEG.event));
end

% add dyanmic event fields
header.events =...
    add_dyn_fields(EEG.event, header.events, Arg.evnames, 'as_array', false);


%% SAVE EDF FILE USING SaveEDF.m
lab_write_edf(savename, EEG.data(Arg.chan, :), header)


%SAVEEDF VERSION
% header.patient.ID = EEG.setname;
% header.duration = double(round(EEG.xmax));
% header.samplerate = EEG.srate;
% header.labels = {EEG.chanlocs.labels};
% 
% header.annotation.event = {EEG.event.type};
% header.annotation.starttime = [EEG.event.latency];
% header.annotation.duration = [EEG.event.duration];

% SaveEDF(savename, EEG.data(Arg.chan, :)', header)

end