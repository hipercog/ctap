function v = unfind(x)

    v = zeros(1, max(x));
    v(x) = 1;
    v = logical(v);