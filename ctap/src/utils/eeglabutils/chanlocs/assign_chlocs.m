function EEGtmp = assign_chlocs(idx, eloc, EEGtmp, writelabel, writeblank)
%ASSIGN_CHLOCS update a channel location with contents of another chlocs struct
%
%
% Usage:
%         EEGtmp = assign_chlocs(idx, eloc, EEGtmp, writelabel);
%
% Input
%	'idx'           index of channel to change
%	'eloc'          new chanlocs structure (singleton) with relevant fields
%   'EEGtmp'        EEG structure to be edited
%   'writelabel'    optional, true|false, overwrite label. Default = false
%   'writeblank'    optional, true|false, if an eloc field is blank, should it 
%                   overwrite the corresponding field? Default = false
%
% Output   
%   'EEGtmp'        EEGLab EEG structure with new channel location added
%
%
%
% See also: set_channel_locations
%
%
% Author: Andreas Henelius 2012 (andreas.henelius@ttl.fi)
% Edit: Ben Cowley 2015 (benjamin.cowley@ttl.fi)
% 
% Copyright(c) 2015 FIOH
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if nargin < 4
        writelabel = false;
    end
    if nargin < 5
        writeblank = false;
    end
    
    fields = fieldnames(eloc);
    if ~writelabel
        fields(strcmpi(fields, 'labels')) = [];
    end

    for j = 1:numel(fields)
        datafield = fields{j};
        if ~writeblank && isempty(eloc.(datafield))
            continue;
        end
        EEGtmp = pop_chanedit(EEGtmp, 'changefield',...
                {idx datafield eloc.(datafield)});
    end
end