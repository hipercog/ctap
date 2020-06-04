function [EEG, varargout] = ctapeeg_load_data(filename, varargin )
%CTAPEEG_LOAD_DATA load a eeg single file as an EEGLAB struct 
%
% SYNTAX
%   [EEG, varargout] = ctapeeg_load_data(filename, varargin)
% 
% INPUT
%   'filename'	name of file to process
% 
% VARARGIN
%   'type'      optional parameter to overload the filename, e.g. if
%               loading neurOne data, 'filename' should be root path of the 
%               recording, 'type' should be 'neurone'
%
% OUTPUT
%   'EEG'       : struct, EEGLAB structure corresponding to given file
% VARARGOUT
%   {1}         : struct, the complete list of arguments actually used
%   {2}         : struct, file description, includes fields from <help dir> and:
%                 - load, boolean, is file loadable
%                 - ext, string, file extension
%                 - others depending on file type
%
%
% USAGE:    Call with 'filename' as a file to get an EEG struct;
%           Call with 'type' as (overloads filename extension):
%               'set': load an existing study to further preprocess. OR
%               'bdf': load a biosemi 128 file; or
%               'edf': load a european data format file; or
%               'gdf': load a CENT NFB Enobio 4/8 channel file; or
%               'vhdr':load a BrainProducts file; or
%               'eeg': load a Neuroscan .eeg file; or
%               'vpd': load a Varioport 6 channel file; or
%               'neurone': load a neurOne recording from .xml & .bin files
%               'txt': load ascii file, meta-data specified via free arguments
%               'mat': load matlab file, meta-data specified via free arguments
%               'raw': load EGI format file using pop_readegi()
% 
%               WIP - importers for Enobio native txt format, BESA, etc.
% 
%           Even if filename has no extension, file_loadable() will
%           still check all supported EEG formats against given filename.
%
% See also:
%           ImportVPD, vpd2eeglab,
%           read_data_gen, recording_neurone_to_eeglab, pop_loadset,
%           pop_biosig, pop_loadbv, pop_loadeeg
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


Arg = sbf_check_input(); % parse the varargin, set defaults

% Check format and file existence
file = file_loadable(filename, ctap_supported_eeg_types());
if ~file.load
    error('ctapeeg_load_data:bad_file',...
        'File does not exist or cannot be loaded')
elseif file.load == 2
    warning('ctapeeg_load_data:bad_extension',...
        'File extension not recognised; might not be possible to load!')
end
if isfield(Arg, 'type') && ~isempty(Arg.type)
    file.ext = Arg.type;
    Arg = rmfield(Arg, 'type');
end

file.ext = lower(strrep(file.ext, '.', ''));
EEG = eeg_emptyset();
res = struct;
res.file = file;


%% Get requested file
switch file.ext
    case 'set'
        EEG = pop_loadset('filename', file.name, 'filepath', file.path);
            
    case {'bdf' 'gdf' 'edf'}
        if Arg.biosig && ~isempty(which('pop_biosig')) 
%             && any(cellfun(@(x) contains(x, [filesep 'biosig']), regexp(path,pathsep,'Split')))
            EEG = pop_biosig(fullfile(file.path, file.name));
        else
%TODO - GDF AND EDF MIGHT NOT BE READABLE USING ctap_readbdf()
            EEG = ctap_readbdf(fullfile(file.path, file.name));
        end
            
    case 'vhdr'
        EEG = pop_loadbv(file.path, file.name);
            
    case 'eeg'
        EEG = loadeeg(fullfile(file.path, file.name));
            
    case 'vpd'
        vpd = ImportVPD(fullfile(file.path, file.name));
        [EEG, file.date] = vpd2eeglab(vpd);
            
    case {'neurone' 'xml'}
        if ~isfield(Arg, 'neurone_version') || strcmpi(Arg.neurone_version, 'old')
            % Loads whole datafile, all events from all tasks - BWRC utils!
            neur1 = read_data_gen(file.path);
            EEG = recording_neurone_to_eeglab(neur1); %old NeurOne-approved syntax
    %         EEG = recording2eeglab(neur1); %even older syntax
            % return meta-data and timing for this recording 
            res.meta = struct;
            res.meta.device = neur1.device;
            res.meta.properties = neur1.properties;
            res.meta.identifier = neur1.identifier;
            res.time = {datetime(datestr(datenum(...
                neur1.properties.start.time,'yyyymmddTHHMMSS')))};
        
        else
            % TODO (BC): THIS OFFICIAL MEGAELECTRONICS readneurone() function calls
            % pop_chanedit() and results in a pop-up which prevents batching
            EEG = readneurone(fullfile(file.path,'/'));
        end
        
    case {'mat' 'txt'}
        tmp = [fieldnames(Arg) struct2cell(Arg)];
        df = {'matlab' 'ascii'; 'mat' 'txt'};
        EEG = pop_importdata('data', fullfile(file.path, file.name)...
            , 'dataformat', df(1, strcmp(df(2, :), file.ext)), tmp{:});
        
    case 'raw'
        EEG = pop_readegi(fullfile(file.path, file.name), [], [], '');
        
end

varargout{1} = Arg;
varargout{2} = res;


%% Sub-functions
    function Arg = sbf_check_input() % parse the varargin, set defaults
        % Unpack and store varargin
        if isempty(varargin)
            vargs = struct;
        elseif numel(varargin) > 1 %(assume parameter/name pairs)
            vargs = cell2struct(varargin(2:2:end), varargin(1:2:end), 2);
        else
            vargs = varargin{1}; %(assume a struct wrapped in a cell)
        end

        % If desired, the default values can be changed here:
        Arg = struct('biosig', false);

        % No Arg fields defined; vargs is canonical: join structs
        Arg = joinstruct(Arg, vargs);
    end

end % ctapeeg_load_data()
