function [tru_tests, all_tests] = min_z(list_props, lgc_fun, reject_opts)

    if ~exist('lgc_fun', 'var')
        lgc_fun = @all;
    end
    if ~exist('reject_opts', 'var')
        reject_opts.measure = ones(1, size(list_props, 2));
        reject_opts.z = 3 * ones(1, size(list_props, 2));
    else
        if ~isfield(reject_opts, 'measure')
            reject_opts.measure = ones(1, size(list_props, 2));
        end
        if ~isfield(reject_opts, 'z')
            reject_opts.z = 3 * ones(1, size(list_props, 2));
        end
    end
    if ~isvector(reject_opts.measure) || ~isvector(reject_opts.z)
        error('min_z:bad_param', '''reject_opts'' must contain numeric vectors')
    end

    reject_opts.measure = logical(reject_opts.measure);
    % subtract the mean
    zs = list_props - repmat(mean(list_props, 1), size(list_props, 1), 1);
    % divide by standard deviation
    zs = zs ./ repmat(std(zs, [], 1), size(list_props, 1), 1);
    % remove NaNs
    zs(isnan(zs)) = 0;
    % test if these z-scores exceed the given bounds
    all_tests = zs < repmat(min(reject_opts.z), size(list_props, 1), 1) |...
                zs > repmat(max(reject_opts.z), size(list_props, 1), 1);
    % test if which tests have failed, according to 
    tru_tests = lgc_fun(all_tests(:, reject_opts.measure), 2);
    
end