function dirlst = recursive_dir(rootdir, pattern)


switch computer
    
    case 'GLNXA64'
        callstr = sprintf('find %s -path %s -prune', rootdir, pattern);
        [status, dirlst] = system(callstr);
        
        if strfind(dirlst, 'No such file or directory')
            dirlst = {};
        else
            dirlst = strsplit(dirlst, '\n');
            % remove possible empty elements (last linebreak)
            ematch = cellfun(@isempty, dirlst);
            dirlst = dirlst(~ematch);
        end
    case 'PCWIN64'
        error(  'recursive_dir:OSerror',...
                'Your operating system is not supported.');

    case 'MACI64'
        error(  'recursive_dir:OSerror',...
                'Your operating system is not supported.');
            
    otherwise
        
        error(  'recursive_dir:OSerror',...
                'Your operating system is not supported.');
end