% Generate html documentation using m2html
% See: http://www.artefact.tk/software/matlab/m2html/
% BitBucket: ~/external_tools/m2html/
% 

%% Setup
mfilesArr = {'pipeline','modules','utils'};
htmldir = fullfile('.','doc','html');

%% Generate
[succ, msg, msgid] = mkdir(htmldir);
m2html( 'mfiles',mfilesArr,...
        'htmldir',htmldir,...
        'recursive','on',...
        'global','on');
