function [s, f] = get_last_call(Cfg, func_name)

%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('Cfg', @isstruct)
p.addRequired('func_name', @ischar)
p.parse(Cfg, func_name)


%% find set and func index of most recent call to func_name
s = 0;
f = 0;
tmp = Cfg.pipe.stepSets(1:Cfg.pipe.current.set);
for i = 1:Cfg.pipe.current.set - 1
    for j = 1:numel(tmp(i).funH)
        if strcmp(func2str(tmp(i).funH{j}), func_name)
            s = i;
            f = j;
        end
    end
end
% find index if in current set
for j = 1:Cfg.pipe.current.funAtSet - 1
    if strcmp(func2str(tmp(end).funH{j}), func_name)
        s = Cfg.pipe.current.set;
        f = j;
    end
end