function match = find_closest_file(srch_name, srch_dir, exts)

    % find all files in srch_dir with the given extension(s)
    fs = cellfun(@dir, fullfile(srch_dir, strcat('*.', unique(exts))), 'un', 0);
    % concat all the matching files to a single vertical struct array
    fs = vertcat(fs{~cellfun(@isempty, fs)});
    % use only the filename part of the given name
    [~, f, ~] = fileparts(srch_name);
    % find the Levenshtein distance between all found filenames and srch_name
    fndst = cellfun(@(x) strdist(x(1:end-4), f), {fs.name});
    % return the first found minimal distance filename
    match = fs(find(fndst==min(fndst), 1)).name;
    
end