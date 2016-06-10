function [interval, error]=t_confidence_interval(x, confidence, dim, num_tails, flag )
% % t_confidence_interval: One or two sided confidence interval of standard error with t distribution
% %
% % Syntax:
% %
% % (interval, error)=t_confidence_interval(x, confidence, dim, num_tails, flag);
% %
% % ***********************************************************
% %
% % Description
% % 
% % [interval]=t_confidence_interval(x);
% % 
% % Calculates the two sided 95% confidence interval using the student-t
% % statistic. 
% % 
% % [interval, error]=t_confidence_interval(x, confidence); 
% % Returns the confidence_interval with a specified confidence level.   
% % confidence must be between 0 to 1.  
% % The default value of confidence is 0.95.
% % 
% % error is an array which indicates which input variables are in error.  
% % For most errors the caculation fails and the program returns, 
% % interval=0 or an array of zeros of size(x).  
% % 
% % (interval, error)=t_confidence_interval(x, confidence, dim);
% % Returns the confidence interval along the dimension of x 
% % specified by the constant dim.  For example, t_confidence_interval(x,0.95,1) 
% % produces the confidence interval values along the first dimension 
% % (the rows) of x.  The default dimension is the first dimension which 
% % has size greater then 1.  
% % 
% % [interval, error]=t_confidence_interval(x, confidence, dim, num_tails);
% % Returns the confidence interval using one or two tails as specified by
% % num_tails.  If num_tails == 1, then a one-tailed confidence interval is
% % returned other wise a two-tailed confidence interval is returned.  
% % The default value is num_tails=2;
% % 
% % [interval, error]=t_confidence_interval(x, confidence, dim, num_tails, flag);
% % If flag = 0, flag =[], or unspecified, then the standard deviation is 
% % calculated using n-1 degrees of freedom. 
% % If flag = 1, then the standard deviation is cacualted using n degrees 
% % of freedom., (the second moment of the set of values about their
% % mean.
% %  
% % 
% % ***********************************************************
% %
% % Input Variables
% %
% % x=0;                % Input data array
% %                     % There is no default value
% %
% % confidence=0.95;    % condidence interval should be between 0 and 1.
% %                     % if confidence < 0.5 the confidence interval is
% %                     % negative.  
% %                     % if confidence > 0.5 the confidence interval is
% %                     % positive.  
% %
% % dim=1;              % dimension along which to calculate the confidence
% %                     % interval.  default is the first dimension which
% %                     % has a length greater than 1.   
% % 
% % num_tails=2;        % The number of tails in the confidence interval.
% %                     % 
% %                     % The default is num_tails=2; (two tails)
% % 
% % flag=0;             % The std deviation can be calculated with n-1
% %                     % degrees of freedom or with n degrees of freedom.
% %                     % 
% %                     % flag=0; calculates the std deviation with n-1
% %                     % degrees of freedom.  
% %                     % 
% %                     % flag=1; calculates the std deviation with n
% %                     % degrees of freedom.  
% %                     % 
% %                     % The default is flag=0; which caculates the std 
% %                     % using n-1 degrees of freedom.  
% %
% % ***********************************************************
% %
% % Output Variables
% %
% % interval is the confidence interval of the standard error calculated 
% %        along a dimension dim.
% % 
% % error=[]; or error=0; No error
% % otherwise  There is an error check the error code
% %      'Bad x-input in t_confidence_interval Return interval=0'
% % 
% % ***********************************************************
% %
% 
% Example='1';
% % 
% % The output along the first dimension has a length of 1.
% x=randn(10, 100);
% confidence=0.95;
% dim=1;
% num_tails=2;
% flag=0;
% 
% (interval, error)=t_confidence_interval(x, confidence, dim, num_tails, flag);
% 
% 
% Example='2';
% 
% % The output along the first dimension has a length of 1.
% x=randn(1, 100);
% dim=[];
% 
% (interval, error)=t_confidence_interval(x, confidence, dim, num_tails,flag);
% 
% 
% Example='3';
% 
% % The output along the first dimension has a length of 100.
% x=randn(100, 1);
% 
% (interval, error)=t_confidence_interval(x, confidence, dim, num_tails,flag);
% 
% 
% Example='4';
% 
% % The output is zeros of size(x); because dim is greater th an the number
% % of dimensions in x.  
% x=randn(10, 100);
% dim=3;
% 
% (interval, error)=t_confidence_interval(x, confidence, dim, num_tails,flag);
% 
% 
% Example='5';
% 
% % The output is zeros of size(x); because dim is less than 1.    
% x=randn(10, 100);
% dim=0;
%
% (interval, error)=t_confidence_interval(x, confidence, dim, num_tails, flag);
% 
% 
% Example='6';
% 
% % The output of a one tailed confidence interval.    
% x=randn(10, 100);
% dim=0;
% num_tails=1;
% 
% (interval1, error)=t_confidence_interval(x, confidence, dim, num_tails, flag);
% 
% num_tails=2;
% (interval2, error)=t_confidence_interval(x, confidence, dim, num_tails, flag);
% 
% 
% % ***********************************************************
% %
% % 
% % List of Dependent Subprograms for 
% % t_confidence_interval
% % 
% % FEX ID# is the File ID on the Matlab Central File Exchange
% % 
% % Program Name   Author   FEX ID#
% % 1) genHyper		Ben Barrowes		6218	
% % 2) t_alpha		
% % 3) t_icpbf	
% % 
% % 
% % ***********************************************************
% %
% % t_confidence_interval is written by Edward L. Zechmann
% %
% %      date 6 September 2008 
% %
% % modified 7 September 2008  Updated Comments
% %
% % ***********************************************************
% %
% % Please feel free to modify this code.
% %
% % See Also: t_icpbf, std
% %

flag2=0;
error=[];

if (nargin < 1 || isempty(x)) || ~isnumeric(x)
    warning('Bad x-input in t_confidence_interval Return interval=0');
    interval=0;
    error=[error 1];
    flag2=1;
elseif logical(length(x) < 2)
    interval=0;
    error=[error 1];
    flag2=1;
end

if (nargin < 2 || isempty(confidence)) || ~isnumeric(confidence)
    confidence=0.95;
end

if confidence < 0 || confidence > 1
    warning('Bad confidence-input in t_confidence_interval: Using default value confidence=0.95');
    confidence=0.95;
    error=[error 2];
end

if (nargin < 4 || isempty(num_tails)) || ~isnumeric(num_tails) 
    num_tails=2;
end

num_tails=round(num_tails);
if num_tails > 2
    warning('Bad num_tails-input in t_confidence_interval: Value too high Using num_tails=2');
    num_tails=2;
    error=[error 3];
end

if num_tails < 1
    warning('Bad num_tails-input in t_confidence_interval: Value too low Using num_tails=1');
    num_tails=1;
    error=[error 4];
end

if (nargin < 5 || isempty(flag)) || ~isnumeric(flag)
    flag=0;
end

if ~isequal(flag, 0)
    flag=1;
end


if flag2==0

    num_dims = ndims(x);
    flag3=0;

    if (nargin < 3 || isempty(dim)) 
        dim = find(size(x) > 1, 1 );
        % must return an array of zeros
        if isempty(dim)
            error=[error 5];
            flag3=1;
        end
    elseif  ~isnumeric(dim)
        error=[error 6];
        warning('Bad x-input in t_confidence_interval: dim is not numeric: Return 0');
        flag3=1;
    elseif (logical(dim > num_dims) || logical(dim < 1)) || size(x,dim) < 2
        flag3=1;
    end
    
    
    if flag3==0

        n=size(x,dim);
        sd=std(x,flag,dim);
        sem=sd./sqrt(n);

        alpha=1-((1-confidence)/num_tails);
        nu=n-1;

        [t_out, T_out, error1_out, error2_out, count_out]=t_icpbf(alpha, nu);
        
        if error2_out > abs(t_out)
            error=[error 7];
            warning('Error estimate of t-statistic greater than the t-statistic: Using t-statistic');
        end
        
        interval=t_out.*sem;
        
    else

        interval=zeros(size(x));
        
    end

end



