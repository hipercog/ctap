function MC = read_measinfo(srcfile)
%READ_MEASINFO A wrapper to read measurement config data from multiple sources

[pathstr, name, ext] = fileparts(srcfile); 

switch ext
    case '.sqlite'
        MC = read_measinfo_sqlite(srcfile);
    case '.xls' | '.xlsx'
        MC = read_measinfo_spreadsheet(srcfile);
    otherwise
        error('read_measinfo:fileTypeError',...
               'The input file type ''%s'' is not supported.', ext)
end
        
end