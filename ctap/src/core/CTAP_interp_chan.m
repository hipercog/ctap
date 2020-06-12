function [EEG, Cfg] = CTAP_interp_chan(EEG, Cfg)
%CTAP_interp_chan - Interpolate given OR inferred channels
%
% Description:
%   Calls eeg_interp(), which can accept either bad channel indices, or
%   find the missing channels from the difference between current channels
%   and a passed chanlocs structure. 
%
% Syntax:
%   [EEG, Cfg] = CTAP_interp_chan(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.interp_chan:
%   .method     string, Method to use, see eeg_interp() for details,
%               default: spherical
%   .select     string, how to select channels to interpolate, can be:
%               'given' exactly as given in 'channels' argument
%               'missing' check current channels against originals
%               'bad' use the record of detected bad channels in EEG.CTAP
%               default = 'missing'
%   .miss_types cellstring, channel types to find in urchanlocs if select = 
%               'missing', default = {'EEG','EOG','REF'}
%   .channels   struct OR cell string array OR vector, chanlocs structure OR 
%               names OR indices of channels to interpolate
%               default: if present, CTAP_interp_chan uses original chanlocs 
%               structure given by CTAP_load_chanlocs or CTAP_tidy_chanlocs. 
%               Else: if present, names in 'EEG.CTAP.badchans.detect.chans'
%               Else: if present, names in 'EEG.CTAP.badchans.(any method).chans'
%               Else: error is thrown.
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%
% See also:  eeg_interp
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set optional arguments
Arg.method = 'spherical';
Arg.channels = [];
Arg.select = 'missing';
Arg.missing_types = {'EEG','EOG','REF'};

% Override defaults with user parameters
if isfield(Cfg.ctap, 'interp_chan')
    Arg = joinstruct(Arg, Cfg.ctap.interp_chan);
end

%check if urchanlocs exists, use as chanlocs struct
if strcmp(Arg.select, 'given')
    if ~isempty(Arg.channels) && iscellstr(Arg.channels)
        Arg.channels = get_eeg_inds(EEG, Arg.channels);
    end
    
elseif strcmp(Arg.select, 'missing')
    if isfield(EEG, 'urchanlocs')
        eeg_chan_match = ismember({EEG.urchanlocs.type}, Arg.missing_types);
        Arg.channels = EEG.urchanlocs(eeg_chan_match);
    end
    
elseif strcmp(Arg.select, 'bad') && isfield(EEG.CTAP, 'badchans')
    if isfield(EEG.CTAP.badchans, 'detect')%detected bad channels not rejected
        Arg.channels = get_eeg_inds(EEG, EEG.CTAP.badchans.detect.chans);

    else%detected bad channels rejected - interpolate against missing channels
        fns = fieldnames(EEG.CTAP.badchans);
        chs = [];
        for i = 1:numel(fns)
            chs = union(chs, find(ismember(...
                {EEG.urchanlocs.labels}, EEG.CTAP.badchans.(fns{i}).chans)));
        end
        if isfield(EEG, 'urchanlocs')
            ix = ismember({EEG.urchanlocs.type}, unique({EEG.urchanlocs(chs).type}));
            Arg.channels = EEG.urchanlocs(ix);
        end
        
    end
end

if isempty(Arg.channels)
   warning('ctapeeg_interp_chan:reqdInterpChansNotFound',...
       'Lack of channel information, cannot interpolate.')
   return
end


%% ASSIST
chans_before_interpolation = {EEG.chanlocs.labels};


%% CORE
%interpolate channels
if ~isfield( EEG.chanlocs, 'sph_theta_besa' )
    EEG.chanlocs = convertlocs( EEG.chanlocs, 'cart2sphbesa' );
end
EEG = eeg_interp( EEG, Arg.channels, Arg.method );

%get labels of interpolated channels for reporting
chs_intrpd = setdiff({EEG.chanlocs.labels}, chans_before_interpolation);

if ~isempty(chs_intrpd)
    EEG = pop_chanedit(EEG, 'settype', {get_eeg_inds(EEG, chs_intrpd) 'EEG'});
end


%% ERROR/REPORT
Cfg.ctap.interp_chan = Arg;

msg = myReport({'Interpolated channels -' chs_intrpd 'by' Arg.method}...
    , Cfg.env.logFile );

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);
