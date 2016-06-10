function updateDisplay(obj,event)

% UPDATEDISPLAY Updates the SLM display.
%    UPDATEDISPLAY Is a callback routine for the
%    Data Acquisition Toolbox timer function.
%    When new data is available from the sound
%    card, this routine is called to calculate
%    the new signal level and refresh the display.
%
% Author: Douglas R. Lanman, 11/21/05

% Extract figure data from callback object.
figData = obj.userData;

% Read current input data from sound card.
x = peekdata(obj,obj.SamplesPerTrigger);

% Esimate signal level (in dBA).
[X,dBA] = estimateLevel(x,obj.SampleRate,figData.C);
dBA_str = sprintf('%5.1f%s',dBA,' dBA');

% Update sound level meter display.
set(figData.samplePlot,'YData',x); 
set(figData.fftPlot,'YData',X);
set(get(figData.fftPlot,'Parent'),'YLim',[-100 60])
set(figData.dBA_text,'string',dBA_str);