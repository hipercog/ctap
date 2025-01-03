function MC = cfg_validate_MC_paths(MC, data_root)
%check and fix the data paths (useful if paths were hardcoded and incorrect)
    [root_path, root_name, ~] = fileparts(data_root);
    for i = 1:numel(MC.measurement)
        sbf_replace_path('physiodata')
        sbf_replace_path('measurementlog')
    end
    
    function sbf_replace_path(pathpart)
        MC.measurement(i).(pathpart) =...
            strrep(MC.measurement(i).(pathpart), '\', filesep);
        if ~isfile(MC.measurement(i).(pathpart))
            % If the data_root FOLDER is in the given path, prepend with
            % data_root PATH...for migrating meas_info.xl BETWEEN systems
            tmp = strfind(MC.measurement(i).(pathpart), root_name);
            if ~isempty(tmp)
                tmp = fullfile(root_path, MC.measurement(i).(pathpart)(tmp:end));
            else
                tmp = fullfile(data_root, MC.measurement(i).(pathpart));
            end
            if isfile(tmp)
                MC.measurement(i).(pathpart) = tmp;
            end
            
        end
    end

end %cfg_validate_paths