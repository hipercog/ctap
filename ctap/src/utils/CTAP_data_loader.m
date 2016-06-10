function EEG = CTAP_data_loader(Cfg, branch, pattern)

tmp = dir(Cfg.env.paths.analysisRoot);
branch_match = ~cellfun(@isempty, regexp({tmp.name},branch));

fpath = fullfile(Cfg.env.paths.analysisRoot, tmp(branch_match).name);

%f = dir(fullfile(fpath, sprintf('*%03d*.set', sbjnr)));
f = dir(fullfile(fpath, pattern));

if length(f) > 1
    f = f(1);
end

EEG = pop_loadset(f.name, fpath);
