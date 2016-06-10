function [peakLatArr, BlinkData] = eeg_detect_blink(veog, fs, varargin)
%EEG_DETECT_BLINK - EEG blink detection using filtering, derivatives and a fancy metric
%
% Description:
%   This function implements main ideas from the paper:
%   http://www.jemr.org/online/8/2/1
%   In this implementation the separation between non-blinks and blinks 
%   is done using k-means instead of gaussian EM and probabilistic
%   assignment.
%
% Syntax:
%   [peakLatArr, Dv] = eeg_detect_blink(veog, fs, varargin);
%
% Inputs:
%   veog    [1,N] numeric, Vertical EOG signal, tested using
%           VeogUp-VeogDown
%   fs      [1,1] numeric, Sampling rate in Hz
%
%   varargin    Keyword-value pairs
%   Keyword         Type, description, values
%   'FIRLength'     interger, Length of the FIR filter, default: floor(0.3*fs) 
%
% Outputs:
%   peakLatArr  [1,N] numeric, Blink positions in samples (= indices of veog)
%   BlinkData   struct, A struct with extra data.
%
% Assumptions:
%
% References:
%   Toivanen, M., Pettersson, K., Lukander, K. (2015),
%   A probabilistic real-time algorithm for detecting blinks, saccades, 
%   and fixations from EOG data.
%   Journal of Eye Movement Research, 8(2):1,1-14.
%
% Example:
%
% Notes: 
%
% See also:
%
% Copyright 2015- Miika Toivanen, Jussi Korpela, FIOH, jussi.korpela@ttl.fi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('veog', @isnumeric);
%p.addOptional('argument2', default_value,@test_function_handle);
p.addParameter('FIRLength', floor(0.3*fs), @isinteger);
p.addParameter('cdfGrid', 0.01, @isnumeric); %in Dv units
p.addParameter('cdfTailProb', 1 - 0.00001, @isnumeric); %probability, set on artificial data

p.parse(veog, varargin{:});
Arg = p.Results;

veog = double(veog); %often single


%% Filter data 
% remove baseline wander
Bfir = fir1(Arg.FIRLength, 0.5/(fs/2),'high'); 
veogf = filtfilt(Bfir, 1, veog);

% remove noise
Bfir = fir1(Arg.FIRLength, 5/(fs/2),'low'); 
veogf = filtfilt(Bfir, 1, veogf);

%np = 5e4;
%plot(1:np, [veogf(1:np)+1000; veog(1:np)]);


%% Take derivative
dveog = diff(veogf);
%np = 5e3;
%plot(1:np, [dveog(1:np)+20; 0.05*veogf(1:np)]);


%% Find local maxima & minima of derivative
max_inds = local_max(dveog);
min_inds = local_max(-dveog);

% make sure that local maximum of derivative start the sequence
keepMatch = max_inds(1) < min_inds;
min_inds = min_inds(keepMatch);
max_inds = max_inds(1:length(min_inds));

% local max/min values of derivative
dveog_max = dveog(max_inds);
dveog_min = dveog(min_inds);


%% Compute THE feature
Dv = dveog_max - dveog_min - abs(dveog_min + dveog_max);
%plot(sort(Dv),'ro');
%hist(Dv, 100);
%set(gca, 'YScale', 'log') 


%% Separate blinks from the rest

%--------------------------------------------------------------------------
%%% Hierarchical divisive clustering
% This would be on good option but no open source implementation was found.
% Buying extra toolboxes would solve the problem...

%{
%--------------------------------------------------------------------------
%%% k-means clustering
% This method is no longer used as k-means is not very stable when the
% is large class imbalance in the data.
fprintf('Running k-means ...');

% Special initalization for classes
% Often there are very few blinks and a random initialization of classes
% does not work as desired. We use the a priori information that non-blinky
% values of Dv are small whereas blinky values are large to create a better
% initial clustering to start from.
[nonBlinkySeed, nonBlinkySeedInd] = min(Dv);
[blinkySeed, blinkySeedInd] = max(Dv);
seedPointInds = [nonBlinkySeedInd, blinkySeedInd];

label = repmat(1,1,length(Dv)); % label 1 == non blink
for i = 1:length(Dv)
    if((Dv(i)- nonBlinkySeed)^2 > (Dv(i) - blinkySeed)^2)
       label(i) = 2; %blinkySeed closer -> switch label
    end
end
cluster = litekmeans(Dv, 2, label);
fprintf(' done. \n');

clusterMeans(1) = mean(Dv(cluster==1));
clusterMeans(2) = mean(Dv(cluster==2));
[~,blinkCluster] = max(clusterMeans); 

blink_match = cluster==blinkCluster;
blink_inds = find(blink_match);
%}

%--------------------------------------------------------------------------
%%% Fit two 1D gaussian using EM -approach
% Currently using this approach since:
%   1. it is independent of costly toolboxes
%   2. it is stable (?) and works

% Fit two Gaussians
[Dv_min, min_ind] = min(Dv); %non-blink cluster seed
[Dv_max, max_ind] = max(Dv); %blink cluster seed
[mu, sd, P] = EMgauss1D(Dv, [min_ind max_ind], 0);

% For testing purposes:
%{
x = -2:0.1:2;
mu = 0;
sigma = 1;
pdf_non_blink = norm_pdf(x, mu(1), sigma(1));
cdf_non_blink = norm_cdf(x, mu(1), sigma(1));

figure
plot(pdf_non_blink)
hold on;
plot(cdf_non_blink)
line([21 21], [0, 1])
line([0 41], [0.5 0.5])
%}

% Find a suitable threshold for Dv
brain = 'jkor';
switch brain
    case 'jkor'
        % Heuristic version by Korpela
        % Make cut between mu(1) and mu(2), mu(1) < mu(2) based on mu(2) alone. 
        x = Dv_min:Arg.cdfGrid:Dv_max;
        cdf_non_blink = norm_cdf(x, mu(1), sd(1));
        th_ind = find(Arg.cdfTailProb < cdf_non_blink, 1 );
        Dv_th = x(th_ind);
        
        blink_match = Dv > Dv_th; % Get the needed blink match!!

    case 'mtoi'

        % Probabilistic version by Miika
        %{
        % Miika version 1 fails since sigma(2) is large and hence values below
        % mu(1) end up being more probable under N(mu(2), sigma(2)).
        P_non_blink = norm_pdf(Dv, mu(1), sigma(1));
        P_blink = norm_pdf(Dv, mu(2), sigma(2));
        %plot(1:length(Dv), [P_blink; P_non_blink],'o-')
        blink_match = P_blink > P_non_blink;
        blink_inds = find(blink_match);
        cluster = repmat(1,1,length(Dv)); % label 1 == non blink
        cluster(blink_match) = 2;
        blinkCluster = 2;
        %blink_inds = find(Dv > 4.5);
        %}

        % Miika version 2 works, but by (quick) tests are no better than Korpela
        mu_nonblink = mu(1); % mean of non-blink
        mu_blink = mu(2);    % mean of blink
        sd_nonblink = sd(1);  % std of non-blink
        sd_blink = sd(2) * 0.1;     % std of blink
        prior_nonblink = P(1);     % prior prob. of non-blink
        prior_blink = P(2);      % prior prob. of blink
        % Compute blink & nonblink likelihoods (using asymmetric Gaussian dists)
        Lnb(Dv > mu_nonblink) = norm_pdf(Dv(Dv > mu_nonblink)...
            , mu_nonblink, sd_nonblink);
        Lnb(Dv <= mu_nonblink) = norm_pdf(mu_nonblink, mu_nonblink, sd_nonblink);
        Lb(Dv < mu_blink) = norm_pdf(Dv(Dv < mu_blink), mu_blink, sd_blink);
        Lb(Dv >= mu_blink) = norm_pdf(mu_blink, mu_blink, sd_blink);
        % Compute the posterior probabilities
        evi_norm = Lnb*prior_nonblink + Lb*prior_blink; % evidence of norm data=
                                                        % normalization constant
        pbn = Lb * prior_blink ./ evi_norm; % normalized probability: sample=blink
        pnbn = 1 - pbn; % normalized probability for the sample to be a non-blink
        
        blink_match = pbn > 0.5; % Get the needed blink match!!
end

%% Find blink peak positions
% veog maximum occurs between dveog_max and _min (dveog=0)
blink_inds = find(blink_match);
max_ind_blinks = max_inds(blink_inds);
min_ind_blinks = min_inds(blink_inds);
peakLatArr = NaN(1,length(max_ind_blinks));
for i=1:length(max_ind_blinks)
    [~, tmpind] = max(veog(max_ind_blinks(i):min_ind_blinks(i)));
     peakLatArr(i) = max_ind_blinks(i) + tmpind -1;
end


%% Assing outputs
cluster = ones(1,length(Dv)); % label 1 == non blink
cluster(blink_match) = 2;
blinkCluster = 2;

BlinkData.Dv = Dv(:);
BlinkData.clusters = cluster(:);
BlinkData.blinkCluster = blinkCluster(:);
BlinkData.dVeogMaxInds = max_inds(:);
BlinkData.dVeogMinInds = min_inds(:);
BlinkData.blinkMatch = blink_match(:);


%% Debug stuff
%{
plot(sort(Dv(blink_match)), 'ro')
hold on;
plot(sort(Dv(~blink_match)), 'bo')
hold off;

subplot(2,1,1);
xbins1 = -10:0.1:30;
hist(Dv(blink_match),xbins1);
ylabel('blinks');
subplot(2,1,2);
hist(Dv(~blink_match),xbins1);
ylabel('non-blinks');
%}

%plot(veogf), hold on, plot(max_ind_blinks, veogf(max_ind_blinks),'ro'), hold off
%events = eeglab_create_event(max_ind_blinks, 'b');
%compare_signals(veog, {'veog'}, EEG.srate, 'eventStruct', events)