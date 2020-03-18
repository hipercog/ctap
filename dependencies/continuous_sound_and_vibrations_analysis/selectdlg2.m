function k = selectdlg2( cellItems, guiTitle, selMode, selDeft )
%selectdlg2   Generate a scrolled matrix of choices for user selection.
%   Choice = selectdlg2(Itemlist) returns an index into Itemlist.
%   Itemlist is cell array containing:
%        a string cell vector of row titles (optional)
%        a string cell vector of column titles (optional)
%        a string cell array of m*n choice item names
%        or just an array of m*n choice item names
%
%   Choice = selectdlg2(Itemlist, Prompt) where:
%   Prompt is an optional string title prompt for the whole selection.
%
%   Choice = selectdlg2(Itemlist, Prompt, Mode) where:
%   Mode is selection mode - 0 for mutiple (default) or 1 for single - 
%        if scalar, it applies to whole (Mode=1 allows only a single button)
%        if vector, Mode applies for each row/column (ones(1,n) for 1 per col)
%        if matrix, m*n identifies buttons which reset the rest,
%                   m*n*2 identifies [col,row] mode for each button.
%
%   Choice = selectdlg2(Itemlist, Prompt, Mode, Default) where:
%   Default is a dx2 index matrix to the button(s) initially selected.
%
%   selectdlg2 displays an array of radio buttons in a fixed size figure 
%   window. The calling process is stopped to await the user selection. The 
%   buttons selected by the user are returned as Choice, a c*2 index into the 
%   Itemlist cell array. Choice is [] if no selection is made, or the dialog 
%   is cancelled or closed.
%
%   For example:
%       items={'One','Two','Three';'Four','Five','Six';'Seven','Eight','Nine'};
%       sel = selectdlg2(items); 
%       items(sub2ind([3,3],sel(:,1),sel(:,2)))
%
%       sel = selectdlg2({items(1,:),items},'Choose 1 item per col',ones(1,3)); 
%       items(sub2ind([3,3],sel(:,1),sel(:,2)))
%
%   See also: MENU, LISTDLG, selectdlg, selectdlg3, listdlg2.

%   Author: Mike Thomson   4 August 2001 

%-------------------------------------------------------------------------
% Set spacing and sizing constants for the GUI elements
%-------------------------------------------------------------------------
SelUnits    = 'points'; % units used for all HG objects
textPadding = [18 4];   % extra [Width Height] on uicontrols to pad text
uiGap       = 5;        % space around uicontrols
winTopGap   = 35;       % gap between top of screen and top of figure **
winLeftGap  = 10;       % gap between side of screen and side of figure **
okWide      = 40;       % for OK & Cancel buttons
scrollWide  = 12;       % 
footWide    = 2*okWide + 3*uiGap;
guicolor    = [0.75 0.75 0.75];

% ** "figure" ==> viewable figure. You must allow space for the OS to add
% a title bar (aprx 42 points on Mac and Windows) and a window border
% (usu 2-6 points). Otherwise user cannot move the window.

%=========================================================================
% CALLBACK OPTIONS
%=========================================================================
if ischar(cellItems)
   fragName=cellItems;
else
   fragName='none';
end;
switch fragName
   
case 'selDlg2_buttonClick'
   % If in single selection mode, reset all other buttons
   if length(selMode)==1,
      if selMode,
         hData=get(gcbf,'Userdata');
         hBtn=hData.Btn;
         set(hBtn, {'Value'}, {0});
         set(gcbo, 'Value', 1);
      end;
      
   % If in single col selection mode, reset other buttons in this column
   elseif selMode(1),
      pos=get(gcbo,'Userdata');
      hData=get(gcbf,'Userdata');
      hBtn=hData.Btn;
      set(hBtn(:,pos(2)), {'Value'}, {0});
      set(gcbo, 'Value', 1);
      
   % If in single row selection mode, reset other buttons in this row
   elseif selMode(2),
      pos=get(gcbo,'Userdata');
      hData=get(gcbf,'Userdata');
      hBtn=hData.Btn;
      set(hBtn(pos(1),:), {'Value'}, {0});
      set(gcbo, 'Value', 1);
   end;

case 'selDlg2_scrollH'
% Find objects
   hData=get(gcbf,'Userdata');
   scrollH=get(hData.ScrlH,'Value');
   xyOff=get(hData.ScrlH,'Position');
   hBtn=hData.Btn;
   hTitleCol=hData.TitC;
   scrollV=0; % in case no V scroll
   if ~isempty(hData.ScrlV), scrollV=get(hData.ScrlV,'Value'); end;
   [rowItems,colItems] = size(hBtn);
   btnColPos = get(hBtn(1,:),{'Position'});
   btnColPos = cat(1,btnColPos{:}); % get col widths
   titPos=get(hTitleCol,{'Position'});
   titPos = cat(1,titPos{:});
   xSclOff = uiGap+xyOff(1) - scrollH;
   ySclOff = xyOff(2)+scrollWide - scrollV;
% Calculate & set button positions
   btPosMtx = local_selectPos(colItems,rowItems,btnColPos(:,3)',btnColPos(1,4),xSclOff,ySclOff,uiGap);
   cUIPos   = num2cell( btPosMtx, 2 );
   set( hBtn, {'Position'}, cUIPos );
% Position Column titles
   newColPos = btPosMtx(1+rowItems*[0:(colItems-1)],:);
   titPos = [newColPos(:,1), titPos(:,2:4)];
   set( hTitleCol, {'Position'}, num2cell(titPos,2) );

case 'selDlg2_scrollV'
% Find objects
   hData=get(gcbf,'Userdata');
   scrollV=get(hData.ScrlV,'Value');
   yOff=get(hData.ScrlV,'Position');
   hBtn=hData.Btn;
   hTitleRow=hData.TitR;
   scrollH=0; % in case no H scroll
   if ~isempty(hData.ScrlH), scrollH=get(hData.ScrlH,'Value'); end;
   [rowItems,colItems] = size(hBtn);
   btnColPos = get(hBtn(1,:),{'Position'});
   btnColPos = cat(1,btnColPos{:}); % get col widths
   titPos=get(hTitleRow,{'Position'});
   titPos = cat(1,titPos{:});
   xSclOff = uiGap+titPos(1,1)+titPos(1,3) - scrollH;
   ySclOff = yOff(2) - scrollV;
% Calculate & set button positions
   btPosMtx = local_selectPos(colItems,rowItems,btnColPos(:,3)',btnColPos(1,4),xSclOff,ySclOff,uiGap);
   cUIPos   = num2cell( btPosMtx, 2 );
   set( hBtn, {'Position'}, cUIPos );
% Position Row titles
   titPos = [titPos(:,1), btPosMtx(1:rowItems,2), titPos(:,3:4)];
   set( hTitleRow, {'Position'}, num2cell(titPos,2) );

case 'selDlg2_okClick'
   set(gcbo,'userdata',1);
   
case 'selDlg2_cancelClick'
   hData=get(gcbf,'Userdata');
   set(hData.ok,'userdata',0);
   
otherwise
   
%=========================================================================
% SET UP CHECKS
%=========================================================================
% Check input
%-------------------------------------------------------------------------
error(nargchk(1,4,nargin));

%-------------------------------------------------------------------------
% Set defaults
%-------------------------------------------------------------------------
if nargin<2, 
   guiTitle='Make a selection'; 
end;
if nargin<3,
   selMode=0;
end;
if nargin<4 | isempty(selDeft),
   selDeft=[0,0];
end;

%-------------------------------------------------------------------------
% Check ITEMLIST sizes
%-------------------------------------------------------------------------
if ~iscell(cellItems),
   error('A cell array is expected as the Itemlist.');
end
% Dismantle the input cell array
[r,c]=size(cellItems);
if r~=1 & c~=1,
   if ~iscell(cellItems{1,1}),
      rowTitle=cell(r,1);  % no rownames
      colTitle=cell(1,c);  % no colnames
      xcItems=cellItems;   % only choice items supplied
   else
      error('Itemlist should be a cell vector of cells or a cell matrix of strings.');
   end;
elseif ~iscell(cellItems{1,1}),
   rowTitle=cell(r,1);  % no rownames
   colTitle=cell(1,c);  % no colnames
   xcItems=cellItems;   % only choice items supplied
elseif length(cellItems)==1 & iscell(cellItems{1}),
   [r,c]=size(cellItems{1});
   rowTitle=cell(r,1);   % no rownames
   colTitle=cell(1,c);   % no colnames
   xcItems=cellItems{1}; % only choice items supplied
elseif length(cellItems)==2,
   xcItems=cellItems{2};
   [r,c]=size(cellItems{2});
   if length(cellItems{1})==c,
      rowTitle=cell(r,1);
      colTitle=cellItems{1}; colTitle=colTitle(:)'; % title vector matches columns
   elseif length(cellItems{1})==r,
      rowTitle=cellItems{1}; rowTitle=rowTitle(:); % title vector matches rows
      colTitle=cell(1,c);
   else
      error('The first cell in Itemlist is the wrong size.');
   end;
elseif length(cellItems)==3,
   xcItems=cellItems{3};     % all items supplied
   [r,c]=size(cellItems{3});
   rowTitle=cellItems{1}; rowTitle=rowTitle(:);
   colTitle=cellItems{2}; colTitle=colTitle(:)';
   if length(rowTitle)~=r | length(colTitle)~=c,
      error('A title in Itemlist is the wrong size.');
   end;
else
   error('Itemlist is the wrong size.');
end;

%-------------------------------------------------------------------------
% Calculate the number of items in the list
%-------------------------------------------------------------------------
[rowItems,colItems] = size( xcItems );

%-------------------------------------------------------------------------
% Check Mode & Default sizes
%-------------------------------------------------------------------------
[r,c,d]=size(selMode);
if r==1 & c==1,
   selMode=selMode*ones(rowItems,colItems);
elseif r==1 & c==colItems,
   selMode=cat(3,ones(rowItems,1)*selMode,zeros(rowItems,colItems));
elseif c==1 & r==rowItems,
   selMode=cat(3,zeros(rowItems,colItems),selMode*ones(1,colItems));
elseif ~(r==rowItems & c==colItems & d<=2),
   error('Bad Mode size');
end;

if selDeft(1,1)~=0 & size(selDeft,2)~=2,
   error('Default must have 2 columns.');
elseif all(all(all(selMode))) & size(selDeft,1)~=1,
   error('When using single-select mode, Default must be a single item.');
end;
if any(any(selDeft>ones(size(selDeft,1),1)*size(xcItems))),
   error('A default value cannot be > number of items.');
end;
if size(selDeft,1)>1 | selDeft(1,1)~=0,
   if any(any(selDeft<ones(size(selDeft,1),2))),
      error('A default value cannot be < 1.');
   end;
end;

%=========================================================================
% BUILD
%=========================================================================
% Create a generically-sized invisible figure window
%------------------------------------------------------------------------
selFig = figure( 'Units'        ,SelUnits, ...
                 'NumberTitle'  ,'off', ...
                 'IntegerHandle','off', ...
                 'MenuBar'      ,'none',...
                 'Name'         ,'Select Dialog 2', ...
                 'Resize'       ,'off', ...
                 'Visible'      ,'off', ...
                 'Color'        ,[0.9 0.9 0.9],...
                 'Colormap'     ,[]);

%------------------------------------------------------------------------
% Add generically-spaced buttons below the header text
%------------------------------------------------------------------------
% Loop to add buttons.
% Note that buttons may overlap, but are placed in correct position relative
% to each other. They will be resized and spaced evenly later on.

for j = 1 : colItems, % start from top left of screen and go down first
   for i = 1 : rowItems,
      modStr = int2str(selMode(i,j,:));
     % make a button - position doesn't matter now
     hBtn(i,j) = uicontrol( ...
            'Style'     ,'radiobutton',...
            'Background',[0.65 0.65 0.65],...
            'Units'     ,SelUnits, ...
            'Position'  ,[uiGap+uiGap*j uiGap*i 10 5], ...
            'Callback'  ,['selectdlg2(''selDlg2_buttonClick'',1,[' modStr ']);'], ...
            'Userdata'  ,[i,j],...
            'String'    ,xcItems{i,j} );
   end % for
end % for
if selDeft(1,1),
   for i=1:size(selDeft,1),
      set(hBtn(selDeft(i,1),selDeft(i,2)),'Value',1);
   end;
end;

% Store the button handles in a structure
hData.Btn=hBtn;

%------------------------------------------------------------------------
% Add frames to define the button area ends (on top of buttons)
%------------------------------------------------------------------------
% Background for row titles
hFrame3 = uicontrol(...
	'Units','points', ...
   'Foreground',guicolor,...
   'BackGround',guicolor,...
	'Style','frame');
% Background for col titles
hFrame4 = uicontrol(...
	'Units','points', ...
   'Foreground',guicolor,...
   'BackGround',guicolor,...
	'Style','frame');

%------------------------------------------------------------------------
% Add row titles with same background color as figure
%------------------------------------------------------------------------
for i = 1 : rowItems,
      hTitleRow(i,1) = uicontrol( ...
        'Style'       ,'text', ...
        'String'      ,rowTitle{i}, ...
        'Units'       ,SelUnits, ...
        'Horizontal'  ,'center',...
        'BackGround'  ,guicolor );
end % for
  
%------------------------------------------------------------------------
% Add column titles with same background color as figure
%------------------------------------------------------------------------
for j = 1 : colItems,
      hTitleCol(j) = uicontrol( ...
        'Style'       ,'text', ...
        'String'      ,colTitle{j}, ...
        'Units'       ,SelUnits, ...
        'Horizontal'  ,'center',...
        'BackGround'  ,guicolor );
end % for

% Store the button & text handles
hData.TitR=hTitleRow;
hData.TitC=hTitleCol;

%------------------------------------------------------------------------
% Add frames to define the button area ends (on top of buttons & titles)
%------------------------------------------------------------------------
% To frame ok buttons
hFrame1 = uicontrol(...
   'Units','points', ...
   'BackGround',guicolor,...
   'Style','frame');
% To frame top text
hFrame2 = uicontrol(...
	'Units','points', ...
   'BackGround',guicolor,...
   'Style','frame');
% Three frames for hiding titles as they scroll
hFrame5 = uicontrol(...
	'Units','points', ...
   'Foreground',guicolor,...
   'BackGround',guicolor,...
	'Style','frame');
hFrame6 = uicontrol(...
	'Units','points', ...
   'Foreground',guicolor,...
   'BackGround',guicolor,...
   'Position'  ,[ 1 1 1 1 ], ...
   'Style','frame');
hFrame7 = uicontrol(...
	'Units','points', ...
   'Foreground',guicolor,...
   'BackGround',guicolor,...
   'Position'  ,[ 1 1 1 1 ], ...
   'Style','frame');
% if both sliders
hFrame8 = uicontrol(...
	'Units','points', ...
   'Foreground',guicolor,...
   'BackGround',guicolor,...
   'Position'  ,[ 1 1 1 1 ], ...
	'Style','frame');

%------------------------------------------------------------------------
% Add generically-sized header text with same background color as figure
%------------------------------------------------------------------------
hText = uicontrol( ...
        'Style'       ,'text', ...
        'String'      ,guiTitle, ...
        'Units'       ,SelUnits, ...
        'Position'    ,[ 100 100 100 20 ], ...
        'Horizontal'  ,'center',...
        'BackGround'  ,guicolor );

% Record extent of text string
maxsize = get( hText, 'Extent' );
textWide  = maxsize(3);
textHigh  = maxsize(4);

%=========================================================================
% TWEAK
%=========================================================================
% Calculate Optimal UIcontrol dimensions based on max text size
%------------------------------------------------------------------------
hCols = [hTitleRow(1), hTitleCol;hTitleRow, hBtn]; % include row & column titles
for j=1:colItems+1
  cAllExtents = get( hCols(:,j),{'Extent'} );% put all data in a cell array
  AllExtents  = cat( 1, cAllExtents{:} );    % convert to an n x 4 matrix
  maxsize     = max( AllExtents(:,3:4) );    % calculate the largest width & height
  maxsize     = maxsize + textPadding;       % add some blank space around text
  btnHigh(j)  = maxsize(2);
  btnWide(j)  = maxsize(1);
end % for
btnHigh=max(btnHigh);  % Set uniform height
titleHigh=btnHigh-textPadding(2)/2;  % half the padding - to centralise vertically
rTitHigh=titleHigh;
if isempty(cat(2,rowTitle{:})), btnWide(1)=1; end; % no row titles
if isempty(cat(2,colTitle{:})), titleHigh=1; end; % no col titles

%------------------------------------------------------------------------
% Retrieve screen dimensions (in correct units)
%------------------------------------------------------------------------
oldUnits = get(0,'Units');         % remember old units
set( 0, 'Units', SelUnits );       % convert to desired units
screensize = get(0,'ScreenSize');  % record screensize
set( 0, 'Units',  oldUnits );      % convert back to old units

%------------------------------------------------------------------------
% How many rows and columns of buttons will fit in the screen?
%------------------------------------------------------------------------
% Vertical
okGap = 2*uiGap + btnHigh;
spaceHigh = screensize(4) - winTopGap - winLeftGap - 2*uiGap - textHigh - ...
            titleHigh - okGap - scrollWide;
numRows = min( floor( spaceHigh/(btnHigh + uiGap) ), rowItems );
if numRows == 0; numRows = 1; end % Trivial case--but very safe to do
butWinHigh = numRows * (btnHigh + uiGap) + uiGap; % allow space between each & 1 at end
panelHigh = rowItems * (btnHigh + uiGap) + uiGap;
scrollF = 1 + butWinHigh/panelHigh;
scrollV = panelHigh - butWinHigh;
% Horizontal
spaceWide = screensize(3) - 2*winLeftGap - 2*uiGap - btnWide(1) - scrollWide;
panelWide = (colItems+1)*uiGap + sum(btnWide(2:colItems+1));
butWinWide = min(spaceWide,panelWide);
scrollG = 1 + butWinWide/panelWide;
scrollH = panelWide - butWinWide;

%------------------------------------------------------------------------
% Resize figure to place it in top left of screen
%------------------------------------------------------------------------
% Calculate the window size needed to display all buttons - resize later if scrolls
winHigh = butWinHigh + textHigh + titleHigh + 2*uiGap + okGap;
winWide = butWinWide + btnWide(1);

% If needed, add the Horizontal scroll slider
if butWinWide<panelWide,
   winHigh = winHigh + scrollWide;
   hScrollH = uicontrol(...
         'Parent',selFig, ...
         'Style','slider',...
         'Units','points', ...
         'Min',0,'Max',scrollH ,...
         'Value',0 , ...
         'Callback','selectdlg2(''selDlg2_scrollH'');',...
         'SliderStep',[0.1*scrollG scrollG]);
   hData.ScrlH=hScrollH; % Store the scroll handle
else
   hData.ScrlH=[];
end;

% If needed, add the Vertical scroll slider
if numRows<rowItems,
   winWide = winWide + scrollWide;
   hScrollV = uicontrol(...
         'Parent',selFig, ...
         'Style','slider',...
         'Units','points', ...
         'Min',0,'Max',scrollV ,...
         'Value',scrollV , ...
         'Callback','selectdlg2(''selDlg2_scrollV'');',...
         'SliderStep',[0.1*scrollF scrollF]);
   hData.ScrlV=hScrollV; % Store the scroll handle
else
   hData.ScrlV=[];
end;

% Make sure the text header fits & also the OK & Cancel buttons
winWide = max(winWide,(2*uiGap + textWide));
winWide = max(footWide,winWide);

% Determine final placement coordinates for bottom of figure window
bottom = screensize(4) - (winHigh + winTopGap);

% Note base of scrolled region
butWinBottom=winHigh-textHigh-titleHigh-2*uiGap-butWinHigh;

% Set figure window position
set( selFig, 'Position', [winLeftGap bottom winWide winHigh] );

%------------------------------------------------------------------------
% Size uicontrols to fit everyone in the window and see all text
%------------------------------------------------------------------------
% Position scroll sliders if there
if butWinWide<panelWide,
   set( hScrollH, 'Position',[btnWide(1) okGap butWinWide scrollWide] );
end
if numRows<rowItems,
   set( hScrollV, 'Position',[winWide-scrollWide butWinBottom scrollWide butWinHigh] );
end

% Calculate button positions
xSclOff = uiGap + btnWide(1) - 0;
ySclOff = butWinBottom - scrollV;
uiPosMtx = local_selectPos(colItems,rowItems,btnWide(2:colItems+1),btnHigh,xSclOff,ySclOff,uiGap);
cUIPos = num2cell( uiPosMtx, 2 );

% Adjust all buttons
set( hBtn, {'Position'}, cUIPos );

%------------------------------------------------------------------------
% Align the Text and Buttons horizontally and distribute them vertically
%------------------------------------------------------------------------

% Calculate placement position of the Header
textWide = winWide - 2*uiGap;

% Move Header & titles text into correct position near the top of figure
set( hText, ...
   'Position', [ uiGap winHigh-uiGap-textHigh textWide textHigh ] );

r=ones(rowItems,1);
titPos=num2cell([ 0*r uiPosMtx(1:rowItems,2) btnWide(1)*r rTitHigh*r ],2);
set( hTitleRow, {'Position'}, titPos );

c=ones(colItems,1);
p=uiPosMtx(1+(0:colItems-1)*rowItems,[1,3]);
titPos=num2cell([ p(:,1) winHigh-2*uiGap-textHigh-titleHigh*c p(:,2) titleHigh*c ],2);
set( hTitleCol, {'Position'}, titPos );

% Position frames
set( hFrame1, 'Position', ...
   [0 0 winWide okGap]);             % frame for ok buttons
set( hFrame2, 'Position', ...
   [0 winHigh-2*uiGap-textHigh winWide textHigh+2*uiGap+0.5]); % top text
set( hFrame3, 'Position', ...
   [0 butWinBottom btnWide(1) butWinHigh]); % under row titles
set( hFrame4, 'Position', ...
   [0 winHigh-2*uiGap-textHigh-titleHigh winWide titleHigh]); % under col titles
set( hFrame5, 'Position', ...
   [0 winHigh-2*uiGap-textHigh-titleHigh btnWide(1) titleHigh]); % over row top / col left titles
if butWinWide<panelWide,
   set( hFrame6, 'Position', ...
    [0 okGap btnWide(1) scrollWide]); % over row title bottom
end;
if numRows<rowItems,
   set( hFrame7, 'Position', ...
    [winWide-scrollWide winHigh-2*uiGap-textHigh-titleHigh scrollWide titleHigh]); % over col title right
end;
if butWinWide<panelWide & numRows<rowItems,
   set( hFrame8, 'Position',[winWide-scrollWide okGap scrollWide scrollWide]);
end;                                            % little square at end of sliders


%------------------------------------------------------------------------
% Add in the OK and Cancel buttons
%------------------------------------------------------------------------
okSpace=(winWide-2*okWide)/3-uiGap; % Extra space if text or buttons are wider
okBtn = uicontrol( ...
           'Units'          ,SelUnits, ...
           'Position'       ,[uiGap+okSpace uiGap okWide btnHigh], ...
           'Callback'       ,'selectdlg2(''selDlg2_okClick'');', ...
           'String'         ,'OK' );
        
% Store the handle
hData.ok=okBtn;

CancelBtn = uicontrol( ...
           'Units'          ,SelUnits, ...
           'Position'       ,[2*uiGap+okWide+okSpace*2 uiGap okWide btnHigh], ...
           'Callback'       ,'selectdlg2(''selDlg2_cancelClick'');', ...
           'String'         ,'Cancel' );

%=========================================================================
% ACTIVATE
%=========================================================================
% Set callbacks for figure close
%------------------------------------------------------------------------
set(selFig, 'CloseRequestFcn' ,['selectdlg2(''selDlg2_cancelClick'');']);

%------------------------------------------------------------------------
% Store the necessary handles in the figure Userdata
%------------------------------------------------------------------------
set(selFig,'Userdata',hData);

%------------------------------------------------------------------------
% Make figure visible
%------------------------------------------------------------------------
set( selFig, 'Visible','on', 'HandleVisibility','callback' );

%------------------------------------------------------------------------
% Wait for choice to be made (i.e OK button UserData must be assigned)...
%------------------------------------------------------------------------
waitfor(okBtn,'userdata');

%------------------------------------------------------------------------
% ...selection has been made. Assign k and delete the Selection figure
%------------------------------------------------------------------------
isok = get(okBtn,'userdata');
if isok==1,
   cellData = get(hBtn,{'Value'});
else
   %   cellData = {0};
   k=[];
   delete(selFig)
   return;
end;

%if iscell(cellData),
   cellData=cat(1,cellData{:}); % convert all btn states to matrix
%end;
if length(cellData)>1,                             % put back shape
   cellData = reshape(cellData,rowItems,colItems); % unless cancelled
end;
[i,j]=find(cellData);          % get index answers

k=[i(:),j(:)];                 % make the result always a column of coords
delete(selFig)

end; %switch

%#########################################################################
%   END   :  main function selectdlg2
%#########################################################################

function uiPosMtx = local_selectPos(colItems,rowItems,btnWide,btnHigh,xSclOff,ySclOff,uiGap)

% Calculate coordinates of bottom-left corner of all buttons
xPos = xSclOff + ones(rowItems,1)*( [0,cumsum(btnWide(1:colItems-1) + uiGap)] ); % colItems columns
yPos = ySclOff + uiGap + [rowItems-1:-1:0]'*ones(1,colItems)*( btnHigh + uiGap ); % rowItems rows

% Combine with desired button size to get an array of position vectors
rowBtn   = ones(rowItems,colItems)*btnHigh;
colBtn   = ones(rowItems,1)*btnWide;
uiPosMtx = [ xPos(:), yPos(:), colBtn(:), rowBtn(:) ];
