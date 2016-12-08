function cdfvalue = norm_cdf(x, mu, sigma)
% Cumulative normal distribution function
% See the documentation of erf()

cdfvalue = (1/2)*(1+ erf( (x - mu)/(sigma * sqrt(2)) ) );

end

