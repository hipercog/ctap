function [res,raw]=fastmcd(data,options);

% version 22/12/2000, revised 19/01/2001, 
% new reweighted correction factors and old cutoff 9/07/2001
% last revision 20/04/2006
%
% FASTMCD computes the MCD estimator of a multivariate data set.  This 
% estimator is given by the subset of h observations with smallest covariance 
% determinant.  The MCD location estimate is then the mean of those h points,
% and the MCD scatter estimate is their covariance matrix.  The default value 
% of h is roughly 0.75n (where n is the total number of observations), but the 
% user may choose each value between n/2 and n.
%
% The MCD method is intended for continuous variables, and assumes that 
% the number of observations n is at least 5 times the number of variables p. 
% If p is too large relative to n, it would be better to first reduce
% p by variable selection or principal components.
%
% The MCD method was introduced in:
%
%   Rousseeuw, P.J. (1984), "Least Median of Squares Regression," 
%   Journal of the American Statistical Association, Vol. 79, pp. 871-881.
%
% The MCD is a robust method in the sense that the estimates are not unduly 
% influenced by outliers in the data, even if there are many outliers. 
% Due to the MCD's robustness, we can detect outliers by their large
% robust distances. The latter are defined like the usual Mahalanobis
% distance, but based on the MCD location estimate and scatter matrix
% (instead of the nonrobust sample mean and covariance matrix).
%
% The FASTMCD algorithm uses several time-saving techniques which 
% make it available as a routine tool to analyze data sets with large n,
% and to detect deviating substructures in them. A full description of the 
% algorithm can be found in:
%
%   Rousseeuw, P.J. and Van Driessen, K. (1999), "A Fast Algorithm for the 
%   Minimum Covariance Determinant Estimator," Technometrics, 41, pp. 212-223.
%
% An important feature of the FASTMCD algorithm is that it allows for exact 
% fit situations, i.e. when more than h observations lie on a (hyper)plane. 
% Then the program still yields the MCD location and scatter matrix, the latter
% being singular (as it should be), as well as the equation of the hyperplane.
%
% Usage:
%   [res,raw]=fastmcd(data,options)                                       
%
% If only one output argument is listed, only the final result ('res') is returned.
% The first input argument 'data' is a vector or matrix.  Columns represent 
% variables, and rows represent observations.  Missing values (NaN's) and 
% infinite values (Inf's) are allowed, since observations (rows) with missing 
% or infinite values will automatically be excluded from the computations.
%
% The second input argument 'options' is a structure.  It specifies certain 
% parameters of the algorithm:
%                                                           
%  options.cor: If non-zero, the robust correlation matrix will be 
%               returned. The default value is 0.      
%  options.alpha: The percentage of observations whose covariance determinant will 
%                 be minimized.  Any value between 0.5 and 1 may be specified.
%                 The default value is 0.75.
%  options.ntrial: The number of random trial subsamples that are drawn for 
%                  large datasets. The default is 500.  
%
% The output structure 'raw' contains intermediate results, with the following 
% fields :
%
%  raw.center: The raw MCD location of the data.
%  raw.cov: The raw MCD covariance matrix (multiplied by a finite sample 
%           correction factor and an asymptotic consistency factor).
%  raw.cor: The raw MCD correlation matrix, if options.cor was non-zero.
%  raw.objective: The determinant of the raw MCD covariance matrix.
%  raw.robdist: The distance of each observation from the raw MCD location
%               of the data, relative to the raw MCD scatter matrix 'raw.cov' 
%  raw.wt: Weights based on the estimated raw covariance matrix 'raw.cov' and 
%          the estimated raw location of the data. These weights determine 
%          which observations are used to compute the final MCD estimates. 
%
% The output structure 'res' contains the final results, namely:
%
%  res.n_obs: The number of data observations (without missing values).
%  res.quan: The number of observations that have determined the MCD estimator, 
%            i.e. the value of h. 
%  res.mahalanobis:  The distance of each observation from the classical
%                    center of the data, relative to the classical shape
%                    of the data. Often, outlying points fail to have a
%                    large Mahalanobis distance because of the masking
%                    effect.
%  res.center: The robust location of the data, obtained after reweighting, if 
%              the raw MCD is not singular.  Otherwise the raw MCD center is 
%              given here.
%  res.cov: The robust covariance matrix, obtained after reweighting and 
%           multiplying with a finite sample correction factor and an asymptotic
%           consistency factor, if the raw MCD is not singular.  Otherwise the 
%           raw MCD covariance matrix is given here.
%  res.cor: The robust correlation matrix, obtained after reweighting, if 
%           options.cor was non-zero.
%  res.method: A character string containing information about the method and 
%              about singular subsamples (if any). 
%  res.robdist:  The distance of each observation to the final,
%                reweighted MCD center of the data, relative to the
%                reweighted MCD scatter of the data.  These distances allow
%                us to easily identify the outliers. If the reweighted MCD
%                is singular, raw.robdist is given here.
%  res.flag: Flags based on the reweighted covariance matrix and the 
%            reweighted location of the data.  These flags determine which 
%            observations can be considered as outliers. If the reweighted
%            MCD is singular, raw.wt is given here.
%  res.plane:  In case of an exact fit, res.plane contains the coefficients
%              of a (hyper)plane a_1(x_i1-m_1)+...+a_p(x_ip-m_p)=0 
%              containing at least h observations, where (m_1,...,m_p)
%              is the MCD location of these observations.
%  res.X: The data matrix. Rows containing missing or infinite values are 
%         ommitted. 
%
% FASTMCD also automatically calls the function PLOTMCD which creates plots for 
% visualizing outliers detected by FASTMCD. The plots that can be produced are:
%
% 1. Plot of Mahalanobis distances versus case number.
% 2. Plot of robust distances versus case number. 
% 3. QQ plot: shows robust distances versus chi-squared quantiles.
% 4. Robust distances versus Mahalanobis distances (i.e. the D-D plot).
% 5. The 97.5% robust tolerance ellipse (if the dataset is bivariate).
%
% Usage:
%     plotmcd(mcdres,options)
%
% The first input argument 'mcdres' is the output argument of the function 
% FASTMCD. The second input argument 'options' is a structure containing:
%                                                           
%  options.ask: A logical flag: if set to 0, all plots are produced sequentially;
%               if set to 1, PLOTMCD displays a menu listing all the plots that 
%               can be produced. The default value is 1. 
%  options.nid: Number of points (must be less than n) to be highlighted in the 
%               appropriate plots. These will be the 'nid' most extreme points,
%               i.e. those with largest robust distance.  
%  options.xlab: Label of the X-axis in the MCD tolerance ellipse plot.
%  options.ylab: Label of the Y-axis in the MCD tolerance ellipse plot.


% The fastmcd algorithm works as follows:
%
%       The dataset contains n cases and p variables. 
%       When n < 2*nmini (see below), the algorithm analyzes the dataset as a whole.
%       When n >= 2*nmini (see below), the algorithm uses several subdatasets.
%
%       When the dataset is analyzed as a whole, a trial subsample of p+1 cases 
%       is taken, of which the mean and covariance matrix are calculated. 
%       The h cases with smallest relative distances are used to calculate 
%       the next mean and covariance matrix, and this cycle is repeated csteps1 
%       times. For small n we consider all subsets of p+1 out of n, otherwise
%       the algorithm draws 500 random subsets by default.
%       Afterwards, the 10 best solutions (means and corresponding covariance 
%       matrices) are used as starting values for the final iterations. 
%       These iterations stop when two subsequent determinants become equal. 
%       (At most csteps3 iteration steps are taken.) The solution with smallest 
%       determinant is retained. 
%
%       When the dataset contains more than 2*nmini cases, the algorithm does part 
%       of the calculations on (at most) maxgroup nonoverlapping subdatasets, of 
%       (roughly) maxobs cases. 
%
%       Stage 1: For each trial subsample in each subdataset, csteps1 (see below) iterations are 
%       carried out in that subdataset. For each subdataset, the 10 best solutions are 
%       stored.   
%       
%       Stage 2 considers the union of the subdatasets, called the merged set. 
%       (If n is large, the merged set is a proper subset of the entire dataset.) 
%       In this merged set, each of the 'best solutions' of stage 1 are used as starting 
%       values for csteps2 (sse below) iterations. Also here, the 10 best solutions are stored.
%
%       Stage 3 depends on n, the total number of cases in the dataset. 
%       If n <= 5000, all 10 preliminary solutions are iterated. 
%       If n > 5000, only the best preliminary solution is iterated. 
%       The number of iterations decreases to 1 according to n*p (If n*p <= 100,000 we 
%       iterate csteps3 (sse below) times, whereas for n*p > 1,000,000 we take only one iteration step). 


% The maximum value for n (= number of observations) is:
nmax=50000;

% The maximum value for p (= number of variables) is:
pmax=50;

% To change the number of subdatasets and their size, the values of 
% maxgroup and nmini can be changed. 
maxgroup=5;
nmini=300;

% The number of iteration steps in stages 1,2 and 3 can be changed
% by adapting the parameters csteps1, csteps2, and csteps3.
csteps1=2;
csteps2=2;
csteps3=100;

% dtrial : number of subsamples if not all (p+1)-subsets will be considered. 
dtrial=500;

% The 0.975 quantile of the chi-squared distribution.
chi2q=[5.02389,7.37776,9.34840,11.1433,12.8325,...
       14.4494,16.0128,17.5346,19.0228,20.4831,21.920,23.337,...
       24.736,26.119,27.488,28.845,30.191,31.526,32.852,34.170,...
       35.479,36.781,38.076,39.364,40.646,41.923,43.194,44.461,...
       45.722,46.979,48.232,49.481,50.725,51.966,53.203,54.437,...
       55.668,56.896,58.120,59.342,60.561,61.777,62.990,64.201,...
       65.410,66.617,67.821,69.022,70.222,71.420];
 
% Median of the chi-squared distribution. 
chimed=[0.454937,1.38629,2.36597,3.35670,4.35146,...
       5.34812,6.34581,7.34412,8.34283,9.34182,10.34,11.34,12.34,...
       13.34,14.34,15.34,16.34,17.34,18.34,19.34,20.34,21.34,22.34,...
       23.34,24.34,25.34,26.34,27.34,28.34,29.34,30.34,31.34,32.34,...
       33.34,34.34,35.34,36.34,37.34,38.34,39.34,40.34,41.34,42.34,...
       43.34,44.34,45.34,46.34,47.33,48.33,49.33];


seed=0;
quan=0;
alpha=0.75;
file=0;

% The value of the fields of the input argument OPTIONS are now determined.
% If the user hasn't given a value to one of the fields, the default value 
% is assigned to it.
if nargin==1
   cor=0;
   ntrial=dtrial;
   lts=0;
elseif isstruct(options) 
   names=fieldnames(options);
      
	if strmatch('cor',names,'exact')
      cor=options.cor;
   else
      cor=0;
	end

	if strmatch('alpha',names,'exact')
      quan=1;
      alpha=options.alpha;
	end

	if strmatch('ntrial',names,'exact')
   	ntrial=options.ntrial;
	else
   	ntrial=dtrial;
   end
   
   if strmatch('lts',names,'exact')
      lts=options.lts;
   else
      lts=0;
   end
   
else
   error('The second input argument is not a structure.')
end   

if size(data,1)==1 
   data=data';
end   

% Observations with missing or infinite values are ommitted. 
ok=all(isfinite(data),2);
data=data(ok,:);
n=size(data,1);
p=size(data,2);

% Some checks are now performed.
if n==0
   error('All observations have missing or infinite values.')
end

if n > nmax
   error(['The program allows for at most ' int2str(nmax) ' observations.'])
end

if p > pmax
   error(['The program allows for at most ' int2str(pmax) ' variables.'])
end

if n < 2*p
   error('Need at least 2*(number of variables) observations.')
end

% hmin is the minimum number of observations whose covariance determinant 
% will be minimized.  
hmin=quanf(0.5,n,p);

if ~quan
   h=quanf(0.75,n,p);
else
   h=quanf(alpha,n,p);
   if h < hmin                                                      
      error(['The MCD must cover at least ' int2str(hmin) ' observations.'])
   elseif h > n
      error('quan is greater than the number of non-missings and non-infinites.')
   end
end

fid=NaN;

% The value of some fields of the output argument are already known.
res.n_obs=n;
res.quan=h;
res.X=data;

% Some initializations.
res.flag=repmat(NaN,1,length(ok));
raw.wt=repmat(NaN,1,length(ok));
raw.robdist=repmat(NaN,1,length(ok));
res.robdist=repmat(NaN,1,length(ok));
res.mahalanobis=repmat(NaN,1,length(ok));
if ~lts
   res.method=sprintf('\nMinimum Covariance Determinant Estimator.');
else
   res.method=sprintf('\nThe function fastmcd.m is called to compute robust distances.');
end   
correl=NaN;

%    z    : if at least h observations lie on a hyperplane, then z contains the 
%           coefficients of that plane.  
% weights : weights of the observations that are not excluded from the computations. 
%           These are the observations that don't contain missing or infinite values.
% bestobj : best objective value found.
z(1:p)=0;
weights=zeros(1,n);
bestobj=inf;

% The breakdown point of the MCD estimator is computed. 
if h==hmin
   %the breakdown point is maximal.
   breakdown=(h-p)*100/n;
else
   breakdown=(n-h+1)*100/n;
end

% The classical estimates are computed.    
clasmean=mean(data);
clascov=cov(data);   

if p < 5
   eps=1e-12;
elseif p <= 8
   eps=1e-14;
else
   eps=1e-16;
end

% The standardization of the data will now be performed.
med=median(data);
mad=sort(abs(data-repmat(med,n,1)));
mad=mad(h,:);
ii=min(find(mad < eps));
if length(ii) 
   % The h-th order statistic is zero for the ii-th variable. The array plane contains
   % all the observations which have the same value for the ii-th variable.
   plane=find(abs(data(:,ii)-med(ii)) < eps)';
   meanplane=mean(data(plane,:));
   weights(plane)=1;
   if p==1
      res.flag=weights;
      raw.wt=weights;
      [raw.center,res.center]=deal(meanplane);
      [raw.cov,res.cov,raw.objective]=deal(0);
      if ~lts
         res.method=sprintf('\nUnivariate location and scale estimation.');   
         res.method=strvcat(res.method,sprintf('%g of the %g observations are identical.',length(plane),n));
         disp(res.method);
      end
   else
      z(ii)=1;
      res.plane=z;
      covplane=cov(data(plane,:));
      [raw.center,raw.cov,res.center,res.cov,raw.objective,raw.wt,res.flag,...
      res.method]=displ(3,length(plane),weights,n,p,meanplane,covplane,res.method,z,ok,...
                        raw.wt,res.flag,file,fid,0,NaN,h,ii);
   end
   return
end         
data=(data-repmat(med,n,1))./repmat(mad,n,1);

% The standardized classical estimates are now computed.
clmean=mean(data);
clcov=cov(data);

% The univariate non-classical case is now handled.
if p==1 & h~=n
   if ~lts
      res.method=sprintf('\nUnivariate location and scale estimation.');
   end   
   [raw.center,raw.cov]=mcduni(data,n,h,n-h+1,alpha);
   scale=raw.cov./sqrt(rawconsfactor(h,n,p)*rawcorfactor(p,n,alpha));
   sor=sort((data-raw.center).^2);
   raw.objective=1/(h-1)*sum(sor(1:h))*prod(mad)^2;
   %m=2*n/asvardiag(h,n,p);
   %quantile=qf(0.975,p,m-p+1);
   quantile=chi2q(p);
   %weights=((data-raw.center)/scale).^2*(m-p+1)/(m*p)<quantile;
   weights=((data-raw.center)/scale).^2<quantile;
   raw.wt=weights;
   [res.center,res.cov]=weightmecov(data,weights,n,p);
   factor=rewconsfactor(weights,n,p);
   factor=factor*rewcorfactor(p,n,alpha);
   res.cov=factor*res.cov;
   mah=(data-res.center).^2/res.cov;
   mah_raw=(data-raw.center).^2/raw.cov;
   res.flag= mah <= chi2q(1);
   [raw.cov,raw.center]=trafo(raw.cov,raw.center,med,mad,p);
   [res.cov,res.center]=trafo(res.cov,res.center,med,mad,p);   
   res.mahalanobis=abs(data'-clmean)/sqrt(clcov);
   raw.robdist=sqrt(mah_raw');
   res.robdist=sqrt(mah');
   if ~lts
      disp(res.method);
   end
   
   spec.ask=1;
   if ~lts
      plotmcd(res,spec);
   end

   return
end

if det(clascov) < exp(-50*p)
   % all observations lie on a hyperplane.
   [z, eigvl]=eigs(clcov,1,0,struct('disp',0));
   res.plane=z;
   weights(1:n)=1;
   if cor
      correl=clcov./(sqrt(diag(clcov))*sqrt(diag(clcov))');
   end
   [clcov,clmean]=trafo(clcov,clmean,med,mad,p);
   [raw.center,raw.cov,res.center,res.cov,raw.objective,raw.wt,res.flag,...
   res.method]=displ(1,n,weights,n,p,clmean,clcov,res.method,z./mad',ok,...
                     raw.wt,res.flag,file,fid,cor,correl);   
   if cor
      [res.cor,raw.cor]=deal(correl);
   end                                 
   return
end

% The classical case is now handled.
if h==n
   if ~lts
      msg=sprintf('The MCD estimates based on %g observations are equal to the classical estimates.\n',h);
      res.method=strvcat(res.method,msg);
   end   
   raw.center=clmean;
   raw.cov=clcov;
   raw.objective=det(clcov);
   mah=mahalanobis(data,clmean,clcov,n,p);
   res.mahalanobis=sqrt(mah);
   raw.robdist=res.mahalanobis;
   weights=mah <= chi2q(p);
   raw.wt=weights;
   [res.center,res.cov]=weightmecov(data,weights,n,p)
   if cor
      raw.cor=raw.cov./(sqrt(diag(raw.cov))*sqrt(diag(raw.cov))');
      res.cor=res.cov./(sqrt(diag(res.cov))*sqrt(diag(res.cov))');
   end
   if det(res.cov) < exp(-50*p)
      [center,covar,z,correl,plane,count]=fit(data,NaN,med,mad,p,z,cor,res.center,res.cov,n);  
      res.plane=z;
      if cor
         correl=covar./(sqrt(diag(covar))*sqrt(diag(covar))');
      end 
      res.method=displrw(count,n,p,center,covar,res.method,file,z,fid,cor,correl);   
      [raw.cov,raw.center]=trafo(raw.cov,raw.center,med,mad,p);
      [res.cov,res.center]=trafo(res.cov,res.center,med,mad,p);
      res.robdist=raw.robdist;
   else
      mah=mahalanobis(data,res.center,res.cov,n,p);
      weights=mah <= chi2q(p);
      [raw.cov,raw.center]=trafo(raw.cov,raw.center,med,mad,p);
      [res.cov,res.center]=trafo(res.cov,res.center,med,mad,p);   
      res.robdist=sqrt(mah);
   end   
   raw.objective=raw.objective*prod(mad)^2;
   res.flag=weights;
   if ~lts
      disp(res.method)
   end   
   
   spec.ask=1;
   if ~lts
      plotmcd(res,spec);
   end

   return
end

percent=h/n;

%  If n >= 2*nmini the dataset will be divided into subdatasets.  For n < 2*nmini the set 
%  will be treated as a whole. 

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
   adjh=floor(group(1)*percent);
   nsamp=floor(ntrial/ngroup);
   minigr=sum(group);   
   obsingroup=fillgroup(n,group,ngroup,seed,fid);
   % obsingroup : i-th row contains the observations of the i-th group.  
   % The last row (ngroup+1-th) contains the observations for the 2nd stage 
   % of the algorithm.

else 
   
   [part,group,ngroup,adjh,minigr,obsingroup]=deal(0,n,1,h,n,n);
   replow=[50,22,17,15,14,zeros(1,45)];
   if n < replow(p)
      % All (p+1)-subsets will be considered. 
      al=1;
      perm=[1:p,p];
      nsamp=nchoosek(n,p+1);
   else
      al=0;
      nsamp=ntrial;
   end
   
end
   
% some further initialisations. 

csteps=csteps1;
inplane=NaN;
% tottimes : the total number of iteration steps.
% fine     : becomes 1 when the subdatasets are merged. 
% final    : becomes 1 for the final stage of the algorithm.     
[tottimes,fine,final,prevdet]=deal(0);

if part
   % bmean1 : contains, for the first stage of the algorithm, the means of the ngroup*10 
   %          best estimates. 
   % bcov1  : analogous to bmean1, but now for the covariance matrices. 
   % bobj1  : analogous to bmean1, but now for the objective values.
   % coeff1 : if in the k-th subdataset there are at least adjh observations that lie on  
   %          a hyperplane then the coefficients of this plane will be stored in the 
   %          k-th column of coeff1.
   coeff1=repmat(NaN,p,ngroup);
   bobj1=repmat(inf,ngroup,10);  
   bmean1=cell(ngroup,10);
	bcov1=cell(ngroup,10);
	[bmean1{:}]=deal(NaN);
	[bcov1{:}]=deal(NaN);
end

% bmean : contains the means of the ten best estimates obtained in the second stage of the
%         algorithm. 
% bcov  : analogous to bmean, but now for the covariance matrices.
% bobj  : analogous to bmean, but now for the objective values.
% coeff : analogous to coeff1, but now for the merged subdataset. 
% If the data is not split up, the 10 best estimates obtained after csteps1 iterations 
% will be stored in bmean, bcov and bobj.
coeff=repmat(NaN,p,1);
bobj=repmat(inf,1,10);
bmean=cell(1,10);
bcov=cell(1,10);
[bmean{:}]=deal(NaN);
[bcov{:}]=deal(NaN);
      
seed=0;



while final~=2
   
   
   if fine | (~part & final)
      
      nsamp=10;
         
    	if final                   
          
         adjh=h;
         ngroup=1;      
         
         if n*p <= 1e+5
            csteps=csteps3;
         elseif n*p <=1e+6
         	csteps=10-(ceil(n*p/1e+5)-2);
      	else
         	csteps=1;
      	end
         
         if n > 5000
         	nsamp=1;
         end          
         
      else             
         
         adjh=floor(minigr*percent);
         csteps=csteps2;
         
      end
      
   end
   
   % found : becomes 1 if we have a singular intermediate MCD estimate. 
   found=0;
   
   for k=1:ngroup
      
      if ~fine
         found=0;
      end
      
		for i=1:nsamp
         
         tottimes=tottimes+1;
         
         % ns becomes 1 if we have a singular trial subsample and if there are at 
         % least adjh observations in the subdataset that lie on the concerning hyperplane.  
         % In that case we don't have to take C-steps. The determinant is zero which is  
         % already the lowest possible value. If ns=1, no C-steps will be taken and we 
         % start with the next sample. If we, for the considered subdataset, haven't 
         % already found a singular MCD estimate, then the results must be first stored in 
         % bmean, bcov, bobj or in bmean1, bcov1 and bobj1.  If we, however, already found 
         % a singular result for that subdataset, then the results won't be stored 
         % (the hyperplane we just found is probably the same as the one we found earlier. 
         % We then let adj be zero. This will guarantee us that the results won't be 
         % stored) and we start immediately with the next sample. 
         adj=1;
         ns=0;
         
         % For the second and final stage of the algorithm the array sortdist(1:adjh) 
         % contains the indices of the observations corresponding to the adjh observations 
         % with minimal relative distances with respect to the best estimates of the 
         % previous stage. An exception to this, is when the estimate of the previous 
         % stage is singular.  For the second stage we then distinguish two cases :  
         % 
         % 1. There aren't adjh observations in the merged set that lie on the hyperplane. 
         %    The observations on the hyperplane are then extended to adjh observations by 
         %    adding the observations of the merged set with smallest orthogonal distances 
         %    to that hyperplane.  
         % 2. There are adjh or more observations in the merged set that lie on the 
         %    hyperplane. We distinguish two cases. We haven't or have already found such 
         %    a hyperplane. In the first case we start with a new sample.  But first, we 
         %    store the results in bmean1, bcov1 and bobj1. In the second case we 
         %    immediately start with a new sample.
         %
         % For the final stage we do the same as 1. above (if we had h or more observations 
         % on the hyperplane we would already have found it).

         if final
            if ~isinf(bobj(i))
            	meanvct=bmean{i};
            	covmat=bcov{i};
            	if bobj(i)==0  
                  [dis,sortdist]=sort(abs(sum((data-repmat(meanvct,n,1))'.*repmat(coeff,1,n))));
               else
                  sortdist=mahal(data,meanvct,covmat,part,fine,final,k,obsingroup,group,...
                                 minigr,n,p);
               end
            else
               break;
            end
         elseif fine 
            if ~isinf(bobj1(k,i))
               meanvct=bmean1{k,i};
            	covmat=bcov1{k,i};
            	if bobj1(k,i)==0  
               	[dis,ind]=sort(abs(sum((data(obsingroup{end},:)-repmat(meanvct,minigr,1))'.*repmat(coeff1(:,k),1,minigr))));
                  sortdist=obsingroup{end}(ind);
                  if dis(adjh) < 1e-8
                     if found==0
                     	obj=0;
                     	coeff=coeff1(:,k);
                     	found=1;
                  	else
                     	adj=0;
                  	end
                  	ns=1;
               	end
               else
                  sortdist=mahal(data,meanvct,covmat,part,fine,final,k,obsingroup,group,...
                                 minigr,n,p);
               end
            else
               break;
            end   
         else
            % The first stage of the algorithm.
            % index : contains trial subsample.
            if ~part
               if al
      				k=p+1;
      				perm(k)=perm(k)+1;
      				while ~(k==1 |perm(k) <=(n-(p+1-k))) 
         				k=k-1;
         				perm(k)=perm(k)+1;
							for j=(k+1):p+1
      						perm(j)=perm(j-1)+1;
   						end
      				end
                  index=perm;
               else
                  [index,seed]=randomset(n,p+1,seed);
                  
               end
            else
               [index,seed]=randomset(group(k),p+1,seed);
               index=obsingroup{k}(index);
            end
               
            meanvct=mean(data(index,:));
            covmat=cov(data(index,:));
   		
            if det(covmat) < exp(-50*p) 
               
               % The trial subsample is singular.
               % We distinguish two cases :
               %
               % 1. There are adjh or more observations in the subdataset that lie
               %    on the hyperplane. If the data is not split up, we have adjh=h and thus
               %    an exact fit. If the data is split up we distinguish two cases. 
               %    We haven't or have already found such a hyperplane.  In the first case
               %    we check if there are more than h observations in the entire set 
               %    that lie on the hyperplane. If so, we have an exact fit situation. 
               %    If not, we start with a new trial subsample.  But first, the 
               %    results must be stored bmean1, bcov1 and bobj1.  In the second case
               %    we immediately start with a new trial subsample.
               %   
               % 2. There aren't adjh observations in the subdataset that lie on the 
               %    hyperplane. We then extend the trial subsample until it isn't singular 
               %    anymore.
               
               
               % eigvct : contains the coefficients of the hyperplane.
               [eigvct, eigvl]=eigs(covmat,1,0,struct('disp',0));
                  
               if ~part
                  dist=abs(sum((data-repmat(meanvct,n,1))'.*repmat(eigvct,1,n)));
               else
                  dist=abs(sum((data(obsingroup{k},:)-repmat(meanvct,group(k),1))'.*repmat(eigvct,1,group(k))));
               end
                  
               obsinplane=find(dist < 1e-8);
               % count : number of observations that lie on the hyperplane.
               count=length(obsinplane);
               
               if count >= adjh               
                  
                  if ~part   
                     [center,covar,eigvct,correl]=fit(data,obsinplane,med,mad,p,eigvct,cor);
                     res.plane=eigvct;
                     weights(obsinplane)=1;
                     [raw.center,raw.cov,res.center,res.cov,raw.objective,...
                     raw.wt,res.flag,res.method]=displ(2,count,weights,n,p,center,covar,...
                     res.method,eigvct,ok,raw.wt,res.flag,file,fid,cor,correl);        
                     if cor
                        [res.cor,raw.cor]=deal(correl);
                     end
                     return
                  elseif found==0
                     dist=abs(sum((data-repmat(meanvct,n,1))'.*repmat(eigvct,1,n)));
                     obsinplane=find(dist < 1e-8);
                     count2=length(obsinplane);
                     if count2>=h
                        [center,covar,eigvct,correl]=fit(data,obsinplane,med,mad,p,eigvct,cor);
                        res.plane=eigvct;
                        weights(obsinplane)=1;
                        [raw.center,raw.cov,res.center,res.cov,raw.objective,...
                        raw.wt,res.flag,res.method,varargout]=displ(2,count2,weights,n,p,center,covar,...
                        res.method,eigvct,ok,raw.wt,res.flag,file,fid,cor,correl);        
                        if cor
                           [res.cor,raw.cor]=deal(correl);
                        end
                       return
                     end
                     obj=0;
                     inplane(k)=count;
                     coeff1(:,k)=eigvct;
                     found=1;
                     ns=1;                          
                  else 
                     ns=1;
                     adj=0;   
                  end
                     
               else
                  
                  while det(covmat) < exp(-50*p)
                     [index,seed]=addobs(index,n,seed);
                     covmat=cov(data(index,:));         
                  end
                  meanvct=mean(data(index,:));      
                     
               end             
            end     
            
            if ~ns
               sortdist=mahal(data,meanvct,covmat,part,fine,final,k,obsingroup,group,...
                              minigr,n,p);  
            end
         
         end
         
         if ~ns
                   
         	for j=1:csteps
         
               tottimes=tottimes+1;
               
               if j > 1
                  % The observations correponding to the adjh smallest mahalanobis 
                  % distances determine the subset for the next iteration.
                  sortdist=mahal(data,meanvct,covmat,part,fine,final,k,obsingroup,group,...
                     			   minigr,n,p);
            	end         
            
            	obs_in_set=sort(sortdist(1:adjh));
               meanvct=mean(data(obs_in_set,:));
               covmat=cov(data(obs_in_set,:));
               obj=det(covmat);
               
   	  			if obj < exp(-50*p) 
                    
                  % The adjh-subset is singular. If adjh=h we have an exact fit situation.
                  % If adjh < h we distinguish two cases :
                  %
                  % 1. We haven't found earlier a singular adjh-subset. We first check if 
                  %    in the entire set there are h observations that lie on the hyperplane.
                  %    If so, we have an exact fit situation. If not, we stop taking C-steps
                  %    (the determinant is zero which is the lowest possible value) and 
                  %    store the results in the appropriate arrays.  We then begin with 
                  %    the next trial subsample.
                  %
                  % 2. We have, for the concerning subdataset, already found a singular
                  %    adjh-subset. We then immediately begin with the next trial subsample.
                    
                  if ~part | final | (fine & n==minigr)
                     [center,covar,z,correl,obsinplane,count]=fit(data,NaN,med,mad,p,NaN,...
                                                           cor,meanvct,covmat,n);
                     res.plane=z;                                   
                     weights(obsinplane)=1;
                     [raw.center,raw.cov,res.center,res.cov,raw.objective,...
                     raw.wt,res.flag,res.method]=displ(2,count,weights,n,p,center,covar,...
                     res.method,z,ok,raw.wt,res.flag,file,fid,cor,correl);        
                     if cor
                        [res.cor,raw.cor]=deal(correl);
                     end
                     return                  
               	elseif found==0
                     [eigvct, eigvl]=eigs(covmat,1,0,struct('disp',0));           
                     dist=abs(sum((data-repmat(meanvct,n,1))'.*repmat(eigvct,1,n)));
                     obsinplane=find(dist<1e-8);
                     count=length(obsinplane);
                     if count >= h 
                        [center,covar,eigvct,correl]=fit(data,obsinplane,med,mad,p,eigvct,cor);
                        res.plane=eigvct;
                        weights(obsinplane)=1;
                        [raw.center,raw.cov,res.center,res.cov,raw.objective,...
                        raw.wt,res.flag,res.method]=displ(2,count,weights,n,p,center,covar,...
                        res.method,eigvct,ok,raw.wt,res.flag,file,fid,cor,correl);        
                        if cor
                           [res.cor,raw.cor]=deal(correl);
                        end
                       return
                  	end
                  	obj=0;
                     found=1;
                     if ~fine
                        coeff1(:,k)=eigvct;
                        dist=abs(sum((data(obsingroup{k},:)-repmat(meanvct,group(k),1))'.*repmat(eigvct,1,group(k))));
                        inplane(k)=length(dist(dist<1e-8));
                     else
                        coeff=eigvct;
                        dist=abs(sum((data(obsingroup{end},:)-repmat(meanvct,minigr,1))'.*repmat(eigvct,1,minigr)));
                        inplane=length(dist(dist<1e-8));
                     end
                     break;         
               	else 
                  	adj=0;
                  	break;
               	end
                  
               end
               
               % We stop taking C-steps when two subsequent determinants become equal.
               % We have then reached convergence.
               if j >= 2 & obj == prevdet
               	break;
            	end
               prevdet=obj;
            	            
            end % C-steps
            
         end
         
         
         % After each iteration, it has to be checked whether the new solution
         % is better than some previous one.  A distinction is made between the
         % different stages of the algorithm:
         %
         %  - Let us first consider the first (second) stage of the algorithm. 
         %    We distinguish two cases if the objective value is lower than the largest 
         %    value in bobj1 (bobj) : 
         %
         %      1. The new objective value did not yet occur in bobj1 (bobj).  We then store
         %         this value, the corresponding mean and covariance matrix at the right 
         %         place in resp. bobj1 (bobj), bmean1 (bmean) and bcov1 (bcov).
         %         The objective value is inserted by shifting the greater determinants 
         %         upwards. We perform the same shifting in bmean1 (bmean) and bcov1 (bcov). 
         %
         %      2. The new objective value already occurs in bobj1 (bobj). A comparison is 
         %         made between the new mean vector and covariance matrix and those 
         %         estimates with the same determinant. When for an equal determinant, 
         %         the mean vector or covariance matrix do not correspond, the new results  
         %         will be stored in bobj1 (bobj), bmean1 (bmean) and bcov1 (bcov).
         %
         %    If the objective value is not lower than the largest value in bobj1 (bobj), 
         %    nothing happens.
         %
         %  - For the final stage of the algorithm, only the best solution has to be kept.
         %    We then check if the objective value is lower than the till then lowest value. 
         %    If so, we have a new best solution. If not, nothing happens.
              
         
         if ~final & adj            
            if fine | ~part
               if obj < max(bobj)
                  [bmean,bcov,bobj]=insertion(bmean,bcov,bobj,meanvct,covmat,obj,1,eps);
               end   
            else
               if obj < max(bobj1(k,:))
                  [bmean1,bcov1,bobj1]=insertion(bmean1,bcov1,bobj1,meanvct,covmat,obj,k,eps);
               end    
            end         
         end
         
          if final & obj< bestobj
             % bestset           : the best subset for the whole data. 
             % bestobj           : objective value for this set.
             % initmean, initcov : resp. the mean and covariance matrix of this set.  
             bestset=obs_in_set;
             bestobj=obj;   
             initmean=meanvct;
             initcov=covmat;
         end
             
      end % nsamp  
   end % ngroup
   
      
   if part & ~fine
      fine=1;
   elseif (part & fine & ~final) | (~part & ~final)
      final=1;
   else
      final=2;
   end
      
end % while loop

% factor : if we multiply the raw MCD covariance matrix with factor, we obtain consistency  
%          when the data come from a multivariate normal distribution.
factor=rawconsfactor(h,n,p);
factor=factor*rawcorfactor(p,n,alpha);
% initcov=factor*initcov;
%%NIEUW
raw.cov=factor*initcov;
raw.objective=bestobj*prod(mad)^2;
[raw.cov,raw.center]=trafo(raw.cov,initmean,med,mad,p);

if cor
   raw.cor=initcov./(sqrt(diag(initcov))*sqrt(diag(initcov))');
end

% We express the results in the original units.
%[raw.cov,raw.center]=trafo(initcov,initmean,med,mad,p);
%raw.cov=factor*raw.cov;
%raw.objective=bestobj*prod(mad)^2;

%The reweighted robust estimates are now computed.
%mah=mahalanobis(data,initmean,initcov,n,p);
%%%NIEUW
mah=mahalanobis(data,initmean,initcov*factor,n,p);
raw.robdist=sqrt(mah);
%m=2*n/asvardiag(h,n,p);
%quantile=qf(0.975,p,m-p+1);
quantile=chi2q(p);
%weights=mah*(m-p+1)/(m*p)<quantile;
weights=mah<quantile;
raw.wt=weights;
[res.center,res.cov]=weightmecov(data,weights,n,p);
factor=rewconsfactor(weights,n,p);
factor=factor*rewcorfactor(p,n,alpha);
res.cov=factor*res.cov;

[trcov,trcenter]=trafo(res.cov,res.center,med,mad,p);  

if cor
   res.cor=res.cov./(sqrt(diag(res.cov))*sqrt(diag(res.cov))');
end

if det(trcov) < exp(-50*p)
   [center,covar,z,correl,plane,count]=fit(data,NaN,med,mad,p,z,cor,res.center,res.cov,n);  
   res.plane=z;
   if cor
      correl=covar./(sqrt(diag(covar))*sqrt(diag(covar))');
   end     
   res.method=displrw(count,n,p,center,covar,res.method,file,z,fid,cor,correl);   
   res.flag=weights;
   res.robdist=raw.robdist;
else
   mah=mahalanobis(data,res.center,res.cov,n,p);
   res.flag=(mah <= chi2q(p));
   res.robdist=sqrt(mah);
end

res.mahalanobis=sqrt(mahalanobis(data,clmean,clcov,n,p));
res.cov=trcov;
res.center=trcenter;

if ~lts
   disp(res.method)
end
spec.ask=1;
if ~lts
   plotmcd(res,spec);
end

%-----------------------------------------------------------------------------------------
function [raw_center,raw_cov,center,covar,raw_objective,raw_wt,mcd_wt,method]=displ(exactfit,...
          count,weights,n,p,center,covar,method,z,ok,raw_wt,mcd_wt,file,fid,cor,correl,varargin)
      
% Determines some fields of the output argument RES for the exact fit situation.  It also 
% displays and writes the messages concerning the exact fit situation.  If the raw MCD 
% covariance matrix is not singular but the reweighted is, then the function displrw is 
% called instead of this function.

[raw_center,center]=deal(center);
[raw_cov,cov]=deal(covar);
raw_objective=0;
mcd_wt=weights;
raw_wt=weights;

switch exactfit
case 1
   msg='The covariance matrix of the data is singular.';
case 2
   msg='The covariance matrix has become singular during the iterations of the MCD algorithm.';
case 3
   msg=sprintf('The %g-th order statistic of the absolute deviation of variable %g is zero. ',varargin{1},varargin{2});   
end
      
msg=sprintf([msg '\nThere are %g observations in the entire dataset of %g observations that lie on the \n'],count,n);
switch p
case 2
   msg=sprintf([msg 'line with equation %g(x_i1-m_1)%+g(x_i2-m_2)=0 \n'],z);       
   msg=sprintf([msg 'where the mean (m_1,m_2) of these observations is the MCD location']);
case 3
   msg=sprintf([msg 'plane with equation %g(x_i1-m_1)%+g(x_i2-m_2)%+g(x_i3-m_3)=0 \n'],z);
   msg=sprintf([msg 'where the mean (m_1,m_2,m_3) of these observations is the MCD location']);
otherwise
   msg=sprintf([msg 'hyperplane with equation a_1 (x_i1-m_1) + ... + a_p (x_ip-m_p) = 0 \n']);
   msg=sprintf([msg 'with coefficients a_i equal to : \n\n']);
   msg=sprintf([msg sprintf('%g  ',z)]);
   msg=sprintf([msg '\n\nand where the mean (m_1,...,m_p) of these observations is the MCD location']); 
end

method=strvcat(method,[msg '.']);            
disp(method)


%-----------------------------------------------------------------------------------------
function method=displrw(count,n,p,center,covar,method,file,z,fid,cor,correl)
                               
% Displays and writes messages in the case the reweighted robust covariance matrix 
% is singular.

msg=sprintf('The reweighted MCD scatter matrix is singular. \n');
msg=sprintf([msg 'There are %g observations in the entire dataset of %g observations that lie on the\n'],count,n);

switch p
case 2
   msg=sprintf([msg 'line with equation %g(x_i1-m_1)%+g(x_i2-m_2)=0 \n\n'],z);       
   msg=sprintf([msg 'where the mean (m_1,m_2) of these observations is : \n\n']);
case 3
   msg=sprintf([msg 'plane with equation %g(x_i1-m_1)%+g(x_i2-m_2)%+g(x_i3-m_3)=0 \n\n'],z);
   msg=sprintf([msg 'where the mean (m_1,m_2,m_3) of these observations is : \n\n']);
otherwise
   msg=sprintf([msg 'hyperplane with equation a_1 (x_i1-m_1) + ... + a_p (x_ip-m_p) = 0 \n']);
   msg=sprintf([msg 'with coefficients a_i equal to : \n\n']);
   msg=sprintf([msg sprintf('%g  ',z)]);
   msg=sprintf([msg '\n\nand where the mean (m_1,...,m_p) of these observations is : \n\n']);
end

msg=sprintf([msg sprintf('%g  ',center)]);
msg=sprintf([msg '\n\nTheir covariance matrix equals : \n\n']);
msg=sprintf([msg sprintf([repmat('% 13.5g ',1,p) '\n'],covar)]);
if cor
   msg=sprintf([msg '\n\nand their correlation matrix equals : \n\n']);
   msg=sprintf([msg sprintf([repmat('% 13.5g ',1,p) '\n'],correl)]);
end   

method=strvcat(method,msg);

%------------------------------------------------------------------------------------------
   
function [wmean,wcov]=weightmecov(dat,weights,n,nvar)

% Computes the reweighted estimates.

if size(weights,1)==1
   weights=weights';
end
wmean=sum(dat.*repmat(weights,1,nvar))/sum(weights);
wcov=zeros(nvar,nvar);
for obs=1:n
   hlp=dat(obs,:)-wmean;
   wcov=wcov+weights(obs)*hlp'*hlp;
end
wcov=wcov/(sum(weights)-1);

%--------------------------------------------------------------------------------------
function [initmean,initcov]=mcduni(y,ncas,h,len,alpha)

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
factor=rawcorfactor(1,ncas,alpha);
factor=factor*rawconsfactor(h,ncas,1);
initcov=factor*sqmin/h;

%-----------------------------------------------------------------------------------------
function [initmean,initcov,z,correl,varargout]=fit(dat,plane,med,mad,p,z,cor,varargin)

% This function is called in the case of an exact fit. It computes the correlation
% matrix and transforms the coefficients of the hyperplane, the mean, the covariance
% and the correlation matrix to the original units.

if isnan(plane)
   [meanvct,covmat,n]=deal(varargin{:});
   [z, eigvl]=eigs(covmat,1,0,struct('disp',0));
   dist=abs(sum((dat-repmat(meanvct,n,1))'.*repmat(z,1,n)));
   plane=find(dist < 1e-8);
   varargout{1}=plane;
   varargout{2}=length(plane);   
end

z=z./mad';
[initcov,initmean]=trafo(cov(dat(plane,:)),mean(dat(plane,:)),med,mad,p);
if cor
   correl=initcov./(sqrt(diag(initcov))*sqrt(diag(initcov))');
else
   correl=NaN;
end

%------------------------------------------------------------------------------------------
function obsingroup=fillgroup(n,group,ngroup,seed,fid)

% Creates the subdatasets.

obsingroup=cell(1,ngroup+1);
   
jndex=0;
for k=1:ngroup
   for m=1:group(k)
      [random,seed]=uniran(seed);
      ran=floor(random*(n-jndex)+1); 
	   jndex=jndex+1;
	   if jndex==1 
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

%-----------------------------------------------------------------------------------------
function [ranset,seed]=randomset(tot,nel,seed)

% This function is called if not all (p+1)-subsets out of n will be considered. 
% It randomly draws a subsample of nel cases out of tot.      

for j=1:nel
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
     
%-----------------------------------------------------------------------------------------
function [index,seed]=addobs(index,n,seed)

% Extends a trial subsample with one observation.

jndex=length(index);
[random,seed]=uniran(seed);
ran=floor(random*(n-jndex)+1);
jndex=jndex+1;
index(jndex)=ran+jndex-1;
ii=min(find(index(1:jndex-1) > ran-1+[1:jndex-1]));
if length(ii)~=0
   index(jndex:-1:ii+1)=index(jndex-1:-1:ii);
   index(ii)=ran+ii-1;
end

%-----------------------------------------------------------------------------------------

function mahsort=mahal(dat,meanvct,covmat,part,fine,final,k,obsingroup,group,minigr,n,nvar)

% Orders the observations according to the mahalanobis distances.

if ~part | final
   [dis,ind]=sort(mahalanobis(dat,meanvct,covmat,n,nvar));
   mahsort=ind;
elseif fine
   [dis,ind]=sort(mahalanobis(dat(obsingroup{end},:),meanvct,covmat,minigr,nvar));
   mahsort=obsingroup{end}(ind);   
else
   [dis,ind]=sort(mahalanobis(dat(obsingroup{k},:),meanvct,covmat,group(k),nvar));
   mahsort=obsingroup{k}(ind);
end
                     
%-----------------------------------------------------------------------------------------

function [covmat,meanvct]=trafo(covmat,meanvct,med,mad,nvar)

% Transforms a mean vector and a covariance matrix to the original units.

covmat=covmat.*repmat(mad,nvar,1).*repmat(mad',1,nvar);
meanvct=meanvct.*mad+med;

%-----------------------------------------------------------------------------------------
function [bestmean,bestcov,bobj]=insertion(bestmean,bestcov,bobj,meanvct,covmat,obj,row,eps)

% Stores, for the first and second stage of the algorithm, the results in the appropriate 
% arrays if it belongs to the 10 best results.

insert=1;

equ=find(obj==bobj(row,:));
   
for j=equ
   if (meanvct==bestmean{row,j}) & all(covmat==bestcov{row,j})
      insert=0;
   end
end
   
if insert
   ins=min(find(obj < bobj(row,:)));
      
   if ins==10
      bestmean{row,ins}=meanvct;
		bestcov{row,ins}=covmat;
      bobj(row,ins)=obj;
   else
      [bestmean{row,ins+1:10}]=deal(bestmean{row,ins:9});
   	bestmean{row,ins}=meanvct;
   	[bestcov{row,ins+1:10}]=deal(bestcov{row,ins:9});
   	bestcov{row,ins}=covmat;
   	bobj(row,ins+1:10)=bobj(row,ins:9);
   	bobj(row,ins)=obj;
   end
      
end
%-----------------------------------------------------------------------------------------

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

%------------------------------------------------------------------------------------------

function [random,seed]=uniran(seed)

% The random generator.

seed=floor(seed*5761)+999;
quot=floor(seed/65536);
seed=floor(seed)-floor(quot*65536);
random=seed/65536.D0;
   
%------------------------------------------------------------------------------------------
   
function plotmcd(mcdres,options)

% The 0.975 quantile of the chi-squared distribution:
chi2q=[5.02389,7.37776,9.34840,11.1433,12.8325,...
       14.4494,16.0128,17.5346,19.0228,20.4831,21.920,23.337,...
       24.736,26.119,27.488,28.845,30.191,31.526,32.852,34.170,...
       35.479,36.781,38.076,39.364,40.646,41.923,43.194,44.461,...
       45.722,46.979,48.232,49.481,50.725,51.966,53.203,54.437,...
       55.668,56.896,58.120,59.342,60.561,61.777,62.990,64.201,...
       65.410,66.617,67.821,69.022,70.222,71.420];
 
 
p=size(mcdres.X,2);

if det(mcdres.cov) < exp(-50*p)
   error('The MCD covariance matrix is singular ')   
end

% The value of the fields of the input argument OPTIONS are now determined.
% If the user hasn't given a value to one of the fields, the default value 
% is assigned to it.
if nargin==1
   ask=0;
   nid=3;
   xlab='X1';
   ylab='X2';
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
   
   if strmatch('xlab',names,'exact')
      xlab=options.xlab;
   else
      xlab='X1';
   end
   
   if strmatch('ylab',names,'exact')
      ylab=options.ylab;
   else
      ylab='X2';
   end

else
   error('The second input argument is not a structure')
end

data=mcdres.X;
choice=1;
n=size(data,1);
ellip=[];

if ask
   al=0;
else
   al=1;
end

closeplot=0;

% md and rd contain resp. the classical and robust distances.
md=sqrt(mahalanobis(data,mean(data),cov(data),n,p));
%rd=sqrt(mahalanobis(data,mcdres.center,mcdres.cov,n,p));
rd=sqrt(mahalanobis(data,mcdres.center,mcdres.cov,n,p));

while choice ~=7   
   if ask
      
      choice=menu('Make a plot selection :','All','Robust Distances',...
         'Mahalanobis Distances','QQ plot of Robust Distances',...
         'Robust versus Mahalanobis Distances',...
         'MCD Tolerance Ellipse','Exit');
      
      if closeplot==1 & choice~=7 & ~(choice==6 & p~=2)
         % Close previous plots.
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
   
   if al & ~(choice==6 & p~=2 | choice==2)
      % Create a new figure window.
      figure
   end
   
   switch choice
      
   case 2   
      x=1:n;
      y=rd;   
      ymax=max([max(y),sqrt(chi2q(p)),2.5])*1.05;
%      beg('Index','Robust Distance',rd,x,y,nid,n,-0.025*n,n*1.05,-0.025*ymax,ymax);
      beg('Production Sequence','Robust Distance',rd,x,y,nid,n,-0.025*n,n*1.05,-0.025*ymax,ymax);
      line([-0.025*n,n*1.05],repmat(max([sqrt(chi2q(p)),2.5]),1,2),'Color','r');
      
   case 3
      x=1:n;
      y=md;
      ymax=max([max(y),sqrt(chi2q(p)),2.5])*1.05;
%      beg('Index','Mahalanobis Distance',md,x,y,nid,n,-0.025*n,n*1.05,-0.025*ymax,ymax);
      beg('Production Sequence','Mahalanobis Distance',md,x,y,nid,n,-0.025*n,n*1.05,-0.025*ymax,ymax);
      line([-0.025*n,n*1.05],repmat(max([sqrt(chi2q(p)),2.5]),1,2),'Color','r');
      
   case 4
      chisqquantile=repmat(0,1,n);
      for i=1:n
         chisqquantile(i)=qchisq((i-1/3)/(n+1/3),p);
      end
      normqqplot(sqrt(chisqquantile),rd);
      box;
      xlabel('Square root of the quantiles of the chi-squared distribution');
      ylabel('Robust distances');
    
   case 5
      x=md;
      y=rd;
      ymax=max([max(y),sqrt(chi2q(p)),2.5])*1.05;
      xmax=max([max(x),sqrt(chi2q(p)),2.5])*1.05;
      beg('Mahalanobis Distance','Robust Distance',rd,x,y,nid,n,-0.01*xmax,xmax,-0.01*ymax,ymax);
      line(repmat(max([sqrt(chi2q(p)),2.5]),1,2),[-0.01*ymax,ymax],'Color','r');
      line([-0.01*xmax,xmax],repmat(max([sqrt(chi2q(p)),2.5]),1,2),'Color','r');
      hold on
      plot([-0.01*xmax,min([xmax,ymax])],[-0.01*ymax,min([xmax,ymax])],':','Color','g');
      hold off
         
   case 6
      if p~=2
         disp('MCD Tolerance Ellips is only drawn for two-dimensional datasets')
      else
         if isempty(ellip)
         	ellip=ellipse(mcdres.center,mcdres.cov);
         end
         xmin=min([data(:,1);ellip(:,1)]);
         xmax=max([data(:,1);ellip(:,1)]);
         ymin=min([data(:,2);ellip(:,2)]);
         ymax=max([data(:,2);ellip(:,2)]);
         xmarg=0.05*abs(xmax-xmin);
         ymarg=0.05*abs(ymax-ymin);
         xmin=xmin-xmarg;
			xmax=xmax+xmarg;
			ymin=ymin-ymarg;
			ymax=ymax+ymarg;
         beg(xlab,ylab,rd,data(:,1)',data(:,2)',nid,n,xmin,xmax,ymin,ymax);
         title('Tolerance ellipse ( 97.5 % )');         
         line(ellip(:,1),ellip(:,2));
      end
      
   end
   
   if al & choice < 6
      ask=0;
      choice=choice+1;
   elseif al==1 & choice==6
      choice=7;
   elseif al==2 & choice==6
      al=0;
      ask=1;
      closeplot=1;
   end
   
 end
   
%----------------------------------------------------------------------------------------   

function beg(xlab,ylab,ord,x,y,nid,n,xmin,xmax,ymin,ymax)

% Creates a scatter plot.

scatter(x,y,3,'k')
      
xlabel(xlab);
ylabel(ylab);

xlim([xmin,xmax]);
ylim([ymin,ymax]);
box;
if nid   
   [ord,ind]=sort(ord);
   ind=ind(n-nid+1:n)';
	text(x(ind),y(ind),int2str(ind));
end

%----------------------------------------------------------------------------------------

function coord=ellipse(mean,covar)

% Determines the coordinates of some points that lie on the 97.5 % tolerance ellipse.

deter=covar(1,1)*covar(2,2)-covar(1,2)^2;
ylimit=sqrt(7.37776*covar(2,2));
y=-ylimit:0.005*ylimit:ylimit;
sqtdi=sqrt(deter*(ylimit^2-y.^2))/covar(2,2);
sqtdi([1,end])=0;
b=mean(1)+covar(1,2)/covar(2,2)*y;
x1=b-sqtdi;
x2=b+sqtdi;
y=mean(2)+y;
coord=[x1,x2([end:-1:1]);y,y([end:-1:1])]';

%-----------------------------------------------------------------------------------------

function quan=quanf(alpha,n,rk)

quan=floor(2*floor((n+rk+1)/2)-n+2*(n-floor((n+rk+1)/2))*alpha);

%-----------------------------------------------------------------------------------------

function rawconsfac=rawconsfactor(quan,n,p)

qalpha=qchisq(quan/n,p);
calphainvers=pgamma(qalpha/2,p/2+1)/(quan/n);
calpha=1/calphainvers;
rawconsfac=calpha;

%-----------------------------------------------------------------------------------------

function rewconsfac=rewconsfactor(weights,n,p)

if sum(weights)==n
   cdelta.rew=1;
else
   qdelta.rew=qchisq(sum(weights)/n,p);
   cdeltainvers.rew=pgamma(qdelta.rew/2,p/2+1)/(sum(weights)/n);
   cdelta.rew=1/cdeltainvers.rew;
end
rewconsfac=cdelta.rew;

%-----------------------------------------------------------------------------------------

function rawcorfac=rawcorfactor(p,n,alpha)

if p > 2 
   coeffqpkwad875=[-0.455179464070565,1.11192541278794,2;-0.294241208320834,1.09649329149811,3]';
   coeffqpkwad500=[-1.42764571687802,1.26263336932151,2;-1.06141115981725,1.28907991440387,3]';
   y1_500=1+(coeffqpkwad500(1,1)*1)/p^coeffqpkwad500(2,1);
   y2_500=1+(coeffqpkwad500(1,2)*1)/p^coeffqpkwad500(2,2);
   y1_875=1+(coeffqpkwad875(1,1)*1)/p^coeffqpkwad875(2,1);
   y2_875=1+(coeffqpkwad875(1,2)*1)/p^coeffqpkwad875(2,2);
   y1_500=log(1-y1_500);
	y2_500=log(1-y2_500);
   y_500=[y1_500;y2_500];
   A_500=[1,log(1/(coeffqpkwad500(3,1)*p^2));1,log(1/(coeffqpkwad500(3,2)*p^2))];
   coeffic_500=A_500\y_500;
   y1_875=log(1-y1_875);
	y2_875=log(1-y2_875);
   y_875=[y1_875;y2_875];
   A_875=[1,log(1/(coeffqpkwad875(3,1)*p^2));1,log(1/(coeffqpkwad875(3,2)*p^2))];
   coeffic_875=A_875\y_875;
   fp_500_n=1-(exp(coeffic_500(1))*1)/n^coeffic_500(2);
   fp_875_n=1-(exp(coeffic_875(1))*1)/n^coeffic_875(2);
else 
   if p == 2
      fp_500_n=1-(exp(0.673292623522027)*1)/n^0.691365864961895;
      fp_875_n=1-(exp(0.446537815635445)*1)/n^1.06690782995919;
   end   
   if p == 1 
      fp_500_n=1-(exp(0.262024211897096)*1)/n^0.604756680630497;
      fp_875_n=1-(exp(-0.351584646688712)*1)/n^1.01646567502486;
   end   
end   
if 0.5 <= alpha & alpha <= 0.875 
   fp_alpha_n=fp_500_n+(fp_875_n-fp_500_n)/0.375*(alpha-0.5);
end         
if 0.875 < alpha & alpha < 1
   fp_alpha_n=fp_875_n+(1-fp_875_n)/0.125*(alpha-0.875);
end         
rawcorfac=1/fp_alpha_n;

%-----------------------------------------------------------------------------------------

function rewcorfac=rewcorfactor(p,n,alpha)

if p > 2 
   coeffrewqpkwad875=[-0.544482443573914,1.25994483222292,2;-0.343791072183285,1.25159004257133,3]';
   coeffrewqpkwad500=[-1.02842572724793,1.67659883081926,2;-0.26800273450853,1.35968562893582,3]';
   y1_500=1+(coeffrewqpkwad500(1,1)*1)/p^coeffrewqpkwad500(2,1);
   y2_500=1+(coeffrewqpkwad500(1,2)*1)/p^coeffrewqpkwad500(2,2);
   y1_875=1+(coeffrewqpkwad875(1,1)*1)/p^coeffrewqpkwad875(2,1);
   y2_875=1+(coeffrewqpkwad875(1,2)*1)/p^coeffrewqpkwad875(2,2);
	y1_500=log(1-y1_500);
	y2_500=log(1-y2_500);
   y_500=[y1_500;y2_500];
   A_500=[1,log(1/(coeffrewqpkwad500(3,1)*p^2));1,log(1/(coeffrewqpkwad500(3,2)*p^2))];
   coeffic_500=A_500\y_500;
   y1_875=log(1-y1_875);
	y2_875=log(1-y2_875);
   y_875=[y1_875;y2_875];
   A_875=[1,log(1/(coeffrewqpkwad875(3,1)*p^2));1,log(1/(coeffrewqpkwad875(3,2)*p^2))];
   coeffic_875=A_875\y_875;
   fp_500_n=1-(exp(coeffic_500(1))*1)/n^coeffic_500(2);
   fp_875_n=1-(exp(coeffic_875(1))*1)/n^coeffic_875(2);
else 
   if p == 2
      fp_500_n=1-(exp(3.11101712909049)*1)/n^1.91401056721863;
      fp_875_n=1-(exp(0.79473550581058)*1)/n^1.10081930350091;
   end
   if p == 1 
      fp_500_n=1-(exp(1.11098143415027)*1)/n^1.5182890270453;
      fp_875_n=1-(exp(-0.66046776772861)*1)/n^0.88939595831888;
   end
end
if 0.5 <= alpha & alpha <= 0.875 
   fp_alpha_n=fp_500_n+(fp_875_n-fp_500_n)/0.375*(alpha-0.5);
end            
if 0.875 < alpha & alpha < 1 
   fp_alpha_n=fp_875_n+(1-fp_875_n)/0.125*(alpha-0.875);
end            
rewcorfac=1/fp_alpha_n;

%-----------------------------------------------------------------------------------------

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
x(I1) = zeros(size(I0)) + Inf;

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

function x = rchisq(n,a)
%RCHISQ   Random numbers from the chisquare distribution
%
%         x = rchisq(n,DegreesOfFreedom)

%        Anders Holtsberg, 18-11-93
%        Copyright (c) Anders Holtsberg

if any(any(a<=0))
   error('DegreesOfFreedom is wrong')
end

x = rgamma(n,a*0.5);


%-----------------------------------------------------------------------------------------

function x = rgamma(n,a)
%RGAMMA   Random numbers from the gamma distribution
%
%         x = rgamma(n,a)

%        Anders Holtsberg, 18-11-93
%        Copyright (c) Anders Holtsberg

if any(any(a<=0))
   error('Parameter a is wrong')
end

if size(n)==1
   n = [n 1];
end

x = qgamma(rand(n),a);

%-----------------------------------------------------------------------------------------

function normqqplot(x,y);
 
y = sort(y);

scatter(x,y,3,'k')

%-----------------------------------------------------------------------------------------

%function asvar=asvardiag(quan,n,p)
%
%alfa=quan/n;
%alfa=1-alfa;
%qalfa=qchisq(1-alfa,p);
%calfainvers=pgamma(qalfa/2,p/2+1);
%calfa=(1-alfa)/calfainvers;
%c2=-1/2*pgamma(qalfa/2,p/2+1);
%c3=-1/2*pgamma(qalfa/2,p/2+2);
%c4=3*c3;
%b1=(calfa*(c3-c4))/(1-alfa);
%b2=1/2+(calfa/(1-alfa))*(c3-((qalfa/p)*(c2+(1-alfa)/2)));
%asvar=(1-alfa)*b1^2*(alfa*((calfa*qalfa)/p-1)^2-1);
%asvar=asvar-2*c3*(calfa)^2*(3*(b1-p*b2)^2+(p+2)*b2*(2*b1-p*b2));
%asvar=asvar/(((1-alfa)*b1*(b1-p*b2))^2);
%
%----------------------------------------------------------------------------------------

function x = qf(p,a,b)
%QF       The F inverse distribution function
%
%         x = qf(p,df1,df2)

%        Anders Holtsberg, 18-11-93
%        Copyright (c) Anders Holtsberg

x = qbeta(p,a/2,b/2);
x = x.*b./((1-x).*a);

%----------------------------------------------------------------------------------------

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
