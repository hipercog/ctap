function [m2]=geospace(a, b, n, flag)
% % geospace: caculates a geometric sequence or psuedogeometric sequence from a to b with n elements
% % 
% % Syntax;  [m2]=geospace(a, b, n, flag);
% % 
% % ***********************************************************
% % 
% % Description
% %  
% % Outputs a geometric sequence of n-numbers from a to b.
% % 
% % If both a > 0 and b > 0, then an actual geometric sequence is 
% % calculated.
% % 
% % If both a < 0 and b < 0, then an actual geometric sequence is 
% % calculated.
% % 
% % otherwise a shifted geometric sequence is calculated.
% % 
% % ***********************************************************
% % 
% % Input Variables
% % 
% % a is the beginning number for the sequence.  
% % 
% % b is the ending number for the sequence. 
% % 
% % n is the number of elements. default is 50.  Minimum is 2.  
% % 
% % flag specifies whether the sequence is increasing in factor order or
% %      decreasing factor order.
% % 
% % ***********************************************************
% % 
% % Output Variables
% % 
% % m2 is a sequence of n numbers from a to b.  
% % 
% % ***********************************************************
% % 
% 
% Example='';
%  
% a=1;          % a and b can be positive or negative real numbers
% 
% b=100;        % a and b can be ascending or descending 
%               % acceptable values: a < b, a > b, or a == b 
%               % a and b have default values of 1
%               
% n=100;        % n is the number of data points from a to b
%               % n has a default value of 2
%              
% flag=1;       % increase factor order from a -> b. Default is 1
%               % if a < b, then the plot of m will appear concave up
%               % if a > b, then the plot of m will appear concave down
%
% flag=0;    	% flag ~= 1
%               % decrease factor order from a -> b 
%               % if a < b, then the plot of m will appear concave down
%               % if a > b, then the plot of m will appear concave up
% 
% [m2]=geospace(a, b, n, flag);
% 
% % 
% % Examples
% a=-100; b=100; n=100; flag=1; [m]=geospace(a,b,n,flag);
% figure(1); plot(m);
%
% a=-100; b=100; n=100; flag=2; [m]=geospace(a,b,n,flag);
% figure(2); plot(m);
%
% a=0;    b=100; n=10;  flag=1; [m]=geospace(a,b,n,flag);
% figure(3); plot(m);
%
% a=0;    b=100; n=10;  flag=2; [m]=geospace(a,b,n,flag);
% figure(4); plot(m);
%
% a=-100; b=0;   n=100; flag=1; [m]=geospace(a,b,n,flag);
% figure(5); plot(m);
%
% a=-100; b=0;   n=100; flag=2; [m]=geospace(a,b,n,flag);
% figure(6); plot(m);
% 
% % 
% % ***********************************************************
% % 
% % Written by Edward L. Zechmann
% %
% %   date      24 November     2007
% %
% % modified     1 March        2008    Fixed bug.  Now program actually
% %                                     calculates a geometric sequence 
% %                                     if a > 0 and b > 0
% % 
% % modified    10 September    2008    Updated Comments.
% % 
% % ***********************************************************
% % 
% % Feel free to modify this code.
% % 

% default values are ones
if (nargin < 2 || isempty(a)) || isempty(b)
    a=1;
    b=1;
end

% The default number of data points is 50
if nargin < 3 || isempty(n)
    n=50;
end

% To keep the program from crashing the minimum number of data points is 2
n=round(n);
if n < 2
    n=2;
end

% The default is to increase factor order from a to b
if nargin < 4 || isempty(flag)
    flag=1;
end

% The Geometric sequence can be calculated in two regimes
if (logical(a > 0) && logical(b > 0)) || (logical(a < 0) && logical(b < 0))
    % Actual Geometric Sequence Regime
    regime=1;
else
    % Shifted Pseudo-Geometric Sequence Regime
    regime=2;
end


if isequal(regime, 1) 

    % if a > 0 and b > 0, then a geometric sequence is calculated.
    % if a < 0 and b < 0, then a geometric sequence is calculated.
    
    r=(b/a)^(1/(n-1));
    m=r.^(0:(n-1));
    m2=a*m;

    if ~isequal(flag, 1)
        m2=b+a-fliplr(m2);
    end
    
else
    
    % if a or b is less than 0 then an actual geometric sequence
    % is not calculated, rather a shifted pseudo-geometric sequence is
    % calculated.
    
    a1=a;
    b1=b;
    
    b=abs(b1-a1)+1;
    a=1;
    
    r=(b/a)^(1/(n-1));
    m=r.^(0:(n-1));
    m2=a*m;

    if ~isequal(flag, 1)
        m2=b+a-fliplr(m2);
    end
    
    m2=a1-1+m2;
    
    if b1 < a1
        m2=2*a1-m2;
    end
    
    
end
    
