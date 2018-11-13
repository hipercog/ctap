function chaninds = get_refchan_inds(EEG, reference)
%GET_REFCHAN_INDS - Return reference channel indices based on specification
%
% Input:
%   EEG         struct, EEG struct
%   reference   [1,m] cell of strings, Reference specification, can be:
%               'asis', use channels in EEG.ref, if present; else average
%               'average'/'common'/'EEG', use all EEG channels
%               'REF', use channels with EEG.chanlocs.type == REF
%               otherwise, use channel(s) given by label names, or 
%               canonical names from this list (defined by 10/20 name):
%                 'occipital' = Oz
%                 'parietal' = Pz
%                 'vertex' = Cz
%                 'frontal' = Fz, Fp1, Fp2
%                 'frontopolar' = Fpz
%                 'midleft' = C3
%                 'midright' = C4
%                 'frontleft' = F3
%                 'frontright' = F4
%                 'backleft' = P3
%                 'backright' = P4
%                 'farleft' = T7
%                 'farright' = T8
%
% Output:
%   chaninds    [1,p] integer, Indices of channels to refer to. To be
%               passed on to CTAP_reref_data.m.
%
% See also:     CTAP_reref_data, ctap_eeg_blink_ERP, canonical_eloc
%   
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

reference = cellstr(reference); %make cell array of strings
% chaninds = []; %make empty output


%% Define channel indices
if length(reference) == 1 %only one string -> maybe something special
    switch reference{1}
        case 'asis'
            if isfield(EEG, 'ref')
                chaninds = find(ismember({EEG.chanlocs.type}, EEG.ref));
                if isempty(chaninds)
                    chaninds = find(ismember({EEG.chanlocs.labels}, EEG.ref));
                end
                if isempty(chaninds), chaninds = EEG.ref; end
            else
                chaninds = 'average';
            end
            if ~isnumeric(chaninds)
                chaninds = get_refchan_inds(EEG, chaninds);
            end
            
        case {'average' 'common' 'EEG'}
            %if EEG.chanlocs.type is missing, this should anyway give the 
            %default empty vector that pop_reref() uses to signal average reref
            chaninds = find(ismember({EEG.chanlocs.type}, 'EEG'));

        case 'REF'
            chaninds = find(ismember({EEG.chanlocs.type}, 'REF'));
            
        otherwise %assume a canonical or actual channel name
            
            %Try to find channel by canonical name
            chaninds = canonical_eloc(EEG.chanlocs, reference{1});
            %...if that failed (returned empty), try just matching to label
            if isempty(chaninds)
                chaninds = find(ismember({EEG.chanlocs.labels}, reference{1}));
            end
    end
   
else
    %many strings -> channel names
    chaninds = find(ismember({EEG.chanlocs.labels}, reference));
end


%% Make sure something is found
if isempty(chaninds)
    warning('get_refchan_inds:channelsNotFound',...
       'Reference channels ''%s'' not found.', strjoin(reference,', ')); 
end


end
