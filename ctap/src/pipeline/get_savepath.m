function savedir = get_savepath(Cfg, funcname, type, varargin)
%GET_SAVEPATH - A central place defining a savepath for a CTAP_X() function
%
% Syntax:
%   savedir = get_savepath(Cfg, funcname, type, varargin);
%
% Inputs:
%   'Cfg'       struct, Pipe configuration structure, see documentation
%   'funcname'  string, Name of function saving out quality control figure
%   'type'      string, The kind of savepath to be produced,
%               allowed values {'qc','fig','data'} each corresponding to a
%               different sub-directory
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

    p = inputParser;
    p.addRequired('Cfg', @isstruct);
    p.addRequired('funcname', @ischar);
    p.addRequired('type', @ischar);

    p.addParameter('suffix', '', @isstr); %appended to path end
    p.addParameter('createDir', true, @islogical); %create directory?

    p.parse(Cfg, funcname, type, varargin{:});
    Arg = p.Results;


    if ~isempty(Arg.suffix)
        Arg.suffix = ['-' Arg.suffix];
    end
    
    switch type
        case 'qc'
            savedir = fullfile(Cfg.env.paths.qualityControlRoot,...
                        funcname,...
                        sprintf('set%d_fun%d%s',...
                                Cfg.pipe.current.set,...
                                Cfg.pipe.current.funAtSet,...
                                Arg.suffix));
        case 'fig'
            savedir = fullfile(Cfg.env.paths.analysisRoot,...
                        'figures',...
                        funcname,...
                        sprintf('set%d_fun%d%s',...
                                Cfg.pipe.current.set,...
                                Cfg.pipe.current.funAtSet,...
                                Arg.suffix));
            
        case 'features'
            savedir = fullfile(Cfg.env.paths.featuresRoot,...
                        funcname,...
                        sprintf('set%d_fun%d%s',...
                                Cfg.pipe.current.set,...
                                Cfg.pipe.current.funAtSet,...
                                Arg.suffix));
                            
        case 'data'
            savedir = fullfile(Cfg.env.paths.exportRoot,...
                        funcname,...
                        sprintf('set%d_fun%d%s',...
                                Cfg.pipe.current.set,...
                                Cfg.pipe.current.funAtSet,...
                                Arg.suffix));
            
        otherwise
            error('get_savepath:inputError', ...
                sprintf('Unknown value ''%s'' for input ''type''. Allowed values are {qc, fig, data}.', type));
            
    end
    
    if Arg.createDir
        if ~isdir(savedir), mkdir(savedir); end
    end
    
end
