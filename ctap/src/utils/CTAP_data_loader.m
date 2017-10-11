function EEG = CTAP_data_loader(Cfg, branch, pattern)
% Note: works only for non-branching flat pipes!

% branch = '1_load'
% pattern = '*042*NB00.set'

tmp = dir(Cfg.env.paths.ctapRoot);
branch_match = ~cellfun(@isempty, regexp({tmp.name},branch));

fpath = fullfile(Cfg.env.paths.ctapRoot, branch);


f = dir(fullfile(fpath, pattern));

if length(f) > 1
    f = f(1);
end

EEG = pop_loadset(f.name, fpath);
