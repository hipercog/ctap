function figH = ctap_eeg_compare_ERP(EEG1, EEG2, eventTypeString, varargin)
%CTAP_EEG_COMPARE_ERP - A function to compare ERPs
%
% Description:
%   
%
% Algorithm:
%   * How the function achieves its results?
%
% Syntax:
%   figH = ctap_eeg_compare_ERP(EEG1, EEG2, eventTypeString, ...)
%
% Inputs:
%   'EEG1'              struct, first EEG structure to compare
%   'EEG2'              struct, second EEG structure to compare
%   'eventTypeString'   string, type of event to build ERP over
%
%   varargin    Keyword-value pairs
%   Keyword         Type, description, values
%   'epochWindow'       vector, [min max] second values for ERP epoch window
%                       default = [-0.5, 0.5]
%   'rmbaseWindow'      vector, [min max] second values for baseline of ERP
%                       default = [-0.5, 0]
%   'channels'          cell string array, channel names to plot
%                       default = {EEG1.chanlocs.labels}
%   'idArr'             cell string array, identifier names for EEG structs
%                       default = {'EEG1','EEG2'}
%   'visible'           string, set figure 'Visible' property 'on' or 'off'
%                       default = 'on'
%
% Outputs:
%   'figH'              integer, figure handle
%
%
% Assumptions:
%
% References:
%
% Example: These lines will be shown as the example
%
% Notes: Include some good-to-know information
%
% See also: plot_epoched_EEG, pop_epoch, pop_rmbase
%
%
% Copyright(c) 2015 FIOH:
% Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('EEG1', @isstruct);
p.addRequired('EEG2', @isstruct);
p.addRequired('eventTypeString', @iscellstr); %event to epoch around
p.addParameter('epochWindow', [-0.5, 0.5], @isnumeric); %in sec
p.addParameter('rmbaseWindow', [-0.5, 0], @isnumeric); %in sec
p.addParameter('channels', {EEG1.chanlocs.labels}, @iscellstr); %in sec
p.addParameter('idArr', {'EEG1','EEG2'}, @iscellstr); %in sec
p.addParameter('visible', 'on', @isstr); %in sec
p.addParameter('reverseYAxis', true, @islogical);

p.parse(EEG1, EEG2, eventTypeString, varargin{:});
Arg = p.Results;


%% Epoch
EEG1 = pop_epoch( EEG1, eventTypeString, Arg.epochWindow);
EEG1 = pop_rmbase( EEG1, 1000*Arg.rmbaseWindow);

EEG2 = pop_epoch( EEG2, eventTypeString, Arg.epochWindow);
EEG2 = pop_rmbase( EEG2, 1000*Arg.rmbaseWindow);


%% Plot
figH = plot_epoched_EEG({EEG1, EEG2},...
                        'channels', Arg.channels,...
                        'idArr', Arg.idArr,...
                        'reverseYAxis', Arg.reverseYAxis,...
                        'visible', Arg.visible);
