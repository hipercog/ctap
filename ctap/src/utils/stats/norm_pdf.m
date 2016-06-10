function vals = norm_pdf(x, mu, sigma)

vals = exp(-0.5 * ((x - mu)./sigma).^2) ./ (sqrt(2*pi) * sigma);