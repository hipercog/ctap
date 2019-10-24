function [EEG, varargout] = ctapeeg_export(EEG, varargin)
%CTAPEEG_EXPORT export EEGLAB-format data as some given type on disk
%
% Description:
%
% SYNTAX
%   [EEG, varargout] = ctapeeg_export(EEG, varargin)
%
% INPUT
%   'EEG'           eeglab data struct
%
% VARARGIN
%   'outdir'        string, output directory
%   'name'          string, name of file
%   'type'          string, file type to save as:
%                   - 'set', 'gdf','edf','bdf','cfwb','cnt', 'leda'
%                   Default = set
%   'evflds'        cell, names of EEG event structure fields to export
%                   Default = {}
%
% Outputs:
%   'EEG'           same eeglab data struct
% VARARGOUT
%   {1}         : struct, the complete list of arguments actually used
%   {2}         : boolean, true if file exists after writing
%
% Assumptions:
%
% References:
%
% Example:
%
% Notes:
%
% See also: pop_saveset, pop_writebva, pop_writeeeg, eeglab2leda
%
% Version History:
% 20.10.2014 Created (Benjamin Cowley, FIOH)
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


sbf_check_input() % parse the varargin, set defaults

if ~isfolder(Arg.outdir), mkdir(Arg.outdir); end


%% ...operation
switch Arg.type
    case 'set'
        savename = fullfile(Arg.outdir, [Arg.name '.set']);
        pop_saveset(EEG, 'filename', [Arg.name '.set'], 'filepath', Arg.outdir);
        
    case 'bva'
        savename = fullfile(Arg.outdir, Arg.name);
        pop_writebva(EEG, savename);
        
    case {'gdf','edf','bdf','cfwb','cnt'}
        savename = fullfile(Arg.outdir, [Arg.name '.' Arg.type]);
        eeglab2edf(EEG, savename, 'evnames', Arg.evflds)
        
    case 'leda'
        leda = eeglab2leda(EEG, 'evnames', Arg.evflds);
        savename = fullfile(Arg.outdir, [Arg.name '.mat']);
        save(savename, 'leda');
end

varargout{1} = Arg;
if exist(savename, 'file')
    success = true;
else
    success = false;
end
varargout{2} = success;


%% Sub-functions
    function sbf_check_input() % parse the varargin, set defaults
        % Unpack and store varargin
        if isempty(varargin)
            vargs = struct;
        elseif numel(varargin) > 1 %(assume parameter/name pairs)
            vargs = cell2struct(varargin(2:2:end), varargin(1:2:end), 2);
        else
            vargs = varargin{1}; %(assume a struct wrapped in a cell)
        end

        % If desired, the default values can be changed here:
        Arg.type = 'set';
        Arg.name = EEG.setname;
        Arg.outdir = pwd;
        Arg.evflds = {};

        % Arg fields are canonical, vargs data is canonical: intersect-join
        Arg = intersect_struct(Arg, vargs);
    end

end % ctapeeg_export()
