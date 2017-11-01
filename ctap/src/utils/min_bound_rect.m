function [sbox, nrows] = min_bound_rect(n)
    % MIN_SQUARE find the minimum rectangle that will bound a given value n
    sbox = ceil(sqrt(n));
    nrows = ceil(n / sbox);
end