function CTAP_clear_results(Cfg)
%CTAP_clear_results - Clear results
%
% Description:
%   Removes intermediate data, logs, crashlogs, features, etc.
%
% Syntax:
%   CTAP_clear_results(Cfg);
%
% Inputs:
%   Cfg  : CTAP configuration structure, must contain this field:
%   Cfg.env.paths.analysisRoot  : the path to clear results from
%
% Outputs: None
%
% Effect: Deletes all files and folders in analysisRoot and below
%
%
% Copyright(c) 2017 FIOH:
% Jan Brogger (jan@brogger.no)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    deletefilesandfolders(Cfg.env.paths.analysisRoot);    
end    

function deletefilesandfolders(root)
    rootDir = dir(root);
    for i = 1:length(rootDir)
        if strcmp(rootDir(i).name,'.')==0 && strcmp(rootDir(i).name,'..')==0
            if rootDir(i).isdir                                    
                dir2delete = fullfile(rootDir(i).folder, rootDir(i).name);
                deletefilesandfolders(dir2delete);
                try                     
                    rmdir(dir2delete);
                catch
                    warning(['Couldn''t rmdir ' dir2delete]);
                end
            else
                try 
                    file2delete = fullfile(rootDir(i).folder, rootDir(i).name);                    delete(file2delete);
                catch
                    warning(['Couldn''t delete' file2delete]);
                end
            end
        end
    end
end