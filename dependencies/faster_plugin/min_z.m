function [anytrue, alltrue, all_tests] = min_z(list_props, reject_opts)

    if (~exist('rejection_options','var'))
        reject_opts.measure = ones(1, size(list_props, 2));
        reject_opts.z = 3 * ones(1, size(list_props, 2));
    else
        if ~isfield('rejection_options', 'measure')
            reject_opts.measure = ones(1, size(list_props, 2));
        end
        if ~isfield('rejection_options', 'z')
            reject_opts.z = 3 * ones(1, size(list_props, 2));
        end
    end

    reject_opts.measure = logical(reject_opts.measure);
    zs = list_props - repmat(mean(list_props, 1), size(list_props, 1), 1);
    zs = zs ./ repmat(std(zs,[],1), size(list_props, 1), 1);
    zs(isnan(zs)) = 0;
    all_tests = abs(zs) > repmat(reject_opts.z, size(list_props, 1), 1);
    anytrue = any(all_tests(:, reject_opts.measure), 2);
    alltrue = all(all_tests(:, reject_opts.measure), 2);
    
end