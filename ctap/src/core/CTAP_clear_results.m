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
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.load_chanlocs:
%
% Outputs: None
%
%
% Copyright(c) 2017 FIOH:
% Jan Brogger (jan@brogger.no)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    root = dir(Cfg.env.paths.analysisRoot);
    for i = 1:length(root)
        if strcmp(root(i).name,'.')==0 && strcmp(root(i).name,'..')==0
            if ~root(i).isdir
                delete(fullfile(root(i).folder, root(i).name));
            else
                files = dir(fullfile(root(i).folder, root(i).name));            
                for j = 1:length(files)
                    if strcmp(files(j).name,'.')==0 && strcmp(files(j).name,'..')==0
                        if ~files(j).isdir
                            delete(fullfile(files(j).folder, files(j).name));
                        else
                            files2 = dir(fullfile(files(j).folder, files(j).name));            
                            for k = 1:length(files2)
                                if strcmp(files2(k).name,'.')==0 && strcmp(files2(k).name,'..')==0
                                    if ~files2(k).isdir
                                        delete(fullfile(files2(k).folder, files2(k).name));
                                    end
                                end
                            end
                        end
                    end
                end        
            end
        end
    end
end    