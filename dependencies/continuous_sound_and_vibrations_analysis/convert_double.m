function [varargout]=convert_double(varargin)
% % This program converts the inputs into double precision arrays.  Then
% % outputs them. An indefinite number of inputs and outputs can be used.   
% % 
% Example;
% a=single([1 2]);          % a is single precision vector    
% [b]=convert_double(a);    % varargin will have one input variable 'a'
%                           % varargout will have one output variable 'b'
% %
% % 
% % 
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %
% % Program Written by Edward L. Zechmann 
% %                date  Not certain 2007
% %            modified 19 December 2007
% %                     added comments and an example
% %                     
% %  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % 
% % Please feel free to modify this code.
% % 

for e1=1:nargin;

    ttype=class(varargin{e1});
    
    if ~isequal(ttype, 'double')
        varargout{e1}=double(varargin{e1});
    else
        varargout{e1}=varargin{e1};
    end
    
end
