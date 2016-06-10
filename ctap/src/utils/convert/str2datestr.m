function dstr = str2datestr(dmy,hms)
%STR2DATESTR - Convert string into datestr -format
%
% Description:
%   Converts string representations of date and time into Matlab datestr
%   format.
%   Runtime constants not defined by function arguments: no
%
% Syntax:
%   dstr = str2datestr(dmy,hms);
%
% Inputs:
%   dmy     string, dd.mm.yyyy representation of date
%   hms     string, hh:mm:ss OR hh;mm;ss representation of time
%
% Outputs:
%
% References:
%
% Example:
%   dstr = str2datestr('20.12.2007', '11:30:12');
%   dstr = str2datestr('20.12.2007', '11;30;12');
%
% See also:
% datestr, datenum
%
% Version History:
%   Based on csvtime_to_datestr.m
%
% Copyright: 2007-2007 Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Runtime constants not defined by function arguments
% none
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Read delimiter locations
dmytmp = strfind(dmy,'.');
hmstmp = strfind(hms,':');

if isempty(hmstmp)
    % ':' not found, search for ';' 
   hmstmp =  strfind(hms,';'); %Some B@W CSV files have ";" as separator
end

%% Set data indices 
% Selecting according to these indices excludes delimiters
dmyind(1,1) = 1;
hmsind(1,1) = 1;

for i = 1:2
    dmyind(i,2) = dmytmp(i)-1;    
    dmyind(i+1,1) = dmyind(i,2)+2; 
    
    hmsind(i,2) = hmstmp(i)-1;
    hmsind(i+1,1) = hmsind(i,2)+2;  
end
dmyind(end,2) = length(dmy);
hmsind(end,2) = length(hms);

%% Assign data into vector
dmy_vec = NaN(size(dmyind,1),1);
hms_vec = NaN(size(dmyind,1),1);
for i = 1:size(dmyind,1)
    dmy_vec(i) = str2double(dmy(dmyind(i,1):dmyind(i,2)));
    hms_vec(i) = str2double(hms(hmsind(i,1):hmsind(i,2)));   
end

%% Convert to datenum -> datestr
csvdatenum = datenum(dmy_vec(3),dmy_vec(2),dmy_vec(1),hms_vec(1),hms_vec(2),hms_vec(3));
dstr = datestr(csvdatenum);