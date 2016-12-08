function varargout = gui_load_neurone(varargin)
%GUI_LOAD_NEURONE   GUI for reading data from a Mega NeurOne Device.
%
% Used together with pop_readneurone.m.
% 
% See also: pop_readneurone.m
%
%  ========================================================================
%  COPYRIGHT NOTICE
%  ========================================================================
%  Copyright 2012 - 
%  Andreas Henelius (andreas.henelius@ttl.fi)
%  Finnish Institute of Occupational Health (http://www.ttl.fi/)
%  and
%  Mega Electronics Ltd (mega@megaemg.com, http://www.megaemg.com)
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

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @gui_load_neurone_OpeningFcn, ...
    'gui_OutputFcn',  @gui_load_neurone_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before gui_load_neurone is made visible.
function gui_load_neurone_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to gui_load_neurone (see VARARGIN)

axes(handles.mega_logo);
axis off

axes(handles.neurone_logo);
axis off

% Load logos
bgcolor     = [1 1 1];
megaLogo    = imread('mega_gradient_edit.png','BackgroundColor', bgcolor);
neuroneLogo = imread('neurone_logo.png','BackgroundColor', bgcolor);

axes(handles.mega_logo);
image(megaLogo)
axis off
axis image

axes(handles.neurone_logo);
image(neuroneLogo)
axis off
axis image

% Parse input arguments
p = inputParser;
p.addOptional('dataPath', @ischar);
p.parse(varargin{:});
Arg = p.Results;

% Choose default command line output for gui_load_neurone
handles.output = hObject;

% Store the input folder given as argument
if isfield(Arg, 'dataPath')
    handles.dataPath = Arg.dataPath;
end

% Update handles structure
guidata(hObject, handles);


%% Read the channels for the selected recording

% read the header so that we get the channel names
recording = module_read_neurone(handles.dataPath, 'headerOnly', true);

% Get a list of all files in the chosen directory
channels_eeg   = {};
channels_eog   = {};
channels_other = {};

for i = 1:numel(recording.properties.channellayout)
    name = recording.properties.channellayout(i).name;
    
    % Determine in which list the channel goes
    % A probable EEG channnel
    if regexpi(name, '\w{1,3}\d')
        channels_eeg = [channels_eeg ; {name}];
    elseif (numel(name) == 2) & regexpi(name, '^\w{2}')
        channels_eeg = [channels_eeg ; {name}];
    elseif (numel(regexpi(name, 'up')) | numel(regexpi(name, 'down')) | numel(regexpi(name, 'left')) | numel(regexpi(name, 'right')) | numel(regexpi(name, 'eog')))
        channels_eog = [channels_eog ; {name}];
    else
        channels_other = [channels_other ; {name}];
    end
end

handles.channellayout =  recording.properties.channellayout;

set(handles.channel_list_eeg, 'String', channels_eeg);
set(handles.channel_list_eog, 'String', channels_eog);
set(handles.channel_list_other, 'String', channels_other);

set(handles.channel_list_eeg, 'Value', []);
set(handles.channel_list_eog, 'Value', []);
set(handles.channel_list_other, 'Value', []);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes gui_load_neurone wait for user response (see UIRESUME)
uiwait(handles.figure1);
%delete(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = gui_load_neurone_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
% varargout{1} = handles.output;

varargout{1}          = handles.gui_out;
close(handles.figure1);

% --- Executes on button press in ok_button.
function ok_button_Callback(hObject, eventdata, handles)
% hObject    handle to ok_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Collect the selected channels from the three listboxes
channel_list = {};

% Check which channels that should be read

% Should all channels be read
gui_out.read_all_channels = get(handles.read_all_channels,'Value');

channel_set_eeg = get(handles.channel_list_eeg);
channel_set_eog = get(handles.channel_list_eog);
channel_set_other = get(handles.channel_list_other);

if (gui_out.read_all_channels)
    channel_list = [channel_set_eeg.String ; channel_set_eog.String ; channel_set_other.String];
else
    channel_list = [channel_list ; channel_set_eeg.String( channel_set_eeg.Value )];
    channel_list = [channel_list ; channel_set_eog.String( channel_set_eog.Value )];
    channel_list = [channel_list ; channel_set_other.String( channel_set_other.Value )];
end

gui_out.ok            = 1;
gui_out.cancel        = 0;
gui_out.channel_list  = channel_list;
gui_out.channellayout = handles.channellayout;

handles.gui_out = gui_out;
guidata(hObject, handles);
uiresume(handles.figure1);


% --- Executes on button press in cancel_button.
function cancel_button_Callback(hObject, eventdata, handles)
% hObject    handle to cancel_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
gui_out.ok     = 0;
gui_out.cancel = 1;

handles.gui_out = gui_out;
guidata(hObject, handles);
uiresume(handles.figure1);

function figure1_CloseRequestFcn(hObject, eventdata, handles)
uiresume(handles.figure1);


% --- Executes on selection change in channel_list_eeg.
function channel_list_eeg_Callback(hObject, eventdata, handles)
% hObject    handle to channel_list_eeg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns channel_list_eeg contents as cell array
%        contents{get(hObject,'Value')} returns selected item from channel_list_eeg


% --- Executes during object creation, after setting all properties.
function channel_list_eeg_CreateFcn(hObject, eventdata, handles)
% hObject    handle to channel_list_eeg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in channel_list_eog.
function channel_list_eog_Callback(hObject, eventdata, handles)
% hObject    handle to channel_list_eog (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns channel_list_eog contents as cell array
%        contents{get(hObject,'Value')} returns selected item from channel_list_eog


% --- Executes during object creation, after setting all properties.
function channel_list_eog_CreateFcn(hObject, eventdata, handles)
% hObject    handle to channel_list_eog (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in channel_list_other.
function channel_list_other_Callback(hObject, eventdata, handles)
% hObject    handle to channel_list_other (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns channel_list_other contents as cell array
%        contents{get(hObject,'Value')} returns selected item from channel_list_other


% --- Executes during object creation, after setting all properties.
function channel_list_other_CreateFcn(hObject, eventdata, handles)
% hObject    handle to channel_list_other (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in read_all_channels.
function read_all_channels_Callback(hObject, eventdata, handles)
% hObject    handle to read_all_channels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of read_all_channels

if get(handles.read_all_channels,'Value')
    state = 'off';
else
    state = 'on';
end

set(handles.channel_list_eeg, 'Enable', state)
set(handles.channel_list_eog, 'Enable', state)
set(handles.channel_list_other, 'Enable', state)
