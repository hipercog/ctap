function erp = ctap_test_erp(epocs, loc, bl, smth)

if nargin < 4
    smth = 20;
end
if nargin < 3
    bl = [find(epocs.times > epocs.xmin * 1000, 1)...
          find(epocs.times < 0, 1, 'last')];
end
if nargin < 2
    loc = 1;
end

% baseline removal per epoch
if any(bl)
    for tidx = 1:epocs.trials
        epocs.data(loc,:,tidx) = epocs.data(loc,:,tidx) -...
            mean(epocs.data(loc,bl(1):bl(2),tidx));
    end
end
% ERP averaging
erp = mean(epocs.data(loc,:,:), 3);
% smoothing by loess quadratic fit
if smth > 0
    erp = smooth(erp, round(epocs.srate / smth), 'loess')';
end

end