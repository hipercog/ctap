function inmat = scale(inmat, varargin)

%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('inmat', @isnumeric);
p.addParamValue('center', true, @islogical);
p.addParamValue('scale', true, @islogical);

p.parse(inmat, varargin{:});
Arg = p.Results;

%% Center columns
if Arg.center
    meanArr = mean(inmat, 1);
    meanMat = repmat(meanArr, size(inmat, 1), 1);
    inmat = inmat - meanMat;
end

%% Scale columns
if Arg.scale
    sdArr = std(inmat, 0, 1);
    sdMat = repmat(sdArr, size(inmat, 1), 1);
    inmat = inmat ./ sdMat;
end