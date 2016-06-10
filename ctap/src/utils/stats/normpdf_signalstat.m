function fitvals = normpdf_signalstat(myvals,mymean,mystd)
% Clone of the normpdf function of the stat toolbox
% Copied from EEGLAB signalstat.m

if nargin < 3,
    mystd = 1;
end
if nargin < 2;
    mymean = 0;
end
if length(mymean) < length(myvals)
	tmpmean = mymean;
	mymean = zeros(size(myvals));
	mymean(:) = tmpmean;
end;
if length(mystd) < length(myvals)
	tmpmean = mystd;
	mystd = zeros(size(myvals));
	mystd(:) = tmpmean;
end;
%mymean(1:10);
%mystd(1:10);

fitvals = zeros(size(myvals));
tmp = find(mystd > 0);
if any(tmp)
    myvalsn = (myvals(tmp) - mymean(tmp)) ./ mystd(tmp);
    fitvals(tmp) = exp(-0.5 * myvalsn .^2) ./ (sqrt(2*pi) .* mystd(tmp));
end
tmp1 = find(mystd <= 0);
if any(tmp1)
    tmp2   = NaN;
    fitvals(tmp1) = tmp2(ones(size(tmp1)));
end