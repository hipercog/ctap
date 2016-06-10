function varstrx = num2varstr(x, varargin)
%NUM2VARSTR - Convert numeric input into a string that can be used in variable names
%
% Used when converting numeric values to strings that are later used as
% part of e.g. R variable names/labels. With standard settings does the 
% following:
%   2 -> "2"
%   1.5 -> "1d5"
%   2e-2 -> "0d02"
%   2e-3 -> "0.002" !This is a bug. Fix if you like!


% Parse input arguments and replace default values if given as input
p = inputParser;
p.addRequired('x', @isnumeric); %the numeric to convert
p.addParamValue('precision', 2, @isinteger); %number of digits to retain (from the right side of the decimal point)
p.parse(x, varargin{:});
Arg = p.Results;

before_decimal_point = fix(x);

after_decimal_point = x - before_decimal_point;
after_decimal_point = round((10^Arg.precision)*after_decimal_point);

if after_decimal_point == 0
    varstrx = num2str(x);
else
    convstr = ['%ud%0',num2str(Arg.precision),'u'];
    varstrx = sprintf(convstr,before_decimal_point, after_decimal_point);
end
