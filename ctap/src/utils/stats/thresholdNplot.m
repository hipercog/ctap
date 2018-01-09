function Res = thresholdNplot(dvec, th, nmad, plot)
% thresholds - Thresholds a data vector
%
% Description:
%   Thresholds data vector 'dvec' either using provided threshold values 
%   in 'th' or by using median +- nmad*MAD as the thresholds

%%%% DEBUG ####
%dvec = randn(20,1);
%th = [NaN NaN];
%nmad = 3;

% Define th
dmad = double(mad(dvec));%dmad, dmedian must be type double or text() will crash
dmedian = double(nanmedian(dvec)); % note: does not ignore NaNs!

if all(isnan(th)) && any(~isnan(nmad))
    %expand nmad if it is a single value
    if isscalar(nmad)
        nmad = [-nmad nmad];
    %sort nmad if no elements were NaN
    elseif ~any(isnan(nmad))
        nmad = sort(nmad);
    end
    th = dmedian + [nmad(1)*dmad, nmad(2)*dmad];
end

isAbove = th(2) < dvec;
isBelow = dvec < th(1);
isInRange = ~isAbove & ~isBelow;


%% Plot
% TODO: why is this plot mandatory?
if plot
    % Defaults
    NBINS = round(0.75 * numel(dvec));
    TOPSPACE = 2;
    LAB_YOFFSET = 0;

    figh = figure('Visible', 'off');

    % Add histogram
    [bincount, binpos] = hist(dvec, NBINS);
    bar(binpos, bincount, 'k'); 
    xlabel('data value');
    ylabel('count');

    % Set axis limits
    cylim = get(gca, 'YLim');
    cylim(2) = cylim(2) + TOPSPACE;
    ylim(cylim);

    madxlim = dmedian + 3.5 * [-dmad, dmad];
    cxlim = [min([madxlim(1), min(dvec), th(1)]),...
             max([madxlim(2), max(dvec), th(2)])];
    xlim(cxlim);

    % Add vertical lines
    sbf_add_vline(dmedian, 'median', 'black', LAB_YOFFSET);

    sbf_add_vline(dmedian + dmad, '+1MAD', 'blue', LAB_YOFFSET);
    sbf_add_vline(dmedian - dmad, '-1MAD', 'blue', LAB_YOFFSET);

    sbf_add_vline(dmedian + 2*dmad, '+2MAD', 'blue', LAB_YOFFSET);
    sbf_add_vline(dmedian - 2*dmad, '-2MAD', 'blue', LAB_YOFFSET);

    sbf_add_vline(dmedian + 3*dmad, '+3MAD', 'blue', LAB_YOFFSET);
    sbf_add_vline(dmedian - 3*dmad, '-3MAD', 'blue', LAB_YOFFSET);

    sbf_add_vline(th(1), 'th-', 'red', -3);
    sbf_add_vline(th(2), 'th+', 'red', -3);
end


%% Set output
Res.threshold = th;
Res.data = dvec;
Res.isBelow = isBelow;
Res.isAbove = isAbove;
Res.isInRange = isInRange;
Res.figh = figh;


%% Helper functions
function sbf_add_vline(x, label, col, yoffset)
    line([x, x], cylim, 'color', col);
    text(x, cylim(2) + yoffset, label,...
        'Rotation', -90,...
        'VerticalAlignment', 'top');
end


end