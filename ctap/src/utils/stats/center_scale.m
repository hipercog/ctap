function inmat = center_scale(inmat, varargin)

%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('inmat', @isnumeric);
p.addParameter('center', true, @islogical);
p.addParameter('scale', true, @islogical);
p.addParameter('scalebound', NaN, @isnumeric);

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
    switch Arg.scalebound
        case -121
            scaler = max(abs(inmat));
        otherwise
            scaler = std(inmat, 0, 1);
    end
    scaleMat = repmat(scaler, size(inmat, 1), 1);
    inmat = inmat ./ scaleMat;
end
