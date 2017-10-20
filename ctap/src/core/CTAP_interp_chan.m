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

%check if urchanlocs exists, use as chanlocs struct
if isfield( EEG, 'urchanlocs' )
    eeg_chan_match = ismember({EEG.urchanlocs.type}, {'EEG','EOG','REF'});
    Arg.channels = EEG.urchanlocs(eeg_chan_match);
    
elseif isfield(EEG.CTAP, 'badchans')
    if isfield(EEG.CTAP.badchans, 'detect')
        Arg.channels = get_eeg_inds(EEG, EEG.CTAP.badchans.detect.chans);

    else %find results of all detection methods used
        fns = fieldnames(EEG.CTAP.badchans);
        for i = 1:numel(fns)
            Arg.channels = union(Arg.channels...
                , get_eeg_inds(EEG, EEG.CTAP.badchans.(fns{i}).chans));
        end
    end
end

% Override defaults with user parameters
if isfield(Cfg.ctap, 'interp_chan')
    Arg = joinstruct(Arg, Cfg.ctap.interp_chan);
end

if isempty(Arg.channels)
   error('ctapeeg_interp_chan:urchanlocsNotFound',...
       'Lack of channel information, cannot interpolate.');
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
chans_interpolated = setdiff({EEG.chanlocs.labels},...
                             chans_before_interpolation);

EEG = pop_chanedit(EEG, 'settype', {get_eeg_inds(EEG, chans_interpolated) 'EEG'});


%% ERROR/REPORT
Cfg.ctap.interp_chan = Arg;

msg = myReport({'Interpolated channels -' chans_interpolated 'by' Arg.method}...
    , Cfg.env.logFile );

EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);
