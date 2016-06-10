function unixtime = datenum2unixtime(dnum)
% DATENUM2UNIXTIME - Converts Matlab datenum to unix time
%
% Does not consider leap seconds.
%
% Jussi Korpela, FIOH
unixtime = (dnum - datenum(1970,1,1,0,0,0))*24*60*60;