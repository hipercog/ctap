function output = scrape_file_for_str(fname, str)

output = cell(1);

fid = fopen(fname);

tline = fgets(fid);
while ischar(tline)
    if iscell(str)
        if ~cellfun(@isempty, strfind(tline, str))
            output{end+1} = tline; %#ok<*AGROW>
        end
    else
        if ~isempty(strfind(tline, str))
            output{end+1} = tline;
        end
    end
        
    tline = fgets(fid);
end

end
