% An example script to set up Matlab path for CTAP use
%
% Note: It is very important to add CTAP dependencies and EEGLAB to the
% _end_ of Matlab path to avoid unnecessary function name collissions.

% Add EEGLAB
% eeglab_path = '/home/your/path/to/EEGLAB/eeglab14_1_1b';
% sbf_addrepopath(eeglab_path, '-end');

% Add CTAP
[ctap_path, ~, ~] = fileparts(mfilename('fullpath'));
sbf_addrepopath(fullfile(ctap_path, 'ctap'), '-end');
sbf_addrepopath(fullfile(ctap_path, 'dependencies'), '-end');

    function sbf_addrepopath(pin)
        if ~isfolder(pin)
            error 'Repo path does not exist!'
        end
        ptharr = strsplit(genpath(pin), ':');
        excl = cellfun(@(x) [filesep x], {'.Rproj' '.git'}, 'Unif', false);
        addpath(strjoin(ptharr(~contains(ptharr, excl)), ':'), '-end');
    end