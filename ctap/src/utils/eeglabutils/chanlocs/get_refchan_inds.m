function chaninds = get_refchan_inds(EEG, reference)
%GET_REFCHAN_INDS - Return reference channel indices based on specification
%
% Input:
%   EEG         struct, EEG struct
%   reference   [1,m] cell of strings, Reference specification, can be:
%               'asis', use channels in EEG.ref, if present; else average
%               'average'/'common'/'EEG', use all EEG channels
%               'REF', use channels with EEG.chanlocs.type == REF
%               otherwise, use channel(s) given by label names, or canonical
%               names from these Biosemi 128, or 10/20 lists:
%                 occipital = 'A23', or 'Oz'
%                 parietal = 'A19', or 'Pz'
%                 vertex = 'A1', or 'Cz'
%                 frontal = 'C21', or 'Fz', 'Fp1', 'Fp2'
%                 frontopolar = 'C17', or 'Fpz'
%                 midleft = 'D19', or 'C3'
%                 midright = 'B22', or 'C4'
%                 farleft = 'D23', or 'T7'
%                 farright = 'B26', or 'T8'
%
% Output:
%   chaninds    [1,p] integer, Indices of channels to refer to. To be
%               passed on to CTAP_reref_data.m.
%
% See also:
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


%% Define channel indices
% chaninds = [];
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
            
            %Definitions of channel names for canonical channels, with
            %matching location, from different naming schemes.
            %Currently supported: {Biosemi 128, 10/20}
            locs.occipital = {'A23' 'Oz'};
            locs.parietal = {'A19' 'Pz'};
            locs.vertex = {'A1' 'Cz'};
            locs.frontal = {'C21' 'Fz', 'Fp1', 'Fp2'};
            locs.frontopolar = {'C17' 'Fpz'};
            locs.midleft = {'D19' 'C3'};
            locs.midright = {'B22' 'C4'};
            locs.farleft = {'D23' 'T7'};
            locs.farright = {'B26' 'T8'};
            
            if ismember(reference{1}, fieldnames(locs))
                chaninds = find(ismember({EEG.chanlocs.labels}...
                    , locs.(reference{1})));
            else
                chaninds = find(ismember({EEG.chanlocs.labels}, reference{1}));
            end
    end
   
else
    %many strings -> channel names
    chaninds = find(ismember({EEG.chanlocs.labels}, reference));
end


%% Make sure something is found
% MAYBEDO (BEN) - WHAT IF NAMED CHANNELS DON'T EXIST? USE GEOMETRY TO FIND, E.G.
% VERTEX? ALL CENTRE-LINE CHANNELS (PICK 3-5 EQUI-SPACED ONES)?
if isempty(chaninds)
    warning('get_refchan_inds:channelsNotFound',...
       'Reference channels ''%s'' not found.', strjoin(reference,', ')); 
end


end
