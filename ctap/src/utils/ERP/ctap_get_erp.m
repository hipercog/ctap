function [erp, interval] = ctap_get_erp(epocs, varargin)
% CTAP_GET_ERP


%% handle inputs
P = inputParser;

P.addRequired('epocs', @isstruct)

P.addParameter('centrality', 'mean', @(x) any(strcmpi(x, {'mean' 'median'})))
P.addParameter('dispersion', 'std', @(x) any(strcmpi(x, {'std' 'bootci'})))
P.addParameter('pnts', 1:epocs.pnts, @isnumeric)
P.addParameter('loc', 1, @isnumeric)
P.addParameter('roi', true, @(x) islogical(x) | any(x == [0 1]))
P.addParameter('smooth', 4, @isnumeric)
P.addParameter('bl', [], @isnumeric) % in ms
P.addParameter('nboot', 100, @isnumeric) % default bootstrap resamples

P.parse(epocs, varargin{:})
P = P.Results;

if isempty(P.bl)
    P.bl = [find(epocs.times(P.pnts) > epocs.xmin * 1000, 1)...
                      find(epocs.times(P.pnts) < 0, 1, 'last')];
end

cntr = str2func(P.centrality);
dspr = str2func(P.dispersion);
nloc = numel(P.loc);


%% baseline removal per epoch
if any(P.bl)
    for l = 1:nloc
        for tidx = 1:epocs.trials
            epocs.data(P.loc(l), P.pnts, tidx) =...
                epocs.data(P.loc(l), P.pnts, tidx) -...
                    cntr(epocs.data(P.loc(l), P.bl(1):P.bl(2), tidx));
        end
    end
end


%% ERP averaging
erp = cntr(epocs.data(P.loc, P.pnts, :), 3);

% handle ROI-ness
if P.roi && nloc > 1
    erp = cntr(erp, 1);
    interval = cntr(epocs.data(P.loc, P.pnts, :));
else
    interval = epocs.data(P.loc, P.pnts, :);
end

if strcmpi(P.dispersion, 'std')
    interval = squeeze(dspr(interval, 0, 3));
    interval = cat(3, interval, -interval);
else %do bootstrap 95% ci
    t = zeros(nloc ^ ~P.roi, numel(P.pnts), 2);
    for i = 1:nloc ^ ~P.roi
        t(i, :, :) = dspr(P.nboot, {cntr, squeeze(interval(i, :, :)), 2}...
                                                        , 'type', 'stud')';
    end
    interval = t;
end


%% smoothing by loess quadratic fit
if P.smooth > 0
    smth = round(epocs.srate / P.smooth);
    for e = 1:size(erp, 1)
        erp(e, :) = smooth(erp(e, :), smth, 'loess')';
        interval(e, :, 1) = smooth(interval(e, :, 1), smth, 'loess')';
        interval(e, :, 2) = smooth(interval(e, :, 2), smth, 'loess')';
    end
end


end