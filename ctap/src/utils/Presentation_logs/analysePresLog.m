function tests=analysePresLog( proto, path, stats )
%% function analysePresLog() will spit out relevant statistics from logs of the given protocol
%  Parameters
%   proto   -   name of the protocol to be analysed.
%   path    -   path to the Presentation log files or stats
%   stats   -   name of a mat file which has the already imported log data

    if nargin < 3
        stats = reportLog( proto, path );
    elseif isstruct
        
    end
    figure();
    hist(stats.Congruent_shape_hit.meanrts);figure(gcf);
    figure();
    hist(stats.Congruent_nonShape_hit.meanrts);figure(gcf);
    figure();
    hist(stats.InCon_shape_hit.meanrts);figure(gcf);
    figure();
    hist(stats.InCon_nonShape_hit.meanrts);figure(gcf);
    % Do mean testing
    [h,p,ci,tstat] = ttest(stats.Congruent_shape_hit.meanrts, stats.InCon_shape_hit.meanrts);
    tests.shape.h = h;
    tests.shape.p = p;
    tests.shape.ci = ci;
    tests.shape.tstat = tstat;
    [h,p,ci,tstat] = ttest(stats.Congruent_nonShape_hit.meanrts, stats.InCon_nonShape_hit.meanrts);
    tests.nonShape.h = h;
    tests.nonShape.p = p;
    tests.nonShape.ci = ci;
    tests.nonShape.tstat = tstat;
end