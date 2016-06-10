function [rew,raw,hsetsfull]=DetMCD(x,varargin)
% DetMCD computes the MCD estimator of a multivariate data set in a deterministic way.
% This estimator is given by the subset of h observations with smallest
% covariance determinant.  The MCD location estimate is then the mean of those h points,
% and the MCD scatter estimate is their covariance matrix.  The default value
% of h is roughly 0.75n (where n is the total number of observations), but the
% user may choose each value between n/2 and n. Based on the raw estimates,
% weights are assigned to the observations such that outliers get zero weight.
% The reweighted MCD estimator is then given by the mean and covariance matrix
% of the cases with non-zero weight. 
%
% To compute the MCD estimator, six initial robust h-subsets are
% constructed based on robust transformations of variables or robust and
% fast-to-compute estimators of multivariate location and shape. Then
% C-steps are applied on these h-subsets until convergence. Note that the
% resulting algorithm is not fully affine equivariant, but it is often
% faster than the FAST-MCD algorithm which is affine equivariant (see
% mcdcov.m). Note that this function can not handle exact fit
% situations: if the raw covariance matrix is singular, the program is
% stopped. In that case, it is recommended to apply the mcdcov.m function.
%
% Reference: 
%   Hubert, M., Rousseeuw, P.J. and Verdonck, T. (2012),
%   "A deterministic algorithm for robust location and scatter", Journal of
%   Computational and Graphical Statistics, in press.
% 
% The MCD method is intended for continuous variables, and assumes that
% the number of observations n is at least 5 times the number of variables p.
% If p is too large relative to n, it would be better to first reduce
% p by variable selection or robust principal components (see the functions
% robpca.m and rapca.m).
%
% Required input argument:
%    x : a vector or matrix whose columns represent variables, and rows represent observations.
%        Missing values (NaN's) and infinite values (Inf's) are allowed, since observations (rows)
%        with missing or infinite values will automatically be excluded from the computations.
%
% Optional input arguments:
%        cor : If non-zero, the robust correlation matrix will be
%              returned. The default value is 0.
%          h : The quantile of observations whose covariance determinant will
%              be minimized.  Any value between n/2 and n may be specified.
%              The default value is 0.75*n.
%      alpha : (1-alpha) measures the fraction of outliers the algorithm should
%              resist. Any value between 0.5 and 1 may be specified. (default = 0.75)
%  scale_est : for choosing the scale estimator. Default value (1) is to use the Qn
%              estimator for data with less than 1000 observations, and to use the
%              tau-scale for data sets with more observations. But one
%              can also always use the Qn estimator (scale_est=2)
%              or the tau scale (scale_est=3).
%      plots : If equal to one, a menu is shown which allows to draw several plots,
%              such as a distance-distance plot. (default)
%              If 'plots' is equal to zero, all plots are suppressed.
%              See also makeplot.m
%  hsetsfull : a matrix, where each row is a permutation of the numbers 1 up to the 
%              number of observations in the data set. Each row should correspond with 
%              an ordering of the observations, typically according to their statistical
%              distances. When this matrix is given, the first h elements of each row are 
%              used to start C-steps. Hence, the initial shape matrices are not computed.
%              This is in particular interesting to use if the MCD
%              estimates are to be computed for a range of h-values. Then
%              first apply DetMCD with alpha=1/2, store the 'hsetsfull' from
%              the output of this first run of the algorithm, and use it as input
%              for the other h-values.
%              Default value = NaN.
%    classic : If equal to one, the classical mean and covariance matrix are computed as well.
%              (default = 0)
%
% I/O: result=DetMCD(x,'alpha',0.5)
%  If only one output argument is listed, only the final result ('result')
%  is returned.
%  The user should only give the input arguments that have to change their default value.
%  The name of the input arguments needs to be followed by their value.
%  The order of the input arguments is of no importance.
%
% Examples: [rew,raw,hsetsfull]=DetMCD(x);
%           result=DetMCD(x,'h',20,'plots',0);
%
% The output structure 'raw' contains intermediate results, with the following
% fields :
%
%     raw.center : The raw MCD location of the data.
%        raw.cov : The raw MCD covariance matrix (multiplied by a
%                  consistency factor).
%        raw.cor : The raw MCD correlation matrix, if input argument 'cor' was non-zero.
%  raw.objective : The determinant of the raw MCD covariance matrix.
%         raw.rd : The robust distance of each observation to the raw MCD center, relative to 
%                  the raw MCD scatter estimate. 
%         raw.wt : Weights based on the estimated raw covariance matrix 'raw.cov' and
%                  the estimated raw location 'raw.center' of the data. These weights determine
%                  which observations are used to compute the final MCD estimates.
%
% The output structure 'rew' contains the final results, namely:
%
%       rew.center : The robust location of the data, obtained after
%                    reweighting.
%          rew.cov : The robust covariance matrix, obtained after
%                    reweighting.
%          rew.cor : The robust correlation matrix, obtained after reweighting, if
%                    options.cor was non-zero.
%            rew.h : The number of observations that have determined the MCD estimator,
%                    i.e. the value of h.
%     rew.Hsubsets : A structure that contains:
%                    i : if 'hsetsfull' is not given as input matrix, it yields the number 
%                        of the initial shape estimate which led to the
%                        optimal result. If 'hsetsfull' is given as input
%                        matrix, it gives the number of the row of
%                        'hsetsfull' which led to the optimal result.
%                    csteps: a vector indicating how many c-steps each initial h-subset needed
%                            to obtain convergence
%                    Hopt  : The subset of h points whose covariance matrix has minimal determinant,
%                            ordered following increasing robust distances.
%        rew.alpha : (1-alpha) measures the fraction of outliers the algorithm should
%                    resist.
%           rew.rd : The robust distance of each observation to the final,
%                    reweighted MCD center of the data, relative to the
%                    reweighted MCD scatter of the data.  These distances allow
%                    us to easily identify the outliers.
%       rew.cutoff : Cutoff values for the robust and Mahalanobis distances
%         rew.flag : Flags based on the reweighted covariance matrix and the
%                    reweighted location of the data.  These flags determine which
%                    observations can be considered as outliers. 
%        rew.class : 'MCDCOV'
%           rew.md : The Mahalanobis distance of each observation (distance from the classical
%                    center of the data, relative to the classical shape
%                    of the data).
%      rew.classic : If the input argument 'classic' is equal to one, this structure
%                    contains results of the classical analysis: center (sample mean),
%                    cov (sample covariance matrix), md (Mahalanobis distances), cutoff, class ('COV').
%            rew.X : If x is bivariate, same as the x in the call to DetMCD,
%                    without rows containing missing or infinite values.
%
% The output 'hsetsfull' is a matrix:
%   when 'hsetsfull' is not given as input variable, it consists of 6 rows, 
%   where each row contains the indices of the observations, ordered according 
%   to their robust distance to each initial shape estimate. Otherwise it
%   is the same as the input variable 'hsetsfull'.
%
% This function is part of LIBRA: the Matlab Library for Robust Analysis,
% available at:
%              http://wis.kuleuven.be/stat/robust.html
%
% Written by Tim Verdonck and Mia Hubert.
% Last update: 11/10/2011


%--------------------------------------------------------------------------
%Setting input parameters

if rem(nargin-1,2)~=0
    error('The number of input arguments should be odd!');
end
% Assigning some input parameters
data = x;
rew.plane=[];
raw.cor=[];
rew.cor=[];
if size(data,1)==1
    data=data';
end

% Observations with missing or infinite values are ommitted.
ok=all(isfinite(data),2);
data=data(ok,:);
xx=data;
[n,p]=size(data);

% Some checks are now performed.
if n==0
    error('All observations have missing or infinite values.')
end
if n < p
    error('Need at least (number of variables) observations.')
end

%internal variables
hmin=quanf(0.5,n,p);
%Assiging default values
h=quanf(0.75,n,p);
default=struct('alpha',0.75,'h',h,'plots',1,'scale_est',1,'cor',0,'hsetsfull',NaN,'classic',0);
list=fieldnames(default);
options=default;
IN=length(list);
i=1;
counter=1;

%Reading optional inputarguments
if nargin>2
    %
    % placing inputfields in array of strings
    %
    for j=1:nargin-1
        if rem(j,2)~=0
            chklist{i}=varargin{j};
            i=i+1;
        end
    end
    dummy=sum(strcmp(chklist,'h')+2*strcmp(chklist,'alpha'));
    switch dummy
        case 0 % default values should be taken
            alfa=options.alpha;
            h=options.h;
        case 3
            error('Both input arguments alpha and h are provided. Only one is required.')
    end
    %
    % Checking which default parameters have to be changed
    % and keep them in the structure 'options'.
    %
    while counter<=IN
        index=strmatch(list(counter,:),chklist,'exact');
        if ~isempty(index) % in case of similarity
            for j=1:nargin-2 % searching the index of the accompanying field
                if rem(j,2)~=0 % fieldnames are placed on odd index
                    if strcmp(chklist{index},varargin{j})
                        I=j;
                    end
                end
            end
            options=setfield(options,chklist{index},varargin{I+1});
            index=[];
        end
        counter=counter+1;
    end
    if dummy==1% checking inputvariable h
        % hmin is the minimum number of observations whose covariance determinant
        % will be minimized.

        if options.h < hmin
            disp(['Warning: The MCD must cover at least ' int2str(hmin) ' observations.'])
            disp(['The value of h is set equal to ' int2str(hmin)])
            options.h = hmin;
        elseif options.h > n
            error('h is greater than the number of non-missings and non-infinites.')
        elseif options.h < p
            error(['h should be larger than the dimension ' int2str(p) '.'])
        end

        options.alpha=options.h/n;
    elseif dummy==2
        if options.alpha < 0.5
            options.alpha=0.5;
            mess=sprintf(['Attention (detmcd.m): Alpha should be larger than 0.5. \n',...
                'It is set to 0.5.']);
            disp(mess)
        end
        if options.alpha > 1
            options.alpha=0.75;
            mess=sprintf(['Attention (detmcd.m): Alpha should be smaller than 1.\n',...
                'It is set to 0.75.']);
            disp(mess)
        end
        options.h=quanf(options.alpha,n,p);
    end
end

h=options.h;  %number of regular data points on which estimates are based. h=[alpha*n]
plots=options.plots; %relevant plots are plotted
alfa=options.alpha; %percentage of regular observations
scale_est=options.scale_est;
hsetsfull=options.hsetsfull;
cor=options.cor;

%--------------------------------------------------------------------------
%MAIN part


switch scale_est
    case 1
        if n>=1000
            scales='W_scale';
        else
            scales='qn';
        end
    case 2
        scales='qn';
    case 3
        scales='W_scale';
end

med=median(data);
sca=feval(scales,data);
ii=find((sca < eps),1);
if ~isempty(ii)
    error(['DetMCD.m: Variable ', int2str(ii), ' has zero scale. MCD can not be computed.']);
end
data=(data-repmat(med,n,1))./repmat(sca,n,1);
cutoff.rd=sqrt(chi2inv(0.975,p)); %cutoff value for the robust distance
cutoff.md=cutoff.rd; %cutoff value for the Mahalanobis distance
clmean=mean(data);
clcov=cov(data);

if p==1 
    [rew.center,rewsca,weights,raw.center,raw.cov,raw.rd,Hopt]=unimcd(data,h);
    rew.Hsubsets.Hopt = Hopt';
    raw.cov=raw.cov*sca^2;
    raw.objective=raw.cov;
    raw.center=raw.center*sca+med;
    raw.cutoff=cutoff.rd;
    raw.wt=weights;
    rew.cov=rewsca^2;
    mah=(data-rew.center).^2/rew.cov;
    rew.rd=sqrt(mah');
    rew.flag=(rew.rd<=cutoff.rd);
    rew.cutoff=cutoff.rd;
    rew.center=rew.center*sca+med;
    rew.cov=rew.cov*sca^2;
    rew.mahalanobis=abs(data'-clmean)/sqrt(clcov);
    
    %classical analysis?
    if options.classic==1
        classic.cov=clcov;
        classic.center=clmean;
        classic.md=rew.mahalanobis;
        classic.flag = (classic.md <= cutoff.md);
        classic.class='COV';
    else
        classic=0;
    end
    %assigning the output
    rewo=rew;rawo=raw;
    rew=struct('center',{rewo.center},'cov',{rewo.cov},'cor',{rewo.cor},'h',{h},'Hsubsets',{rewo.Hsubsets},...
        'alpha',{alfa},'rd',{rewo.rd},'cutoff',{cutoff},'flag',{rewo.flag}, 'plane',{rewo.plane},...
        'class',{'MCDCOV'},'md',{rewo.mahalanobis},'classic',{classic});
    raw=struct('center',{rawo.center},'cov',{rawo.cov},'cor',{rawo.cor},'objective',{rawo.objective},...
        'rd',{rawo.rd},'wt',{rawo.wt});
    if plots
        makeplot(rew);
    end
    return
end

if isnan(hsetsfull)
    hsetsfull=NaN(6,n);
    %Determining initial shape estimates
    
    %1) Hyperbolic tangent of standardized data
    y1=tanh(data);
    R1=corr(y1);
    [P,L]=eig(R1);
    ind=initset(data,scales,P,n,p);
    hsetsfull(1,:)=ind;
    
    %2) Spearmann correlation matrix
    y2=data;
    for j=1:p
        y2(:,j)=tiedrank(data(:,j));
    end
    R2=corr(y2);
    [P,L]=eig(R2);
    ind=initset(data,scales,P,n,p);
    hsetsfull(2,:)=ind;
    
    %3) Tukey normal scores
    y3=norminv((y2-1/3)/(n+1/3));
    R3=corr(y3);
    [P,L]=eig(R3);
    ind=initset(data,scales,P,n,p);
    hsetsfull(3,:)=ind;
    
    %4) Spatial sign covariance matrix
    znorm=sqrt(sum(data.^2,2));
    ii=znorm>eps;
    zznorm=data;
    zznorm(ii,:)=data(ii,:)./repmat(znorm(ii),1,p);
    SCM=(zznorm'*zznorm)./(n-1);
    [P,L]=eig(SCM);
    ind=initset(data,scales,P,n,p);
    hsetsfull(4,:)=ind;
    
    %5) BACON
    [~,ind5]=sort(znorm);
    half=ceil(n/2);
    Hinit=ind5(1:half);
    covx=cov(data(Hinit,:));
    [P,L]=eig(covx);
    ind=initset(data,scales,P,n,p);
    hsetsfull(5,:)=ind;
    
    %6) Raw OGK estimate for scatter
    P=ogkscatter(data,scales);
    ind=initset(data,scales,P,n,p);
    hsetsfull(6,:)=ind;
    
Isets=hsetsfull(:,1:half);
nIsets=size(Isets,1);

for k=1:nIsets
    xk=data(Isets(k,:),:);
    [P,T,L,r,centerX,meanvct] = classSVD(xk);
    if r < p
        error('DetMCD.m: More than half of the observations lie on a hyperplane.')
    end
    score=(data - repmat(meanvct,n,1))*P;
    [dis,sortdist]=sort(mahalanobis(score,zeros(size(score,2),1),'cov',L));
    hsetsfull(k,:)=sortdist;
end
    
end

% construction of h-subsets
nIsets=size(hsetsfull,1);
Hsets=hsetsfull(:,1:h);
%--------------------------------------------------------------------------
%Applying C-steps as in mcdcov.m

% Some initializations.
raw.wt=NaN(1,length(ok));
raw.rd=NaN(1,length(ok));
rew.rd=NaN(1,length(ok));
rew.mahalanobis=NaN(1,length(ok));
rew.flag=NaN(1,length(ok));

%nsamp=size(Hsets,1);
csteps=100;
prevdet=0;
bestobj=inf;
cutoff.rd=sqrt(chi2inv(0.975,p)); %cutoff value for the robust distance
cutoff.md=cutoff.rd; %cutoff value for the Mahalanobis distance

for i=1:nIsets
    for j=1:csteps
        if j==1
            obs_in_set=Hsets(i,:);
        else
            score=(data - repmat(meanvct,n,1))*P;
            mah=mahalanobis(score,zeros(size(score,2),1),'cov',L);
            [dis2,sortdist]=sort(mah);
            obs_in_set=sortdist(1:h);
        end
        [P,T,L,r,centerX,meanvct] = classSVD(data(obs_in_set,:));
        obj=prod(L);

        if r < p
            error('DetMCD.m: More than h of the observations lie on a hyperplane.');
        end
        if j >= 2 && obj == prevdet
            break;
        end
        prevdet=obj;

    end
    if obj < bestobj
        % bestset           : the best subset for the whole data.
        % bestobj           : objective value for this set.
        % initmean, initcov : resp. the mean and covariance matrix
        % of this set.
        bestset=obs_in_set;
        bestobj=obj;
        initmean=meanvct;
        initcov=P*diag(L)*P';
        raw.initcov=initcov;
        rew.Hsubsets.Hopt=bestset;
        rew.Hsubsets.i=i; %to determine which subset gives best results.
    end
    rew.Hsubsets.csteps(i)=j; %how many csteps necessary to converge.
end

[P,T,L,r,centerX,meanvct] = classSVD(data(bestset,:));
mah=mahalanobis((data - repmat(meanvct,n,1))*P,zeros(size(P,2),1),'cov',L);
sortmah=sort(mah);

factor = sortmah(h)/chi2inv(h/n,p);
raw.cov=factor*initcov;
% We express the results in the original units.
raw.cov=raw.cov.*repmat(sca,p,1).*repmat(sca',1,p);
raw.center=initmean.*sca+med;
raw.objective=bestobj*prod(sca)^2;
mah=mah/factor;
raw.rd=sqrt(mah);
weights=raw.rd<=cutoff.rd;
raw.wt=weights;
[rew.center,rew.cov]=weightmecov(data,weights);
trcov=rew.cov.*repmat(sca,p,1).*repmat(sca',1,p);
trcenter=rew.center.*sca+med;

mah=mahalanobis(data,rew.center,'cov',rew.cov);
rew.rd=sqrt(mah);
rew.flag=(rew.rd <= cutoff.rd);

rew.mahalanobis=sqrt(mahalanobis(data,clmean,'cov',clcov));
rawo=raw;
reso=rew;

if options.classic==1
    classic.center=clmean.*sca+med;
    classic.cov=clcov.*repmat(sca,p,1).*repmat(sca',1,p);
    classic.md=rew.mahalanobis;
    classic.flag = (classic.md <= cutoff.md);
    if cor==1
        diagcl=sqrt(diag(clcov));
        classic.cor=clcov./(diagcl*diagcl');
    end
    classic.class='COV';
    
else
    classic=0;
end
    
if cor==1
    diagraw=sqrt(diag(raw.cov));
    raw.cor=raw.cov./(diagraw*diagraw');
    diagrew=sqrt(diag(rew.cov));
    rew.cor=rew.cov./(diagrew*diagrew');
end

rew=struct('center',{trcenter},'cov',{trcov},'cor',{rew.cor},'h',{h},'Hsubsets',{reso.Hsubsets},'alpha',{alfa},...
    'rd',{reso.rd},'cutoff',{cutoff},'flag',{reso.flag},'plane',{reso.plane},...
    'class',{'MCDCOV'},'md',{reso.mahalanobis},'classic',{classic},'X',{xx});
raw=struct('center',{rawo.center},'cov',{rawo.cov},'cor',{raw.cor},'objective',{rawo.objective},...
    'rd',{rawo.rd},'cutoff',{cutoff},'wt',{rawo.wt});

if size(data,2)~=2
    rew=rmfield(rew,'X');
    raw=rmfield(raw,'X');
end

if plots
    makeplot(rew);
end
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%Some auxiliary functions:
%--------------------------------------------------------------------------
function quan=quanf(alfa,n,rk)
quan=floor(2*floor((n+rk+1)/2)-n+2*(n-floor((n+rk+1)/2))*alfa);
%--------------------------------------------------------------------------
function [scale]=W_scale(x)
c=4.5;
[n,p]=size(x);
Wc=inline('(1-(x./c).^2).^2.*(abs(x)<c)');
sigma0=mad(x,1);
w=Wc(c,(x-repmat(median(x),n,1))./repmat(sigma0,n,1));
loc=diag(x'*w)'./sum(w);

c=3;
rc=inline('min(x.^2,c^2)');
sigma0=mad(x,1);
b=c*norminv(3/4);
nes=n*(2*((1-b^2)*normcdf(b)-b*normpdf(b)+b^2)-1);
scale=sigma0.^2./nes.*sum(rc(c,(x-repmat(loc,n,1))./repmat(sigma0,n,1)));
scale=sqrt(scale);
%--------------------------------------------------------------------------
function [P,L]=ogkscatter(x,scales)

[n,p]=size(x);
U=eye(p);
for i=1:p
    sYi=x(:,i);
    for j=1:(i-1)
        sYj=x(:,j);
        sY=sYi+sYj;
        dY=sYi-sYj;
        U(i,j)= 0.25*(feval(scales,sY)^2-feval(scales,dY)^2);
    end
end
U=tril(U,-1)+U';
[P,L]=eig(U);

%--------------------------------------------------------------------------
function [ind]=initset(data,scales,P,n,p)

lambda=feval(scales,data*P);
sqrtcov=P*diag(lambda)*P';
sqrtinvcov=P*diag(1./lambda)*P';
estloc=median(data*sqrtinvcov)*sqrtcov;
centeredx=(data-repmat(estloc,n,1))*P;
[~,ind]=sort(mahalanobis(centeredx,zeros(p,1),'cov',diag(lambda).^2));
