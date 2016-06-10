function rmpath_pattern(patternList)

%{
rmdirPatternList = { 
    [filesep,'.hg'],...
    [filesep,'.git'],...
    fullfile('utils','statistics','nan'),...
    [filesep,'obsolete'],...
    [filesep,'backup-versions'],... 
    [filesep,'tmp'],...
    [filesep,'maybe-of-interest'],... 
    [filesep,'doc'],... 
    ['biosig4octmat-2.22',filesep,'maybe-missing'],...
    fullfile('external','biosig-20090130'),...
    fullfile('external','fieldtrip-20090727'),...
    'samples-of-project-specific-files'};
%}


%% Remove directories - directories based on pattern
currentPath = path(); 
inclusionMatch = false(numel(strfind(currentPath, pathsep))+1,...
                       numel(patternList));
                  

% Convert into cell array of strings
pathArr = textscan(currentPath, '%s','Delimiter', pathsep);
pathArr = pathArr{:}; %unwrap one level of cell, now [n,1] cell of strings

% Search matches to patterns
for k = 1:length(patternList)  
    inclusionMatch(:,k) = cellfun(@isempty, strfind(pathArr, patternList{k}));
end

% Select rows that DO MATCH ANY of the patterns
exclusionMatch = sum(inclusionMatch, 2)~=size(inclusionMatch,2);
rmpathArr = pathArr(exclusionMatch, 1);

% Remove directories
for i = 1:numel(rmpathArr)
    rmpath(rmpathArr{i});
end