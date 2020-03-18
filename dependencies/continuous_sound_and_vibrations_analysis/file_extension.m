function [filename_base, ext]=file_extension(filename)
% % file_extension: separates a filename and path from the file extension
% % 
% % Syntax:
% % 
% % [filename_base, ext]=file_extension(filename);
% % 
% % **********************************************************************
% %
% % Description 
% % 
% % This program separates the filename from the extension.  For example a
% % file with the name data_file1.txt.  Has an etension txt and a filename
% % base of data_file1.  
% % 
% % **********************************************************************
% % 
% % Output Variables
% % 
% % filename_base is the part of the filename before the extension 
% % 
% % ext is the filename extension for example 'txt'.
% % 
% % **********************************************************************
% 
% Example='1';
%
% filename='data_file1.txt';
%
% [filename_base, ext]=file_extension(filename);
%
% 
% % **********************************************************************
% %
% % Program Written by Edward L. Zechmann 
% %
% %     date  5 August      2007
% %
% % modified 27 December    2007    Added a description and an example
% %                                 updated comments
% %   
% % modified 10 April       2009    Updated comments
% %
% % **********************************************************************
% % 
% % Please feel free to modify this code.
% % 

if nargin < 1
    filename='';
end

k = strfind(filename, '.');

if ~isempty(k)
    if ~isempty(k(1))
        ext=filename((k(1)+1):end);
        filename_base=filename(1:(k(1)-1));
    else
        ext='';
        filename_base=filename;
    end
else
    ext='';
    filename_base=filename;
end
    
    
    
    