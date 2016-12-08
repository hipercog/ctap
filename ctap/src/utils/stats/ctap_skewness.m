function sk = ctap_skewness(d1, varargin)
%CTAP_SKEWNESS calculate skewness for a numeric vector.
% 
% Description: equivalent to:
% skewns = @(x) (sum((x - mean(x)) .^ 3) ./ length(x)) ./ (var(x,1).^1.5);
%
% With thanks to commenters on this page:
% https://se.mathworks.com/matlabcentral/answers/174236-how-to-calculate-skewness-kurtosis
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser;
p.addRequired('data', @isvector);

p.addParameter('bias', 0, @islogical);

p.parse(d1, varargin{:});
Arg = p.Results;

%clear out the NaNs
d1(isnan(d1)) = [];
% Get the data length.
dL = length(d1);
% Get the data mean.
dM = mean(d1);
%super clear skewness calculation
numerator = sum((d1 - dM) .^ 3) ./ dL;
denominator = var(d1, 1) .^ 1.5;
sk = numerator ./ denominator;

% adjust sk for bias
if Arg.bias && dL > 2
    sk = (sqrt(dL * (dL - 1)) / (dL - 2)) * sk;
end
