function [peakLatArr, BlinkData] = eeg_detect_blink(veog, fs, varargin)
%EEG_DETECT_BLINK - EEG blink detection using filtering, derivatives and a fancy metric
%
% Description:
%   This function implements main ideas from the paper:
%   http://www.jemr.org/online/8/2/1
%   
%   This implementation applies several classification methods to establish
%   the separation between non-blinks and blinks.
%   Results of all of them are reported but only one used by default to
%   mark blinks (see varargin classMethod). 
%   
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

%p.addParameter('classMethod', 'emgauss_asymmetric', @ischar);
p.addParameter('classMethod', 'kmeans', @ischar);
p.addParameter('FIRLength', floor(0.3*fs), @isinteger);
p.addParameter('featureAcceptRange', [NaN NaN], @isnumeric);
p.addParameter('cdfGrid', 0.01, @isnumeric); %in Dv units
p.addParameter('cdfTailProb', 1 - 0.00001, @isnumeric); %probability, set on artificial data
p.addParameter('emGaussReasoning', 'heuristic', @ischar);


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
%figure();
%plot(sort(Dv),'ro');
%plot(sort(Dv_sub),'ro');
%ylim([-10,30])
%hist(Dv, 100);
%set(gca, 'YScale', 'log') 
%keyboard

% Limit range of accepted Dv values to handle outliers
if ~isnan(Arg.featureAcceptRange(1))
    % Restrict allowed Dv values to avoid outliers
    % Suitable range would be e.g. [-5, 25] (from seamless nback)
    low_match = Dv < Arg.featureAcceptRange(1);
    high_match = Dv > Arg.featureAcceptRange(2);
    ok_match = ~low_match & ~high_match;
    ok_inds = find(ok_match);
else
    % select all
    high_match = false(1, numel(Dv)); %none marked as extremely high
    ok_match = true(1, numel(Dv));
    ok_inds = 1:numel(Dv);
end

Dv_sub = Dv(ok_inds); % only reasonable observations to classification


%% Separate blinks from the rest
switch Arg.classMethod
    case 'hierdivisive'
%--------------------------------------------------------------------------
%%% Hierarchical divisive clustering
% This would be a good option but no open source implementation was found.
% Buying extra toolboxes would solve the problem...

    case 'kmeans'
%--------------------------------------------------------------------------
%%% k-means clustering
% This method is no longer used as k-means is not very stable when there
% is large class imbalance in the data.
% Could not verify the problem with class imbalance.
        blink_match_tmp = sbf_1Dclass_kmeans(Dv_sub);

    case 'emgauss_heuristic' | 'emgauss_asymmetric'
%--------------------------------------------------------------------------
%%% Fit two 1D gaussian using EM -approach
% Pros:
%   1. it is independent of costly toolboxes
%   2. it is stable and usually works
% Cons:
%   1. overly conservative: non-blink distribution too narrow -> very small
%   fluctuations end up being labelled as blinks

        % Fit two Gaussians
        %[Dv_min, min_ind] = min(Dv); %non-blink cluster seed, sensitive to outliers!
        [Dv_min, min_ind] = min(abs(Dv_sub)); %non-blink cluster seed around zero
        [Dv_max, max_ind] = max(Dv_sub); %blink cluster seed
        [mu, sd, P] = EMgauss1D(Dv_sub, [min_ind max_ind], 0);

        % Interpret
        blink_match_tmp = sbf_emgauss_interpret(Dv_sub, mu, sd, P, Arg,...
                                       strrep(Arg.classMethod, 'emgauss_', ''));
    otherwise
        error('eeg_detect_blink:parameterError',...
              'Unknown value ''%s'' for varargin ''classMethod''.', Arg.classMethod);
        
end

% debug:
% figure();
% yvals = rand(1,numel(Dv_sub));
% plot(Dv_sub(~blink_match_kmeans), yvals(~blink_match_kmeans), 'bo');
% hold on;
% plot(Dv_sub(blink_match_kmeans), yvals(blink_match_kmeans), 'ro');
% hold off;

% veog maximum occurs between dveog_max and _min (dveog=0)
%blink_inds = find(blink_match);
blink_inds = horzcat(ok_inds(blink_match_tmp), find(high_match));
blink_match = false(1, numel(Dv));
blink_match(blink_inds) = true;

max_ind_blinks = max_inds(blink_inds);
min_ind_blinks = min_inds(blink_inds);
peakLatArr = NaN(1,length(max_ind_blinks));
for i = 1:length(max_ind_blinks)
    [~, tmpind] = max(veog(max_ind_blinks(i):min_ind_blinks(i)));
     peakLatArr(i) = max_ind_blinks(i) + tmpind -1;
end

% debug:
% figure();
% yvals = rand(1,numel(Dv));
% plot(Dv(~blink_match), yvals(~blink_match), 'bo');
% hold on;
% plot(Dv(blink_match), yvals(blink_match), 'ro');
% hold off;


%% Assing outputs
cluster = ones(1,length(Dv)); % label 1 == non blink
cluster(blink_match) = 2;
%blinkCluster = 2;

BlinkData.Dv = Dv(:);
BlinkData.dVeogMaxInds = max_inds(:);
BlinkData.dVeogMinInds = min_inds(:);
BlinkData.blinkMatch = blink_match(:);
BlinkData.clusters = cluster(:);
% BlinkData.blinkIdxEMGauss.heuristic = ok_inds(blink_match_emgauss_heur);
% BlinkData.blinkIdxEMGauss.asymm = ok_inds(blink_match_emgauss_asymm);
% BlinkData.blinkIdxKMeans = ok_inds(blink_match_kmeans);
BlinkData.DvAcceptRange = Arg.featureAcceptRange;


%% Debug stuff

% For testing purposes:
%{
figure;
%blink_match = blink_match_kmeans;
%blink_match = blink_match_emgauss_heur;
blink_match = blink_match_emgauss_asymm;
plot(Dv(blink_match), rand(sum(blink_match),1), 'ro')
hold on;
plot(Dv(~blink_match), rand(sum(~blink_match),1), 'bo')
hold off;


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


%% Helper functions

% 1D classification using k-means
function [blink_match] = sbf_1Dclass_kmeans(Dv)

    fprintf('Running k-means ...');

    % Special initalization for classes
    % Often there are very few blinks and a random initialization of classes
    % does not work as desired. We use the a priori information that non-blinky
    % values of Dv are small whereas blinky values are large to create a better
    % initial clustering to start from.

    % Initialize classes
    [nonBlinkySeed, nonBlinkySeedInd] = min(Dv);
    [blinkySeed, blinkySeedInd] = max(Dv);
    %seedPointInds = [nonBlinkySeedInd, blinkySeedInd];

    label = ones(1,length(Dv)); % label 1 == non blink
    for dix = 1:length(Dv)
        if((Dv(dix)- nonBlinkySeed)^2 > (Dv(dix) - blinkySeed)^2)
           label(dix) = 2; %blinkySeed closer -> switch label
        end
    end

    % Refine classes
    cluster = litekmeans(Dv, 2, label);


    clusterMeans = [mean(Dv(cluster==1)), mean(Dv(cluster==2))] ;
    [~, max_ind] = max(clusterMeans); 

    blink_match = cluster==max_ind;
    fprintf(' done. \n');
end


function [blink_match] = sbf_emgauss_interpret(Dv, mu, sd, P, Arg, method)

    % Find a suitable threshold for Dv
    switch method

        case 'heuristic'
            % Heuristic version by Korpela
            % Make cut between mu(1) and mu(2),
            % mu(1) < mu(2) based on mu(2) alone. 
            x = Dv_min:Arg.cdfGrid:Dv_max;
            cdf_non_blink = norm_cdf(x, mu(1), sd(1));
            th_ind = find(Arg.cdfTailProb < cdf_non_blink, 1 );
            if isempty(th_ind)
                th_ind = numel(cdf_non_blink);
            end
            Dv_th = x(th_ind);

            blink_match = Dv > Dv_th; % Get the needed blink match!!

        case 'asymmetric'

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

        otherwise
            error('eeg_detect_blink:parameterError',...
                'Unknown EMGauss decision method.');
    end

end %end of sbf_1Dclass_emgauss


end