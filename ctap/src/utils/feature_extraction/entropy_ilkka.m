function H = entropy_ilkka(P,s_length)
% ENTROPY_ILKKA - Spectral entropy as GE Healthcare Finland defines it
%
%   H = entropy_ilkka(P, s_length)
%
%	Computes normalised spectral entropy for power spectral density
%
%   in:	P	        PSD
%       s_length    Length of spectrum
%
%  out:	H	        spectral entropy

%	(c) Ilkka Korhonen 03.02.2000
%   modified by Mika Särkelä 14th-Oct-2002

if nargin < 2
    s_length = length(P);
end

P(:) = abs(P);
p = P/sum(P);
H = sum((p).*log(1./p))/log(s_length);