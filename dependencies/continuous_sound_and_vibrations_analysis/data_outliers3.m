function [ptsa, nptsa, rt_stats, other_stats, rt_outlier_stats, other_outlier_stats]=data_outliers3(flag1, rta, dep_var, round_kind, round_digits, abs_rta, abs_other, sod, outfile, save_file, row_names, row_unit, col_name, array_names, array_units, varargin)
% % data_outliers: Determine the outliers and return descriptive statistics
% %
% % Syntax:
% %
% % [ptsa, nptsa, rt_stats, other_stats, rt_outlier_stats, ...
% % other_outlier_stats]=data_outliers3(rta, dep_var, round_kind, ...
% % round_digits, abs_rta, abs_other, sod, outfile, save_file, ...
% % row_names, row_unit, col_name, array_names, array_units, varargin);
% %
% % ********************************************************************
% %
% % Description
% %
% % Program finds outliers based on the first input variable data array rta.
% %
% % Descriptive statistics of the data excluding the outliers are
% % calculated for the rta array and the varargin data arrays.
% %
% % Descriptive statistics of the outliers fo teh data based on the rta
% % array are calculated for the rta array and the varargin data arrays.
% %
% % The output descriptive statistics are namely:
% %      1)  Arithmetic Mean
% %      2)  Robust Mean
% %      3)  Standard Deviation
% %      4)  95% confidence interval, two sided, t-distribution
% %      5)  Median index
% %      6)  Median
% %      7)  Minimum
% %      8)  Maximum
% %
% %
% % Data_outliers uses the robust mean for finding the outliers.
% % All data with excessive residuals can be detected as outliers. 
% %
% % There are several input and output variables which are described in
% % more detail in the sections below respectively.
% %
% % ********************************************************************
% %
% % Input Variables
% %
% % flag1=0;                % Boolean which selects Linear or Exponential
% %                         % scaling before calculating mean and median.
% %
% % rta=abs(randn(28,8));   % Data array to find outliers and primary
% %                         % data set to analyze with descriptive statistics
% %                         % default is abs_rta=0;
% %
% % dep_var=1;              % Dependence of the varargin arrays on the rta
% %                         % arrays.  Controls how outliers are chosen.
% %                         %
% %                         % 1 outliers are calculated only using the
% %                         % rta array then applied to all varargin arrays.
% %                         %
% %                         % 0 outliers are calculated for the rta array
% %                         % and independently for all varargin arrays.
% %
% % round_kind=1;           % Array of values one element for the rta array
% %                         % and one element for each varargin array
% %                         % (see example)
% %                         % 1 round to specified number of significant
% %                         % digits
% %                         %
% %                         % 0 round to specified digits place
% %                         %
% %                         % default is round_kind=1;
% %
% % round_digits=3;         % Array of values one element for the rta array
% %                         % and one element for each varargin array
% %                         % (see example)% Type of rounding depends on round_kind
% %                         %
% %                         % if round_kind==1 number of significant digits
% %                         % if round_kind==0 specified digits place
% %                         %
% %                         % default is round_digits=3;
% %
% % abs_rta=1;              % 1 use the absolute value of the rta data to
% %                         % find the outliers and anlayze the descriptive statistics
% %                         % 0 or [] do not use absolute value
% %                         % default is abs_rta=0;
% %
% % abs_other=[];           % Logical array of values one element for the
% %                         % rta array and one element for each varargin array
% %                         % (see example)
% %                         % 1 for an element in the varargin will
% %                         % use the absolute value of the rta data to
% %                         % anlayze the descriptive statistics
% %                         % 0 or [] does not use absolute value
% %                         %
% %                         % default is abs_other=zeros(1+length(varargin), 1);
% %
% % sod=0;                  % 1 surpress outlier detection
% %                         % 0 find the outliers and remove them from the
% %                         % statistical analysis
% %                         % default is sod=1;
% %
% %
% % outfile='stat_of_data'; % string filename for saving analyzed data
% %                         % '.txt' extension is added if not present
% %                         %
% %                         % fid is another option if the outfile is
% %                         % already an existing file data will be written
% %                         % at the current position of file
% %                         % default is outfile='outliers_stats';
% %
% % save_file=1;            % 1 to save data
% %                         % 0 for not saving data
% %                         % default is save_file=1;
% %
% % row_names=[ 20,  25, 31.5, 40,  50,  63,  80,  100,  125,  160, ...
% %           200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600, ...
% %           2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000];
% %                         % Array of values one element for each row of
% %                         % data in the rta array.
% %                         % (see example)
% %                         % can be numbers or a cell array of strings
% %                         % if empty default is numbers
% %                         % from 1 to num_rows
% %                         %
% %                         % first element is the name of the first row
% %                         % in the rta array the next elements are the
% %                         % names of the subsequent row in the rta array.
% %                         % These same names are used to name the
% %                         % rows in the varargin arrays.
% %                         %
% %                         % default is row_names='';
% %
% % row_unit='Hz';          % Cell array of strings, Cell Arary of Numbers
% %                         % array of numbers, or single string
% %                         % One element for each row of
% %                         % data in the rta array.   (see example)
% %                         % Can also be a single string
% %                         % one string all rows are assumed
% %                         % to have the same units
% %
% %                         % first element is the units of the rta array
% %                         % the next elements are the units in the
% %                         % varargin arrays.
% %
% %                         % default is row_unit='';
% %
% % col_name='Peak Number'; % Single string (see example)
% %                         % String describing a distinguishing characteristic
% %                         % of one column from the next column.
% %                         % could be someting like 'Peak Number'.
% %                         %
% %                         % default is col_name='';
% %
% % array_names={'Reverberation Times', 'Signal Levels', 'Background Levels'};
% %                         % Cell array of strings, Cell array of numbers
% %                         % array of numbers, or single string
% %                         % One element for the rta array and one element
% %                         % for each array in varargin   (see example)
% %                         % Can also be a single string
% %                         % If one string, then all arrays are assumed
% %                         % to have the same name.
% %                         %
% %                         % first element is the units of the rta array
% %                         % the next elements are the units in the
% %                         % varargin arrays.
% %                         % default is array_names='';
% %
% % array_units={'s', 'dBA', 'dBA'};
% %                         % Cell array of strings, Cell array of numbers
% %                         % array of numbers, or single string
% %                         % One element for the rta array and one element
% %                         % for each array in varargin   (see example)
% %                         % Can also be a single string
% %                         % If one string, then all arrays are assumed
% %                         % to have the same units.
% %                         %
% %                         % first element is the units of the rta array
% %                         % the next elements are the units in the
% %                         % varargin arrays.
% %                         %
% %                         % default is array_units='';
% %
% % varargin                % List of arrays of associated with rta array
% %                         % to statistically describe and analyze.
% %                         %
% %                         % The varargin data arrays must have the same
% %                         % size as the rta array.
% %                         %
% %                         % varargin consists of a comma delimited
% %                         % list of arrays
% %                         %
% %                         % array1, array2, ..., arrayn
% %                         %
% %                         % array1 ... arrayn are data arrays that need
% %                         % statistical analysis using the same outliers
% %                         % as the rta
% %                         %
% %                         % units_other_data is a cell array of units for
% %                         % each of the data arrays.  Each of the arrays
% %                         % has its own, so if there were
% %                         % arrays1 ... array3 then the
% %                         % units_other_data={'dB', 'Pascals', 's'};
% %                         % would be possible units.
% %                         % There is no default value for varargin.
% %
% % ********************************************************************
% %
% % Output Variables
% %
% % ptsa is the cell array of indices of the data points within the
% %      specified number of standard deviations
% %
% % nptsa is the cell array of indices of the data points outside the
% %      specified number of standard deviations
% %
% % rt_stats is a cell array of descriptive statistics for the input variable rta
% %
% % other_stats is a cell array of descriptive statistics for the
% %      arbitrary input variables varargin
% %
% % rt_outlier_stats is a cell array of descriptive statistics for the
% %      outliers from the rta input variable.
% %
% % other_outlier_stats is a cell array of descriptive statistics for the
% %      outliers from the arbitrary input variables varargin.
% %
% % ********************************************************************
%
% Example='1';
%
% % Shows an array of random numbers.
%
%
% flag1=0;                  % Boolean which selects Linear or Exponential
%                           % scaling before calculating mean and median.
%
% rta=abs(randn(28,8));     % Data array to find outliers and primary
%                           % data set to analyze with descriptive statistics
%                           % default is rta=0;
%
% dep_var=1;                % Dependence of the varargin arrays on the rta
%                           % arrays.  Controls how outliers are chosen.
%                           %
%                           % 1 outliers are calculated only using the
%                           % rta array then applied to all varargin arrays.
%                           %
%                           % 0 outliers are calculated for the rta array
%                           % and independently for all varargin arrays.
%
% round_kind=[1 0 0];       % 1 round to specified number of significant
%                           % digits.
%                           %
%                           % 0 round to specifid digits place
%
% round_digits=[3 0 0];     % Type of rounding depends on round_kind
%                           %
%                           % if round_kind==1 number of significant digits
%                           % if round_kind==0 spcecified digits place
%                           % 3 round to 3 significant digits
%                           % 0 round to the ones place
%
% abs_rta=1;                % Use the absolute value of the rta data to
%                           % find the outliers and anlayze the descriptive statistics
%
% abs_other=[];             % logical array
%                           % Do not use the absolute value of the rta
%                           % data to anlayze the descriptive statistics
%
% sod=0;                    % Allow removal of outliers
%
%
% outfile='stat_of_data';   % filename for saving analyzed data is
%                           % 'stat_of_data.txt'
%
% save_file=1;              % Save data to a text file
%
% row_names=[ 20,  25, 31.5, 40,  50,  63,  80,  100,  125,  160, ...
%           200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600, ...
%           2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000];
%                           % Row names can be a constant,
%                           % arrays of numbers
%                           % cell arrays of numbers
%                           % or cell arrays of strings
%
% row_unit='Hz';            % one string all rows are assumed
%                           % to have the same units
%
% col_name='Microphone Number';
%                           % string distinguishing one column from
%                           % the next column
%
% array_names={'Reverberation Times', 'Signal Levels', 'Background Levels'};
%                           % cell array of strings
%                           % One string for the rta array and one sring
%                           % for each array in varargin
%
% array_units={'s', 'dBA', 'dBA'};
%                           % cell array of strings
%                           % specifies the units for the rta array and
%                           % each data array in varargin
%                           % 1zt string is the units of rta
%                           % the next n strings are the units of varargin
%                           %
%                           % For reverberation times
%                           % rta is the reverberations times with units of
%                           % seconds
%                           %
%                           % varargin contains two arrays the siganl
%                           % levels dBA and the background levels in dBA
%
% sigl=100+randn(28,8);     % signal levels dBA
% bgl=10+randn(28,8);       % background levels dBA
%
% % varargin                % List of arrays of associated with rta array
% %                         % to statistically describe and analyze.
% %                         %
% %                         % The varargin data arrays must have the same
% %                         % size as the rta array.
% %                         %
% %                         % varargin consists of a comma delimited
% %                         % list of arrays
% %                         %
% %                         % array1, array2, ..., arrayn
% %                         %
% %                         % array1 ... arrayn are data arrays that need
% %                         % statistical analysis using the same outliers
% %                         % as the rta
% %                         %
% %                         % units_other_data is a cell array of units for
% %                         % each of the data arrays.  Each of the arrays
% %                         % has its own, so if there were
% %                         % arrays1 ... array3 then the
% %                         % units_other_data={'dB', 'Pascals', 's'};
% %                         % would be possible units.
% %
% %
% % Run the example with the code below.
% [ptsa, nptsa, rt_stats, other_stats, rt_outlier_stats, other_outlier_stats]=data_outliers3(flag1, rta, dep_var, round_kind, round_digits, abs_rta, abs_other, sod, outfile, save_file, row_names, row_unit, col_name, array_names, array_units, sigl, bgl);
%
%
% % In general, the calling arguments are
% % [ptsa, nptsa, rt_stats, other_stats, rt_outlier_stats, other_outlier_stats]=data_outliers3(flag1, rta, dep_var, round_kind, round_digits, abs_rta, abs_other, sod, outfile, save_file, row_names, row_unit, col_name, array_names, array_units, varargin);
%
%
% Example='2';
%
% % Using only 2 columns eliminates most of the descriptive ststistics.
% % Use above code then run the following
% flag1=1;  % convert data to Linear units proportional to Pascals
%           % before calculating the mean and median
% rta=abs(randn(28,2));     % Data array to find outliers and primary
% sigl=100+randn(28,2);     % signal levels dBA
% bgl=10+randn(28,2);       % background levels dBA
%
% [ptsa, nptsa, rt_stats, other_stats, rt_outlier_stats, other_outlier_stats]=data_outliers3(flag1, rta, dep_var, round_kind, round_digits, abs_rta, abs_other, sod, outfile, save_file, row_names, row_unit, col_name, array_names, array_units, sigl, bgl);
%
%
%
%
% Example='3';
%
% % Using sod=1. eliminates removing outliers.
% % Use above code then run the following.
%
% flag1=1;
% sod=1;
% rta=abs(randn(28,8));     % Data array to find outliers and primary
% sigl=100+randn(28,8);     % signal levels dBA
% bgl=10+randn(28,8);       % background levels dBA
%
% [ptsa, nptsa, rt_stats, other_stats, rt_outlier_stats, other_outlier_stats]=data_outliers3(flag1,rta, dep_var, round_kind, round_digits, abs_rta, abs_other, sod, outfile, save_file, row_names, row_unit, col_name, array_names, array_units, sigl, bgl);
%
%
%
% % ********************************************************************
% %
% %
% % Reference:
% % Rousseeuw PJ, Leroy AM (1987): Robust regression and outlier detection.
% % Wiley.
% %
% %
% % Alexandros Leontitsis
% % Institute of Mathematics and Statistics
% % University of Kent at Canterbury
% % Canterbury
% % Kent, CT2 7NF
% % U.K.
% %
% % University e-mail: al10@ukc.ac.uk (until December 2002)
% % Lifetime e-mail: leoaleq@yahoo.com
% % Homepage: http://www.geocities.com/CapeCanaveral/Lab/1421
% %
% %
% % ********************************************************************
% %
% %
% % Subprograms
% %
% % 
% % List of Dependent Subprograms for 
% % data_outliers3
% % 
% % FEX ID# is the File ID on the Matlab Central File Exchange
% % 
% % 
% % Program Name   Author   FEX ID#
% %  1) fastlts		Peter J. Rousseeuw		NA	
% %  2) fastmcd		Peter J. Rousseeuw		NA	
% %  3) file_extension		Edward L. Zechmann			
% %  4) genHyper		Ben Barrowes		6218	
% %  5) m_round		Edward L. Zechmann			
% %  6) pow10_round		Edward L. Zechmann			
% %  7) rmean		Edward L. Zechmann			
% %  8) sd_round		Edward L. Zechmann			
% %  9) t_alpha		Edward L. Zechmann			
% % 10) t_confidence_interval		Edward L. Zechmann			
% % 11) t_icpbf		Edward L. Zechmann				
% %
% %
% % ********************************************************************
% %
% %
% % data_outliers is written by Edward L. Zechmann
% %
% %  created 16 December    2007
% %
% % modified 20 December    2007    Added comments.
% %                                 Added col_name field.
% %                                 Improved ability to input data sets
% %                                 of cell arrays.
% %                                 Improved formatiting of output
% %                                 text file.
% %
% % modified  6  January    2007    Added features abs_rta, abs_other, sod
% %                                 and updated comments.
% %
% % modified 26 February    2007    Updated the row units and the array
% %                                 units.
% %                                 Replaced geomean with LMSloc robust
% %                                 mean.
% %                                 Modified code to print actual values
% %                                 including negative numbers, when
% %                                 the absolute value is used to process
% %                                 the descriptive statistics (mean, std,...).
% %
% % modified 19 September   2008    Updated Comments
% %
% % modified 16 December    2008    Added Arithmetic Mean.
% %
% % modified  9 January     2009    Added Default values.
% %                                 Added rounding the output.
% %                                 Added Analysis of Outliers.
% %
% % modified 10 January     2009    Finished updates.
% %
% % modified 11 January     2009    Updated Comments
% %
% % modified 21 March       2009    Added a flag to data_outliers3 to
% %                                 convert dB data to Pa before
% %                                 calculating mean and median values.
% %                                 Updated comments
% %
% % modified  6 October     2009    Updated comments
% %
% % modified  6 February    2011    Changed method of identifying outliers 
% %                                 to FASTLTS Updated comments
% %
% % modified 21 February    2011    Fixed a bugs in trasnposing the input 
% %                                 to fstlts into a column vector.
% %                                 Updated comments.
% % 
% % modified  5 Janaury     2012    Replace LMSloc with fastlts.  
% %                                 Updated comments
% % 
% %
% %
% %
% % ********************************************************************
% %
% % Please feel free to modify this code.
% %
% % See Also:  LMSloc, mean, std, t_confidence_interval
% %

num_vars=length(varargin);

% initialize flag1 if empty
if nargin < 1 || isempty(flag1) || ~isnumeric(flag1)
    flag1=zeros(1+num_vars, 1);
elseif length(flag1) < 1+num_vars
    flag2=zeros( 1+num_vars, 1);
    flag2(1:length(flag1),1)=flag1;
    flag1=flag2;
end


% initialize abs_rta if empty
if nargin < 2 || isempty(abs_rta)
    abs_rta=0;
end


if nargin < 3 || isempty(dep_var) || ~isnumeric(dep_var)
    dep_var=1;
end

if ~isequal(dep_var, 1)
    dep_var=0;
end

if nargin < 4 || isempty(round_kind) || ~isnumeric(round_kind)
    round_kind=ones(1+num_vars, 1);
end

if length(round_kind) < (num_vars+1)
    for e1=(length(round_kind)+1):(num_vars+1);
        round_kind(e1)=0;
    end
end

if nargin < 5 || isempty(round_digits) || ~isnumeric(round_digits)
    round_digits=ones(1+num_vars, 1);
end

if length(round_digits) < (num_vars+1)
    for e1=(length(round_digits)+1):(num_vars+1);
        if isequal(round_kind(e1), 1)
            round_digits(e1)=3;
        else
            round_digits(e1)=0;
        end
    end
end


if nargin < 6 || isempty(abs_rta) || ~isnumeric(abs_rta)
    abs_rta=0;
end

if nargin < 7 || isempty(abs_other) || ~isnumeric(abs_other)
    abs_other=zeros(1+num_vars, 1);
end

% initialize abs_rta if shorter than varargin
if length(abs_other) < num_vars
    for e1=(length(abs_other)+1):num_vars;
        abs_other(e1)=0;
    end
end

if nargin < 8 || isempty(sod) || ~isnumeric(sod)
    sod=1;
end

% Value must be a scalar
sod=sod(1);
if  ~isequal(sod, 1);
    sod=0;
end

if nargin < 9 || isempty(outfile) || (~ischar(outfile) && ~isnumeric(outfile))
    outfile='outliers_stats';
end

if nargin < 10 || isempty(save_file) || ~isnumeric(save_file)
    save_file=1;
end

if nargin < 11 || isempty(row_names)
    row_names='';
end

if nargin < 12 || isempty(row_unit)
    row_unit='';
end

if nargin < 13 || isempty(col_name)
    col_name='';
end

if nargin < 14 || isempty(array_names)
    array_names='';
end

if nargin < 15 || isempty(array_units)
    array_units='';
end


rta2=rta;
% For analyzing impulsive noise data
% num_data_rows would be the nnumber of frequency bands
% num_cols would be the number of microphone channels
[num_data_rows, buf]=size(rta);


% calculate the maximum number of columns
max_num_cols=1;
for e1=1:num_data_rows;
    if iscell(rta)
        max_num_cols=max(max_num_cols, length(rta{e1, :}));
    else
        max_num_cols=max(max_num_cols, length(rta(e1, :)));
    end
end


% initialize row_names if shorter than num_data_rows
if length(row_names) < num_data_rows
    if iscell(row_names)
        % If it is not a string assume it is an array of numbers
        if ischar(row_names{1})
            for e1=(length(row_names)+1):num_data_rows;
                row_names{e1}='';
            end
        else
            for e1=(length(row_names)+1):num_data_rows;
                row_names{e1}=0;
            end
        end
        
    else
        if ischar(row_names(1)) && ~isempty(row_names)
            buf=row_names;
            row_names=cell(num_data_rows);
            for e1=1:num_data_rows;
                row_names{e1}=[buf, ' ', num2str(e1)];
            end
        else
            for e1=(length(row_names)+1):num_data_rows;
                row_names(e1)=0;
            end
        end
        
    end
    
end


% initialize row_unit if shorter than num_data_rows
if length(row_unit) < num_data_rows
    if iscell(row_unit)
        % If it is not a string assume it is an array of numbers
        if ischar(row_unit{1})
            for e1=(length(row_unit)+1):num_data_rows;
                row_unit{e1}='';
            end
        else
            for e1=(length(row_unit)+1):num_data_rows;
                row_unit{e1}=0;
            end
        end
        
    else
        if ~isempty(row_unit) && ischar(row_unit(1)) && ~isempty(row_unit)
            buf=row_unit;
            row_unit=cell(num_data_rows);
            for e1=1:num_data_rows;
                row_unit{e1}=[buf];
            end
        else
            for e1=(length(row_unit)+1):num_data_rows;
                row_unit(e1)=0;
            end
        end
        
    end
end



% initialize col_name if shorter than max_num_cols
% if length(col_name) < max_num_cols
%     if iscell(col_name)
%         % If it is not a string assume it is an array of numbers
%         if ischar(col_name{1})
%            for e1=(length(col_name)+1):max_num_cols;
%                col_name{e1}='';
%            end
%        else
%            for e1=(length(col_name)+1):max_num_cols;
%                col_name{e1}=0;
%            end
%        end
%    else
%        if ischar(col_name(1)) && ~isempty(col_name)
%            buf=col_name;
%            col_name=cell(max_num_cols, 1);
%            for e1=1:max_num_cols;
%                col_name{e1}=[buf, ' ', num2str(e1)];
%            end
%        else
%            for e1=(length(col_name)+1):max_num_cols;
%                col_name(e1)=0;
%            end
%        end
%    end
%end


% col_name
if iscell(col_name)
    % If it is not a string assume it is an array of numbers
    if ischar(col_name{1})
        col_name=col_name{1};
    else
        col_name=num2str(col_name{1});
    end
else
    % If it is not a string assume it is an array of numbers
    if ischar(col_name)
        % Do nothing
    else
        col_name=num2str(col_name);
    end
end


% initialize array_names if shorter than num_vars=length(varargin)
if length(array_names) < (num_vars+1)
    if iscell(array_names)
        % If it is not a string assume it is an array of numbers
        if ischar(array_names{1})
            for e1=(length(array_names)+1):(num_vars+1);
                array_names{e1}='';
            end
        else
            for e1=(length(array_names)+1):(num_vars+1);
                array_names{e1}=0;
            end
        end
        
    else
        if ischar(array_names(1)) && ~isempty(array_names)
            buf=array_names;
            array_names=cell((num_vars+1), 1);
            for e1=1:(num_vars+1);
                array_names{e1}=[buf, ' ', num2str(e1)];
            end
        else
            for e1=(length(array_names)+1):(num_vars+1);
                array_names(e1)=0;
            end
        end
        
    end
    
end


% initialize array_units if shorter than num_vars=length(varargin)
if length(array_units) < (num_vars+1)
    if iscell(array_units)
        % If it is not a string assume it is an array of numbers
        if ischar(array_units{1})
            for e1=(length(array_units)+1):(num_vars+1);
                array_units{e1}='';
            end
        else
            for e1=(length(array_units)+1):(num_vars+1);
                array_units{e1}=0;
            end
        end
        
    else
        if ischar(array_units(1)) && ~isempty(array_units)
            buf=array_units;
            array_units=cell((num_vars+1), 1);
            for e1=1:(num_vars+1);
                array_units{e1}=[buf, ' ', num2str(e1)];
            end
        else
            for e1=(length(array_units)+1):(num_vars+1);
                array_units(e1)=0;
            end
        end
        
    end
    
end


ptsa=cell(num_data_rows,(num_vars+1));
nptsa=cell(num_data_rows,(num_vars+1));

mn_rt1a=zeros(num_data_rows,1);
mn_rt2a=zeros(num_data_rows,1);
stdrta=zeros(num_data_rows,1);
ci_inta=zeros(num_data_rows,1);
median_indexa=zeros(num_data_rows,1);
median_val=zeros(num_data_rows,1);
min_rta=zeros(num_data_rows,1);
max_rta=zeros(num_data_rows,1);

out_mn_rt1a=zeros(num_data_rows,1);
out_mn_rt2a=zeros(num_data_rows,1);
out_stdrta=zeros(num_data_rows,1);
out_ci_inta=zeros(num_data_rows,1);
out_median_indexa=zeros(num_data_rows,1);
out_median_val=zeros(num_data_rows,1);
out_min_rta=zeros(num_data_rows,1);
out_max_rta=zeros(num_data_rows,1);

% Initialize the maximum number of outliers in array rta data row.
max_num_out=0;

for e1=1:num_data_rows;
    
    if iscell(rta);
        buf1=rta{e1, :};
        if iscell(buf1);
            rt=buf1{1};
        else
            rt=buf1;
        end
    else
        rt=rta(e1, :);
    end
    
    num_cols=length(rt);
    
    if num_cols > 0
        if isequal(abs_rta, 1)
            rtb=abs(rt);
        else
            rtb=rt;
        end
        
        rtb=squeeze(rtb);
        rtb=rtb(:);
                
        % Calculate the robust estimate of the mean.
        %
        % Statistical language for this type of mean is
        % "calculates the Least Median of Squares (LMS)
        % location parameter of the columns of a matrix
        % X. If X is a vector, it returns the LMS
        % location parameter of its components. If X
        % is a scalar, it returns X."
        
        %if isequal(flag1(1), 1)
        %    [gm]=LMSloc(10.^(rtb./20));
        %    gm=20.*log10(gm);
        %else
        %    [gm]=LMSloc(rtb);
        %end
        
        [ gm ] = rmean(rtb, flag1(1));
        
        % calculate standard deviation
        %if isequal(flag1(1), 1)
        %    stdrt=20.*log10(std(10.^(rts./20)));
        %else
        stdrt=std(rtb);
        %end
        
        if length(rtb) > 3 && isequal(sod, 0)
            
            if ~isempty(rtb)
                [res, raw] = fastlts(rtb);
                npts=find(res.flag==0);
            else 
                npts=[];
            end
            
            pts=setdiff( 1:num_cols, npts); % find the indices of the outliers
            
            %pts=intersect( find(rtb > gm - num_std*stdrt), find(rtb < gm + num_std*stdrt)); % find all values within num_std std of geometric mean
            %npts=setdiff( 1:num_cols, pts); % find the indices of the outliers
        else
            pts=1:num_cols;
            npts=[];
        end
        
        if isempty(pts)
            pts=1:num_cols;
            npts=[];
        end
        
        % Determine the maximum number of outliers in any rta data row
        max_num_out=max([max_num_out, length(npts)]);
        
        % indices of set of non-outliers (i.e. values kept)
        ptsa{e1, 1}=pts;
        
        % indices of set of outliers (i.e. values discarded from
        % descriptive statistics)
        nptsa{e1, 1}=npts;
        
        % select the set of non-outliers data for calculating descriptive statistics
        if isequal(abs_rta, 1)
            rts=abs(rt(pts));
        else
            rts=rt(pts);
        end
        
        % Calculate the arithmetic mean.
        if isequal(flag1(1), 1)
            [mn_rt1]=mean(10.^(rts./20));
            mn_rt1=20.*log10(mn_rt1);
        else
            [mn_rt1]=mean(rts);
        end
        
        
        % Calculate the robust estimate of the mean
        %if isequal(flag1(1), 1)
        %    [mn_rt2]=LMSloc(10.^(rts./20));
        %    mn_rt2=20.*log10(mn_rt2);
        %else
        %    [mn_rt2]=LMSloc(rts);
        %end
        
        [ mn_rt2 ] = rmean(rts, flag1(1));
        
        % calculate standard deviation
        %if isequal(flag1(1), 1)
        %    stdrt=20.*log10(std(10.^(rts./20)));
        %else
        stdrt=std(rts);
        %end
        
        % calculate 95% confidence interval of
        % the standard error of the
        % t-distribution with a two-sided test
        [ci_int]=t_confidence_interval(rts, 0.95);
        
        % Calculate the median
        if isequal(flag1(1), 1)
            [medianrt]=median(10.^(rts./20));
            medianrt=20.*log10(medianrt);
        else
            medianrt=median(rts);
        end
        
        % Calculate the median index
        % (data point closest ot the median value)
        [mbuf ix]=min(abs(rts-medianrt));
        
        % Calculate the minimum
        minrt=min(rts);
        
        % Calculate the maximum
        maxrt=max(rts);
        
        
        mn_rt1a(e1,1)=      m_round(mn_rt1,   round_kind(1), round_digits(1));
        mn_rt2a(e1,1)=      m_round(mn_rt2,   round_kind(1), round_digits(1));
        stdrta(e1,1)=       m_round(stdrt,    1, 3);
        ci_inta(e1,1)=      m_round(ci_int,   1, 3);
        median_indexa(e1,1)=m_round(ix,       0, 0);
        median_val(e1,1)=   m_round(medianrt, round_kind(1), round_digits(1));
        min_rta(e1,1)=      m_round(minrt,    round_kind(1), round_digits(1));
        max_rta(e1,1)=      m_round(maxrt,    round_kind(1), round_digits(1));
        
        if ~isequal(sod, 1) && ~isempty(npts)
            % select the set of outliers data for calculating descriptive statistics
            if isequal(abs_rta, 1)
                rts=abs(rt(npts));
            else
                rts=rt(npts);
            end
            
            % Calculate the arithmetic mean.
            if isequal(flag1(1), 1)
                [mn_rt1]=mean(10.^(rts./20));
                mn_rt1=20.*log10(mn_rt1);
            else
                [mn_rt1]=mean(rts);
            end
            
            
            % Calculate the robust estimate of the mean
            %if isequal(flag1(1), 1)
            %    [mn_rt2]=LMSloc(10.^(rts./20));
            %    mn_rt2=20.*log10(mn_rt2);
            %else
            %    [mn_rt2]=LMSloc(rts);
            %end
            
            [ mn_rt2 ] = rmean(rts, flag1(1));
            
            % calculate standard deviation
            %if isequal(flag1(1), 1)
            %    stdrt=20.*log10(std(10.^(rts./20)));
            %else
            stdrt=std(rts);
            %end
            
            % calculate 95% confidence interval of
            % the standard error of the
            % t-distribution with a two-sided test
            [ci_int]=t_confidence_interval(rts, 0.95);
            
            % Calculate the median
            if isequal(flag1(1), 1)
                [medianrt]=median(10.^(rts./20));
                medianrt=20.*log10(medianrt);
            else
                medianrt=median(rts);
            end
            
            
            % Calculate the median index
            % (data point closest ot the median value)
            [mbuf ix]=min(abs(rts-medianrt));
            
            % Convert to Median Index of the original data array
            ix=npts(ix);
            
            % Calculate the minimum
            minrt=min(rts);
            
            % Calculate the maximum
            maxrt=max(rts);
            
            out_mn_rt1a(e1,1)=      m_round(mn_rt1,   round_kind(1), round_digits(1));
            out_mn_rt2a(e1,1)=      m_round(mn_rt2,   round_kind(1), round_digits(1));
            out_stdrta(e1,1)=       m_round(stdrt,    1, 3);
            out_ci_inta(e1,1)=      m_round(ci_int,   1, 3);
            out_median_indexa(e1,1)=m_round(ix,       0, 0);
            out_median_val(e1,1)=   m_round(medianrt, round_kind(1), round_digits(1));
            out_min_rta(e1,1)=      m_round(minrt,    round_kind(1), round_digits(1));
            out_max_rta(e1,1)=      m_round(maxrt,    round_kind(1), round_digits(1));
            
        else
            
            out_mn_rt1a(e1,1)=0;
            out_mn_rt2a(e1,1)=0;
            out_stdrta(e1,1)=0;
            out_ci_inta(e1,1)=0;
            out_median_indexa(e1,1)=0;
            out_median_val(e1,1)=0;
            out_min_rta(e1,1)=0;
            out_max_rta(e1,1)=0;
            
        end
        
    else
        % if the data array is empty
        ptsa{e1,1}=[];
        nptsa{e1,1}=[];
        
        mn_rt1a(e1,1)=0;
        mn_rt2a(e1,1)=0;
        stdrta(e1,1)=0;
        ci_inta(e1,1)=0;
        median_indexa(e1,1)=0;
        median_val(e1,1)=0;
        min_rta(e1,1)=0;
        max_rta(e1,1)=0;
        
        
        out_mn_rt1a(e1,1)=0;
        out_mn_rt2a(e1,1)=0;
        out_stdrta(e1,1)=0;
        out_ci_inta(e1,1)=0;
        out_median_indexa(e1,1)=0;
        out_median_val(e1,1)=0;
        out_min_rta(e1,1)=0;
        out_max_rta(e1,1)=0;
        
    end
end

% Save data to the output variable rt_stats
rt_stats=[mn_rt1a, mn_rt2a, stdrta, ci_inta, median_indexa, median_val, min_rta, max_rta];

% Calculate the number of descriptive statistics
num_stats=size(rt_stats, 2);

% % Save data to the output variable rt_outlier_stat
rt_outlier_stats=[out_mn_rt1a, out_mn_rt2a, out_stdrta, out_ci_inta, out_median_indexa, out_median_val, out_min_rta, out_max_rta];

% % Initialize the output variables other_stats and other_outlier_stats
other_stats=zeros(num_vars, num_data_rows, num_stats);
other_outlier_stats=zeros(num_vars, num_data_rows, num_stats);

for e2=1:num_vars;
    
    rta=varargin{e2};
    
    [num_data_rows, buf]=size(rta);
    
    for e1=1:num_data_rows;
        
        if iscell(rta);
            buf1=rta{e1, :};
            if iscell(buf1);
                rt=buf1{1};
            else
                rt=buf1;
            end
        else
            rt=rta(e1, :);
        end
        
        num_cols=length(rt);
        
        if num_cols > 0
            
            if ~isequal(dep_var, 1)
                % Calculate the robust estimate of the mean.
                %
                % Statistical language for this type of mean is
                % "calculates the Least Median of Squares (LMS)
                % location parameter of the columns of a matrix
                % X. If X is a vector, it returns the LMS
                % location parameter of its components. If X
                % is a scalar, it returns X."
                % select the set of outliers data for calculating descriptive statistics
                
                if isequal( abs_other(e2), 1)
                    rto=abs(rt);
                else
                    rto=rt;
                end
                
                rto=squeeze(rto);
                rto=rto(:);
                
                %if isequal(flag1(1+e2), 1)
                %    [gm]=LMSloc(10.^(rto./20));
                %    gm=20.*log10(gm);
                %else
                %    [gm]=LMSloc(rto);
                %end
                
                [ gm ] = rmean(rto, flag1(1+e2));
                
                % calculate standard deviation
                %if isequal(flag1(1+e2), 1)
                %    stdrt=20.*log10(std(10.^(rts./20)));
                %else
                stdrt=std(rt);
                %end
                
                if length(rt) > 3 && isequal(sod, 0)
                    
                    if ~isempty(rto)
                        [res, raw] = fastlts(rto);
                        npts=find(res.flag==0);
                    else
                        npts=[];
                    end
                    
                    pts=setdiff( 1:num_cols, npts); % find the indices of the outliers
                    
                    %pts=intersect( find(rto > gm - num_std*stdrt), find(rto < gm + num_std*stdrt)); % find all values within num_std std of geometric mean
                    %npts=setdiff( 1:num_cols, pts); % find the indices of the outliers
                else
                    pts=1:num_cols;
                    npts=[];
                end
                
                if isempty(pts)
                    pts=1:num_cols;
                    npts=[];
                end
                
                % Determine the maximum number of outliers in any rta data row
                max_num_out=max([max_num_out, length(npts)]);
                
                % indices of set of non-outliers (i.e. values kept)
                ptsa{e1, e2+1}=pts;
                
                % indices of set of outliers (i.e. values discarded from
                % descriptive statistics)
                nptsa{e1, e2+1}=npts;
            else
                
                
                [mp1 np1]=size(ptsa);
                
                if mp1 < e1
                    pts=ptsa{1, 1};
                    ptsa{e1, e2+1}=ptsa{1, 1};
                else
                    pts=ptsa{e1, 1};
                    ptsa{e1, e2+1}=ptsa{e1, 1};
                end
                
            end
            
            
            % select the set of non-outliers data for calculating
            % descriptive statistics
            if isequal( abs_other(e2), 1)
                rts=abs(rt(pts));
            else
                rts=rt(pts);
            end
            
            
            % Calculate the arithmetic mean.
            if isequal(flag1(1+e2), 1)
                [mn_rt1]=mean(10.^(rts./20));
                mn_rt1=20.*log10(mn_rt1);
            else
                [mn_rt1]=mean(rts);
            end
            
            
            % Calculate the robust estimate of the mean
            if ~isempty(rts)
            %    if isequal(flag1(1+e2), 1)
            %        [mn_rt2]=LMSloc(10.^(rts./20));
            %        mn_rt2=20.*log10(mn_rt2);
            %    else
            %        [mn_rt2]=LMSloc(rts);
            %    end
            
            [ mn_rt2 ] = rmean(rts, flag1(1+e2));
            
            else
                mn_rt2=[];
            end
            
            
            
            % calculate standard deviation
            %if isequal(flag1(1+e2), 1)
            %    stdrt=20.*log10(std(10.^(rts./20)));
            %else
            stdrt=std(rts);
            %end
            
            % calculate 95% confidence interval of
            % the standard error of the
            % t-distribution with a two-sided test
            [ci_int]=t_confidence_interval(rts, 0.95);
            
            % Calculate the median
            if isequal(flag1(1+e2), 1)
                [medianrt]=median(10.^(rts./20));
                medianrt=20.*log10(medianrt);
            else
                [medianrt]=median(rts);
            end
            
            
            % Calculate the median index
            % (data point closest ot the median value)
            [mbuf ix]=min(abs(rts-medianrt));
            
            % Calculate the minimum
            minrt=min(rts);
            
            % Calculate the maximum
            maxrt=max(rts);
            
            
            other_stats(e2, e1, 1)=m_round(mn_rt1,   round_kind(e2+1), round_digits(e2+1));
            other_stats(e2, e1, 2)=m_round(mn_rt2,   round_kind(e2+1), round_digits(e2+1));
            other_stats(e2, e1, 3)=m_round(stdrt,    1, 3);
            other_stats(e2, e1, 4)=m_round(ci_int,   1, 3);
            other_stats(e2, e1, 5)=m_round(ix,       0, 0);
            other_stats(e2, e1, 6)=m_round(medianrt, round_kind(e2+1), round_digits(e2+1));
            other_stats(e2, e1, 7)=m_round(minrt,    round_kind(e2+1), round_digits(e2+1));
            other_stats(e2, e1, 8)=m_round(maxrt,    round_kind(e2+1), round_digits(e2+1));
            
            
            if ~isequal(sod, 1) && ~isempty(npts)
                
                if isequal(dep_var, 1)
                    
                    [mp1 np1]=size(nptsa);
                    
                    if mp1 < e1
                        npts=nptsa{1, 1};
                        nptsa{e1, e2+1}=nptsa{1, 1};
                    else
                        npts=nptsa{e1, 1};
                        nptsa{e1, e2+1}=nptsa{e1, 1};
                    end
                    
                end
                
                % select the set of outliers data for calculating descriptive statistics
                if isequal( abs_other(e2), 1)
                    rts=abs(rt(npts));
                else
                    rts=rt(npts);
                end
                
                % Calculate the arithmetic mean.
                if isequal(flag1(1+e2), 1)
                    [mn_rt1]=mean(10.^(rts./20));
                    mn_rt1=20.*log10(mn_rt1);
                else
                    [mn_rt1]=mean(rts);
                end
                
                
                % Calculate the robust estimate of the mean
                %if isequal(flag1(1+e2), 1)
                %    [mn_rt2]=LMSloc(10.^(rts./20));
                %    mn_rt2=20.*log10(mn_rt2);
                %else
                %    [mn_rt2]=LMSloc(rts);
                %end
                
                [ mn_rt2 ] = rmean(rts, flag1(1+e2));
                
                % calculate standard deviation
                %if isequal(flag1(1+e2), 1)
                %    stdrt=20.*log10(std(10.^(rts./20)));
                %else
                stdrt=std(rts);
                %end
                
                
                % calculate 95% confidence interval of
                % the standard error of the
                % t-distribution with a two-sided test
                [ci_int]=t_confidence_interval(rts, 0.95);
                
                % Calculate the median
                if isequal(flag1(1+e2), 1)
                    [medianrt]=median(10.^(rts./20));
                    medianrt=20.*log10(medianrt);
                else
                    [medianrt]=median(rts);
                end
                
                
                % Calculate the median index
                % (data point closest ot the median value)
                [mbuf ix]=min(abs(rts-medianrt));
                
                % Convert to Median Index of the original data array
                ix=npts(ix);
                
                % Calculate the minimum
                minrt=min(rts);
                
                % Calculate the maximum
                maxrt=max(rts);
                
                other_outlier_stats(e2, e1, 1)=m_round(mn_rt1,   round_kind(e2+1), round_digits(e2+1));
                other_outlier_stats(e2, e1, 2)=m_round(mn_rt2,   round_kind(e2+1), round_digits(e2+1));
                other_outlier_stats(e2, e1, 3)=m_round(stdrt,    1, 3);
                other_outlier_stats(e2, e1, 4)=m_round(ci_int,   1, 3);
                other_outlier_stats(e2, e1, 5)=m_round(ix,       0, 0);
                other_outlier_stats(e2, e1, 6)=m_round(medianrt, round_kind(e2+1), round_digits(e2+1));
                other_outlier_stats(e2, e1, 7)=m_round(minrt,    round_kind(e2+1), round_digits(e2+1));
                other_outlier_stats(e2, e1, 8)=m_round(maxrt,    round_kind(e2+1), round_digits(e2+1));
                
            else
                
                other_outlier_stats(e2, e1, 1:8)=0;
                
            end
            
        else
            
            % if the data is empty
            other_stats(e2, e1, 1:8)=0;
            
            other_outlier_stats(e2, e1, 1:8)=0;
            
        end
    end
    
end

% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Write the descriptive statistics to the tab delimited outfile
%
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Write Data Vertically
if isequal(save_file, 1)
    
    % check if outfile is a filename or a fid
    if isa(outfile, 'double') && outfile > -1
        flag2=1;
        fid=outfile;
    else
        flag2=0;
        [filename_base, ext]=file_extension(outfile);
        fid=fopen([filename_base '.txt'], 'w');
    end
    
    for e2=1:(1+num_vars);
        
        if isequal(e2, 1)
            rta=rta2;
            [num_data_rows, buf]=size(rta);
            
            mn_rt1a=rt_stats(:, 1);
            mn_rt2a=rt_stats(:, 2);
            stdrta=rt_stats(:, 3);
            ci_inta=rt_stats(:, 4);
            median_indexa=rt_stats(:, 5);
            median_val=rt_stats(:, 6);
            min_rta=rt_stats(:, 7);
            max_rta=rt_stats(:, 8);
            
            out_mn_rt1a=rt_outlier_stats(:, 1);
            out_mn_rt2a=rt_outlier_stats(:, 2);
            out_stdrta=rt_outlier_stats(:, 3);
            out_ci_inta=rt_outlier_stats(:, 4);
            out_median_indexa=rt_outlier_stats(:, 5);
            out_median_val=rt_outlier_stats(:, 6);
            out_min_rta=rt_outlier_stats(:, 7);
            out_max_rta=rt_outlier_stats(:, 8);
            
        else
            rta=varargin{e2-1};
            [num_data_rows, buf]=size(rta);
            for e1=1:num_data_rows;
                mn_rt1a(e1, 1)=other_stats(e2-1, e1, 1);
                mn_rt2a(e1, 1)=other_stats(e2-1, e1, 2);
                stdrta(e1, 1)=other_stats(e2-1, e1, 3);
                ci_inta(e1, 1)=other_stats(e2-1, e1, 4);
                median_indexa(e1, 1)=other_stats(e2-1, e1, 5);
                median_val(e1, 1)=other_stats(e2-1, e1, 6);
                min_rta(e1, 1)=other_stats(e2-1, e1, 7);
                max_rta(e1, 1)=other_stats(e2-1, e1, 8);
            end
            
            for e1=1:num_data_rows;
                out_mn_rt1a(e1, 1)=other_outlier_stats(e2-1, e1, 1);
                out_mn_rt2a(e1, 1)=other_outlier_stats(e2-1, e1, 2);
                out_stdrta(e1, 1)=other_outlier_stats(e2-1, e1, 3);
                out_ci_inta(e1, 1)=other_outlier_stats(e2-1, e1, 4);
                out_median_indexa(e1, 1)=other_outlier_stats(e2-1, e1, 5);
                out_median_val(e1, 1)=other_outlier_stats(e2-1, e1, 6);
                out_min_rta(e1, 1)=other_outlier_stats(e2-1, e1, 7);
                out_max_rta(e1, 1)=other_outlier_stats(e2-1, e1, 8);
            end
            
        end
        
        
        %Print the row header for each data set;
        if isequal(e2, 1)
            fprintf(fid, 'Data and Descriptive Statistics of Main Data Set to determine Outliers\r\n\r\n');
            
            
            fprintf(fid, 'Array and Row Names\tData\t');
            
            tabs1='';
            for e1=1:(max_num_cols);
                tabs1=[tabs1, '\t'];
            end
            fprintf(fid, tabs1);
            
            
            if ~isequal(sod, 1) && logical(max_num_out > 0)
                fprintf(fid, 'Descriptive Statistics of Data with Outliers Removed\t');
                tabs1='';
                for e1=1:(num_stats);
                    tabs1=[tabs1, '\t'];
                end
                fprintf(fid, tabs1);
                fprintf(fid,'Analysis of Outliers');
                
                tabs1='';
                for e1=1:(max_num_out+1);
                    tabs1=[tabs1, '\t'];
                end
                fprintf(fid, tabs1);
                
                fprintf(fid, 'Descriptive Statistics of Outliers');
                
            else
                fprintf(fid, 'Descriptive Statistics of Data ');
            end
            
            fprintf(fid, '\r\n\r\n\t');
            
        elseif isequal(e2, 2)
            fprintf(fid, 'Other Data and Statistics\t');
        else
            fprintf(fid, '\t');
        end
        
        if isequal(e2, 1)
            fprintf(fid, '%s\t', col_name);
            tabs1='';
            for e1=1:(max_num_cols-1);
                tabs1=[tabs1, '\t'];
            end
        else
            tabs1='';
            for e1=1:(max_num_cols);
                tabs1=[tabs1, '\t'];
            end
        end
        
        fprintf(fid, tabs1);
        
        if num_cols  > 2
            fprintf(fid, '\tArithmetic Mean\tRobust Mean\tStandard Deviation\t95+-%%Confidence Interval\tMedian Index\tMedian\tMinimum\tMaximum');
            
            
            % If there are outliers then print all of the descriptive
            % statistics of the outliers.
            if max_num_out > 0
                fprintf(fid,'\t\tOutliers');
                tabs1='';
                for e3=1:(max_num_out);
                    tabs1=[tabs1, '\t'];
                end
                
                fprintf(fid, tabs1);
                fprintf(fid, '\tArithmetic Mean\tRobust Mean\tStandard Deviation\t95+-%%Confidence Interval\tMedian Index\tMedian\tMinimum\tMaximum\t\r\n');
            else
                fprintf(fid, '\r\n');
            end
        else
            fprintf(fid, '\tArithmetic Mean\tRobust Mean\t\r\n');
        end
        
        fprintf(fid, '%s\t', [array_names{e2}, ' ', array_units{e2} ]);
        
        nums=1:(max_num_cols);
        fprintf(fid, '%i\t', nums);
        if e2 > length(array_units)
            e3=length(array_units);
        else
            e3=e2;
        end
        
        
        if max_num_cols  > 2
            % Print the units of the descriptive statistics
            % they have the same units as the array; however, the median
            % index has the units of an index of the median of the data array.
            fprintf(fid, '\t');
            for e1=1:4;
                fprintf(fid, [array_units{e3}, '\t']);
            end
            
            fprintf(fid, '%s\t', 'Index');
            
            for e1=6:num_stats;
                fprintf(fid, [array_units{e3}, '\t']);
            end
            
            
            if max_num_out > 0
                
                fprintf(fid, '\t%s\t', 'Indices');
                
                tabs1='';
                for e1=1:(max_num_out);
                    tabs1=[tabs1, '\t'];
                end
                fprintf(fid, tabs1);
                
                % Print the units of the descriptive statistics
                % they have the same unitsas the array; however, the median
                % index has the units of an index.
                for e1=1:4;
                    fprintf(fid, [array_units{e3}, '\t']);
                end
                
                fprintf(fid, '%s\t', 'Index');
                
                for e1=6:num_stats;
                    fprintf(fid, [array_units{e3}, '\t']);
                end
                
            end
            
            fprintf(fid, '\r\n');
            
        else
            fprintf(fid, ['\t' array_units{e3}, '\t', array_units{e3}, '\t\r\n']);
        end
        
        [num_data_rows, buf]=size(rta);
        
        for e1=1:num_data_rows;
            
            if iscell(rta);
                buf1=rta{e1, :};
                if iscell(buf1);
                    rt=buf1{1};
                else
                    rt=buf1;
                end
            else
                rt=rta(e1, :);
            end
            
            num_cols=length(rt);
            
            [mp1 np1]=size(ptsa);
            
            if mp1 < e1
                pts=ptsa{1,e2};
                npts=nptsa{1,e2};
            else
                pts=ptsa{e1,e2};
                npts=nptsa{e1, e2};
            end
            
            mn_rt1=mn_rt1a(e1);
            mn_rt2=mn_rt2a(e1);
            std_rt=stdrta(e1);
            ci_int=ci_inta(e1);
            ix=median_indexa(e1);
            medianrt=median_val(e1);
            minrt=min_rta(e1);
            maxrt=max_rta(e1);
            
            out_mn_rt1=out_mn_rt1a(e1);
            out_mn_rt2=out_mn_rt2a(e1);
            out_std_rt=out_stdrta(e1);
            out_ci_int=out_ci_inta(e1);
            out_ix=out_median_indexa(e1);
            out_medianrt=out_median_val(e1);
            out_minrt=out_min_rta(e1);
            out_maxrt=out_max_rta(e1);
            
            
            if ~isempty(row_unit)
                if iscell(row_unit)
                    if ischar(row_unit{e1})
                        row_unit1=row_unit{e1};
                    else
                        % If its not a string assume its a number
                        row_unit1=num2str(row_unit{e1});
                    end
                elseif ischar(row_unit)
                    row_unit1=row_unit;
                else
                    row_unit1=num2str(row_unit(e1));
                end
            else
                row_unit1='';
            end
            
            if isempty(row_names)
                fprintf(fid, '%i\t', e1);
            else
                if length(row_names) >= e1
                    if iscell(row_names)
                        if ischar(row_names{e1})
                            if isempty(row_names{e1})
                                fprintf(fid, '%s\t', [num2str(e1), ' ', row_unit1]);
                            else
                                fprintf(fid, '%s\t', [row_names{e1}, ' ', row_unit1]);
                            end
                        else
                            % If its not a string assume its a number
                            if isempty(num2str(row_names{e1}))
                                fprintf(fid, '%s\t', [num2str(e1), ' ', row_unit1]);
                            else
                                fprintf(fid, '%s\t', [num2str(row_names{e1}), ' ', row_unit1]);
                            end
                        end
                    else
                        if isempty(num2str(row_names(e1)))
                            fprintf(fid, '%s\t', [num2str(e1), ' ', row_unit1]);
                        else
                            if ischar(row_names(e1))
                                fprintf(fid, '%s\t', [row_names ' ', row_unit1]);
                            else
                                fprintf(fid, '%s\t', [num2str(row_names(e1)), ' ', row_unit1]);
                            end
                        end
                    end
                else
                    fprintf(fid, '%i\t', e1);
                end
            end
            
            
            % Print the Data
            if ~(any(isempty(rt)) || any(isempty(round_kind)) || any(isempty(round_digits)))
                [A2, A_str]=m_round(rt, round_kind(e2), round_digits(e2));
            else
                A_str={};
                A2=[];
            end
            
            
            for e3=1:length(A_str);
                fprintf(fid, '%s\t', A_str{e3});
            end
            
            if max_num_cols > num_cols
                for e3=1:(max_num_cols-num_cols);
                    fprintf(fid, '\t' );
                end
            end
            
            
            
            if num_cols  > 2
                
                % Print the Descriptive Statistics of all the data
                [A2, A_str]=m_round([mn_rt1 mn_rt2 std_rt, ci_int ix medianrt minrt maxrt], [round_kind(e2)*[1 1] [1 1 0] round_kind(e2)*[1 1 1]], [round_digits(e2)*[1 1] [3 3 0] round_digits(e2)*[1 1 1]]);
                
                fprintf(fid, '\t' );
                for e3=1:length(A_str);
                    fprintf(fid, '%s\t', A_str{e3});
                end
                
                fprintf(fid, '\t' );
                for e3=1:length(npts);
                    fprintf(fid, '%d\t', npts(e3) );
                end
                
                
                if max_num_out > 0
                    
                    fprintf(fid, '\t' );
                    for e3=1:(max_num_out-length(npts));
                        fprintf(fid, '\t' );
                    end
                    
                    % Print the Descriptive Statistics of the outlier data
                    [A2, A_str]=m_round([out_mn_rt1 out_mn_rt2 out_std_rt, out_ci_int out_ix out_medianrt out_minrt out_maxrt], [round_kind(e2)*[1 1] [1 1 0] round_kind(e2)*[1 1 1]], [round_digits(e2)*[1 1] [3 3 0] round_digits(e2)*[1 1 1]]);
                    
                    
                    for e3=1:length(A_str);
                        fprintf(fid, '%s\t', A_str{e3});
                    end
                    
                end
                
            else
                
                % Print the Descriptive Statistics of all the data
                [A2, A_str]=m_round([mn_rt1, mn_rt2], round_kind(e2), round_digits(e2));
                
                fprintf(fid, '\t' );
                for e3=1:length(A_str);
                    fprintf(fid, '%s\t', A_str{e3});
                end
                
            end
            
            fprintf(fid, '\r\n');
            
        end
        fprintf(fid, '\r\n');
    end
    
    if isequal(flag2, 0)
        fclose(fid);
        fclose('all');
    end
    
end

if isequal(sod, 1) || logical(max_num_out < 1) || logical(max_num_cols < 2)
    rt_outlier_stats=[];
    other_outlier_stats=[];
end

% Write Data Horizontally
