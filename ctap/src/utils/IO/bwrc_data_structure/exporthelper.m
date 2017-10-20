function exporthelper(inputdir, outputdir)
%EXPORTHELPER : Export data from Matlab to csv-format using dataexport_append.
%
% Description:
%   Export data from structures in mat-files to a csv-file in long format.
%
% Syntax:
%
%   exporthelper(inputdir, outputdir)
%
% Inputs:
%
%   inputdir  : Input directory of .mat-files in "ATTK-data structure"
%               format.
%   outputdir : Output directory of created CSV-file. Use trailing slash.
%
% Outputs:
%               CSV-file in directory specifed by outputdir named as
%               export_<yyyymmdd>_long.csv.
%
% Example: exporthelper('c:\data\', 'd:\exported_data\')
%
% See also: dataexport_append
%
% Author: Andreas Henelius 2009

% If only one input argument is given (nargin),
% then assume we want the output directory to
% be the same as the input directory.

if nargin < 2
    outputdir = inputdir;
end

% Make sure that both inputdir and outputdir paths
% properly terminate with a / or \ (filesep).
if ~strcmpi(inputdir(end), filesep)
    inputdir = [inputdir filesep];
end

if ~strcmpi(inputdir(end), filesep)
    inputdir = [inputdir filesep];
end


W = what(inputdir);

for i=1:length(W.mat)
   W.mat{i} = [W.path filesep W.mat{i}];
end

[data, labels, n_factors]   = dataexport_append(W.mat,[outputdir 'export_' datestr(now,'yyyymmdd') '_long.csv'],[], 'outputFormat','long');
% [data, labels, n_factors] = dataexport_append(W.mat,[outputdir 'export_' datestr(now,'yyyymmdd') '_wide.csv'],[],'outputFormat','wide');

end
