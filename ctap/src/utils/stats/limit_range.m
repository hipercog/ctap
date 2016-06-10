function outmat = limit_range(inmat, varargin)
% Limit value range of the _columns_ of the input matrix.
% Needed e.g. in feeding data to DBNs or other neural nets.
% Current version is work-in-progress. 
%
% Input
%   inmat   [n, m] numeric, Input data matrix, range limited for each column
%                         m separately
%
% Output
%   outmat  [n,m] numeric, Output data matrix, range limited per column

%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('inmat', @isnumeric); 
p.addParamValue('sigma', 2, @isnumeric);
p.addParamValue('appendScaling', false, @islogical);

p.parse(inmat, varargin{:});
Arg = p.Results;

%% Code
if Arg.appendScaling
    outmat = NaN(size(inmat,1)+1, size(inmat,2));
else
    outmat = NaN(size(inmat));
end

for i=1:size(inmat,2)
    outmat(:,i) = limit_range_vec(inmat(:,i));
end

%% Subfunctions
    function outvec = limit_range_vec(invec)
        outvec = invec-mean(invec);
        sc = std(outvec);
        outvec = outvec/sc;
        
        match = outvec < -Arg.sigma;
        outvec(match) = -Arg.sigma;
        match = Arg.sigma < outvec;
        outvec(match) = Arg.sigma;
        
        outvec = (outvec + Arg.sigma)/(2*Arg.sigma);
        
        if Arg.appendScaling
            outvec =  [outvec; sc];
        end
    end
end