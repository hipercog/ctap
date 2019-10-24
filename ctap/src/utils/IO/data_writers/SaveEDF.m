function SaveEDF(filename, data, header) 
% SAVEEDF
% Author:  Shapkin Andrey, 
% 15-OCT-2012
% 
% Specifications of EDF+ :  http://www.edfplus.info/
% 
% filename - File name
% data - [m n] signals matrix (m - #channels, n - signal length), 
%           data can also be cell of signals data
% 
% header - Contains structure:
%%% 1
% header.patientID local patient identification data:
%   [patientID Sex(F or M) Birthdate (dd-MMM-yyyy) Name_name]
%   example: NNN-0001 M 01-JAN-2000 Ivanov_Ivav_Ivanovich
%   Default [X X X X]
% or:
% header.patient            structure of cells with patient ID:
% header.patient.ID         patient code, default XX
% header.patient.Sex        Sex(F or M), default X
% header.patient.BirthDate  birthdate in dd-MMM-yyyy format using the English 3-character abbreviations of the month in capitals default 01-JAN-2000
% header.patient.Name       patient name, defaul X
% 
%%% 2
% header.recordID local recording identification data:
%   [Startdate dd-MMM-yyyy recordID technician_code equipment_code] 
%   Default [Startdate X X X X]
%   example: Startdate 02-MAR-2002 PSG-1234/2002 Petrov_7180 Telemetry03
% or:
% header.record     structure of cells with record ID:
% header.record.ID  hospital administration code of the investigation, default X
% eader.record.Tech code specifying the responsible investigator or technician , default X
% header.record.Eq  code specifying the used equipment, default X
% 
%%% 3
%    startdate of recording (dd.mm.yy)
%    header.StartDate  , default = 01.01.00
%%% 4
%    starttime of recording (hh.mm.ss)
%    header.StartTime  , default = 00.00.00
% 5  header.duration        signal block duration in seconds, 
%                           Default = 1
% 6  header.labels        - structure of cells with name of channels, 
%                           Default: numbering of channels
% 7  header.transducer    - transducer type  or structure of cells with transducer type of channels, 
%                           Default = ' '
% 8  header.units         - physical dimension or structure of cells with  physical dimension of channels, 
%                           Default = ' '
% 9  header.prefilt       - prefiltering or structure of cells with prefiltering of channels, 
%                           Default = ' ' -  HP:0.1Hz LP:75Hz N:50Hz
%%% 10 Annotation
% header.annotation.event      structure of cells with event name 
% header.annotation.duration   vector with event duration (seconds)
% header.annotation.starttime  vector with event startime  (seconds)
%%% 
% 11 header.samplerate


if ~isfield(header, 'duration')
    header.duration=1;
end

if ~iscell(data),
    data=num2cell(data, 1);
end


% samplerate
samplerate=header.samplerate(1);
header.samplerate = repmat(samplerate, length(data),1);

header.channels = length(data);
signal_length=length(data{1});
header.records=ceil(signal_length/(header.samplerate(1).*header.duration)); % Quantity of blocks



%%%% PART 1: Annotation channel formation

%EDF annotations contents TALs structure +Ts[21]Ds[20]Event text[20][0]
% + start TALs
% Ts starttime of event in seconds
% [21]Ds duration of event in seconds (optional) [21]=char(21)
% [20]Event text[20] event description  [20]=char(20)
% [0] char(0) end TALs  [0]=char(0)
%The Annotation save in the form of the additional channel [EDF Annotations] containing ASCII in a digital form

% header.records - number of blocks
Pa=5; % quantity of events in one block
if Pa>length(header.annotation.event), Pa=length(header.annotation.event); end
if length(header.annotation.event)*Pa>header.records % if [quantity of events]*P >> [number of blocks]
    Pa=ceil(length(header.annotation.event)./header.records);
end

%  % TALs forming
Annt=cell(1, header.records); 
for p1=1:header.records
    a=[43 unicode2native(num2str(p1-1)) 20 20 00];
     if Pa.*p1<=length(header.annotation.event)
for p2=Pa.*p1-Pa+1:Pa.*p1
    a=[a 43 unicode2native(num2str(header.annotation.starttime(p2)))];
        if header.annotation.duration(p2)>0
       a=[a 21 unicode2native(num2str(header.annotation.duration(p2)))];
        end
       a=[a 20 unicode2native(header.annotation.event{p2}) 20 00];
end
    end
Annt{p1}=a;
 
    end
fs=cell2mat(cellfun(@length, Annt, 'UniformOutput', false)); 
AnnotationSR=ceil(max(fs)./2).*2; if AnnotationSR<header.samplerate(1), AnnotationSR=header.samplerate(1).*2; end
AnnotationDATA=zeros(AnnotationSR, header.records);
for p1=1:header.records
    AnnotationDATA(1:fs(p1), p1)=Annt{p1};
end

% channel with annotation data
AnnotationDATA=typecast(uint8(AnnotationDATA(:)'), 'int16');
AnnotationSR=length(AnnotationDATA)./header.records; % samplerate annotation channel

data=[data double(AnnotationDATA)];
header.samplerate=[header.samplerate; AnnotationSR];

header.channels = length(data);
signal_length=length(data{1});


%%%%% PART 2: Header forming

%1 local patient identification
if ~isfield(header,'patientID')
       header.patientID='';
    if isfield(header,'patient')
     %1 patient code
        if ~isfield(header.patient,'ID')
            header.patientID='X';
        else
            header.patientID=header.patient.ID;
        end
     %2 Sex
        if ~isfield(header.patient,'Sex')
            header.patientID=[header.patientID ' X'];
        else
            header.patientID=[header.patientID ' ' header.patient.Sex];
        end
    %3 BirthDate
        if ~isfield(header.patient,'BirthDate')
            header.patientID=[header.patientID ' X'];
        else
            header.patientID=[header.patientID ' ' header.patient.BirthDate];
        end
    %4 Patient name 
        if ~isfield(header.patient,'Name')
            header.patientID=[header.patientID ' X'];
        else
            header.patient.Name(double(header.patient.Name)==32)='_';
            header.patientID=[header.patientID ' ' header.patient.Name];
        end
    else
        header.patientID='X X X X';
    end   
end
       
header.patientID=header.patientID(:);

%2 local recording identification
if ~isfield(header,'recordID')
   header.recordID='Startdate'; 
   
if ~isfield(header, 'startdate')
header.recordID=[header.recordID ' X'];
else
   F_month={'JAN' 'FEB' 'MAR' 'APR' 'MAY' 'JUN' 'JUL' 'AUG' 'SEP' 'OCT' 'NOV' 'DEC'};
   header.recordID=[header.recordID ' ' header.startdate(1:2) '-' F_month{str2num(header.startdate(4:5))} '-' header.startdate(7:8)];
end

    if isfield(header,'record')
    %1 hospital administration code of the investigation
        if ~isfield(header.record,'ID')
             header.recordID=[header.recordID ' X'];
        else
            header.recordID=[header.recordID ' ' header.record.ID];
        end
    %2 code specifying the responsible investigator or technician
        if ~isfield(header.record,'Tech')
           header.recordID=[header.recordID ' X'];
        else
            header.recordID=[header.recordID ' ' header.record.Tech];
        end 
    %3 code specifying the used equipment, default X
        if ~isfield(header.record,'Eq')
           header.recordID=[header.recordID ' X'];
        else
           header.recordID=[header.recordID ' ' header.record.Eq];
        end     
    else
        header.recordID=[header.recordID ' X X X'];
    end
end
 header.recordID= header.recordID(:);

%3 startdate of recording (dd.mm.yy)
if ~isfield(header, 'startdate')
header.startdate='01.01.00';
end
header.startdate=header.startdate(:);

%4 starttime of recording (hh.mm.ss)
if ~isfield(header, 'starttime')
header.starttime='00.00.00';
end
header.starttime=header.starttime(:);


%5 labels
if ~isfield(header, 'labels')
    header.labels=cellstr(num2str([1:header.channels-1]'));
end
header.labels{end+1}='EDF Annotations';% annotation channel
labels = char(32*ones(header.channels, 16));

for n=1:header.channels
    if length(header.labels{n})>16,header.labels{n}=header.labels{n}(1:16);end
labels(n,1:length(header.labels{n})) = header.labels{n}; 
end
header.labels=labels';
header.labels=header.labels(:);

%6 transducer type
if ~isfield(header, 'transducer')
header.transducer={' '};
end
if ~iscell(header.transducer), header.transducer={header.transducer}; end
if length(header.transducer)==1
   header.transducer(1:header.channels)=header.transducer;
end
    
transducer=char(32*ones(header.channels, 80));
for n=1:header.channels
    if n>length(header.transducer)
        header.transducer{n}=' ';
    end
if length(header.transducer{n})>80,header.transducer{n}=header.transducer{n}(1:80);end
if isempty(header.transducer{n}), header.transducer{n}=' '; end
transducer(n,1:length(header.transducer{n})) = header.transducer{n}; 
end
header.transducer=transducer';
header.transducer=header.transducer(:);

%7 units

if ~isfield(header, 'units')
header.units={' '};
end
if ~iscell(header.units), header.units={header.units}; end
if length(header.units)==1
   header.units(1:header.channels)=header.units;
end
    
units=char(32*ones(header.channels, 8));
for n=1:header.channels
    if n>length(header.units)
        header.units{n}=' ';
    end
if length(header.units{n})>8,header.units{n}=header.units{n}(1:8);end
if isempty(header.units{n}), header.units{n}=' '; end
units(n,1:length(header.units{n})) = header.units{n}; 
end
units(double(units)<32)=' ';
units(double(units)>126)=' ';

header.units=units';
header.units=header.units(:);


%8 prefiltering

if ~isfield(header, 'prefilt')
header.prefilt={' '};
end
if ~iscell(header.prefilt), header.prefilt={header.prefilt}; end
if length(header.prefilt)==1
   header.prefilt(1:header.channels)=header.prefilt;
end
    
prefilt=char(32*ones(header.channels, 80));
for n=1:header.channels
    if n>length(header.prefilt)
        header.prefilt{n}=' ';
    end
if length(header.prefilt{n})>80,header.prefilt{n}=header.prefilt{n}(1:80);end
prefilt(n,1:length(header.prefilt{n})) = header.prefilt{n}; 
end
header.prefilt=prefilt';

header.prefilt=header.prefilt(:);

%9 samplerate
samplerate=header.samplerate;
header.samplerate=sprintf('%-8i', header.samplerate)';
header.samplerate=header.samplerate(:);


%PART 3: forming of data

% detrend
%data(1:end-1)=cellfun(@detrend, data(1:end-1), 'UniformOutput', false);

header.physmax = repmat(32767, header.channels,1);
header.physmin = repmat(-32768,header.channels,1);
header.digmax = repmat(32767,header.channels,1);
header.digmin = repmat(-32768,header.channels,1);
%
header.digmin = sprintf('%-8i', header.digmin)'; % digital minimum
header.digmax = sprintf('%-8i', header.digmax)';  %digital maximum
header.physmin = sprintf('%-8i', header.physmin)';  %physical minimum  
header.physmax = sprintf('%-8i', header.physmax)'; %physical maximum  

%Scale=32767/maxdata;
%data(1:end-1)=cellfun(@(x) x.*Scale, data(1:end-1), 'UniformOutput', false);

% preparing the data


%Structure of the data in format EDF:

%[block1 block2 .. , block Pn], where Pn is quantity of blocks  Pn=header.records
% Block structure:
% [(d seconds of 1 channel) (d seconds of 2 channel) ... (d seconds of �h channel)], Where �h - quantity of channels, d - duration of the block
% Ch = header.channels
% d = header.duration


for p1=1:length(data)
    data{p1}=(buffer(data{p1}, samplerate(p1).*header.duration, 0));
end

DATAout=cell2mat(data');
DATAout=DATAout(:);
    
    
%%%  SAVE DATA    
fid = fopen(filename, 'wb', 'ieee-le');

%%%%%% PART4: save header
 % 8 ascii : version of this data format (0)
fprintf(fid, ['0       ']);   
% 80 ascii : local patient identification
fprintf(fid, '%-80s', [header.patientID]);
% 80 ascii : local recording identification
fprintf(fid,'%-80s', [header.recordID]);
% 8 ascii : startdate of recording (dd.mm.yy)
fprintf(fid, '%8s', header.startdate); 
% 8 ascii : starttime of recording (hh.mm.ss)
fprintf(fid, '%8s', header.starttime);
% 8 ascii : number of bytes in header record
fprintf(fid, '%-8s', num2str(256*(1+header.channels)));  % number of bytes in header
% 44 ascii : reserved
fprintf(fid, '%-44s', 'EDF+C'); % reserved (44 spaces)
% 8 ascii : number of data records (-1 if unknown)
fprintf(fid, '%-8i', header.records);  
% 8 ascii : duration of a data record, in seconds
fprintf(fid, '%8f', header.duration);  % header.duration=1 seconds;
% 4 ascii : number of signals (ns) in data record
fprintf(fid, '%-4s', num2str(header.channels));  

% ns * 16 ascii : ns * label (e.g. EEG FpzCz or Body temp)
fwrite(fid, header.labels, 'char*1'); 
% ns * 80 ascii : ns * transducer type (e.g. AgAgCl electrode)
fwrite(fid, header.transducer, 'char*1'); 
% ns * 8 ascii : ns * physical dimension (e.g. uV or degreeC)
fwrite(fid, header.units, 'char*1'); 
% ns * 8 ascii : ns * physical minimum (e.g. -500 or 34)
fwrite(fid, header.physmin, 'char*1'); 
% ns * 8 ascii : ns * physical maximum (e.g. 500 or 40)
fwrite(fid, header.physmax, 'char*1'); 
% ns * 8 ascii : ns * digital minimum (e.g. -2048)
fwrite(fid, header.digmin, 'char*1'); 
 % ns * 8 ascii : ns * digital maximum (e.g. 2047)
fwrite(fid, header.digmax, 'char*1');
% ns * 80 ascii : ns * prefiltering (e.g. HP:0.1Hz LP:75Hz)
fwrite(fid, header.prefilt, 'char*1'); 
% ns * 8 ascii : ns * nr of samples in each data record
fwrite(fid, header.samplerate, 'char*1'); 
% ns * 32 ascii : ns * reserved
fwrite(fid, repmat(' ', 32.*header.channels, 1), 'char*1'); % reserverd (32 spaces / channel)

%%%%%% PART5: save data
fwrite(fid, DATAout, 'int16');
fclose(fid);
