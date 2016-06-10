function x = softmax_norm(x, dmean, dsd)
% Implements softmax normalization
% See: https://en.wikipedia.org/wiki/Softmax_function
x = sigmoid((x-dmean)/dsd);