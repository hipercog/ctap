function [match, num_match] = find_closest_file(srch_name, srch_dir, exts)

    if nargin < 3, exts = ''; end

    if ~isempty(exts) && ~iscell(exts) && ischar(exts)
        exts = {exts};
    end
    
    % find all files in srch_dir with the given extension(s)
    if isempty(exts)
        fs = dir(srch_dir);
    else
        fs = cellfun(@dir, fullfile(srch_dir, strcat('*', unique(exts))), 'un', 0);
    end
    
    % concat all matching files to vertical struct array, with non-empty rows
    fs = vertcat(fs{~cellfun(@isempty, fs)});
    
    % use only the filename part of the given and found names
    [~, fnm, ~] = cellfun(@fileparts, {fs.name}, 'Un', 0);
    [~, f, ~] = fileparts(srch_name);
    
    % find the Levenshtein distance between all found filenames and srch_name
    fndst = cellfun(@(x) strdist(x, f), fnm);
    
    % get minimal distance filename(s)
    closest = fndst==min(fndst);
    mindst = fndst(closest);
    baserate = min(cellfun(@length, fnm));
    if min(mindst) > baserate
        warning('find_closest_file:no_close_match'...
            , 'Closest file requires %dpc changes to match: not very close!!'...
            , round((min(mindst) * 100) / baserate))
    end
    
    % return the first found, and the quantity found
    match = fs(find(closest, 1)).name;
    num_match = sum(closest);
    
end