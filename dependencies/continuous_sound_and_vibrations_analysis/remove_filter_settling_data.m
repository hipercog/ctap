function [y2]=remove_filter_settling_data(y, sample_factor, num_pts_se, num_data_pts, flag1)
% % remove_filter_settling_data: removes data added to time records to settle the filter
% %
% % Syntax;
% %
% % [y2]=remove_filter_settling_data(y, sample_factor, num_pts_se, num_data_pts, flag1);
% %
% % ***********************************************************
% %
% % Description
% %
% % Removes data that had been added to time records to settle the filter.  
% % Supports multichannel arrays.  
% % 
% % Automatically reshapes the two dimensional array "y" assuming there are
% % data points than more channels.  
% % 
% % 
% % ***********************************************************
% %
% % Input Variables
% %
% % y=randn(50000, 1);      % is the input time record
% %                         % default is y=randn(50000, 1);
% % 
% % sample_factor=1;        % is the upsample or downsample factor
% %                         % default is sample_factor=1;
% % 
% % num_pts_se=0;           % is the number of settling points used to
% %                         % settle the filter.  
% %                         % default is num_pts_se=0;
% % 
% % num_data_pts=length(y); % is the number of good data points to place
% %                         % in the output time record. 
% %                         % default is num_data_pts=length(y);
% % 
% % flag1=2;                % determines whether to upsample, downsample,
% %                         % or keep the sample samling rate. 
% %                         % 
% %                         % flag1=0 downsample 
% %                         % 
% %                         % flag1=1 upsample 
% %                         % 
% %                         % flag1=1 same sampling rate
% %                         % 
% %                         % default is flag1=2; (same sampling rate)
% %
% % 
% %
% % ***********************************************************
% %
% % Output Variables
% % 
% % y is the output time record after removal of the filter settling data 
% %         and after downsampling, upsampling, or keeping the same 
% %         sampling rate.  
% %         y is the has the shape( num samples, num channels)
% % 
% % ***********************************************************
% %
% % written by Edward L. Zechmann
% % 
% %     date  2 July        2010
% %
% % modified  7 July        2010    Rearranged cases
% %                                 Added more comments
% %
% % modified  7 July        2010    Simplified variable names.
% %                                 Updated comments
% %                                 
% %
% %
% % ***********************************************************
% % 
% % see also: filter, filtfilt, resample, downsample, upsample
% % 
% % 


if (nargin < 1 || isempty(y)) || ~isnumeric(y)
    y=randn(50000, 1);
end

% Make the data have the correct data type and size
[y]=convert_double(y);

[num_pts, num_mics]=size(y);

if num_mics > num_pts
    y=y';
    [num_pts, num_mics]=size(y);
end

if (nargin < 2 || isempty(sample_factor)) || ~isnumeric(sample_factor)
    sample_factor=1;
end

if (nargin < 3 || isempty(num_pts_se)) || ~isnumeric(num_pts_se)
    num_pts_se=0;
end

if (nargin < 4 || isempty(num_data_pts)) || ~isnumeric(num_data_pts)
    num_data_pts=length(y);
end

if (nargin < 5 || isempty(flag1)) || ~isnumeric(flag1)
    flag1=2;
end



switch flag1
        
    case 0

        % downsampling
        buf_pts=(floor(num_pts_se/sample_factor)+1);
        buf_2pts=(floor(num_data_pts/sample_factor)+1);
        
    case 1
        
        % upsampling
        buf_pts=(floor(num_pts_se*sample_factor)+1);
        buf_2pts=(floor(num_data_pts*sample_factor)+1);

    case 2

        % same sampling rate
        buf_pts=num_pts_se+1;
        buf_2pts=num_data_pts;
        
    otherwise
        
        % same sampling rate
        buf_pts=num_pts_se+1;
        buf_2pts=num_data_pts;

end

% Determine the indices of the data.
data_pts=buf_pts:(buf_pts-1+buf_2pts);



% Set the output data array.
y2=y(data_pts, :);

