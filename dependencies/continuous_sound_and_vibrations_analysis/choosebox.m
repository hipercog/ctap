function [selection,value] = choosebox(varargin)
%CHOOSEBOX  Two-listed item selection dialog box.
%   [SELECTION,OK] = CHOOSEBOX('ListString',S) creates a modal dialog box 
%   which allows you to select a string or multiple strings from a list.
%   Single or multiple strings can be transferred from a base list to a
%   selection list using an arrow-button. Single strings also can be
%   transferred by double-clicking; single or multiple strings are
%   transferred by pressing <CR>.
%   SELECTION is a vector of indices of the selected strings (length 1
%   in the single selection mode). The indices will be in the order of
%   selection from the base list. If a group of multiple strings is
%   selected, its order inside the group will not change, but different
%   groups are ordered by their selection. 
%   OK is 1 if you push the OK button, or 0 if you push the Cancel 
%   button or close the figure. In that case SELECTION will be [],
%   regardless to the actual selection list.
%   Important parameter is 'ChooseMode', see list below.
%
%   Inputs are in parameter,value pairs:
%
%   Parameter       Description
%   'ChooseMode'    string; can be 'pick' or 'copy'.
%                   When set to 'pick', transferred string items from the
%                   base list box are removed. When retransferred, they
%                   again are listed in their initial positions.
%                   When set to 'copy', transferred string items remain in
%                   the base list and can be transferred several times.
%                   default is 'pick'.
%   'ListString'    cell array of strings for the base list box.
%   'SelectionMode' string; can be 'single' or 'multiple'; defaults to
%                   'multiple'.
%   'ListSize'      [width height] of listbox in pixels; defaults
%                   to [160 300].
%   'InitialValue'  vector of indices of which items of the list box
%                   are initially selected; defaults to none [].
%   'Name'          String for the figure's title. Defaults to ''.
%   'PromptString'  string matrix or cell array of strings which appears 
%                   as text above the base list box.  Defaults to {}.
%   'SelectString'  string matrix or cell array of strings which appears
%                   as text above the selection list box. Defaults to {}.
%   'OKString'      string for the OK button; defaults to 'OK'.
%   'CancelString'  string for the Cancel button; defaults to 'Cancel'.
%   'uh'            uicontrol button height, in pixels; default = 18.
%   'fus'           frame/uicontrol spacing, in pixels; default = 8.
%   'ffs'           frame/figure spacing, in pixels; default = 8.
%
%   Example:
%     d = dir;
%     str = {d.name};
%     [s,v] = choosebox('Name','File deletion',...
%                     'PromptString','Files remaining in this directory:',...
%                     'SelectString','Files to delete:',...
%                     'ListString',str)
%
%   inspired by listdlg.m from Mathworks.
%
%   programmed by Peter Wasmeier, Technical University of Munich
%   p.wasmeier@bv.tum.de
%   11-12-03

%   Original listdlg file by
%   T. Krauss, 12/7/95, P.N. Secakusuma, 6/10/97
%   Copyright 1984-2002 The MathWorks, Inc.
%   $Revision: 1.20 $  $Date: 2002/04/09 01:36:06 $

%   Test:  d = dir;[s,v] = choosebox('Name','File deletion','PromptString','Files remaining in this directory:','SelectString','Files to delete:','ListString',{d.name});


error(nargchk(1,inf,nargin))

arrow=[...
     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0
     0     1     1     1     1     1     1     1     1     1     1     1     1     1     1     1     0
     0     1     1     1     1     1     1     0     1     1     1     1     1     1     1     1     0
     0     1     1     1     1     1     1     0     0     1     1     1     1     1     1     1     0
     0     1     1     1     1     1     1     0     0     0     1     1     1     1     1     1     0
     0     1     1     1     1     1     1     0     0     0     0     1     1     1     1     1     0
     0     1     1     0     0     0     0     0     0     0     0     0     1     1     1     1     0
     0     1     1     0     0     0     0     0     0     0     0     0     0     1     1     1     0
     0     1     1     0     0     0     0     0     0     0     0     0     0     0     1     1     0
     0     1     1     0     0     0     0     0     0     0     0     0     0     1     1     1     0
     0     1     1     0     0     0     0     0     0     0     0     0     1     1     1     1     0
     0     1     1     1     1     1     1     0     0     0     0     1     1     1     1     1     0
     0     1     1     1     1     1     1     0     0     0     1     1     1     1     1     1     0
     0     1     1     1     1     1     1     0     0     1     1     1     1     1     1     1     0
     0     1     1     1     1     1     1     0     1     1     1     1     1     1     1     1     0
     0     1     1     1     1     1     1     1     1     1     1     1     1     1     1     1     0
     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0];
for i=1:3
   rarrow(:,:,i)=arrow;
   larrow(:,:,i)=fliplr(arrow);
end
clear arrow;

figname = '';
smode = 2;   % (multiple)
cmode = 1;   % remove from left hand side
promptstring = {};
selectstring={};
liststring = [];
listsize = [160 300];
initialvalue = [];
okstring = 'Ok';
cancelstring = 'Cancel';
fus = 8;
ffs = 8;
uh = 18;

if mod(length(varargin),2) ~= 0
    % input args have not com in pairs, woe is me
    error('Arguments to LISTDLG must come param/value in pairs.')
end
for i=1:2:length(varargin)
    switch lower(varargin{i})
     case 'name'
      figname = varargin{i+1};
     case 'promptstring'
      promptstring = varargin{i+1};
     case 'selectstring'
      selectstring = varargin{i+1};
     case 'selectionmode'
      switch lower(varargin{i+1})
       case 'single'
        smode = 1;
       case 'multiple'
        smode = 2;
      end
     case 'choosemode'
      switch lower(varargin{i+1})
       case 'pick'
        cmode = 1;
       case 'copy'
        cmode = 2;
      end
     case 'listsize'
      listsize = varargin{i+1};
     case 'liststring'
      liststring = varargin{i+1};
     case 'initialvalue'
      initialvalue = varargin{i+1};
     case 'uh'
      uh = varargin{i+1};
     case 'fus'
      fus = varargin{i+1};
     case 'ffs'
      ffs = varargin{i+1};
     case 'okstring'
      okstring = varargin{i+1};
     case 'cancelstring'
      cancelstring = varargin{i+1};
     otherwise
      error(['Unknown parameter name passed to LISTDLG.  Name was ' varargin{i}])
    end
end

if isstr(promptstring)
    promptstring = cellstr(promptstring); 
end

if isstr(selectstring)
    selectstring = cellstr(selectstring); 
end

if isempty(initialvalue)
    initialvalue = 1;
end

if isempty(liststring)
    error('ListString parameter is required.')
end

ex = get(0,'defaultuicontrolfontsize')*1.7;  % height extent per line of uicontrol text (approx)

fp = get(0,'defaultfigureposition');
w = 4*fus +2*ffs+2*listsize(1)+50;
h = 2*ffs+7*fus+ex*length(promptstring)+listsize(2)+2*uh;
fp = [fp(1) fp(2)+fp(4)-h w h];  % keep upper left corner fixed

fig_props = { ...
    'name'                   figname ...
    'resize'                 'off' ...
    'numbertitle'            'off' ...
    'menubar'                'none' ...
    'windowstyle'            'modal' ...
    'visible'                'off' ...
    'createfcn'              ''    ...
    'position'               fp   ...
    'closerequestfcn'        'delete(gcbf)' ...
            };

ad.fromstring=cellstr(liststring);
ad.tostring='';
ad.pos_left=[1:size(ad.fromstring,2)]';
ad.pos_right=[];
ad.value=0;
ad.cmode=cmode;
setappdata(0,'ListDialogAppData',ad)

fig = figure(fig_props{:});

uicontrol('style','frame',...
          'position',[1 1 fp([3 4])])
uicontrol('style','frame',...
          'position',[ffs ffs 2*fus+listsize(1) 2*fus+uh])
uicontrol('style','frame',...
          'position',[ffs+2*fus+50+listsize(1) ffs 2*fus+listsize(1) 2*fus+uh])
uicontrol('style','frame',...
          'position',[ffs ffs+3*fus+uh 2*fus+listsize(1) ...
                    listsize(2)+3*fus+ex*length(promptstring)+(uh+fus)*(smode==2)])
uicontrol('style','frame',...
          'position',[ffs+2*fus+50+listsize(1) ffs+3*fus+uh 2*fus+listsize(1) ...
                    listsize(2)+3*fus+ex*length(promptstring)+(uh+fus)*(smode==2)])

if length(promptstring)>0
    prompt_text = uicontrol('style','text','string',promptstring,...
                            'horizontalalignment','left','units','pixels',...
                            'position',[ffs+fus fp(4)-(ffs+fus+ex*length(promptstring)) ...
                    listsize(1) ex*length(promptstring)]);
end
if length(selectstring)>0
    select_text = uicontrol('style','text','string',selectstring,...
                            'horizontalalignment','left','units','pixels',...
                            'position',[ffs+3*fus+listsize(1)+50 fp(4)-(ffs+fus+ex*length(promptstring)) ...
                    listsize(1) ex*length(selectstring)]);
end

btn_wid = listsize(1);

leftbox = uicontrol('style','listbox',...
                    'position',[ffs+fus ffs+uh+4*fus listsize(1) listsize(2)+25],...
                    'string',ad.fromstring,...
                    'backgroundcolor','w',...
                    'max',2,...
                    'tag','leftbox',...
                    'value',initialvalue, ...
                    'callback',{@doFromboxClick});
         
rightbox = uicontrol('style','listbox',...
                    'position',[ffs+3*fus+listsize(1)+50 ffs+uh+4*fus listsize(1) listsize(2)+25],...
                    'string',ad.tostring,...
                    'backgroundcolor','w',...
                    'max',2,...
                    'tag','rightbox',...
                    'value',[], ...
                    'callback',{@doToboxClick});

ok_btn = uicontrol('style','pushbutton',...
                   'string',okstring,...
                   'position',[ffs+fus ffs+fus btn_wid uh],...
                   'callback',{@doOK});

cancel_btn = uicontrol('style','pushbutton',...
                       'string',cancelstring,...
                       'position',[ffs+3*fus+btn_wid+50 ffs+fus btn_wid uh],...
                       'callback',{@doCancel});

toright_btn = uicontrol('style','pushbutton',...
                       'position',[ffs+2*fus+10+listsize(1) ffs+uh+4*fus+(smode==2)*(fus+uh)+listsize(2)/2-25 30 30],...
                       'cdata',rarrow,...
                       'callback',{@doRight});

toleft_btn = uicontrol('style','pushbutton',...
                       'position',[ffs+2*fus+10+listsize(1) ffs+uh+4*fus+(smode==2)*(fus+uh)+listsize(2)/2+25 30 30],...
                       'cdata',larrow,...
                       'callback',{@doLeft});


try
    set(fig, 'visible','on');
    uiwait(fig);
catch
    if ishandle(fig)
        delete(fig)
    end
end

if isappdata(0,'ListDialogAppData')
    ad = getappdata(0,'ListDialogAppData');
    selection = ad.pos_right;
    value = ad.value;
    rmappdata(0,'ListDialogAppData')
else
    % figure was deleted
    selection = [];
    value = 0;
end

function doOK(varargin)
ad=getappdata(0,'ListDialogAppData');
ad.value = 1;
setappdata(0,'ListDialogAppData',ad)
delete(gcbf);

function doCancel(varargin)
ad.value = 0;
ad.pos_right = [];
setappdata(0,'ListDialogAppData',ad)
delete(gcbf);

function doFromboxClick(varargin)
% if this is a doubleclick, doOK
if strcmp(get(gcbf,'SelectionType'),'open')
    doRight;
end

function doToboxClick(varargin)
% if this is a doubleclick, doOK
if strcmp(get(gcbf,'SelectionType'),'open')
    doLeft;
end

function doRight(varargin)
ad=getappdata(0,'ListDialogAppData');
leftbox=findobj('Tag','leftbox');
rightbox=findobj('Tag','rightbox');
selection=get(leftbox,'Value');
ad.pos_right=[ad.pos_right;ad.pos_left(selection)];
ad.tostring=[ad.tostring ad.fromstring(selection)];
if ad.cmode==1 % remove selected items
    ad.pos_left(selection)=[];
    ad.fromstring(selection)=[];
end
setappdata(0,'ListDialogAppData',ad)
set(leftbox,'String',ad.fromstring,'Value',[]);
set(rightbox,'String',ad.tostring,'Value',[]);

function doLeft(varargin)
ad=getappdata(0,'ListDialogAppData');
leftbox=findobj('Tag','leftbox');
rightbox=findobj('Tag','rightbox');
selection=get(rightbox,'Value');
if ad.cmode==1 % if selected items had been removed
    % Sort in the items from right hand side again
    for i=1:length(selection)
        next_item=min(find(ad.pos_left>ad.pos_right(selection(i))));
        if isempty(next_item)   % Inserting item is last one
            ad.pos_left(end+1)=ad.pos_right(selection(i));
            ad.fromstring(end+1)=ad.tostring(selection(i));
        elseif next_item==ad.pos_left(1)    % Inserting item is first one
            ad.pos_left=[ad.pos_right(selection(i));ad.pos_left];
            ad.fromstring=[ad.tostring(selection(i)) ad.fromstring];
        else                    % Inserting item is anywhere in the middle
            ad.pos_left=[ad.pos_left(1:next_item-1);ad.pos_right(selection(i));ad.pos_left(next_item:end)];
            ad.fromstring=[ad.fromstring(1:next_item-1) ad.tostring(selection(i)) ad.fromstring(next_item:end)];
        end
    end
end
ad.pos_left=ad.pos_left(:);     % Make sure it is a nx1-vector
ad.pos_right(selection)=[];
ad.tostring(selection)=[];
setappdata(0,'ListDialogAppData',ad)
set(leftbox,'String',ad.fromstring,'Value',[]);
set(rightbox,'String',ad.tostring,'Value',[]);

