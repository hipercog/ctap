function samples = lognorm_sample(X, N, Arg)
    % This function samples N times from the vector X with a preference
    % for lower values using a lognormal distribution.
    arguments
        X (1,:)
        N (1,1)
        Arg.mu (1,1) double = 0
        Arg.sigma (1,1) double = 1
    end


    % The length of the input vector
    lenX = length(X);

    % Generate lognormal distributed random numbers
    pd = makedist('Lognormal', 'mu', Arg.mu, 'sigma', Arg.sigma);
    randomIdx = random(pd, N, 1);

    % Scale and round the indices to the range of X
    scaledIdx = round((lenX - 1) * cdf(pd, randomIdx)) + 1;

    % Sample from X using the generated indices
    samples = X(scaledIdx);
end