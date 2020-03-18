function [y, x, a]=match_height_and_slopes2(num_pts, x1, x2, h1, h2, s1, s2)
% % match_height_and_slopes2: creates a quartic with specifed height and slope at the end points.  
% % 
% % Syntax:
% % 
% % [y, x, a]=match_height_and_slopes2(num_pts, x1, x2, h1, h2, s1, s2);
% %
% % ***********************************************************
% %
% % Description
% %
% % An analytical solution for a quartic polynomial of known heights and
% % slopes at the end point.  
% % 
% % 
% %
% % ***********************************************************
% %
% % Input Variables
% % 
% % num_pts=100;    % number of datapoints for the output array.  
% % 
% % x1=0;           % (meters) position of the first coordinate
% %                 % default is x1=0;
% % 
% % x2=1;           % (meters) position of the second coordinate
% %                 % default is x2=1;
% % 
% % h1=0;           % (meters) height of the first coordinate
% %                 % default is h1=0;
% % 
% % h2=0;           % (meters) height of the second coordinate
% %                 % default is h2=0;
% % 
% % s1=0;           % (unitless) slope of the first coordinate
% %                 % default is s2=1;
% % 
% % s2=0;           % (unitless) slope of the second coordinate
% %                 % default is s2=-1;
% % 
% %
% % ***********************************************************
% % 
% % Output Variables 
% % 
% % y is the polynomial output array at the from x1 to x2 where the number 
% %         of points from x1 to x2 is numpts.  
% % 
% % x is the positions of the polynomial data points.   
% % 
% % a is the array of ppolynomial coefficients.  Array "a" follows the 
% %         convention used by the polyval fucntion so a=[y3 y2 y1 y0]; 
% %          a is a row vector.  
% % 
% % 
% %
% % 
% % ***********************************************************
% %
% % match_height_and_slopes2 is written by Edward L. Zechmann
% % 
% %     date 10 July        2010
% % 
% % modified 12 July        2010    Noticed results are ill-conditioned at  
% %                                 x1==0, x1==1, x2==0, x2==1.
% % 
% % modified 13 July        2010    Implemented an analytical solution 
% %                                 ill-conditioned problems were solved. 
% % 
% % modified  4 August      2010    Updated Comments    
% %
% % ***********************************************************
% %
% % see also: ployval, polyfit, polyvalm, \ (matrix left division)
% % 

if (nargin < 1 || isempty(num_pts)) || ~isnumeric(num_pts)
    num_pts=100;
end

if (nargin < 2 || isempty(x1)) || ~isnumeric(x1)
    x1=0;
end

if (nargin < 3 || isempty(x2)) || ~isnumeric(x2)
    x2=1;
end

if (nargin < 4 || isempty(h1)) || ~isnumeric(h1)
    h1=0;
end

if (nargin < 5 || isempty(h2)) || ~isnumeric(h2)
    h2=0;
end

if (nargin < 6 || isempty(s1)) || ~isnumeric(s1)
    s1=1;
end

if (nargin < 7 || isempty(s2)) || ~isnumeric(s2)
    s2=-1;
end


% positions
x=[x1, x2];

% heights
h=[h1, h2];

% slopes
s=[s1, s2];

[buf, ix]=sort(x);

% sorted positions
x1=x(ix(1));
x2=x(ix(2));

% sorted heights by position
h1=h(ix(1));
h2=h(ix(2));

% sorted sorted by position
s1=s(ix(1));
s2=s(ix(2));

% normalize the positions 
x3=x1;
diffx3=(x2-x1);
dx3=(x2-x1)/(num_pts-1);

% normalize the slopes
s1p=s1*diffx3;
s2p=s2*diffx3;

% apply the analytical solution on the domain x1=0 and x2=1.
y0=h1;
y1=s1p;
y2=3*(h2-h1)-2*s1p-s2p;
y3=s1p+s2p+2*(h1-h2);

% place the polynomial coefficients into an array.  
a=[y3 y2 y1 y0];


% Calculate the nomalized positions
x=0:(1/(num_pts-1)):1;
y=polyval(a, x);

% Calculate the actual positions
x=x3+dx3*(-1+(1:num_pts));

% plot the curve
% figure;
% plot(x, y);
% axis equal

