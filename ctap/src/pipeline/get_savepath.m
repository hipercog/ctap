function savedir = get_savepath(Cfg, funcname, infoname)
%GET_SAVEPATH - A central place defining a savepath for a CTAP_X() function
%
% Syntax:
%   savedir = get_savepath(Cfg, funcname);
%
% Inputs:
%   'Cfg'       struct, pipe configuration structure, see documentation
%   'funcname'  string, name of function saving out quality control figure
%
%
% Outputs:
%   'savedir'   string, full path to saving location
%
%
% Copyright(c) 2015 FIOH:
% Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%TODO (feature-request): Add functionality to clean up the existing savedir,
% to avoid having data from multiple runs in the same folder.
% This would have to be chosen explicitly by the user, and done on a
% per-subject, per-file basis (not for whole QC folder returned by this
% function)

    if nargin < 3
        infoname = '';
    else
        infoname = ['-' infoname];
    end
    
    savedir = fullfile(Cfg.env.paths.qualityControlRoot,...
                        funcname,...
                        sprintf('set%d_fun%d%s',...
                                Cfg.pipe.current.set,...
                                Cfg.pipe.current.funAtSet,...
                                infoname));
    if ~isdir(savedir), mkdir(savedir); end
end
