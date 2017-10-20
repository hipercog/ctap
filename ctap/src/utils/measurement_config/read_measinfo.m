function MC = read_measinfo(srcfile)
%MC_LOADER A wrapper to read measurement config data from multiple sources

[pathstr, name, ext] = fileparts(srcfile); 

switch ext
    case '.sqlite'
        MC = read_measinfo_sqlite(srcfile);
    case '.xls'
        MC = read_measinfo_spreadsheet(srcfile);
    case '.xlsx'
        MC = read_measinfo_spreadsheet(srcfile);
    otherwise
        error('mc_loader:fileTypeError',...
               sprintf('The input file type ''%s'' is not supported.',ext))
end
        
end