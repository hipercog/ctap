function remove_intermediate_files(rootdir)

% get list of result directories
dirlst = recursive_dir(rootdir, '*this*');

if isempty(dirlst)
   error('No directories found.'); 
end

disp('Removing files...');
for k = 1:numel(dirlst)
    disp(sprintf('... from %s', dirlst{k}));
    
    % find actual intermediate result dirs
    f = dir( sprintf('%s/*_*',dirlst{k}) );
    f = regexpi({f.name},'[1-9]_.*','match');
    f = sort([f{:}]); %alphabetical order, largest #_* last

    % delete all but last
    for i=1:(numel(f)-1)
        delete(fullfile(dirlst{k}, f{i}, '*.set'));
        delete(fullfile(dirlst{k}, f{i}, '*.fdt'));
    end
end
disp('... done.')