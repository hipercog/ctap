function [out1, out2] = importPresLog( file_name )
% Import any Presentation log file into MATLAB and enjoy your analysis ;)
% This function imports all columns of any presentation log file into
% MATLAB and names the variables to the column names used in the log file.
% Columns are automaticaly converted to the type they primarily contain,
% for example:
%   Trial, Time, TTime, Uncertainty, Duration, ReqTime, ReqDur = double
% Temporal data are as written by Presentation: all in ten thousandths of a
% second. Convert to your preferred format.
% 
% The data are exported as tables.
%
% Usage: [out1, out2] = presLog(file_name);
% * INPUT
%       * file_name  -> full qualified file name as string
%
% * OUTPUT
%       * out1      -> tabular data for every event
%       * out2      -> tabular data for task-related events from each trial
%

% Get the first part of log data (all event info)
T = readtable(file_name...
    , 'NumHeaderLines', 3, 'Delimiter', '\t', "FileType", "text");
T.Properties.VariableNames = strrep(strrep(strip(lower(...
            T.Properties.VariableNames), '_'), '_str', ''), '_num', '');
ix = find(contains(T.code, 'End task'));
out1 = T(1:ix, :);

% Get the second part of log data (task-related info)
fid = fopen(file_name);
textscan(fid, '%s', ix + 5, 'Delimiter', '\n');
B = textscan(fid, '%s%s%s%s%s%s%s%s%s%s%s%s', 1, 'Delimiter', '\t');
vars = matlab.lang.makeUniqueStrings(matlab.lang.makeValidName([B{:}]));

T2 = readtable(file_name...
    , 'NumHeaderLines', ix + 5, 'Delimiter', '\t', "FileType", "text");
T2.Properties.VariableNames = strrep(strrep(strip(lower(vars), '_')...
                                                , '_str', ''), '_num', '');
ix = find(contains(T2.code, 'End task'));
out2 = T2(1:ix, :);


%% All legacy code below was adapted to read CENT Presentation logs.
% % Tobias Otto, tobias.otto@ruhr-uni-bochum.de
% % 1.1
% % 02.02.2011
% 
% % 21.09.2010, Tobias: first draft
% % 02.02.2011, Tobias: added check for wrong header entries
% 
% % -Ben- 
% % Check what type of log we'll find - sometimes log files can include 
% % more columns using Presentation's 'stimulus_properties' parameter
% % if strfind( fileName, 'pilot' )
% %     pilot = true;
% % else
% %     pilot = false;
% % end
% 
% % Init variables
% tmp         = [];
% names       = {};
% out1        = [];
% out2        = [];
% j           = 0;
% 
% % -Ben- convNames contents now depends on presence of extra columns.
% if ~salt
%     convNames   = {'trial', 'Time', 'TTime', 'Uncertainty', 'Duration'...
%     , 'Uncertainty', 'ReqTime', 'ReqDur'};%
% else
%     convNames   = {'trial', 'cond_num', 'vertices_num', 'Time', 'TTime'...
%     , 'Uncertainty', 'Duration', 'Uncertainty', 'ReqTime', 'ReqDur'};%
% end
% convNames   = lower(convNames);
% 
% % -Ben- Store this constant value to avoid calling many times.
% CNL = length(convNames);
% 
% % Load file
% fid = fopen(fileName,'r');
% if(fid == -1)
%     disp(' *************************************************************');
%     disp(['The file ' fileName ' can''t be loaded']);
%     disp(' *************************************************************');
%     error('Please check the input file name and try again');
% end
% 
% % Read file
% header{1} = fgetl(fid);
% header{2} = fgetl(fid);
% header{3} = fgetl(fid);
% 
% % Get variable names
% % -Ben- Have separated the functions for reading the header line and
% % for normal lines, to handle whitespace.
% [numEntries, indexEntries, logLine] = sepHeaders(fid);
% 
% for i = 1:numEntries
%     tmp             = logLine(indexEntries(i):indexEntries(i+1));
%     tmp(tmp==32)    = '_';                  % Replace white space with _
%     tmp(tmp==40)    = '_';                  % Replace ( with _
%     tmp(tmp==41)    = '';                  % Replace ) with nothing
%     names{i}        = lower(tmp(tmp~=9));   % remove tab
% end
% 
% % -Ben- Columns duplicated names get overwritten, i.e. 'Uncertainty'
% % Could not give enough time to make this work.
% % for i = 1:numEntries-1
% %     for j = i+1:numEntries
% %         if strcmp(names{i}, names{j})
% %             names{j} = strcat(names{j}, '_2');
% %         end
% %     end
% % end
% 
% % -Ben- Store this constant value to avoid calling many times.
% NML = length(names);
% 
% % Remove white line
% fgetl(fid);
% % -Ben- Remove unwanted starting line - commented out for completeness.
% %fgetl(fid);
% % -Ben- Store this constant value to make changes easier.
% offset = 5;
% 
% % Get entries by line
% try
%     while( ischar(logLine) )
%         j = j+1;
%         
%         % Separate values from line
%         [numEntries, indexEntries, logLine] = sepEntries(fid);
%         if numEntries <= 1
%             break;
%         end
%         % Some rows have less entries than in the header - pad the line
%         if( NML > numEntries )
%             for x = 1:NML-numEntries
%                 logLine = [logLine char(9)];
%                 indexEntries = [indexEntries length(logLine)];
%             end
%         % Some rows have more entries than defined in header file - Warn user and ignore entry !!!
%         elseif( NML < numEntries )
%             disp(' **********************************************************************');
%             disp([' Additional entries. Please check log file line ' num2str(j+offset)]);
%             disp(' **********************************************************************'); 
%         end
%         % Copy entries to struct
%         for i = 1:NML
%             tmp = logLine(indexEntries(i):indexEntries(i+1));
%             tmp = tmp(tmp~=9);  % Remove tab
% 
%             % Check, if entry has to be converted to a double value
%             k=1;
%             while( k <= CNL && ~strcmpi(convNames{k}, names{i}) )
%                 k=k+1;
%             end
% 
%             if( k <= CNL )
%                 % -Ben- Stop at the first completely empty line, since 
%                 % Pres always adds at least *some* column data
%                 if isempty(tmp)
%                     tmp = 'NaN';
%                 end
%                 out1(j).(names{i})      = str2double(tmp);
%                 out2.(names{i})(j,:)    = str2double(tmp);
%             else
%                 out1(j).(names{i})      = tmp;
%                 out2.(names{i}){j,:}    = tmp;
%             end
%         end
%     end
%     
% catch
%     disp(' *************************************************************')
%     warning('importPresLog:read_fail', 'Failed on line %d', j+offset)
%     disp(' *************************************************************')
% end
% 
% % Tidy up
% fclose(fid);
% 
% % SUB FUNCTIONS
% % -Ben- Renamed but otherwise unchanged, except line 165 - now separators
% % includes the last index, to buffer against the effect of calling diff()
% function [numEntries, indexEntries, logLine] = sepHeaders(fid)
% % Get header line
% logLine         = fgetl(fid);
% % Find valid separators
% separators      = [find(double(logLine)==9) length(logLine)];
% separators      = separators(diff(separators)~=1);
% % Compute last variables
% numEntries      = length(separators)+1;
% indexEntries    = [1 separators length(logLine)];
% 
% % -Ben- New version of sepEntries() ignores presence of adjacent tabs, as these
% % represent empty fields (which we want recorded as empty in the output
% function [numEntries, indexEntries, logLine] = sepEntries(fid)
% % Get header line
% logLine         = fgetl(fid);
% % Find all separators
% separators      = find(double(logLine)==9);
% % Compute last variables
% numEntries      = length(separators)+1;
% indexEntries    = [1 separators length(logLine)];
