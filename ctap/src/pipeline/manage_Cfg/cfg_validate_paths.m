function Cfg = cfg_validate_paths(Cfg)
%check and fix the data paths (useful if paths were hardcoded and incorrect)
    [servpath, servname, ~] = fileparts(Cfg.env.paths.serverRoot);
    for i = 1:numel(Cfg.MC.measurement)
        sbf_replace_path('physiodata')
        sbf_replace_path('measurementlog')
    end
    
    function sbf_replace_path(pathpart)
        Cfg.MC.measurement(i).(pathpart) =...
            strrep(Cfg.MC.measurement(i).(pathpart), {'\' '/'}, filesep);
        tmp = strfind(Cfg.MC.measurement(i).(pathpart), servname);
        if ~isempty(tmp)
            Cfg.MC.measurement(i).(pathpart) = fullfile(servpath, ...
                Cfg.MC.measurement(i).(pathpart)(tmp:end));
        end
    end

end %cfg_validate_paths