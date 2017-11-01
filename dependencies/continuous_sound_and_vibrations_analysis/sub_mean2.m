function [SP2, mean_array2, mean1, array_bins]=sub_mean2(SP, Fs, pps)
% % sub_mean:  Removes the running average from a time record given a sampling rate and high pass cutoff frequency.  
% %
% % Syntax:
% % 
% % [SP2, mean_array2]=sub_mean2(SP, Fs, pps);
% % 
% % **********************************************************************
% % 
% % Description
% % 
% % This program removes the running average from a time record and returns 
% % the running average in separate arrays.  The output arrays SP2 and
% % mean_array2 both have the same size as the input array SP.  
% % 
% % The user controls how much of the low frequency content is removed 
% % along with the running average.  The user inputs the sampling rate and 
% % high pass cutoff frequency (number of data averages per second).    
% % 
% % The frequency content lower than the pps averages per second is
% % greatly attenuated.  
% % 
% % **********************************************************************
% % 
% % Input Variables
% % 
% % SP=randn(10, 50000);
% %                     % (Pa) is the time record of the sound pressure
% %                     % default is SP=rand(1, 50000);
% %
% % Fs=50000;           % (Hz) is the sampling rate of the time record.
% %                     % default is Fs=50000; Hz.
% % 
% % pps=25;             % (Hz) Number of averages per second for determining 
% %                     %      how often to sample the mean.
% %                     % default is pps=25;  
% %                     % 
% %                     %      Note:  pps is similar to a high pass filter
% %                     %             cutoff frequency.  
% % 
% % 
% % 
% % **********************************************************************
% % 
% % Output Variables
% % 
% % SP2 is the sound pressure with the running average subtracted.
% % SP2 has the same size as the input array.
% % 
% % mean_array2 is the running mean.  
% % mean_array2 has the same size as the input array.
% % 
% % 
% % **********************************************************************
% 
% 
% Example='1';
% 
% SP=rand(2,5000);  % Pa sound pressure time record 
%                   % 
% Fs=50000;         % Hz smpling rate for sound data
% pps=25;           % stands for points per seconds
%                   % number of data averages in data points per second 
%                   % milliseconds per data point is 1000/pps
%                   % default is pps=25; 40 ms per data point 
% 
% [SP2, mean_array2]=sub_mean2(SP, Fs, pps);
%
% 
% 
% % **********************************************************************
% % 
% % 
% % List of Dependent Subprograms for 
% % sub_mean2
% % 
% % FEX ID# is the File ID on the Matlab Central File Exchange
% % 
% % 
% % Program Name   Author   FEX ID#
% % 1) convert_double		Edward L. Zechmann			
% % 
% % 
% % **********************************************************************
% % 
% % Program Written by Edward L. Zechmann
% %    
% %     Date 15 August      2007
% % 
% % modified 18 December    2007    Updated comments.
% %                                 Added transpose to SP to have
% %                                 size(num_channel,num_data)
% %                                 converted pps into an input variable.       
% %     
% % modified  6 January     2009    Fixed a bug which was shifting the mean
% %                                 by half a bin.  Smoothed the ends by 
% %                                 adding two shorter means to the 
% %                                 beginning and ending.
% % 
% % modified  6 October     2009    Updated comments
% % 
% % modified  7 July        2010    Added option to only subtract mean by
% %                                 setting pps to 0.
% %     
% % modified 17 July        2010    Fixed a bug in only subtract mean by
% %                                 setting pps to 0.  Now works with
% %                                 multiple channels. 
% %     
% % **********************************************************************
% % 
% % Please Feel Free to Modify This Program
% %    
% % See also: sub_mean, moving, runmean, fastrunmean, mean
% %   


if (nargin < 1 || isempty(SP)) || ~isnumeric(SP)
    SP=rand(1, 50000);
end

% Make the data have the correct data type 
[SP]=convert_double(SP);


% Make sure SP has the correct indexing order of the 
% channels and sound pressure data
[m1, n1]=size(SP);
flag1=0;

if m1 > n1
    flag1=1;
    SP=SP';
    [m1 n1]=size(SP);
end

% Default value for the pps is 25 Hz
% the pps is similar to a 
% high pass filtercutoff 
if nargin < 3 || isempty(pps) || ~isnumeric(pps)
    pps=25;
end

% Only subtract mean value.
flag2=1;
if isequal(pps,0);
    flag2=0;
end

% limit the number of bins (averages) to speed up processing the data
if nargin < 2  || isempty(Fs) || ~isnumeric(Fs)
    bins=1000;
else
    bins=ceil(pps*n1/Fs); %25 Hz sampling rate, 40 ms per bin
    if bins > 100000
        bins=100000; % limit the number of bins to 100000.
    end
end


if bins < 1
    bins=1;
end

if bins > n1
    bins=n1;
end

% Determine the window size (number of data points per average) 
r1=ceil(n1/bins);


if r1 > 10 && isequal(flag2, 1)
    
    mean2=zeros(1, bins);
    array_bins2=zeros(1, bins);
    
    for e1=1:m1;
        
        smean1=mean(SP(e1, 1:floor(r1/8)), 2);
        smean2=mean(SP(e1, floor(r1/8):floor(r1/4)), 2);
        smean3=mean(SP(e1, floor(r1/4):floor(r1/2)), 2);
        
        endmean1=mean(SP(e1, n1+1-(1:floor(r1/8))), 2);
        endmean2=mean(SP(e1, n1+1-(floor(r1/8):floor(r1/4))), 2);
        endmean3=mean(SP(e1, n1+1-(floor(r1/4):floor(r1/2))), 2);
        
        for e2=1:(bins-1);
            
            mean2(e2)=mean(SP(e1, (e2-1)*r1+(1:r1)), 2);
            array_bins2(e2)=(e2-1)*r1+1;
            
        end
        
        e2=bins;
        mean2(e2)=mean(SP(e1, ((e2-1)*r1+1):end), 2);
        array_bins2(e2)=(e2-1)*r1+1;
        n2=max([n1 array_bins2(end)]);
        
        if array_bins2(end) + floor(r1/2) < floor(n1-r1*3/8)

            %mean1=zeros(1, 12+n1);
            %array_bins=zeros(1, 12+n1);
            mean1=[smean1*[1 1 1 1] smean2 smean3 mean2 endmean3 endmean2 endmean1*[1 1 1 1] ];
            array_bins=[[-3 -2 -1 0]  r1*3/16  r1*3/8  r1/2+array_bins2 n1-r1*3/8 n1-r1*3/16  n2+[1 2 3 4] ];

        else

            %mean1=zeros(1, 10+n1);
            %array_bins=zeros(1, 10+n1);
            mean1=[smean1*[1 1 1 1] smean2 smean3 mean2 endmean1*[1 1 1 1] ];
            n2=r1/2+array_bins2(end);
            array_bins=[[-3 -2 -1 0]  r1*3/16  r1*3/8  r1/2+array_bins2  n2+[1 2 3 4] ];

        end
        
        mean_array2(e1,:)=interp1(array_bins, mean1,1:n1,'pchip'); 
        
    end
    
    
else

    mean_array2=mean(SP, 2)*ones(1, n1);
    
end

SP2=SP-mean_array2;

% Make sure that the ouput has the same size as it was input
% channels and data have the smae indices 
if isequal(flag1, 1)
    SP2=SP2';
    mean_array2=mean_array2';
end

