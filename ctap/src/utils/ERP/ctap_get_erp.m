function [erp, sdev] = ctap_get_erp(epocs, varargin)
% CTAP_GET_ERP


P = inputParser;

P.addRequired('epocs', @isstruct)

P.addParameter('central', @mean, @(x) )
P.addParameter('pnts', 1:epocs.pnts, @isnumeric)
P.addParameter('loc', 1, @isnumeric)
P.addParameter('roi', true, @(x) islogical(x) | any(x == [0 1]))
P.addParameter('smooth', 4, @isnumeric)
P.addParameter('bl', [find(epocs.times > epocs.xmin * 1000, 1)...
                      find(epocs.times < 0, 1, 'last')], @isnumeric)

P.parse(epocs, varargin{:})
P = P.Results;

% baseline removal per epoch
if any(P.bl)
    for l = 1:numel(P.loc)
        for tidx = 1:epocs.trials
            epocs.data(P.loc(l), P.pnts, tidx) =...
                epocs.data(P.loc(l), P.pnts, tidx) -...
                    mean(epocs.data(P.loc(l), P.bl(1):P.bl(2), tidx));
        end
    end
end
% ERP averaging
erp = zeros(numel(P.loc), numel(P.pnts));
for l = 1:numel(P.loc)
    erp(l, :) = mean(epocs.data(P.loc(l), P.pnts, :), 3);
    % smoothing by loess quadratic fit
    if P.smooth > 0
        erp(l, :) = smooth(erp(l, :), round(epocs.srate / P.smooth), 'loess')';
    end
end

sdev = [];
if numel(P.loc) > 1
    sdev = std(erp);
    if P.roi
        erp = P.central(erp);
    end
end