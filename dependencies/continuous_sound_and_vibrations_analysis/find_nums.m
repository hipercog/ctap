function [nums, matches]=find_nums(str, flag1, decimal_point, complex_var, spaces)
% % find_nums: Finds floating point complex, real, integer, and currency (dollars) numbers in a string
% %
% % Syntax:
% %
% % [nums, matches]=find_nums(str, flag1, decimal_point, complex_var);
% %
% % ***********************************************************
% %
% % Description
% %
% % [nums]=find_nums(str);
% %
% % Returns nums, an array of floating point double precision complex
% % valued numbers found in the input string, str, by searching for
% % floating point numbers with or without commas separating the 3 digit
% % groupings.  By default the period is the decimal point.  Also both the
% % floating point and exponential formats are acceptable.
% %
% %
% % [nums]=find_nums(str, flag1);
% % Returns nums an array of double precision numbers of class specified
% % by flag using a period as the decimal point and comma as the 3 digit
% % separators.  Numbers may have the 3 digit separators or not. 
% %
% % flag1=1:     % complex (floating point)
% % 
% % flag1=2:     % real (floating point)
% % 
% % flag1=3:     % integers are treated as real floating point numbers 
% %              % without a fractional part (nothing to the right of
% %              % the decimal point is accepted)
% % 
% % flag1=4:     % currency (dollars) is treated as a real floating point 
% %              % numbers rounded to 2 digits to the right of the decimal 
% %              % point.  
% % 
% %              % The default value of flag is complex floating point
% %              % default is flag1=1:
% %
% % 
% % 
% % [nums]=find_nums(str, flag1, decimal_point);
% % decimal_point specifies the covention to use for the decimal point and
% % 3 digit separators. Either the American or European conventions can be
% % used.  
% %
% % decimal_point=1 uses the American convention, period for
% % decimal point and commas for 3 digit separators.
% %
% % Otherwise the European convention is used which means that a comma 
% % is used for the decimal point and periods are used for the 3 digit
% % separators.
% %
% % [nums]=find_nums(str, flag1, decimal_point, complex_var);
% %
% % complex_var is a regular expression for the complex variable letter.
% % To use both i and j as letters for the imaginary part use
% % the default which is complex_var='[ij]';
% %
% % [nums, matches]=find_nums(str, flag1, decimal_point, complex_var);
% % matches is a cell array of strings which matched the specified type 
% % of number given by the flag input variable.
% % 
% % spaces is a boolean if spaces=1 then spaces are allowed between the 
% % sign and the number, otherwise spaces are not allowed between the sign 
% % and the number.
% %
% % ***********************************************************
% %
% % Input Variables
% %
% % str is an input string cannot be a cell array.
% %     default is str=''; (empty string)
% %
% % flag1 specifies the type of number to search for.  Program supports
% %     complex, real, integer, and currency (dollars).
% %     default is complex floating point with or without 3 digit 
% %     separators;
% %
% % decimal_point specifies the convention for the decimal point.
% %     default is American convention where the decimal point is a period
% %     and the 3 digit separator is a comma.
% %
% % complex_var is the letter which designates the imaginary part of a
% %     complex number the default is complex_var='[ij]';  Both i
% %     and j to are designated by default for indicating the imaginary
% %     part of complex numbers.
% %
% % spaces is a boolean if 1 then spaces are allowed between the sign and
% %     the number, otherwise spaces are not allowed between the sign and
% %     the number.
% %
% % ***********************************************************
% %
% % Output Variables
% %
% % nums is an array of double precision numbers in complex format if 
% %     complex numbers are specified otherwise it is in real format 
% %     depending on the sytem settings the numbers may be displayed in 
% %     exponential format. 
% %
% % matches is a cell array of character strings of the parts of str which
% %     matched the regular expression.
% %
% %
% % ***********************************************************
%
%
% Example='1';
% % One Complex number
% str='1 i';
% [nums]=find_nums(str);
%
%
%
% Example='2';
% % Multiple Complex numbers
% str='1 i 1 i 1 i 1 2,000.01      +8274i  -1 i 3i, last number 3.0-2i';
% flag1=1;
% decimal_point=1;
% complex_var='i';
% [nums]=find_nums(str, flag1, decimal_point, complex_var);
%
%
%
% Example='3';
% % Complex numbers using both i and j.
%
% str='1 i 1 j 1 j 1 2,000.01   +8274i  -1 i 3j, last number 3.0-2i';
% flag1=1;
% decimal_point=1;
% complex_var='[ij]';
% [nums]=find_nums(str, flag1, decimal_point, complex_var);
%
%
%
% Example='4';
% % Complex numbers using both i and j using the European decimal point
% % convention.
% str='2.000.765,01   +8.274,00182347i   2.000.765,01   +8.274,7j ';
% flag1=1;
% decimal_point=2;
% complex_var='[ij]';
% [nums]=find_nums(str, flag1, decimal_point, complex_var);
%
%
%
% Example='5';
% % real numbers using the European decimal point convention
% % using both the floating point and exponential formats.
% % The fourth number may return Inf depending on the machine.
% str='2.000.765,01   +8.274,00182347E-98 2,934857e24   2.000.765,01e349   +8.274,7  -47.456.345.345,248796 ';
% flag1=2;
% decimal_point=2;
% [nums]=find_nums(str, flag1, decimal_point);
%
%
%
% Example='6';
% % Integer using the European decimal point convention
% % using both the floating point and exponential formats.
% % The fourth number may return Inf depending on the machine.
% str='2.000.765,01   +8.274,00182347E-98 2,934857e24   2.000.765,01e349   +8.274,7  -47.456.345.345,248796 ';
% flag1=3;
% decimal_point=2;
% [nums]=find_nums(str, flag1, decimal_point);
%
%
%
% Example='7';
% % Integers using the American decimal point convention
% str=' +  1,356,3456   -2,356,345  1,000  - 54,345,345,345  2,000.01      +8274  -1 3, last number 3.0';
% flag1=3;
% decimal_point=1;
% [nums]=find_nums(str, flag1, decimal_point);
%
%
%
% Example='8';
% % currency (dollars) numbers using the European decimal point convention
% % The second number is truncated since it has more than two digits to
% % the right of the decimal point.
% str='$2.000.765,01   +8274,35182347 $2.934.857,98   2.000.765,01   -$8.274,76  -47.456.345.345,24 ';
% flag1=4;
% decimal_point=2;
% [nums]=find_nums(str, flag1, decimal_point);
%
%
%
% Example='9';
% % currency (dollars) numbers using the American decimal point convention
% % The second number is truncated since it has more than two digits to
% % the right of the decimal point.
% str='- $2,000,765.01   - $8274.35182347 -$2,934,857.98   -2,000,765.01   + $8,274.76  +47,456,345,345.24 ';
% flag1=4;
% decimal_point=1;
% spaces=1;
% [nums]=find_nums(str, flag1, decimal_point, spaces);
%
%
%
% % ***********************************************************
% %
% % References
% %
% % Regular Expressions used in this program are modified from the
% % sources below.
% %
% %
% % http://regexlib.com/REDetails.aspx?regexp_id=130
% % Al Kahler
% %
% % DESCRIPTION Matches US currency input with commas.
% % This provides a fix for the currency regular expression posted at
% % http://regxlib.com/REDetails.aspx?regexp_id=70 by escaping the .
% % (period) to ensure that no other characters may be used in it's place.
% %
% % ^\$?([0-9]{1,3},([0-9]{3},)*[0-9]{3}|[0-9]+)(\.[0-9][0-9])?$
% %
% %
% % DESCRIPTION Matches floating point input.
% % http://www.regular-expressions.info/floatingpoint.html
% % [-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?
% %
% % 
% % ***********************************************************
% %
% % find_nums is written by Edward L. Zechmann
% %
% %     date 20 September  2008
% %
% % modified 21 September  2008   Added spaces argument which allows
% %                               spaces between the sign and the number.
% %
% % modified 23 September  2008   Fixed a bug in parsing complex numbers
% %                               that have spaces between the sign.
% %
% % modified 24 September  2008   Added option to find integers by treating
% %                               them as floating point numbers and 
% %                               rounding to the nearest integer
% %
% % modified 25 September  2008   Updated Comments
% %                               Removed dependency on pow10round
% %
% % modified 29 September  2008   Fixed bugs in matching and evaluating 
% %                               complex numbers
% %                               Updated Comments
% %
% %
% % ***********************************************************
% %
% % Please Feel Free to Modify This Program
% %
% % See Also: isdigit, str2num, str2double
% %

if (nargin < 1 || isempty(str)) || ~ischar(str)
    str='';
end

if (nargin < 2 || isempty(flag1)) || ~isnumeric(flag1)
    flag1=1;
end

if (nargin < 3 || isempty(decimal_point)) || ~isnumeric(decimal_point)
    decimal_point=1;
end

if (nargin < 4 || isempty(complex_var)) || ~ischar(complex_var)
    complex_var='[ij]';
end

if (nargin < 5 || isempty(spaces)) || ~isnumeric(spaces)
    spaces=1;
end

if isequal(decimal_point, 1)
    % American Convention
    % decimal point character
    dp='\.';

    % 3 digit separator character
    ds=',';
else
    % European Convention
    % decimal point character
    dp=',';

    % 3 digit separator character
    ds='\.';
end

cv=complex_var;

if isequal(spaces, 1)
    sp=' ';
else
    sp='';
end



% floating point number with no 3 digit separators American convention
float_no_ds_A=['([-+]?', sp, '*[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)'];

% floating point number with 3 digit separators American convention
ds_float_A=['([-+]?', sp, '*([0-9]{1,3}', ',', '([0-9]{3}', ',', ')*[0-9]{3}|[0-9]+)(', '\.', '?[0-9]+)?([eE][+-]?[0-9]+)?)'];

% floating point numbers with or without 3 digit separators American
% convention
fb_A=['(', ds_float_A, '|', float_no_ds_A, ')'];



% floating point number with no 3 digit separators specified convention
float_no_ds=['([-+]?', sp, '*[0-9]*', dp, '\.?[0-9]+([eE][-+]?[0-9]+)?)'];

% floating point number with 3 digit separators specified convention
ds_float=['([-+]?', sp, '*([0-9]{1,3}', ds, '([0-9]{3}', ds, ')*[0-9]{3}|[0-9]+)(', dp, '?[0-9]+)?([eE][+-]?[0-9]+)?)'];

% floating point numbers with or without 3 digit separators
fb=['(', ds_float, '|', float_no_ds, ')'];



% Complex floating point numbers with or without 3 digit separators
% using the specified convention
complex_float=['(', fb, sp, '*[-+]*', sp, '*', fb, cv, ')|(', fb, sp, '*[-+]*', sp, '*', cv, ')|(', fb,  cv, ')|([-+]*', sp, '*', cv, ')|(', fb, ')' ];


% Currency (dollars) with two digits to the right of the decimal place
currency_comma=['[-+]?', sp, '*\$?([0-9]{1,3}', ds, '([0-9]{3}', ds, ')*[0-9]{3}|[0-9]+)(', dp, '[0-9]*)?'];
currency_no_comma=['[-+]?', sp, '*\$?([0-9]{1,3}', ds, '([0-9]{3}', ds, ')*[0-9]{3}|[0-9]+)(', dp, '[0-9]*)?'];

% Currency (dolalrs) with or without 3 digit separators using specified
% convention
cur=['(', currency_comma, '|', currency_no_comma, ')?'];


switch flag1
    case 1
        [start_idx, end_idx, extents, matches] = regexp(str, complex_float);
    case 2
        [start_idx, end_idx, extents, matches] = regexp(str, fb);
    case 3
        [start_idx, end_idx, extents, matches] = regexp(str, fb);
    case 4
        [start_idx, end_idx, extents, matches] = regexp(str, cur);
    otherwise
        [start_idx, end_idx, extents, matches] = regexp(str, complex_float);
end

num_nums=length(start_idx);
nums=zeros(num_nums, 1);

% befor parsing into numbers remove currency symbols $.
matches2=matches;
matches2 = strrep(matches2, '$', '');

% remove 3 digit separators
if isequal(decimal_point, 1)
    % American convention
    % remove commas
    matches2 = strrep(matches2, ',', '');
else
    % European convention
    % remove periods
    matches2 = strrep(matches2, '.', '');

    % change comma to a period
    matches2 = strrep(matches2, ',', '.');
end


% convert strings to double precision numbers
count=0;

for e1=1:num_nums;

    switch flag1
        
        case 1

            % Complex Floating Point Numbers
            
            %search for the floating point parts of the complex number
            [start_idx1, end_idx1, extents1, matches3] = regexp(matches2{1, e1}, ['(', fb_A, ')']);
            
            %search for the complex variable letter designator
            [start_idx2, end_idx2, extents2, matches4] = regexp(matches2{1, e1}, cv);
            
            % Count the number of negative signs on the imaginary part
            if isempty(end_idx2)
                matches5={};
            else
                if isempty(end_idx1)
                    [start_idx5, end_idx5, extents5, matches5] = regexp(matches2{1, e1}(1:(end_idx2(1)-1)), '-');
                elseif isequal(length(end_idx1), 1)
                    if isequal(end_idx2(1), end_idx1(1)+1)
                        % floating point is attached to the imaginary
                        % part of the complex number
                        [start_idx5, end_idx5, extents5, matches5] = regexp(matches2{1, e1}(1:(end_idx2(1)-1)), '-');
                    else
                        % floating point is attached to the real part of
                        % the complex number
                        [start_idx5, end_idx5, extents5, matches5] = regexp(matches2{1, e1}((end_idx1(1)+1):(end_idx2(1)-1)), '-');
                    end
                    
                else
                    [start_idx5, end_idx5, extents5, matches5] = regexp(matches2{1, e1}((end_idx1(1)+1):(end_idx2(1)-1)), '-');
                end
            end
            
            if isequal(mod(length(matches5), 2), 1)
                imag_sign=-1;
            else
                imag_sign=1;
            end
            
            if length(matches3) >= 2
                matches3 = strrep(matches3, ' ', '');
                % both a real and an imaginary part
                real_part=str2double(matches3{1, 1});
                imag_part=imag_sign*abs(str2double(matches3{1, 2}));
                
            elseif isequal(length(matches3), 1)
                matches3 = strrep(matches3, ' ', '');
                if length(matches4) >= 1
                    % floating point number can be attached to the real or
                    % imaginary part
                    % check if index of letter is directly after the floating
                    % point number
                    % The sign can appear infront of the imaginary part.
                    %

                    if isequal(end_idx2(1), end_idx1(1)+1)
                        % floating point is attached to the imaginary
                        % number
                        real_part=0;
                        imag_part=imag_sign*abs(str2double(matches3{1, 1}));
                    else
                        % both part exist
                        real_part=str2double(matches3{1, 1});
                        imag_part=imag_sign;
                        
                    end
                else
                    real_part=str2double(matches3{1, 1});
                    imag_part=0;
                end
                
            else
                real_part=0;
                [start_idx5, end_idx5, extents5, matches5] = regexp(matches2{1, e1}(1:(end_idx2(1)-1)), '-');

                if isequal(mod(length(matches5), 2), 1)
                    imag_sign=-1;
                else
                    imag_sign=1;
                end
            
                imag_part=imag_sign;
                
            end

            nums(e1)=real_part+imag_part*i;

        case 2
            
            % Floating Point Numbers
            
            matches2{1, e1} = strrep(matches2{1, e1}, ' ', '');
            nums(e1)=str2double(matches2{1, e1});
            
        case 3
            
            % Integer Numbers
            
            matches2{1, e1} = strrep(matches2{1, e1}, ' ', '');
            num_buf=str2double(matches2{1, e1});
            
            if isequal(num_buf, round(num_buf))
                count=count+1;
                nums(count)=round(num_buf);
                matches{count}=matches2{1, e1};
            end

            if isequal(e1, num_nums)
                nums=nums(1:count);
                matches_buf=cell(1, count);
                for e2=1:count
                    matches_buf{e2}=matches{e2};
                end
                matches=matches_buf;
            end
            
        case 4

            % Currency (Dollars)
            
            matches2{1, e1} = strrep(matches2{1, e1}, ' ', '');
            nums(e1)=1/100*round(100*str2double(matches2{1, e1}));

        otherwise
            
            % Assume a complex number.
            % Remove the spaces.
            % Parse the matched characters.
            matches2{1, e1} = strrep(matches2{1, e1}, ' ', '');
            nums(e1)=str2double(matches2{1, e1});
            
    end

end

