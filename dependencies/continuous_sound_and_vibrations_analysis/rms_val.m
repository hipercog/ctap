function [prms]=rms_val(p, dim)
% % rms_val: Calculates the rms value along a specific dimension
% %
% % Syntax:  [prms]=rms_val(p, dim);
% %
% % **********************************************************************
% %
% % Description 
% % 
% % [prms]=rms_val(p, dim);
% % 
% % Returns a matrix prms of root-mean-square values of the input variable 
% % p calcualted along dimension dim.  
% % 
% % If dim is not specified or is empty, then the rms value is calculated
% % along the first non-singleton dimension.  This behavior is consistent
% % with the built-in Matlab sum program.  
% % 
% % **********************************************************************
% % 
% % Input variables
% % 
% % p is the input variable which is used to calculate the rms values.  
% %
% % dim is the dimension to calculate the rms values along.  
% % 
% % **********************************************************************
% 
% 
% Example='1';
%
% % Example using random data from a standard normal distribution
% % whos rms value is one.  
%
% p=randn(10, 1000);
%
% p_rms=rms_val(p, 2);
% 
% % p should return a column vector of length 10 with values nearly 1.  
%  
% 
% Example='2';
%
% % Example using random data from a standard normal distribution
% % whos rms value is one.  
%
% p=rand(10, 1000);
%
% p_rms=rms_val(p, 2);
% 
% % p should return a column vector of length 10 with values 
% % approximately 1/sqrt(3)~0.5774.  
%  
% 
% % **********************************************************************
% %
% % written by Edward L. Zechmann  
% % 
% %      date 11 December   2007
% % 
% % **********************************************************************
% %
% % Please feel free to modify this code.
% % 
% % See also: rms by George Scott Copeland on Matlab Central File Exchange
% % 


if (nargin < 1 || isempty(p)) || ~isnumeric(p)
    p=randn(1, 50000);
end

if (nargin < 2 || isempty(dim)) || ~isnumeric(dim)
    dim=[];
end

dim=round(dim);

num_dims = ndims(p);


if dim > num_dims 
    
    prms=p;
    
elseif dim < 1
    
    prms=0;
    
else
    
    if ~isempty(dim)
        n=sqrt(size(p, dim));
        prms=sqrt(sum(p.^2, dim))./n;
    else
        num=numel(p);
        buf=sqrt(sum(p.^2));
        prms=1./sqrt(num./numel(buf)).*buf;
    end
    
end
