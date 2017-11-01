function MC = cfg_fix_paths(fixPathStr, fixField, MC)

for i = 1:numel(MC.measurement)
    if ~isdir(MC.measurement(i).(fixField)) ||...
        ~exist(MC.measurement(i).(fixField), 'file')==2
            MC.measurement(i).(fixField) = fullfile(...
                fixPathStr, MC.measurement(i).(fixField));
    end
end