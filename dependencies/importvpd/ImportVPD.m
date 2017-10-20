function data = ImportVPD(filename, varargin)
%IMPORTVPD reads Varioport (.vpd) binary data with some preprocessing options
%
% Description:
%   Reads .vpd file format produced by the Varioport psychophysiological
%   recording system, returns Matlab struct
%
%  
% Syntax:
% data = importVPD('filename','argument',value,'argument2',value,...)
%
%
% Inputs:
%   'filename'      string, aboslute or relative path of the vpd file
%
% Argument  (type)  [default value]  Description   
% 'verbose' (binary)     [1]   output present channels to screen
%
% 'peek'    (binary)     [0]   output present channels to screen, import nothing
%
% 'chnumbs' (array)      []    channels to import according to number(s)
%       //example: 'chnumbs',[1 4 13:14] ~ import channels 1,4,13 and 14
%
% 'chnames' (cell array) {}    channels to import according to name(s)   
%       //example: 'chames',{{'EKG'; 'EMG1'; 'MARKER'}}  ~ import said channels
%       - if set, overrides chnumbs value
%
% //If both chnumbs and chnames are left empty, imports all channels in file
%
% 'ds'      (cell array) {}    downsample channels
%       //example: 'ds',{{'EKG', 32; 'EMG1', 128}} ~ resample EKG to 32 Hz and EMG1 to 128 Hz   
%       - ratio between source and target samplerates must be integer 
%       - priority is first, so subsequent processing is done to the downsampled channel
%
% 'dsopt'   (int)        [1]    type of antialias filter to use in downsampling
%                             1 = 8th order Chebysev 
%                             2 = nth order Chebysev
%                             3 = 30th order FIR
%                             4 = nth order FIR
%                              
% 'dsorder'  (int)       [10]   filter order for the options where it´s specifiable
%
% 'readmarkers' (binary) [1]   import marker information if channel present
%
% 'ecgpeaks'  (binary)   [0]    ECG-peakdetection with Winmax algorithm
%       - rather heavy algorithm, needs more than 64 Hz sr to work 
%
% 'ecgpeakwaitbar' (binary) [1] Enable/disable progress bar for ECG peakdetection
%
%
% Example uses:
% 
% mydata = importVPD('EXP001.vpd', 'chnames', {{'EKG';'EMG1'}}, 'verbose', 0,...
% 'ecgpeaks', 1, 'ecgpeakwaitbar', 1, 'ds', {{'EKG',64;'EMG1',512}},...
% 'dsopt', 2, 'dsorder', 13)
% This imports channels EKG and EMG1 from the file, doesn´t print the
% channellist, resample EKG to 64 Hz and EMG1 to 512 Hz using order 13
% Chebysev antialiasfilter, detect ech peaks with progress bar enabled
% 
% importVPD('EXP001.vpd','peek',1)
% This print the channels present in file
%
% mydata = importVPD('EXP001.vpd')
% This import all channels into mydata struct
%
%
%
% Assumptions:
%    Data must be reconstructed with Variograf software.
%    Most of the actual read function taken and generalized from Ledalab V325
%    Tested on Matlab 7.9.0(R2009b)
%    Requires signal processing toolbox
%
% References:
%
% Example:
%
% Notes: Include some good-to-know information
%
% See also: vpd2eeglab
%
% Version history:
% v0.1 Pentti Henttonen 22.6.2010
%
% Added the function extractEventsInternal to parse an event struct from
% the marker channel internal to the VPD
% Ben Cowley (ben.cowley@aalto.fi)  16.7.2010
%
% Added 16.8.2010 by Pena:
% 1) free argument input (thought first must still be the filename)
% 2) possibility to request channels by name instead of number
% 3) verbosity is now optional (to an extent)
% 4) spiffy ecg-peakdetection
% 5) downsampling
% TBD:
% *) more filters
% *) EMG preprocessing
% 
% Copyright(c) 2010: Pentti Henttonen (pentti.henttonen@hse.fi)
% Extension copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%DEFAULT SETTINGS
%%override with function arguments
def.peek = 0;
def.verbose = 1;
def.chnumbs = [];
def.chnames = {};
def.readmarkers = 1;
def.ecgpeaks = 0;
def.ecgpeakwaitbar = 1;
def.ds = {};
def.dsopt = 1;
def.dsorder = 10; 

%overwrites defaults with arguments
args = struct(varargin{:});
argfields = fieldnames(args);
for argf = 1:length(argfields)
    def.(argfields{argf}) = args.(argfields{argf});
end 
clear args argfields;

%BEGIN FUNCTION

%open the actual file
fid = fopen(filename,'r','b');  %MOTOROLA format, big-endian

%if no channels requested, request all channels in file
if isempty(def.chnumbs) == 1 && isempty(def.chnames) == 1 
def.allchannels = 1;
else
def.allchannels = 0;    
end

%check if 'peek' argument present
%if yes, just call the "seevpdchans" function to display channels and
%terminate
if def.peek == 1
seevpdchans(filename,fid,1);  
fprintf('\n')
return
end

%call "seevpdchans" function to save the channels to main struct
%if verbose flag set on, print it on screen
if def.verbose == 1
data.channels = seevpdchans(filename,fid,1);  
else
data.channels = seevpdchans(filename,fid,0);  
end    
    
fprintf('\n');

%read the actual channel count from file
fseek(fid, hex2dec('0007'), 'bof');
knum = fread(fid, 1);

fprintf('Opening file: %s\n',filename)

%BEGIN CHANNEL REQUEST LIST LOOP

%check if allchans flas is set:

%if yes, make the reqchans variable and include all the channels
if def.allchannels == 1
reqchans = 1:knum;
fprintf('No channel list specified, extracting all channels (%i)\n',knum)

    %if not, use the requested channels names, if given
    elseif isempty(def.chnames) == 0
    % make the reqchans list from requested channels matching channellist
    lenchan=length(unique((def.chnames)));
    reqchans=zeros(1,lenchan);
    for chn_x = 1:lenchan
    try        
        reqchans(1,chn_x) =...
            find(strcmp(data.channels(:,1),def.chnames(chn_x))==1);         
    catch ME,
        disp(ME.message);   
    end    
    end 
    reqchans=unique(reqchans(reqchans>0));

        %if no name-requested channels, use the number-requested channels    
        else
        reqchans = def.chnumbs;   
end   


    %check if there are requested channels with value greater than
    %total number of channels present in the file.    
    %If there are some, print warning and include the bad channel #´s 
    if isempty(find(reqchans > knum, 1))== 0
    indx =  reqchans((find(reqchans > knum)));
    fprintf('Warning: nonexisting channels ( ')
        for cc = 1:length(indx)
        fprintf('%i\t',indx(cc))
        end    
        fprintf(') requested\n') 
    end    

%print the extracted channels and their names, using the data.channels cell
%gotten from seevpdchans function

    fprintf('Extracting channels:\n')  
    for jj = 1:length(reqchans)
        %only print progress if channels are in file
        if reqchans(jj) <= knum          
        fprintf('%i (%s)\n',reqchans(jj),data.channels{reqchans(jj),1})
        else
        end    
    end   
    fprintf('\n')    
    
%end
%END CHANNEL REQUEST LOOP

%OBTAIN SAMPLERATE, DATE AND TIME

%read division factor for global scanrate measure
fseek(fid, hex2dec('0014'), 'bof');
snrate = fread(fid, 1, 'uint16');

%set global scanrare (scaled "real" scanrate is 76800 / snrate)
gsrate = 76800;
%obtain scaled scanrate
scaled_scanrate = gsrate / snrate;

%read date and time of measurement start
%in BCD-format, need to convert to hex to obtain real value

%date of measure start
fseek(fid, hex2dec('0010'), 'bof');
rsdate = dec2hex(fread(fid, 3,'*ubit8'));
%time of measure start
fseek(fid, hex2dec('000c'), 'bof');
rstime = dec2hex(fread(fid, 3,'*ubit8'));

%Save total channels and samplerate to main struct
data.total_channels = knum;
data.global_scanrate = scaled_scanrate;

%Convert the date and time arrays into Matlab date format 
%and save to main struct
data.mdate = datestr(sprintf('%s,%s,%s',rsdate(2,:),rsdate(1,:),rsdate(3,:)),1);
data.mtime = datestr(sprintf('%s:%s:%s',rstime(1,:),rstime(2,:),rstime(3,:)),13);

%END OBTAIN SAMPLERATE, DATE AND TIME

%%%BEGIN MAIN LOOP%%%
        
    for i=1:length(reqchans)    
        %check that requested channel exists in present channels    
        if reqchans(i) <= knum   
            %call "channelread" function for requested channels
            %save output channel data to main struct
            data.chn(i) = channelread(reqchans(i),fid,scaled_scanrate,knum);       
        else
            %if channel doesn´t exist, leave empty and move on
            %%%if requested channels contain unobtainable channels 
            %%%not in linear order, this may result in empty
            %%%channels inside main struct. No biggie.
        end
                                  
        if isempty(def.ds) ~= 1        
            dspresent = find(strcmp(data.chn(i).chname,def.ds)==1);
        
            if isempty(dspresent) ~= 1
                data.chn(i).signal = imvpdsample(data.chn(i).signal...
                , data.chn(i).sr, cell2mat(def.ds(dspresent,2)), def.dsopt...
                , def.dsorder, data.chn(i).chname);
                data.chn(i).sr = cell2mat(def.ds(dspresent,2));
            end
        
        end
        
        %check if read markers flag is set
        if def.readmarkers == 1
        
            % If this is the marker channel...
            if strcmp(data.chn(i).chname, 'MARKER')
                % Parse marker signals and append to this channel's output data
                data.events =...
                    extractEventsInternal(data.chn(i).signal, data.chn(i).sr);
            end
        end
        
        %check whether waitbat for the (lenghty) ecg peakdetection is
        %wanted
        if def.ecgpeakwaitbar == 1
            waitbar = 1;
        else
            waitbar = 0;    
        end
        
        %check if ecg-peaksdetection flag is set                
        if def.ecgpeaks == 1 %only for EKG or ECG
            if strcmp(data.chn(i).chname, 'EKG') || strcmp(data.chn(i).chname, 'ECG')
                data.chn(i).rpeaks =...
                    imvpd_ecgpeaks(data.chn(i).signal, data.chn(i).sr, waitbar);
            end
        end

    end


%close the opened file and end
fclose(fid);
fprintf('DONE!')
end

%%%END MAIN LOOP%%%

%%%%CHANNEL READ FUNCTION%%%%
%INPUT: requested channel number, filename, scaled samplerate, 
%total number of channels in file
%OUTPUT: channel name, channel unit, channel samplerate, signal
%
%VARIPORT DATA IS OBTAINED AS FOLLOWING:
%Physical value = (Binary value - Offset) * Multip. factor / Div. factor
%Final storage samplerate = 76800Hz / Snrate / Scanfc / Stofac

function out = channelread(chnr,fid,scnrate,chncnt)
%%%this function is almost 100% taken from LedaLabV325!!!

%Read requested channel name, pass directly to output
fseek(fid, (chnr - 1) * 40 + 36, 'bof');
out.chname = strtrim(fread(fid, 6,'*char')');  

%Read multiplication factor value
fseek(fid, (chnr - 1) * 40 + 52, 'bof');
mul = fread(fid, 1, 'uint16');
%Read division factor value
fseek(fid, (chnr - 1) * 40 + 56, 'bof');
div = fread(fid, 1, 'uint16');
%Read offset value
fseek(fid, (chnr - 1) * 40 + 54, 'bof');
offset = fread(fid, 1, 'uint16');
%Read channel resolution. 1: 2 byte(WORD), 0: 1 byte(BYTE)
fseek(fid, (chnr - 1) * 40 + 47, 'bof');
res = fread(fid, 1);
if res && 1
    sres = 'uint16';
else
    sres = 'uint8';
end;
%Read channel unit
fseek(fid, (chnr - 1) * 40 + 42, 'bof');
unit = strtrim((fread(fid, 4,'*char'))');
    
%Read channel sampling rate factor
fseek(fid, (chnr - 1) * 40 + 48, 'bof');
scan_fac = fread(fid, 1);

%Read channel storage rate factor
fseek(fid, (chnr - 1) * 40 + 50, 'bof');
store_fac = fread(fid, 1);

%Calculate final storage rate
scaled_scan_fac = scnrate/(scan_fac * store_fac);

%Read file offset: begin of channel data
fseek(fid, (chnr - 1) * 40 + 60, 'bof');
%Read origin (=after cheksum header incl. channeldef)
doffs = fread(fid, 1,'uint32') + 38 + chncnt* 40;
%Read channel length in byte
fseek(fid, (chnr - 1) * 40 + 64, 'bof');
dlen = fread(fid, 1,'uint32');

%Using all information, read channel data
fseek(fid, doffs, 'bof');
rawsignal = fread(fid, dlen / (res + 1), sres);

%Pass the unit and samplerate to output
out.unit = unit;
out.sr = scaled_scan_fac;

%Calculate the real physical signalm pass to output
out.signal = (rawsignal - offset) .* (mul / div);
%END OF CHANNEL READ FUNCTION%
end

%%%PRINT .VPD CHANNELS FUNCTION%%%
function [channellist] = seevpdchans(filename,fid,verbose)

%read total number of channels
fseek(fid, hex2dec('0007'), 'bof');
cnum = fread(fid, 1);

%read the samplerate and scale it
fseek(fid, 20, 'bof');
scanrate = fread(fid, 1, 'uint16');
scnrate = 76800 / scanrate;

%main loop through all channels present
%save obtained data to "chans" array
chans=cell(cnum,3);
for i = 1:cnum    
    %read channel name, save to first column of array    
    fseek(fid, (i - 1) * 40 + 36, 'bof');
    chans{i,1} = strtrim(fread(fid, 6,'*char')');  
    %read channel unit, save to second column 
    fseek(fid, (i - 1) * 40 + 42, 'bof');
    chans{i,2}= strtrim((fread(fid, 4,'*char'))');
    %read and calculate real samplerate, save to third column
    fseek(fid, (i - 1) * 40 + 48, 'bof');
    scanfac = fread(fid, 1);
    fseek(fid, (i - 1) * 40 + 50, 'bof');
    storefac = fread(fid, 1);
    chans{i,3} = scnrate/(scanfac * storefac);
end

%pass chans array to ouput
channellist = chans;

if verbose == 1
    %Display on screen
    fprintf('\n##############################\n')
    fprintf('Channel info for %s\n',filename)
    fprintf('##############################\n')
    fprintf('#\tCHANNEL\tUNIT\tSamplerate\n')
    %loop through all channels
    for j = 1:cnum
    fprintf('%i\t%s\t\t%s\t\t%i\n',j,char(chans{j,1}),char(chans{j,2}),chans{j,3})        
    end
end
%END PRINT .VPD CHANNELS FUNCTION%
end

%%% extractEventsInternal FUNCTION %%%
% Short event extraction script for reading markers in VPD marker channel
function event = extractEventsInternal( signal, sr )

fprintf('Extracting event information...')
% Init vars to handle counting and storing events
N=length(signal);
a=1;
i=1;
% Prealloc event struct for speed
event=struct('time',{},'nid',{},'name',{},'userdata',{{}});
% While loop to run through marker channel indices
while i<N
    % If a marker channel element is non-0
    if signal(i)~=0
        % Fix the index of the 1st non-0 element
        j=i;
        % Count through all subsequenct elements of the same value
        while j<N && signal(j+1)==signal(j)
            j = j+1;
        end
        % Leave j as only the distance between i and j
        j=j-i;
        % Create an event with core data:
        event(a).time=i/sr; %1st time of marker in secs
        event(a).nid=a; %unique ID for marker
        event(a).name=signal(i); %name of event = marker value
        % ...and metadata
        event(a).userdata.dur=j/sr; %duration of marker in secs
        a=a+1; %Increment for next event
        i=i+j; %Jump i to end of the marker segment
    end
    i=i+1;
end
fprintf('..done\n')
%%% END extractEventsInternal FUNCTION %%%
end

function [rpeaks] = imvpd_ecgpeaks(ecg,samplingrate,waitbar)
%LIBROW ecg_peakdetection function
     fprintf('#Running Librow ecg peak detection#\n This might take some time...\n');
       
     if  samplingrate < 64
     fprintf('Warning: samplerate is too small for effective ECG-peakdetection\nApproach results with caution!\n')     
     else
     end
     
 % Remove lower frequencies with (I)FFT
    fprintf('FFT lowpass filter...\n');
 
    fresult=fft(ecg);
    fresult(1 : round(length(fresult)*5/samplingrate))=0;
    fresult(end - round(length(fresult)*5/samplingrate) : end)=0;
    
    corrected=real(ifft(fresult));  %=>ECG with removed low-frequency component
            
 %   Filter - first pass
 
    fprintf('Winmax filter, 1st pass (default window)...\n');
    WinSize = floor(samplingrate * 571 / 1000);
    if rem(WinSize,2)==0
        WinSize = WinSize+1;
    end
    
    if waitbar == 1
    filtered1=ecgdemowinmax(corrected, WinSize,1); %=>Filtered ECG (1-st pass) - filter has default window size
    else
    filtered1=ecgdemowinmax(corrected, WinSize,0); %=>Filtered ECG (1-st pass) - filter has default window size    
    end
  
 %   Scale ecg
    peaks1=filtered1/(max(filtered1)/7);    
    
 % Filter by threshold filter
    fprintf('Threshold filter...\n');
    for data = 1:1:length(peaks1)
        if peaks1(data) < 4
            peaks1(data) = 0;
        else
            peaks1(data)=1;
        end
    end
    positions=find(peaks1);
    distance=positions(2)-positions(1);
    for data=1:1:length(positions)-1
        if positions(data+1)-positions(data)<distance
            distance=positions(data+1)-positions(data);
        end
    end
     %peaks =>Detected peaks in filtered ECG
     %positions =>positions of peaks in sample
    
  % Optimize filter window size
    QRdistance=floor(0.04*samplingrate);
    if rem(QRdistance,2)==0
        QRdistance=QRdistance+1;
    end
    WinSize=2*distance-QRdistance;
    
    
    
  % Filter - second pass
    fprintf('Winmax filter, 2nd pass (optimized size)...\n');
    
    if waitbar == 1
    filtered2=ecgdemowinmax(corrected, WinSize,1);  %=> Filtered ECG (2-d pass) - now filter has optimized window size
    else
    filtered2=ecgdemowinmax(corrected, WinSize,0);
    end    
        
    peaks2=filtered2;  
    for data=1:1:length(peaks2)
        if peaks2(data)<4
            peaks2(data)=0;
        else
            peaks2(data)=1;
        end
    end
    %peaks2 =>Detected peaks in filtered ECG after second pass
    positions2=find(peaks2); %=>final positions of peaks in sample
  
  
  if isempty(positions2) ~= 1  
    
  rtd=difff(positions2')/(samplingrate*1000);  
  ecgts = timeseries(rtd,positions2);
  ecgts = setinterpmethod(ecgts,'zoh');
  newecgtime = 1:length(ecg); 
  ecgts = resample(ecgts,newecgtime,'zoh');
  ibi0 = ecgts.data;
  
  %out.lowpassed = corrected;
  rpeaks.positions = positions2;
  rpeaks.ibi = ibi0; 
  
  fprintf('Peakdetection complete!\n');
  
  else
  fprintf('No peaks found! Check signal and samplerate!\n');      
  rpeaks.positions = [];
  rpeaks.ibi = [];
  
  end
  
end
  

function Filtered=ecgdemowinmax(Original, WinSize,waitbar)

if waitbar == 1
info.title = 'Running WinMax';
info.msg = 'Progress';   
info.color = [1 0 0]; %red
else
end    

    WinHalfSize = floor(WinSize/2);
    WinHalfSizePlus = WinHalfSize+1;
    WinSizeSpec = WinSize-1;
    FrontIterator = 1;
%     WinPos = WinHalfSize;
    WinMaxPos = WinHalfSize;
    WinMax = Original(1);
    OutputIterator = 0;
    for LengthCounter = 0:1:WinHalfSize-1
        if Original(FrontIterator+1) > WinMax
            WinMax = Original(FrontIterator+1);
            WinMaxPos = WinHalfSizePlus + LengthCounter;
        end
        FrontIterator=FrontIterator+1;
    end
    if WinMaxPos == WinHalfSize
        Filtered(OutputIterator+1)=WinMax;
    else
        Filtered(OutputIterator+1)=0;
    end
    OutputIterator = OutputIterator+1;
   
    
    for LengthCounter = 0:1:WinHalfSize-1
        if Original(FrontIterator+1)>WinMax
            WinMax=Original(FrontIterator+1);
            WinMaxPos=WinSizeSpec;
        else
            WinMaxPos=WinMaxPos-1;
        end
        if WinMaxPos == WinHalfSize
            Filtered(OutputIterator+1)=WinMax;
        else
            Filtered(OutputIterator+1)=0;
        end
        FrontIterator = FrontIterator+1;
        OutputIterator = OutputIterator+1;
       
    end
    
    if waitbar == 1
    h = progbar(info);
    else
    end
        
    for FrontIterator=FrontIterator:1:length(Original)-1
        if Original(FrontIterator+1)>WinMax
            WinMax=Original(FrontIterator+1);
            WinMaxPos=WinSizeSpec;
        else
            WinMaxPos=WinMaxPos-1;
            if WinMaxPos < 0
                WinIterator = FrontIterator-WinSizeSpec;
                WinMax = Original(WinIterator+1);
                WinMaxPos = 0;
                WinPos=0;
                for WinIterator = WinIterator:1:FrontIterator
                    if Original(WinIterator+1)>WinMax
                        WinMax = Original(WinIterator+1);
                        WinMaxPos = WinPos;
                    end
                    WinPos=WinPos+1;
                end
            end
        end
        if WinMaxPos==WinHalfSize
            Filtered(OutputIterator+1)=WinMax;
        else
            Filtered(OutputIterator+1)=0;
        end
        OutputIterator=OutputIterator+1;
        
   if waitbar == 1     
   progbar(h,(FrontIterator/(length(Original)-1))*100)         
   else
   end    
                                  
    end
    
   if waitbar ==1 
   progbar(h,-1) 
   else
   end    
   
%     WinIterator = WinIterator-1;
    WinMaxPos = WinMaxPos-1;
    for LengthCounter=1:1:WinHalfSizePlus-1
        if WinMaxPos<0
            WinIterator=length(Original)-WinSize+LengthCounter;
            WinMax=Original(WinIterator+1);
            WinMaxPos=0;
            WinPos=1;
            for WinIterator=WinIterator+1:1:length(Original)-1
                if Original(WinIterator+1)>WinMax
                    WinMax=Original(WinIterator+1);
                    WinMaxPos=WinPos;
                end
                WinPos=WinPos+1;
            end
        end
        if WinMaxPos==WinHalfSize
            Filtered(OutputIterator+1)=WinMax;
        else
            Filtered(OutputIterator+1)=0;
        end
        FrontIterator=FrontIterator-1;
        WinMaxPos=WinMaxPos-1;
        OutputIterator=OutputIterator+1;
      
       
    end  
end

function [handle]=progbar(pb, progress, msg)

% progbar.m

% update form
if nargin == 2 || nargin == 3

	try
		% get info
		info=get(pb, 'userdata');
    catch ME,
        disp(ME.message);
		% ignore in that case
		return;
	end

	% close
	if(progress==-1),	close(pb);	return; end

	% get out fast
	if (info.period)
		if (cputime - info.lastclock)<info.period,  return; end
		info.lastclock=cputime;
		set(pb,'userdata',info);
	end

	% check types
	if ~isnumeric(pb)
		error('pb should be a progress bar handle');
	end
	if ~isnumeric(progress)
		error('progress should be numeric');
	end

	% constrain
	if(progress<=0),    progress=0.001; end
	if(progress>100),   progress=100;   end

	% do update
	BarHandle=get(get(pb,'Children'),'Children');
	set(BarHandle,'position',[0 0 progress 1],'visible','on');
	progress=ceil(progress-0.5);
	if isempty(info.title)
		set(pb,'name',[int2str(progress) '%']);
	else
		set(pb,'name',[int2str(progress) '% - ' info.title]);
	end

	% handle msg
	if nargin == 3
		ax=get(pb, 'children');
		ti=get(ax, 'title');
		set(ti, 'string', msg);
	end

	% ok
	drawnow
	return

end

if nargin<2
	if nargin==0,   info.dummy='dummy'; end
	if nargin==1,   info=pb;    end

	% check type
	if isa(info, 'char')
		if strcmp(info, 'demo')
			progbar_demo
			return
		end
		if strcmp(info, 'perfdemo')
			progbar_perfdemo
			return
		end
		if strcmp(info, 'testdemo')
			progbar_testdemo
			return
		end
	end

	if ~isstruct(info)
		error('Single argument should be an info structure or ''demo''');
	end

	% extract
	if ~isfield(info,'title'),  info.title='';	end
	if ~isfield(info,'msg'),    info.msg='';	end
	if ~isfield(info,'size'),   info.size=1;	end
	if ~isfield(info,'period'), info.period=0.1;	end
	if ~isfield(info,'pos'),    info.pos='centre';	end
	if ~isfield(info,'color'),  info.color=[0 0 192]/255;   end
	if ~isfield(info,'clearance'),  info.clearance=0;   end

	% check values
	if floor(info.size)~=info.size || info.size<1 || info.size>5
		error('size should be a small integer (1-5)');
	end
	if info.period<0
		error('period should not be negative');
	end
	if info.clearance<0 || info.clearance>1
		error('clearance should be between 0 and 1');
	end

	spars=get(0,'screensize');
	sl=spars(1);
	sb=spars(2);
	sw=spars(3);
	sh=spars(4);

	pw=200*info.size; % progress bar width
	ph=16*info.size; % progress bar height
	mh=~isempty(info.msg)*30;	% message bar height
	border=16;
	th=border+ph+border+mh; % total height
	tw=border+pw+border; % total width

	% check position
	switch info.pos
		case {'center','centre'}
			x=sl+sw/2;
			y=sb+sh/2;
		case {'centerleft','centreleft'}
			x=sl+sw/4;
			y=sb+sh/2;
		case {'centerright','centreright'}
			x=sl+3*sw/4;
			y=sb+sh/2;
		case {'top'}
			x=sl+sw/2;
			y=sb+3*sh/4;
		case {'topleft'}
			x=sl+sw/4;
			y=sb+3*sh/4;
		case {'topright'}
			x=sl+3*sw/4;
			y=sb+3*sh/4;
		case {'bottom'}
			x=sl+sw/2;
			y=sb+sh/4;
		case {'bottomleft'}
			x=sl+sw/4;
			y=sb+sh/4;
		case {'bottomright'}
			x=sl+3*sw/4;
			y=sb+sh/4;
		otherwise
			error(['pos ''' info.pos ''' was not recognised']);
	end

	info.lastclock=cputime;
	info.id='progbar';
	handle=figure(...
		'MenuBar','none',...
		'numbertitle','off',...
		'userdata',info,...
		'name',info.title);
	set(handle,'position',[x-tw/2 y-th/2 tw th]);
	set(handle,'resize','off');

	% get color
	color=info.color;
	if ~isempty(which('rgb.m'))
		color=rgb(color);
	end

	% check color
	if ~isa(color,'double') || size(color,1)~=1 || size(color,2)~=3
		close(handle);
		error('Unrecognised color');
	end

	rectangle('position',[0 0 0.001 1],'facecolor',color,'edgecolor',color,'visible','off')
	set(gca,'position',[border/tw border/th pw/tw ph/th])
	axis([0 100 -info.clearance 1+info.clearance])
	set(gca,'Xtick',[]);
	set(gca,'Ytick',[]);
	set(gca,'box','on');

	title(info.msg);
	drawnow
	return

end

end


function [downsampled] = imvpdsample(input,ssr,tsr,opt,ord,sname)

fac = ssr / tsr;

if ssr < tsr == 1
fprintf('Target samplerate higher than source!')
downsampled = input;
return
else    
end

if opt == 1
fprintf('Downsampling %s signal from %i to %i Hz using order 8 Chebysev filter...',sname,ssr,tsr)
downsampled = decimate(input,fac); %8th order Chebyshev filter
fprintf('....done\n')

elseif opt == 2
fprintf('Downsampling %s signal from %i to %i Hz using order %i Chebysev filter...',sname,ssr,tsr,ord)    
downsampled = decimate(input,fac,ord); %nth order Chebyshev filter
fprintf('....done\n')

elseif opt == 3
fprintf('Downsampling %s signal from %i to %i Hz using order 30 FIR filter...',sname,ssr,tsr)    
downsampled = decimate(input,fac,'fir');  %30th order FIR filter   
fprintf('....done\n')

elseif opt == 4
fprintf('Downsampling %s signal from %i to %i Hz using order %i FIR filter...',sname,ssr,tsr,ord)    
downsampled = decimate(input,fac,ord,'fir'); %nth order FIR filter
fprintf('....done\n')

end
%elseif opt == 5
%fprintf('Decimating signal from %i to %i Hz\n',ssr,tsr)
%downsampled = downsample(input,fac); %decimation fithout lowpass    
%fprintf('..done\n')
end

function y = difff(x)   
y=[diff(x);NaN];
end

