function [epmap, rownm, colnm] = electrodeProximity( EEG )
%ELECTRODEPROXIMITY calculates Euclidean distance between all pairs of given
% electrodes
%
% Description:  
%       The function disregards "non-EEG" channels. These are taken as specified
%       in the channel location structure/file (anything not labeled EEG or 
%       "empty" is considered non-EEG). It is highly recommended that you define
%       channel type for each channel, when defining your channel location file
%
% Syntax:
%       [epmap, rownm, colnm] = electrodeProximity( EEG )
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   
% Outputs:
%   epmap       matrix, [EEG.nbchan EEG.nbchan] square distance matrix
%   rownm       cell string array, row names for epmap
%   colnm       cell string array, column names for epmap
%
% Assumptions:
%   Assumes that the EEG.chanlocs structure has .X .Y .Z fields, and that
%   these contain a sensible set of locations of the electrodes on the scalp
%
%
% See also:  eucl_dist
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



eegChan = strcmp('EEG', {EEG.chanlocs.type}) | strcmp('', {EEG.chanlocs.type});
eegchs = sum(eegChan);
epmap = zeros(eegchs);
rownm = cell(eegchs,1);
colnm = cell(1,eegchs);

for i = 1:eegchs
    rownm{i} = EEG.chanlocs(i).labels;
    for k = 1:eegchs
        A = [EEG.chanlocs(i).X; EEG.chanlocs(i).Y; EEG.chanlocs(i).Z];
        B = [EEG.chanlocs(k).X; EEG.chanlocs(k).Y; EEG.chanlocs(k).Z];

        epmap(i,k) = eucl_dist(A, B);

        if i == 1,	colnm{k} = EEG.chanlocs(k).labels;	end
    end
end

function d = eucl_dist(a,b)
%EUCL_DIST computes Euclidean distance between two vectors by:
%    ||A-B|| = sqrt ( ||A||^2 + ||B||^2 - 2*A.B )
    aa=sum(a.*a,1);
    bb=sum(b.*b,1);
    ab=a'*b; 
    d = sqrt(abs(repmat(aa',[1 size(bb,2)]) + repmat(bb,[size(aa,2) 1]) - 2*ab));

end %electrodeProximity()
