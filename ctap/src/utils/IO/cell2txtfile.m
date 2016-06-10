function cell2txtfile(file, header, data, conversion, varargin)
%CELL2TXTFILE - Write data from cell array into a .txt file
%
% Description:
%   Writes data from a cell array into a text file using the conversion
%   specifiers given by the user. Also the delimiter used can be custom
%   set. The cell array should contain only one value in each cell to avoid
%   unexpected results. Empty cells are not allowed. Empty strings and NaN
%   appear as missing data, see example below. varargin 'allownans' further
%   controls the output.
%   This function is especially handy in situations where numeric and text
%   data should be written in the same txt file.
%
%   Overwrites any existing .txt files of the same name and path. 
%
% Syntax:
%   cell2txtfile(filename, header, data, conversion, varargin);
%
% Inputs:
%   file        string, Full name and path of the output .txt file
%   header      p-by-m cell array of strings or empty string '',
%               Contains column headings for the data in 'data'.
%               If 'header' is '' only data is written
%   data        n-by-m cell array, Contains the data to be written. Each
%               cell should contain only one number or string.
%   conversion  1-by-m cell array of strings, Conversion specifiers for the
%               columns in 'data'. Example {'%s','%1.0f','%15.4f'}
%   varargin    Keyword-value pairs. Options:
%               Keyword         Value
%               'delimiter'     Delimiter to use, e.g. ',', ';' or '\t',
%                               default:','
%               'allownans'     How to write NaN,
%                               string, allowed values: {'no','yes'},
%                               default: 'no'. 'no' outputs nothing for NaN,
%                               'yes' outputs NaN.
%               'writemode'     Replace existing or append,
%                               string, allowed values: {'wt','at'},
%                               default: 'wt'
%                               'wt' -> overwrite, 'at' -> append

%
% Outputs:
%   Writes into txt file specified in 'file'.
%
% Example:
%   header = {'var1','var2','var3'};
%   conversion = {'%s','%f','%d'};
%   data = {'text',2.5,4.0; '',NaN,4.0; 'moretext',2.4,5; };
%   cell2txtfile('test.txt', header, data, conversion)
%
%   'test.txt' contains:
%   var1,var2,var3
%   text,2.500000,4
%   ,,4
%   moretext,2.400000,5
%
% Jussi Korpela, 20.3.2007, TTL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TODO (feature-addition): Add support for a custom NA string to be able to 
%                          easily export to a wider range of systems

%% Parse input arguments and set varargin defaults
p = inputParser;

p.addRequired('file', @ischar);
p.addRequired('header'); %allowed: cellstr or ''
p.addRequired('data', @iscell);
p.addRequired('conversion', @iscellstr);   

p.addParameter('delimiter', ',', @ischar); %default delimiter
p.addParameter('allownans', 'no', @ischar); %{{'no'},'yes'}
p.addParameter('writemode', 'wt', @ischar); %'wt' write new file, 'at' append to existing file

p.parse(file, header, data, conversion, varargin{:});
Arg = p.Results;


%% Check inputs
if size(header,1) > size(header,2)
    header = header';
    % has to be row vector, so that subfunction write() operates on it
    % properly
    % Note that we cannot assume, that header contains only one row of
    % information.
end


%% Data conversion specifiers
conv_data = strcat(conversion, Arg.delimiter);
conv_data(end) = {strrep(conv_data{end}, Arg.delimiter, '\n')};
%conv_data = cellstr(conv_data);

if ~isempty(header)
    % Header conversion specifiers
    conv_header = cell(length(header),1);
    for n = 1:length(header)-1
        conv_header(n) = {['%s',Arg.delimiter]};
    end
    conv_header(end) = {'%s\n'};
end


%% Remove NaNs from numeric columns
if strcmp(Arg.allownans, 'no')
    num_match = cell2mat(cellfun(@isnumeric, data, 'UniformOutput', false)); %numeric cells as logical array
    num_col_ind = find(sum(num_match,1) == size(data,1)); %columns that have only numbers
    numdata = data(:, num_col_ind); %numeric columns as cell array

    if sum(sum( cellfun(@isempty, numdata, 'UniformOutput', true) )) == 0
        % no empty cells
        nan_match = cell2mat(cellfun(@isnan, numdata, 'UniformOutput', false));
        numdata(nan_match) = {[]}; % replace NaNs with empty cells
    else
        % some empty cells
        error('cell2txtfile:inputError',...
            'The numeric data columns contain empty cells. Cannot process.');
    end

    data(:,num_col_ind) = numdata; %update the original data structure
    clear('numdata');
end


%% Writedata
[fid, message] = fopen(file, Arg.writemode);

if fid==-1
   error('cell2txtfile:fileOpenError',message); 
end

if ~isempty(header)
    %Header
    conv_header = cat(2,conv_header{:});
    write(fid, header, conv_header);
end

% Write Data to text file
% Concatenate cell array with specifiers into string
conv_data = cat(2,conv_data{:});

% write to file
write(fid, data, conv_data);

fclose(fid);
    

%% Subfunctions
    function write(fid, data, conv)
        % Function for writing data in a cell array into a file
        % specified by 'fid'
        % Process the file row-wise, writing one row at a time.
       for i = 1:size(data,1)
            fprintf(fid, conv, data{i,:});
        end
    end %end of write
end