function  [y_out, x_out, y_in]=resample_interp3(y_in, x_in, dx_out, remove_mean, shift)
% % resample_interp3:  resamples using interp1 with additional options
% %
% % Syntax;
% % 
% % [y_out, x_out, y_in]=resample_interp3(y_in, x_in, dx_out, remove_mean, shift);
% % 
% % ********************************************************************
% % 
% % Description
% % 
% % Interpolates an array with more options than interp.  
% % Uses a distance increment and offset to determine the independent 
% % variable interpolation points.  
% % 
% % ********************************************************************
% % 
% % Input Variables
% % 
% % y_in=rand(50000, 1);    % Input y values, dependent variable
% %                         % default is y_in=rand(50000, 1);
% % 
% % x_in=0:0.01:1;          % input x values, independent variable
% %                         % default is x_in=0:0.01:1;
% % 
% % dx_out=0.001;           % Increment size for the output x-positions
% %                         % default is dx_out=0.001;
% % 
% % remove_mean=0;          % 0 do not remove mean value
% %                         % 1 remove mean value
% %                         % default is remove_mean=0;
% % 
% % shift=0;                % Starting position for the output x-positions
% %                         % default is shift=0;
% % 
% % ********************************************************************
% % 
% % Output Variables
% % 
% % y_out is the interpolated y values from the positions x_out.  
% % 
% % x_out is the row vector of x positions, incremented at every dx_out 
% %                 starting at shift.  
% % 
% % y_in is the row vector of y_in positions as modified frmo teh original
% %                 input y_in.  
% % 
% % ********************************************************************
% 
% 
% Example='1';
%  
% y_in=rand(50000, 1);
% x_in=0:0.01:1;
% dx_out=x_in(2)-x_in(1);
% remove_mean=0;
% shift=0;
% [y_out, x_out, y_in]=resample_interp3(y_in, x_in, dx_out, remove_mean);
% 
% 
% % ********************************************************************
% %
% % written by Edward L. Zechmann
% %
% % date      5 January     2009
% % 
% % modified 18 February    2010
% % 
% % modified 21 February    2010    Added the shift option and 
% %                                 updated comments.
% % 
% % ********************************************************************
% % 
% % Please feel free to modify this code
% % 
% % see also: interp, interp1, interp2
% % 
% % 
 
if nargin < 1 || isempty(y_in) || ~isnumeric(y_in)
    y_in=rand(50000, 1);
end

if nargin < 2 || isempty(x_in) || ~isnumeric(x_in)
    x_in=0:0.01:1;
end

if nargin < 3 || isempty(dx_out) || ~isnumeric(dx_out)
    if length(x_in) > 1
        dx_out=x_in(2)-x_in(1);
    else
        dx_out=0.001;
    end
end

if nargin < 4 || isempty(remove_mean) || ~isnumeric(remove_mean)
    remove_mean=0;
end

if nargin < 5 || isempty(shift) || ~isnumeric(shift)
    shift=0;
end


% Transpose the input array if necessary 
size_y=size(y_in);
flag1=0;
if size_y(1) <= size_y(2)
    y_in=y_in';
    size_y=size(y_in);
    flag1=1;
end

n=size_y(1);


x_in=x_in(1:n);

% Make sure that all output values are within the input domain
n2=floor(x_in(end)./dx_out);


x_out=dx_out.*(0:(n2-1));

max_x=find(x_out <= max(x_in), 1, 'last' );
y_out=zeros(max_x, size_y(2));



for e2=1:size_y(2);
    y_out(:, e2) = interp1(x_in(1:n), y_in(1:n, e2)', x_out(1:max_x)+shift, 'cubic');
end

if remove_mean == 1
    for e2=1:size_y(2);
        y_out(:, e2) =y_out(:, e2)-mean(y_out(:, e2));
    end

    for e2=1:size_y(2);
        y_in(:, e2) =y_in(:, e2)-mean(y_in(:, e2));
    end
end

if flag1==1
    y_in=y_in';
    y_out=y_out';
end

x_out=x_out(1:max_x);

