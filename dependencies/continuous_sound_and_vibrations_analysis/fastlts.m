function [res,raw] = fastlts(x,y,options)

% version 22/12/2000, revised 19/01/2001, 30/01/2003
% last revision: 20/04/2006
%
% FASTLTS carries out least trimmed squares (LTS) regression, introduced in
%
%   Rousseeuw, P.J. (1984), "Least Median of Squares Regression,"
%   Journal of the American Statistical Association, Vol. 79, pp. 871-881.
%
% The LTS regression method minimizes the sum of the h smallest squared
% residuals, where h must be at least half the number of observations. The
% default value of h is roughly 0.75n (n is the total number of observations),
% but the user may choose any value between n/2 and n.
%
% The LTS regression method is intended for continuous variables, and assumes
% that the number of observations n is at least 4 times the number of
% regression coefficients p. If p is too large with respect to n, it would be
% better to first reduce p by variable selection or principal components.
%
% The LTS is a robust method in the sense that the estimated regression
% fit is not unduly influenced by outliers in the data, even if there are
% several outliers. Due to this robustness, we can detect outliers by their
% large LTS residuals.
%
% Usage:
%   [res,raw]=fastlts(x,y,options)
%
% If only one output argument is listed, only the final result ('res') is returned.
% The first input argument 'x' is a matrix of explanatory variables (also
% called 'regressors'). Rows of x represent observations, and columns
% represent variables.
% The second input argument 'y' is a vector with n elements that contains
% the response variable.
% Missing values (NaN's) and infinite values (Inf's) are allowed, since
% observations with missing or infinite values will automatically be excluded
% from the computations.
%
% The third input argument 'options' is a structure. It specifies certain
% parameters of the algorithm:
%
% options.intercept: Logical flag: if 1, a model with constant term will be
%                    fitted; if 0, no constant term will be included.
%                    Its default value is 1.
% options.alpha: The percentage of squared residuals whose sum will be
%                minimized. Its default value is 0.75. In general, alpha must
%                be a value between 0.5 and 1.
% options.ntrial: Number of initial subsets drawn. Its default value is 500.
%
% The output structure 'raw' contains intermediate results, with the
% following fields:
%
% raw.coefficients: vector of raw LTS coefficient estimates (including the
%                   intercept, when options.intercept=1)
% raw.fitted: vector like y containing the raw fitted values of the response.
% raw.residuals: vector like y containing the raw residuals from the regression.
% raw.scale: scale estimate of the raw residuals.
% raw.objective: objective function of the LTS regression method, i.e. the sum
%                of the h smallest squared raw residuals.
% raw.wt: vector like y containing weights that can be used in a weighted
%         least squares. These weights are 1 for points with reasonably
%         small raw residuals, and 0 for points with large raw residuals.
%
% The output structure 'res' contains the final results, namely:
%
% res.alpha: the same as options.alpha
% res.quan: the number h of observations that have determined the least
%           trimmed squares estimator (equals options.alpha*n).
% res.coefficients: vector of coefficient estimates (including the intercept,
%                   when options.intercept=1) obtained after reweighting.
% res.fitted: vector like y containing the fitted values of the response
%             after reweighting.
% res.residuals: vector like y containing the residuals from the weighted
%                least squares regression.
% res.scale: scale estimate of the reweighted residuals.
% res.rsquared: robust version of R squared. This is 1 minus the fraction:
%               (sum of the quan smallest squared residuals) over (sum of
%               the quan smallest (y-loc)^2), where the denominator
%               is minimized over loc. Note that loc is not subtracted from
%               y if options.intercept = 0 in the call to FASTLTS.
% res.flag: vector like y containing flags based on the reweighted regression.
%           These flags determine which observations can be considered as
%           outliers.
% res.intercept: same as options.intercept (default: intercept=1).
% res.method: character string naming the method (Least Trimmed Squares).
% res.X: same as the input x in the call to fastlts. If options.intercept was 1,
%        a column with 1's is added to x.
% res.y: same as the input y in the call to fastlts.
%
% FASTLTS also automatically calls the function plotlts which creates a set of
% plots for assessing the fit obtained by fastlts.
% The plots that can be produced are:
%
%  1. Standardized LTS Residuals versus LTS Fitted Values
%  2. Standardized LTS Residuals versus case number
%  3. Normal QQ plot: shows LTS Residuals versus normal quantiles
%  4. Diagnostic plot: shows LTS residuals versus Robust Distances of x-rows
%  5. Scatterplot with LTS line and tolerance band (if the dataset is bivariate)
%
% Usage:
%     plotlts(ltsres,options)
%
% The required input argument for PLOTLTS is the first output argument 'ltsres'
% created by the function FASTLTS.  Optional arguments are summarized in a
% structure 'options' containing:
%
%  options.ask: A logical flag; if set to 0, all plots are shown subsequently;
%               if set to 1, the user can choose a plot from a menu. The default
%               value is 1.
%  options.nid: Number of points (must be less than n) to be highlighted in the
%               appropriate plots. These will be the 'nid' most outlying
%               observations, i.e. those with standardized LTS residuals furthest
%               from zero.
%

%default values
pmax=20;
nmax=50000;
dtrial=500;
maxgroup=5;
nmini=300;
csteps1=2;
csteps2=2;
csteps3=100;

seed=0;
intercept=1;
ntrial=500;
alpha=0.75;

if nargin == 1
    y=x;
    x=ones(length(y));
elseif nargin > 1
    if isstruct(y)
        options=y;
        y=x;
        x=ones(length(y));
        msg='Univariate location and scatter estimation. Program uses exact algorithm in fastmcd.m';
        disp(msg);
    elseif nargin < 3,
        options = struct([]);
    end
    if nargin > 2 & ~isstruct(options)
        error('The third input argument is not a structure.')
    end
    if isfield(options,'ntrial')
        ntrial=options.ntrial;
    end
    if isfield(options,'alpha')
        alpha=options.alpha;
        if (alpha < 0.5) | (alpha > 1),
            error('alpha out of range 0.5 - 1');
        end
    end
    if isfield(options,'intercept')
        intercept=options.intercept;
    end
end

[dimx1 dimx2]=size(x);
[dimy1 dimy2]=size(y);
res.alpha=alpha;

if dimy1==1
    y=y';
end

if dimy2~=1
    error('y is not onedimensional.');
end

na.x=~isfinite(x*ones(dimx2,1));
na.y=~isfinite(y);

if size(na.x,1)~=size(na.y,1)
    error('Number of observations in x and y not equal.');
end

ok=~(na.x|na.y);
x=x(ok,:);
y=y(ok,:);
dx=size(x);
dy=size(y,1);
n=dx(1);

if n == 0
    error('All observations have missing values!');
end
if n > nmax
    error(['The program allows for at most ' int2str(nmax) ' observations.']);
end


X=x;
bestobj=inf;

%univariate case
if ~any(x-1)
    p=1;
    h=quanf(alpha,n,p);
    res.quan=h;
    res.method='Univariate location and scale estimation.';
    specific.alpha=alpha;
    specific.lts=1;
    
    [rewmcd,rawmcd]=fastmcd(y,specific);
    center=rawmcd.center;
    scale=sqrt(rawmcd.cov);
    resid=y-center;
    raw.coefficients=center;
    raw.fitted=repmat(NaN,length(ok),1);
    raw.fitted=repmat(center,n,1);
    raw.residuals=repmat(NaN,length(ok),1);
    raw.residuals=resid;
    if abs(scale) < 1e-7
        weights=abs(resid)<=1e-7;
        raw.wt=repmat(NaN,length(ok),1);
        raw.wt=weights;
        raw.scale=0;
        res.scale=0;
        raw.objective=0;
        res.coefficients=center;
        res.fitted=raw.fitted;
    else
        sor=sort(resid.^2);
        raw.objective=sum(sor(1:h));
        raw.scale=scale;
        quantile=qnorm(0.9875);
        weights=abs(resid/scale)<=quantile;
        raw.wt=repmat(NaN,length(ok),1);
        raw.wt=weights;
        weights=weights';
        reweighting=cov(y(weights==1));
        res.coefficients=mean(y(weights==1));
        cdelta_rew=rewconsfactorlts(weights,n,0);
        if alpha<1
            factor=rewcorfactorlts(p,intercept,n,alpha);
        else
            factor=1;
        end
        res.scale=sqrt(sum(weights*(reweighting))/(sum(weights)-1))*cdelta_rew*factor;
        resid=y-res.coefficients;
        weights=abs(resid/res.scale)<=2.5;
        res.fitted=repmat(NaN,length(ok),1);
        res.fitted=repmat(res.coefficients,n,1);
    end
    res.residuals=repmat(NaN,length(ok),1);
    res.residuals=resid;
    res.rsquared=0;
    res.flag=repmat(NaN,length(ok),1);
    res.flag=weights;
    res.intercept=intercept;
    if abs(scale) < 1e-7
        res.method=strvcat(res.method,'More than half of the data are equal!');
    end
    res.X=x;
    res.y=y;
    
    spec.ask=1;
    %plotlts(res,spec);
    
    
    return
end

if intercept == 1
    dx=dx+[0 1];
    x=cat(2,x,ones(n,1));
end
p=dx(2);

if n <= 2*p
    error('Need more than twice as many observations as variables.');
end

if p > pmax
    error(['The program allows for at most ' int2str(pmax) ' variables.'])
end

rk=rank(x);
if rk < p
    error('x is singular');
end


h=quanf(alpha,n,p);
res.quan=h;

if h == n
    res.method='Least Squares Regression.';
    [Q,R]=qr(x,0);
    z=R\(Q'*y);
    raw.coefficients=z;
    residuals=y-x*z;
    raw.residuals=repmat(NaN,length(ok),1);
    raw.residuals=residuals;
    fitted=x*raw.coefficients;
    raw.fitted=repmat(NaN,length(ok),1);
    raw.fitted=fitted;
    s0=sqrt(sum(residuals.^2)/(n-p));
    if abs(s0) < 1e-7
        weights=abs(residuals)<=1e-7;
        raw.wt=repmat(NaN,length(ok),1);
        raw.wt=weights;
        raw.scale=0;
        res.scale=0;
        res.coefficients=raw.coefficients;
        raw.objective=0;
    else
        sor=sort(residuals.^2);
        raw.objective=sum(sor(1:h));
        raw.scale=s0;
        weights=abs(residuals/s0)<=qnorm(0.9875);
        raw.wt=repmat(NaN,length(ok),1);
        raw.wt=weights;
        [Q,R]=qr(x(weights==1,:),0);
        z=R\(Q'*y(weights==1));
        res.coefficients=z;
        fitted=x*res.coefficients;
        residuals=y-x*z;
        factor=rewconsfactorlts(weights,n,p);
        res.scale=sqrt(sum(weights.*(residuals.^2))/(sum(weights)-1))*factor;
        weights=abs(residuals/res.scale)<=2.5;
    end
    if intercept
        s1=sum(residuals.^2);
        center=mean(y);
        sh=sum((y-center).^2);
        res.rsquared=1-s1/sh;
    else
        s1=sum(residuals.^2);
        sh=sum(y.^2);
        res.rsquared=1-s1/sh;
    end
    if res.rsquared > 1
        res.rsquared=1;
    elseif res.rsquared < 0
        res.rsquared=0;
    end
    res.residuals=repmat(NaN,length(ok),1);
    res.residuals=residuals;
    res.flag=repmat(NaN,length(ok),1);
    res.flag=weights;
    res.intercept=intercept;
    if abs(s0) < 0
        res.method=strvcat(res.method,'An exact fit was found!');
    end
    %disp(res.method);
    res.fitted=repmat(NaN,length(ok),1);
    res.fitted=fitted;
    res.X=x;
    res.y=y;
    
    spec.ask=1;
    %plotlts(res,spec);
    
    return
end

if p < 5
    eps=1e-12;
elseif p <= 8
    eps=1e-14;
else
    eps=1e-16;
end

% standardization of the data

xorig=x;
yorig=y;
data=[x y];
if ~intercept
    datamed=repmat(0,1,p+1);
    datamad=median(abs(data)).*1.4826;
    for i=1:p+1
        if abs(datamad(i)) <= eps
            datamad(i)=sum(abs(data(:,i)));
            datamad(i)=(datamad(i)/n)*1.2533;
            if abs(datamad(i)) <= eps;
                error('The MAD of some variable is zero');
            end
        end
    end
    for i=1:p
        x(:,i)=x(:,i)./datamad(i);
    end
    y(:,1)=y(:,1)./datamad(p+1);
else
    datamed=median(data);
    datamed(p)=0;
    datamad(p)=1;
    for i=1:p+1
        if i ~= p
            datamad(i)=median(abs(data(:,i)-datamed(i)))*1.4826;
            if abs(datamad(i)) <= eps
                datamad(i)=sum(abs(data(:,i)-datamed(i)));
                datamad(i)=(datamad(i)/n)*1.2533;
                if abs(datamad(i)) <= eps
                    error('The MAD of some variable is zero');
                end
            end
        end
    end
    for i=1:p-1
        x(:,i)=(x(:,i)-datamed(i))./datamad(i);
    end
    y(:,1)=(y(:,1)-datamed(p+1))./datamad(p+1);
end

res.method='Least Trimmed Squares Regression.';
% disp(res.method);

al=0;
if n >= 2*nmini
    
    maxobs=maxgroup*nmini;
    if n >= maxobs
        ngroup=maxgroup;
        group(1:maxgroup)=nmini;
    else
        ngroup=floor(n/nmini);
        minquan=floor(n/ngroup);
        group(1)=minquan;
        for s=2:ngroup
            group(s)=minquan+double(rem(n,ngroup)>=s-1);
        end
    end
    part=1;
    adjh=floor(group(1)*alpha);
    nsamp=floor(ntrial/ngroup);
    minigr=sum(group);
    obsingroup=fillgroup(n,group,ngroup,seed);
    totgroup=ngroup;
    
else
    
    [part,group,ngroup,adjh,minigr,obsingroup]=deal(0,n,1,h,n,n);
    replow=[50,22,17,15,14,zeros(1,45)];
    if n < replow(p)
        al=1;
        perm=[1:p-1,p-1];
        nsamp=nchoosek(n,p);
    else
        al=0;
        nsamp=ntrial;
    end
    
end

csteps=csteps1;
[tottimes,fine,final]=deal(0);

if part
    bobj1=repmat(inf,ngroup,10);
    bcoeff1=cell(ngroup,10);
    [bcoeff1{:}]=deal(NaN);
end

bcoeff=cell(1,10);
bobj=repmat(inf,1,10);
[bcoeff{:}]=deal(NaN);
seed=0;
coeffs=repmat(NaN,p,1);

while final ~= 2
    
    if fine | (~part & final)
        nsamp=10;
        if final
            adjh=h;
            ngroup=1;
            if n*p <= 1e+5
                csteps=csteps3;
            elseif n*p <= 1e+6
                csteps=10-(ceil(n*p/1e+5)-2);
            else
                csteps=1;
            end
            if n > 5000
                nsamp=1;
            end
        else
            adjh=floor(minigr*alpha);
            csteps=csteps2;
        end
    end
    
    for k=1:ngroup
        
        for i=1:nsamp
            tottimes=tottimes+1;
            prevobj=0;
            
            if final
                
                if ~isinf(bobj(i))
                    z=bcoeff{i};
                else
                    break;
                end
                
            elseif fine
                
                if ~isinf(bobj1(k,i))
                    z=bcoeff1{k,i};
                else
                    break;
                end
                
            else
                
                z(1,1)=Inf;
                while z(1,1) == Inf
                    
                    if ~part
                        if al
                            k=p;
                            perm(k)=perm(k)+1;
                            while ~(k==1|perm(k) <= (n-(p-k)))
                                k=k-1;
                                perm(k)=perm(k)+1;
                                for j=(k+1):p
                                    perm(j)=perm(j-1)+1;
                                end
                            end
                            index=perm;
                        else
                            [index,seed]=randomset(n,p,seed);
                        end
                    else
                        [index,seed]=randomset(group(k),p,seed);
                        index=obsingroup{k}(index);
                    end
                    if p > 1
                        z=x(index,:)\y(index,1);
                    elseif x(index,1) ~= 0
                        z(1,1)=y(index,1)/x(index,1);
                    else
                        z(1,1)=x(index,1);
                    end
                    if al
                        break;
                    end
                end
            end
            
            if z(1,1) ~= Inf
                if ~part | final
                    residu=y-x*z;
                elseif ~fine
                    residu=y(obsingroup{k},1)-x(obsingroup{k},:)*z;
                else
                    residu=y(obsingroup{totgroup+1},1)-x(obsingroup{totgroup+1},:)*z;
                end
                
                
                more1=0;
                more2=0;
                nmore=200;
                nmore2=nmore/2;
                
                if intercept
                    [sortres,sortind]=sort(residu);
                    if ~part
                        [center,cover,loc]=mcduni(sortres,obsingroup,adjh,obsingroup-adjh+1,alpha);
                        z(p)=z(p)+center;
                        residu=residu-center;
                    elseif ~fine
                        [center,cover,loc]=mcduni(sortres,size(obsingroup{k},2),adjh,size(obsingroup{k},2)-adjh+1,alpha);
                        z(p)=z(p)+center;
                        residu=residu-center;
                    elseif ~final & size(obsingroup{totgroup+1},2)-adjh <= nmore
                        [center,cover,loc]=mcduni(sortres,size(obsingroup{totgroup+1},2),adjh,size(obsingroup{totgroup+1},2)-adjh+1,alpha);
                        z(p)=z(p)+center;
                        residu=residu-center;
                    elseif final & n-adjh <= nmore
                        [center,cover,loc]=mcduni(sortres,n,adjh,n-adjh+1,alpha);
                        z(p)=z(p)+center;
                        residu=residu-center;
                    else
                        [sortres1,sortind1]=sort(abs(sortres));
                        [sortres2,sortind2]=sort(sortres(sortind1(1:adjh)));
                        further = 1;
                        if final & (sortind1(sortind2(1))+nmore-nmore2+adjh-1 > n  | sortind1(sortind2(1))-nmore2< 1)
                            [center,cover,loc]=mcduni(sortres,n,adjh,n-adjh+1,alpha);
                            z(p)=z(p)+center;
                            residu=residu-center;
                        elseif fine & ~final & (sortind1(sortind2(1))+nmore-nmore2+adjh-1 > size(obsingroup{totgroup+1},2) | sortind1(sortind2(1))-nmore2 < 1)
                            [center,cover,loc]=mcduni(sortres,size(obsingroup{totgroup+1},2),adjh,size(obsingroup{totgroup+1},2)-adjh+1,alpha);
                            z(p)=z(p)+center;
                            residu=residu-center;
                        else
                            while further
                                sortres2(1:adjh+nmore)=sortres(sortind1(sortind2(1))-nmore2:sortind1(sortind2(1))+adjh-1+nmore-nmore2);
                                [center,cover,loc]=mcduni(sortres2,adjh+nmore,adjh,nmore+1,alpha);
                                if loc == 1 & ~more1
                                    if ~more2
                                        nmore=nmore2;
                                        nmore2=nmore2+nmore2;
                                        more1=1;
                                        if sortind1(sortind2(1))-nmore2 < 1
                                            further=0;
                                        end
                                    end
                                else
                                    if loc == nmore+1 & ~more2
                                        if ~more1
                                            nmore=nmore2;
                                            nmore2=-nmore2;
                                            more2=1;
                                            if final & sortind1(sortind2(1))+nmore-nmore2+adjh-1 > n | sortind1(sortind2(1))-nmore2< 1
                                                further=0;
                                            elseif fine & sortind1(sortind2(1))+nmore-nmore2+adjh-1 > size(obsingroup{totgroup+1},2) | sortind1(sortind2(1))-nmore2< 1
                                                further=0;
                                            end
                                        end
                                    else
                                        if loc == 1 & more1
                                            if ~more2
                                                nmore2=nmore2+100;
                                                if sortind1(sortind2(1))-nmore2 < 1
                                                    further=0;
                                                end
                                            end
                                        else
                                            if loc == nmore+1 & more2
                                                if ~more1
                                                    nmore2=nmore2+100;
                                                    if final & sortind1(sortind2(1))+nmore-nmore2+adjh-1 > n | sortind1(sortind2(1))-nmore2< 1
                                                        further=0;
                                                    elseif fine & sortind1(sortind2(1))+nmore-nmore2+adjh-1 > size(obsingroup{totgroup+1},2) | sortind1(sortind2(1))-nmore2< 1
                                                        further=0;
                                                    end
                                                end
                                            else
                                                further=0;
                                            end
                                        end
                                    end
                                end
                            end
                            z(p)=z(p)+center;
                            residu=residu-center;
                        end
                    end
                end
                for j=1:csteps
                    tottimes=tottimes+1;
                    [sortres,sortind]=sort(abs(residu));
                    if fine & ~final
                        sortind=obsingroup{totgroup+1}(sortind);
                    elseif part & ~final
                        sortind=obsingroup{k}(sortind);
                    end
                    obs_in_set=sort(sortind(1:adjh));
                    [Q,R]=qr(x(obs_in_set,:),0);
                    z=R\(Q'*y(obs_in_set,1));
                    if ~part | final
                        residu=y-x*z;
                    elseif ~fine
                        residu=y(obsingroup{k},1)-x(obsingroup{k},:)*z;
                    else
                        residu=y(obsingroup{totgroup+1},1)-x(obsingroup{totgroup+1},:)*z;
                    end
                    
                    more1=0;
                    more2=0;
                    nmore=200;
                    nmore2=nmore/2;
                    
                    if intercept
                        [sortres,sortind]=sort(residu);
                        if ~part
                            [center,cover,loc]=mcduni(sortres,obsingroup,adjh,obsingroup-adjh+1,alpha);
                            z(p)=z(p)+center;
                            residu=residu-center;
                        elseif ~fine
                            [center,cover,loc]=mcduni(sortres,size(obsingroup{k},2),adjh,size(obsingroup{k},2)-adjh+1,alpha);
                            z(p)=z(p)+center;
                            residu=residu-center;
                        elseif ~final & size(obsingroup{totgroup+1},2)-adjh <= nmore
                            [center,cover,loc]=mcduni(sortres,size(obsingroup{totgroup+1},2),adjh,size(obsingroup{totgroup+1},2)-adjh+1,alpha);
                            z(p)=z(p)+center;
                            residu=residu-center;
                        elseif final & n-adjh <= nmore
                            [center,cover,loc]=mcduni(sortres,n,adjh,n-adjh+1,alpha);
                            z(p)=z(p)+center;
                            residu=residu-center;
                        else
                            [sortres1,sortind1]=sort(abs(sortres));
                            [sortres2,sortind2]=sort(sortres(sortind1(1:adjh)));
                            further = 1;
                            if final & (sortind1(sortind2(1))+nmore-nmore2+adjh-1 > n  | sortind1(sortind2(1))-nmore2< 1)
                                [center,cover,loc]=mcduni(sortres,n,adjh,n-adjh+1,alpha);
                                z(p)=z(p)+center;
                                residu=residu-center;
                            elseif fine & ~final & (sortind1(sortind2(1))+nmore-nmore2+adjh-1 > size(obsingroup{totgroup+1},2) | sortind1(sortind2(1))-nmore2 < 1)
                                [center,cover,loc]=mcduni(sortres,size(obsingroup{totgroup+1},2),adjh,size(obsingroup{totgroup+1},2)-adjh+1,alpha);
                                z(p)=z(p)+center;
                                residu=residu-center;
                            else
                                while further
                                    sortres2(1:adjh+nmore)=sortres(sortind1(sortind2(1))-nmore2:sortind1(sortind2(1))+adjh-1+nmore-nmore2);
                                    [center,cover,loc]=mcduni(sortres2,adjh+nmore,adjh,nmore+1,alpha);
                                    if loc == 1 & ~more1
                                        if ~more2
                                            nmore=nmore2;
                                            nmore2=nmore2+nmore2;
                                            more1=1;
                                            if sortind1(sortind2(1))-nmore2 < 1
                                                further=0;
                                            end
                                        end
                                    else
                                        if loc == nmore+1 & ~more2
                                            if ~more1
                                                nmore=nmore2;
                                                nmore2=-nmore2;
                                                more2=1;
                                                if final & sortind1(sortind2(1))+nmore-nmore2+adjh-1 > n  | sortind1(sortind2(1))-nmore2< 1
                                                    further=0;
                                                elseif fine & sortind1(sortind2(1))+nmore-nmore2+adjh-1 > size(obsingroup{totgroup+1},2) | sortind1(sortind2(1))-nmore2< 1
                                                    further=0;
                                                end
                                            end
                                        else
                                            if loc == 1 & more1
                                                if ~more2
                                                    nmore2=nmore2+100;
                                                    if sortind1(sortind2(1))-nmore2 < 1
                                                        further=0;
                                                    end
                                                end
                                            else
                                                if loc == nmore+1 & more2
                                                    if ~more1
                                                        nmore2=nmore2+100;
                                                        if final & sortind1(sortind2(1))+nmore-nmore2+adjh-1 > n | sortind1(sortind2(1))-nmore2< 1
                                                            further=0;
                                                        elseif fine & sortind1(sortind2(1))+nmore-nmore2+adjh-1 > size(obsingroup{totgroup+1},2) | sortind1(sortind2(1))-nmore2< 1
                                                            further=0;
                                                        end
                                                    end
                                                else
                                                    further=0;
                                                end
                                            end
                                        end
                                    end
                                end
                                z(p)=z(p)+center;
                                residu=residu-center;
                            end
                        end
                    end
                    sor=sort(abs(residu));
                    obj=sum(sor(1:adjh).^2);
                    if j >= 2 & obj == prevobj
                        break;
                    end
                    prevobj=obj;
                end
                
                if ~final
                    if fine |~part
                        if obj < max(bobj)
                            [bcoeff,bobj]=insertion(bcoeff,bobj,z,obj,1,eps);
                        end
                    else
                        if obj < max(bobj1(k,:))
                            [bcoeff1,bobj1]=insertion(bcoeff1,bobj1,z,obj,k,eps);
                        end
                    end
                end
                
                if final & obj < bestobj
                    bestset=obs_in_set;
                    bestobj=obj;
                    coeffs=z;
                end
            end
        end
    end
    
    if part & ~fine
        fine = 1;
    elseif (part & fine & ~final) | (~part & ~final)
        final = 1;
    else
        final = 2;
    end
    
end


if p <= 1
    coeffs(1)=coeffs(1)*datamad(p+1)/datamad(1);
else
    for i=1:p-1
        coeffs(i)=coeffs(i)*datamad(p+1)/datamad(i);
    end
    if ~intercept
        coeffs(p)=coeffs(p)*datamad(p+1)/datamad(p);
    else
        coeffs(p)=coeffs(p)*datamad(p+1);
        for j=1:p-1
            coeffs(p)=coeffs(p)-coeffs(j)*datamed(j);
        end
        coeffs(p)=coeffs(p)+datamed(p+1);
    end
end
bestobj=bestobj*(datamad(p+1)^2);
x=xorig;
y=yorig;



raw.coefficients=coeffs;
raw.objective=bestobj;
fitted=x*coeffs;
raw.fitted=repmat(NaN,length(ok),1);
raw.residuals=repmat(NaN,length(ok),1);
raw.fitted=fitted;
residuals=y-fitted;
raw.residuals=residuals;
sor=sort(residuals.^2);
factor=rawcorfactorlts(p,intercept,n,alpha);
factor=factor*rawconsfactorlts(h,n);
sh0=sqrt((1/h)*sum(sor(1:h)));
s0=sh0*factor;
if abs(s0) < 1e-7
    weights=abs(residuals)<=1e-7;
    raw.wt=repmat(NaN,length(ok),1);
    raw.wt=weights;
    raw.scale=0;
    res.scale=0;
    res.coefficients=raw.coefficients;
    raw.objective=0;
else
    raw.scale=s0;
    quantile=qnorm(0.9875);
    weights=abs(residuals/s0)<=quantile;
    raw.wt=repmat(NaN,length(ok),1);
    raw.wt=weights;
    [Q,R]=qr(x(weights==1,:),0);
    z=R\(Q'*y(weights==1));
    res.coefficients=z;
    fitted=x*res.coefficients;
    residuals=y-fitted;
    res.scale=sqrt(sum(weights.*residuals.^2)/(sum(weights)-1));
    factor=rewcorfactorlts(p,intercept,n,alpha);
    factor=factor*rewconsfactorlts(weights,n,p);
    res.scale=res.scale*factor;
    weights=abs(residuals/res.scale)<=2.5;
end
res.flag=repmat(NaN,length(ok),1);
res.flag=weights;
if intercept
    specific.alpha=alpha;
    specific.lts=1;
    [rewmcd,rawmcd]=fastmcd(y,specific);
    sh=sqrt(rewmcd.cov);
    sh0=res.scale;
    res.rsquared=1-(sh0/sh)^2;
else
    sor=sort(residuals.^2);
    s1=sum(sor(1:h));
    sor=sort(y.^2);
    sh=sum(sor(1:h));
    res.rsquared=1-(s1/sh);
end
if res.rsquared > 1
    res.rsquared=1;
elseif res.rsquared < 0
    res.rsquared=0;
end
res.residuals=repmat(NaN,length(ok),1);
res.residuals=residuals;
res.intercept=intercept;
if abs(s0) < 1e-7
    res.method=strvcat(res.method,'An exact fit was found!');
end
res.fitted=repmat(NaN,length(ok),1);
res.fitted=fitted;
res.X=x;
res.y=y;

spec.ask=1;
%plotlts(res,spec);
% --------------------------------------------------------------------

function obsingroup = fillgroup(n,group,ngroup,seed)

% Creates the subdatasets.

obsingroup=cell(1,ngroup+1);

jndex=0;
for k = 1:ngroup
    for m = 1:group(k)
        [random,seed]=uniran(seed);
        ran=floor(random*(n-jndex)+1);
        jndex=jndex+1;
        if jndex == 1
            index(1,jndex)=ran;
            index(2,jndex)=k;
        else
            index(1,jndex)=ran+jndex-1;
            index(2,jndex)=k;
            ii=min(find(index(1,1:jndex-1) > ran-1+[1:jndex-1]));
            if length(ii)
                index(1,jndex:-1:ii+1)=index(1,jndex-1:-1:ii);
                index(2,jndex:-1:ii+1)=index(2,jndex-1:-1:ii);
                index(1,ii)=ran+ii-1;
                index(2,ii)=k;
            end
        end
    end
    obsingroup{k}=index(1,index(2,:)==k);
    obsingroup{ngroup+1}=[obsingroup{ngroup+1},obsingroup{k}];
end

% --------------------------------------------------------------------

function [random,seed]=uniran(seed)

% The random generator.

seed=floor(seed*5761)+999;
quot=floor(seed/65536);
seed=floor(seed)-floor(quot*65536);
random=seed/65536.D0;


% --------------------------------------------------------------------

function [ranset,seed] = randomset(tot,nel,seed)

for j = 1:nel
    [random,seed]=uniran(seed);
    num=floor(random*tot)+1;
    if j > 1
        while any(ranset==num)
            [random,seed]=uniran(seed);
            num=floor(random*tot)+1;
        end
    end
    ranset(j)=num;
end


% --------------------------------------------------------------------

function mah=mahalanobis(dat,meanvct,covmat,n,p)

% Computes the mahalanobis distances.

for k=1:p
    d=covmat(k,k);
    covmat(k,:)=covmat(k,:)/d;
    rows=setdiff(1:p,k);
    b=covmat(rows,k);
    covmat(rows,:)=covmat(rows,:)-b*covmat(k,:);
    covmat(rows,k)=-b/d;
    covmat(k,k)=1/d;
end

hlp=dat-repmat(meanvct,n,1);
mah=sum(hlp*covmat.*hlp,2)';

% --------------------------------------------------------------------

function [output] = replow(k,pmax)

replow=[500,50,22,17,15,14];
help=zeros(1,pmax-5);
replow=[replow help];
output=replow(k);

% --------------------------------------------------------------------

function [initmean,initcov,iloc]=mcduni(y,ncas,h,len,alpha)

% The exact MCD algorithm for the univariate case.

y=sort(y);

ay(1)=sum(y(1:h));

for samp=2:len
    ay(samp)=ay(samp-1)-y(samp-1)+y(samp+h-1);
end

ay2=ay.^2/h;

sq(1)=sum(y(1:h).^2)-ay2(1);

for samp=2:len
    sq(samp)=sq(samp-1)-y(samp-1)^2+y(samp+h-1)^2-ay2(samp)+ay2(samp-1);
end

sqmin=min(sq);
ii=find(sq==sqmin);
ndup=length(ii);
slutn(1:ndup)=ay(ii);
initmean=slutn(floor((ndup+1)/2))/h;
factor=rawcorfactormcd(ncas,alpha);
factor=factor*rawconsfactormcd(h,ncas);
initcov=factor^2*sqmin/h;
iloc=ii(1);

% -----------------------------------------------------------------------------

function [bestmean,bobj]=insertion(bestmean,bobj,z,obj,row,eps)

insert=1;

equ=find(obj==bobj(row,:));

for j=equ
    if (z==bestmean{row,j})
        insert=0;
    end
end

if insert
    ins=min(find(obj < bobj(row,:)));
    
    if ins==10
        bestmean{row,ins}=z;
        bobj(row,ins)=obj;
    else
        [bestmean{row,ins+1:10}]=deal(bestmean{row,ins:9});
        bestmean{row,ins}=z;
        bobj(row,ins+1:10)=bobj(row,ins:9);
        bobj(row,ins)=obj;
    end
    
end

% --------------------------------------------------------------------------------

function plotlts(ltsres,options)

scale=ltsres.scale;
if scale == 0
    disp('WARNING: More than half of the data lie on a hyperplane. No plots can be made.')
    return
end

if nargin==1
    ask=0;
    nid=3;
elseif isstruct(options)
    names=fieldnames(options);
    
    if strmatch('ask',names,'exact')
        ask=options.ask;
    else
        ask=0;
    end
    
    if strmatch('nid',names,'exact')
        nid=options.nid;
    else
        nid=3;
    end
else
    error('The second input argument is not a structure.')
end

if ltsres.intercept
    p=size(ltsres.coefficients,1)-1;
else
    p=size(ltsres.coefficients,1);
end
data=ltsres.X;
n=size(data,1);
choice=1;
coef=ltsres.coefficients;
resid=ltsres.residuals;
alpha=ltsres.alpha;

if ask
    al=0;
else
    al=1;
end

closeplot=0;

while choice ~=7
    if ask
        choice=menu('Make a plot selection:','All','Standardized LTS Residuals versus LTS Fitted Values',...
            'Index Plot of Standardized LTS Residuals','Normal QQplot of LTS residuals',...
            'Diagnostic plot of LTS Residuals versus Robust Distances of X computed by the MCD (see function fastmcd.m)',...
            'Scatterplot with LTS line and tolerance band (if the dataset is bivariate)','Exit');
        
        if closeplot==1 & choice ~=7 & ~(choice==5 & p==0) & ~(choice==2 & p==0)
            %close previous plots.
            for i=1:5
                close
            end
            closeplot=0;
        end
        
        if choice==1
            al=2;
        end
        
    end
    
    if choice==1
        choice=2;
    end
    
    
    if al & ~((choice==5 & p==0) | choice==2)
        %create a new figure window
        figure
    end
    
    switch choice
        
        case 2
            if p==0
                disp('residual vs fit plot is not available for univariate location and scale estimation')
            else
                x=data*coef;
                y=resid/scale;
                beg('Fitted Values','Standardized LTS Residual',abs(y),x,y,nid,n,min(x),max(x),min([-3 min(y)]),max([3 max(y)]));
                v=axis;
                line([v(1),v(2)],[qnorm(0.9875),qnorm(0.9875)],'color','r');
                line([v(1),v(2)],[0,0],'color','k');
                line([v(1),v(2)],[-qnorm(0.9875),-qnorm(0.9875)],'color','r');
            end
            
        case 3
            x=1:size(resid,1);
            y=resid/scale;
            beg('Index','Standardized LTS Residual',abs(y),x,y,nid,n,min(x),max(x),min([-3 min(y)]),max([3 max(y)]));
            v=axis;
            line([v(1),v(2)],[qnorm(0.9875),qnorm(0.9875)],'color','r');
            line([v(1),v(2)],[0,0],'color','k');
            line([v(1),v(2)],[-qnorm(0.9875),-qnorm(0.9875)],'color','r');
            
        case 4
            normalquantile=repmat(0,1,n);
            for i=1:n
                normalquantile(i)=qnorm((i-1/3)/(n+1/3),0,1);
            end
            normqqplot(normalquantile,resid);
            xlabel('Quantiles of the standard normal distribution');
            ylabel('Standardized LTS residuals');
            
        case 5
            if p==0
                disp('Diagnostic plot is not available for univariate location and scale estimation')
            else
                disp('The function fastmcd is now called to compute robust distances.')
                specific.lts=1;
                specific.alpha=alpha;
                [rewmcd,rawmcd]=fastmcd(data(:,1:p),specific);
                if -log(abs(det(rewmcd.cov)))/p > 50
                    error('The MCD covariance matrix was singular');
                else
                    RD=rewmcd.robdist;
                end
                
                quant=max([sqrt(qchisq(0.975,p)) 2.5]);
                x=RD';
                y=resid/scale;
                beg('Robust Distance computed by the MCD','Standardized LTS Residual',max(abs(x/(2.5)),abs(y/quant)),x,y,nid,n,min(x),max([quant+0.1 max(x)]),min([-4 min(y)]),max([4 max(y)]));
                ylim=get(gca,'Ylim');
                ylim=[min(ylim(1),min([-4 min(y)])),max(ylim(2),max([4 max(y)]))];
                line([quant,quant],[ylim(1),ylim(2)],'color','r');
                xlim=get(gca,'Xlim');
                xlim=[min(xlim(1),min(x)),max(xlim(2),max([quant+0.1 max(x)]))];
                line([xlim(1),xlim(2)],[qnorm(0.9875),qnorm(0.9875)],'color','r');
                line([xlim(1),xlim(2)],[-qnorm(0.9875),-qnorm(0.9875)],'color','r');
                title('Diagnostic plot');
            end
            
        case 6
            if p~=1
                disp('Scatterplot with LTS line and tolerance band is only available for bivariate data')
            else
                x=data(:,1);
                y=ltsres.y;
                x1 = x(1);
                xn = x(n);
                y1 = ltsres.fitted(1);
                yn = ltsres.fitted(n);
                dx = xn - x1;
                dy = yn - y1;
                slope = dy./dx;
                centerx = (x1 + xn)/2;
                centery = (y1 + yn)/2;
                maxx = max(x);
                minx = min(x);
                maxy = centery + slope.*(maxx - centerx);
                miny = centery - slope.*(centerx - minx);
                mx = [minx; maxx];
                my = [miny; maxy];
                %plot(x,y,'o');
                scatter(x,y,3,'k');
                hold on
                plot(mx,my,'-');
                plot(mx,my+qnorm(0.9875),'-');
                plot(mx,my-qnorm(0.9875),'-');
                hold off
            end
            
    end
    
    if al & choice < 6
        ask=0;
        choice=choice+1;
    elseif al == 1 & choice == 6
        choice=7;
    elseif al == 2 & choice == 6
        al=0;
        ask=1;
        closeplot=1;
    end
    
end

% ---------------------------------------------------------------------

function beg(xlab,ylab,ord,x,y,nid,n,xmin,xmax,ymin,ymax)

% Creates a scatter plot

scatter(x,y,3,'k')

xlabel(xlab);
ylabel(ylab);

xlim=([xmin,xmax]);
ylim=([ymin,ymax]);
box;
if nid
    [ord,ind]=sort(ord);
    ind=ind(n-nid+1:n);
    text(x(ind),y(ind),int2str(ind));
end

%--------------------------------------------------------------------

function quan=quanf(alpha,n,rk)

quan=floor(2*floor((n+rk+1)/2)-n+2*(n-floor((n+rk+1)/2))*alpha);

%--------------------------------------------------------------------

function  x = qnorm(p,m,s)
%QNORM 	  The normal inverse distribution function
%
%         x = qnorm(p,Mean,StandardDeviation)

%       Anders Holtsberg, 13-05-94
%       Copyright (c) Anders Holtsberg

if nargin<3, s=1; end
if nargin<2, m=0; end

if any(any(abs(2*p-1)>1))
    error('A probability should be 0<=p<=1, please!')
end
if any(any(s<=0))
    error('Parameter s is wrong')
end

x = erfinv(2*p-1).*sqrt(2).*s + m;

%----------------------------------------------------------------------

function  f = dnorm(x,m,s)
%DNORM 	  The normal density function
%
%         f = dnorm(x,Mean,StandardDeviation)

%       Anders Holtsberg, 18-11-93
%       Copyright (c) Anders Holtsberg

if nargin<3, s=1; end
if nargin<2, m=0; end
f = exp(-0.5*((x-m)./s).^2)./(sqrt(2*pi)*s);

%----------------------------------------------------------------------

function  X = rnorm(n,m,s)
%RNORM 	  Normal random numbers
%
%         p = rnorm(Number,Mean,StandardDeviation)

%       Anders Holtsberg, 18-11-93
%       Copyright (c) Anders Holtsberg

if nargin<3, s=1; end
if nargin<2, m=0; end
if nargin<1, n=1; end
if size(n)==1
    n = [n 1];
    if size(m,2)>1, m = m'; end
    if size(s,2)>1, s = s'; end
end

X = randn(n).*s + m;

%--------------------------------------------------------------------

function normqqplot(x,y);
%QQPLOT   Plot empirical quantile vs empirical quantile
%
%         qqplot(x,y,ps)
%
%         If two distributions are the same (or possibly linearly
%	  transformed) the points should form an approximately straight
%	  line. Data is x and y. Third argument ps is an optional plot
%	  symbol.
%
%         See also QQNORM

y = sort(y);

scatter(x,y,3,'k')

%-----------------------------------------------------------------

function rawcorfaclts=rawcorfactorlts(p,intercept,n,alpha)

if intercept==1
    p=p-1;
end
if p==0
    fp_500_n=1-exp(0.262024211897096)*1/n^0.604756680630497;
    fp_875_n=1-exp(-0.351584646688712)*1/n^1.01646567502486;
    if 0.500 <= alpha & alpha<=0.875
        fp_alpha_n=fp_500_n+(fp_875_n-fp_500_n)/0.375*(alpha-0.500);
        fp_alpha_n=sqrt(fp_alpha_n);
    end
    if 0.875 < alpha & alpha < 1
        fp_alpha_n=fp_875_n+(1-fp_875_n)/0.125*(alpha-0.875);
        fp_alpha_n=sqrt(fp_alpha_n);
    end
else
    if p==1
        if intercept==1
            fp_500_n=1-exp(0.630869217886906)*1/n^0.650789250442946;
            fp_875_n=1-exp(0.565065391014791)*1/n^1.03044199012509;
        else
            fp_500_n=1-exp(-0.0181777452315321)*1/n^0.697629772271099;
            fp_875_n=1-exp(-0.310122738776431)*1/n^1.06241615923172;
        end
    end
    if p>1
        if intercept==1
            coefgqpkwad875=[-0.458580153984614,1.12236071104403,3;-0.267178168108996,1.1022478781154,5]';
            coefeqpkwad500=[-0.746945886714663,0.56264937192689,3;-0.535478048924724,0.543323462033445,5]';
        else
            coefgqpkwad875=[-0.251778730491252,0.883966931611758,3;-0.146660023184295,0.86292940340761,5]';
            coefeqpkwad500=[-0.487338281979106,0.405511279418594,3;-0.340762058011,0.37972360544988,5]';
        end
        y1_500=1+coefeqpkwad500(1,1)*1/p^coefeqpkwad500(2,1);
        y2_500=1+coefeqpkwad500(1,2)*1/p^coefeqpkwad500(2,2);
        y1_875=1+coefgqpkwad875(1,1)*1/p^coefgqpkwad875(2,1);
        y2_875=1+coefgqpkwad875(1,2)*1/p^coefgqpkwad875(2,2);
        y1_500=log(1-y1_500);
        y2_500=log(1-y2_500);
        y_500=[y1_500;y2_500];
        A_500=[1,log(1/(coefeqpkwad500(3,1)*p^2));1,log(1/(coefeqpkwad500(3,2)*p^2))];
        coeffic_500=A_500\y_500;
        y1_875=log(1-y1_875);
        y2_875=log(1-y2_875);
        y_875=[y1_875;y2_875];
        A_875=[1,log(1/(coefgqpkwad875(3,1)*p^2));1,log(1/(coefgqpkwad875(3,2)*p^2))];
        coeffic_875=A_875\y_875;
        fp_500_n=1-exp(coeffic_500(1))*1/n^coeffic_500(2);
        fp_875_n=1-exp(coeffic_875(1))*1/n^coeffic_875(2);
    end
    if 0.500 <= alpha & alpha <= 0.875
        fp_alpha_n=fp_500_n+(fp_875_n-fp_500_n)/0.375*(alpha-0.500);
    end
    if 0.875 < alpha & alpha<1
        fp_alpha_n=fp_875_n+(1-fp_875_n)/0.125*(alpha-0.875);
    end
end
rawcorfaclts=1/fp_alpha_n;

%---------------------------------------------------------------

function rewcorfaclts=rewcorfactorlts(p,intercept,n,alpha)

if intercept==1
    p=p-1;
end
if p==0
    fp_500_n=1-exp(1.11098143415027)*1/n^1.5182890270453;
    fp_875_n=1-exp(-0.66046776772861)*1/n^0.88939595831888;
    if 0.500 <= alpha & alpha <= 0.875
        fp_alpha_n=fp_500_n+(fp_875_n-fp_500_n)/0.375*(alpha-0.500);
        fp_alpha_n=sqrt(fp_alpha_n);
    end
    if 0.875 < alpha & alpha < 1
        fp_alpha_n=fp_875_n+(1-fp_875_n)/0.125*(alpha-0.875);
        fp_alpha_n=sqrt(fp_alpha_n);
    end
else
    if p==1
        if intercept==1
            fp_500_n=1-exp(1.58609654199605)*1/n^1.46340162526468;
            fp_875_n=1-exp(0.391653958727332)*1/n^1.03167487483316;
        else
            fp_500_n=1-exp(0.6329852387657)*1/n^1.40361879788014;
            fp_875_n=1-exp(-0.642240988645469)*1/n^0.926325452943084;
        end
    end
    if p>1
        if intercept==1
            coefqpkwad875=[-0.474174840843602,1.39681715704956,3;-0.276649353112907,1.42543242287677,5]';
            coefqpkwad500=[-0.773365715932083,2.02013996406346,3;-0.337571678986723,2.02037467454833,5]';
        else
            coefqpkwad875=[-0.267522855927958,1.17559984533974,3;-0.161200683014406,1.21675019853961,5]';
            coefqpkwad500=[-0.417574780492848,1.83958876341367,3;-0.175753709374146,1.8313809497999,5]';
        end
        y1_500=1+coefqpkwad500(1,1)*1/p^coefqpkwad500(2,1);
        y2_500=1+coefqpkwad500(1,2)*1/p^coefqpkwad500(2,2);
        y1_875=1+coefqpkwad875(1,1)*1/p^coefqpkwad875(2,1);
        y2_875=1+coefqpkwad875(1,2)*1/p^coefqpkwad875(2,2);
        y1_500=log(1-y1_500);
        y2_500=log(1-y2_500);
        y_500=[y1_500;y2_500];
        A_500=[1,log(1/(coefqpkwad500(3,1)*p^2));1,log(1/(coefqpkwad500(3,2)*p^2))];
        coeffic_500=A_500\y_500;
        y1_875=log(1-y1_875);
        y2_875=log(1-y2_875);
        y_875=[y1_875;y2_875];
        A_875=[1,log(1/(coefqpkwad875(3,1)*p^2));1,log(1/(coefqpkwad875(3,2)*p^2))];
        coeffic_875=A_875\y_875;
        fp_500_n=1-exp(coeffic_500(1))*1/n^coeffic_500(2);
        fp_875_n=1-exp(coeffic_875(1))*1/n^coeffic_875(2);
    end
    if 0.500 <= alpha & alpha <= 0.875
        fp_alpha_n=fp_500_n+(fp_875_n-fp_500_n)/0.375*(alpha-0.500);
    end
    if 0.875 < alpha & alpha < 1
        fp_alpha_n=fp_875_n+(1-fp_875_n)/0.125*(alpha-0.875);
    end
end
rewcorfaclts=1/fp_alpha_n;

%---------------------------------------------------------------

function rawcorfacmcd=rawcorfactormcd(n,alpha)

fp_500_n=1-(exp(0.262024211897096)*1)/n^0.604756680630497;
fp_875_n=1-(exp(-0.351584646688712)*1)/n^1.01646567502486;
if 0.5 <= alpha & alpha <= 0.875
    fp_alpha_n=fp_500_n+(fp_875_n-fp_500_n)/0.375*(alpha-0.5);
end
if 0.875 < alpha & alpha < 1
    fp_alpha_n=fp_875_n+(1-fp_875_n)/0.125*(alpha-0.875);
end
rawcorfacmcd=1/fp_alpha_n;

%---------------------------------------------------------------

function rawconsfacmcd=rawconsfactormcd(quan,n)

qalpha=qchisq(quan/n,1);
calphainvers=pgamma(qalpha/2,1/2+1)/(quan/n);
calpha=1/calphainvers;
rawconsfacmcd=calpha;

%--------------------------------------------------------------

function rewconsfaclts=rewconsfactorlts(weights,n,p)

if sum(weights)==n
    cdelta_rew=1;
else
    if p==0
        qdelta_rew=qchisq(sum(weights)/n,1);
        cdeltainvers_rew=pgamma(qdelta_rew/2,1/2+1)/(sum(weights)/n);
        cdelta_rew=sqrt(1/cdeltainvers_rew);
    else
        cdelta_rew=(1/sqrt(1-((2*n)/(sum(weights)*(1/qnorm((sum(weights)+n)/(2*n)))))...
            *dnorm(1/(1/(qnorm((sum(weights)+n)/(2*n)))))));
    end
end
rewconsfaclts=cdelta_rew;

%-------------------------------------------------------------

function rawconsfaclts=rawconsfactorlts(quan,n)

rawconsfaclts=(1/sqrt(1-((2*n)/(quan*(1/qnorm((quan+n)/(2*n)))))*...
    dnorm(1/(1/(qnorm((quan+n)/(2*n)))))));

%--------------------------------------------------------------

function x = qchisq(p,a)
%QCHISQ   The chisquare inverse distribution function
%
%         x = qchisq(p,DegreesOfFreedom)

%        Anders Holtsberg, 18-11-93
%        Copyright (c) Anders Holtsberg

if any(any(abs(2*p-1)>1))
    error('A probability should be 0<=p<=1, please!')
end
if any(any(a<=0))
    error('DegreesOfFreedom is wrong')
end

x = qgamma(p,a*0.5)*2;

%-----------------------------------------------------------------------------------------

function x = qgamma(p,a)
%QGAMMA   The gamma inverse distribution function
%
%         x = qgamma(p,a)

%        Anders Holtsberg, 18-11-93
%        Copyright (c) Anders Holtsberg

if any(any(abs(2*p-1)>1))
    error('A probability should be 0<=p<=1, please!')
end
if any(any(a<=0))
    error('Parameter a is wrong')
end

x = max(a-1,0.1);
dx = 1;
while any(any(abs(dx)>256*eps*max(x,1)))
    dx = (pgamma(x,a) - p) ./ dgamma(x,a);
    x = x - dx;
    x = x + (dx - x) / 2 .* (x<0);
end

I0 = find(p==0);
x(I0) = zeros(size(I0));
I1 = find(p==1);
x(I1) = zeros(size(I1)) + Inf;

%-----------------------------------------------------------------------------------------

function f = dgamma(x,a)
%DGAMMA   The gamma density function
%
%         f = dgamma(x,a)

%       Anders Holtsberg, 18-11-93
%       Copyright (c) Anders Holtsberg

if any(any(a<=0))
    error('Parameter a is wrong')
end

f = x .^ (a-1) .* exp(-x) ./ gamma(a);
I0 = find(x<0);
f(I0) = zeros(size(I0));

%-----------------------------------------------------------------------------------------

function F = pgamma(x,a)
%PGAMMA   The gamma distribution function
%
%         F = pgamma(x,a)

%       Anders Holtsberg, 18-11-93
%       Copyright (c) Anders Holtsberg

if any(any(a<=0))
    error('Parameter a is wrong')
end

F = gammainc(x,a);
I0 = find(x<0);
F(I0) = zeros(size(I0));

%-----------------------------------------------------------------------------------------

function x = qt(p,a)
%QT       The student t inverse distribution function
%
%         x = qt(p,DegreesOfFreedom)

%       Anders Holtsberg, 18-11-93
%       Copyright (c) Anders Holtsberg

s = p<0.5;
p = p + (1-2*p).*s;
p = 1-(2*(1-p));
x = qbeta(p,1/2,a/2);
x = x.*a./((1-x));
x = (1-2*s).*sqrt(x);

%------------------------------------------------------------------------------------------

function x = qbeta(p,a,b)
%QBETA    The beta inverse distribution function
%
%         x = qbeta(p,a,b)

%       Anders Holtsberg, 27-07-95
%       Copyright (c) Anders Holtsberg

if any(any((a<=0)|(b<=0)))
    error('Parameter a or b is nonpositive')
end
if any(any(abs(2*p-1)>1))
    error('A probability should be 0<=p<=1, please!')
end
b = min(b,100000);

x = a ./ (a+b);
dx = 1;
while any(any(abs(dx)>256*eps*max(x,1)))
    dx = (betainc(x,a,b) - p) ./ dbeta(x,a,b);
    x = x - dx;
    x = x + (dx - x) / 2 .* (x<0);
    x = x + (1 + (dx - x)) / 2 .* (x>1);
end

%-----------------------------------------------------------------------------------------

function d = dbeta(x,a,b)
%DBETA    The beta density function
%
%         f = dbeta(x,a,b)

%       Anders Holtsberg, 18-11-93
%       Copyright (c) Anders Holtsberg

if any(any((a<=0)|(b<=0)))
    error('Parameter a or b is nonpositive')
end

I = find((x<0)|(x>1));

d = x.^(a-1) .* (1-x).^(b-1) ./ beta(a,b);
d(I) = 0*I;

%----------------------------------------------------------------------------------------

