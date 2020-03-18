function MC = read_measinfo_spreadsheet(xlsfile)
%READ_MEASINFO_SPREADSHEET - Read the MC from a spreadsheet
%
% Description:
%
% Syntax:
%   MC = read_measinfo_spreadsheet(mcfilename)
%
% Inputs:
%   mcfilename   The filename of the Excel spreadsheet containing the
%                measurement configuration (MC).
%
%                The following sheets are read from the MC
%                  - subject       (required)
%                  - measurement   (required)
%                  - blocks        (optional)
%                  - events        (optional)
% Outputs:
%   MC   A struct containing the information in the MC,
%        one field per sheet.
%
%
% Authors: Jussi Korpela and Andreas Henelius (FIOH, 2014)
% -------------------------------------------------------------------------

%% ------------------------------------------------------------------------
% Read the sheets
% -------------------------------------------------------------------------

[status, sheets] = xlsfinfo(xlsfile);

%% ------------------------------------------------------------------------
% Read sheet :: subject
% -------------------------------------------------------------------------

[~, ~, raw] = xlsread(xlsfile, 'subject');
MC.subject = cell2struct(raw(2:end,:), raw(1,:), 2);

% remove empty rows that appear no matter what
isnan_match = cellfun(@sbf_isnan, {MC.subject.subject});
MC.subject = MC.subject(~isnan_match);

clear('raw','isnan_match');

%% ------------------------------------------------------------------------
% Read sheet :: measurement
% -------------------------------------------------------------------------

[~, ~, raw] = xlsread(xlsfile, 'measurement');
MC.measurement = cell2struct(raw(2:end,:), raw(1,:), 2);

% remove empty rows that appear no matter what
isnan_match = cellfun(@sbf_isnan, {MC.measurement.casename});
MC.measurement = MC.measurement(~isnan_match);

%% ------------------------------------------------------------------------
% Read sheet :: blocks
% -------------------------------------------------------------------------

if numel(intersect('blocks', sheets))
    [~, ~, raw] = xlsread(xlsfile, 'blocks');
    MC.blocks = cell2struct(raw(2:end,:), raw(1,:), 2);
    
    % remove empty rows that appear no matter what
    isnan_match = cellfun(@sbf_isnan, {MC.blocks.casename});
    MC.blocks = MC.blocks(~isnan_match);
end
%% ------------------------------------------------------------------------
% Read sheet :: events
% -------------------------------------------------------------------------

if numel(intersect('events', sheets))
    [~, ~, raw] = xlsread(xlsfile, 'events');
    MC.events = cell2struct(raw(2:end,:), raw(1,:), 2);
    
    % remove empty rows that appear no matter what
    isnan_match = cellfun(@sbf_isnan, {MC.events.casename});
    MC.events = MC.events(~isnan_match);
end


%% ------------------------------------------------------------------------
% Helper function
% -------------------------------------------------------------------------

    function res = sbf_isnan(element)
        % Returns scalar logical for all inputs
        res = isnan(element);
        res = res(1);
    end

% -------------------------------------------------------------------------
end
