function [labels, diffData] = compare_configuration_structs(Cfg1, Cfg2)
%COMPARE_CONFIGURATION_STRUCTS - Compare CTAP conf structs
%
% Description:
%   Compares two CTAP configuration structs and reports any differences.
%
%
% Syntax:
%   [labels, diffData] = compare_configuration_structs(Cfg1, Cfg2);
%
% Inputs:
%   Cfg1    struct, CTAP configuration struct
%   Cfg2    struct, CTAP configuration struct
%
% Outputs:
%   labels      [1,3] cell of strings, Labels for the data columns
%   diffData    [m,3] cell, Differences: {field name, value in Cfg1,
%                           value in Cfg2}
%
% Assumptions:
%
% References:
%
% Example:
%   Cfg1 = cfg_wcst_testing();
%   Cfg2 = cfg_wcst_pilot_noprepro();
%   [labs, diffs] = compare_configuration_structs(Cfg1, Cfg2);
%
% Notes:
%
% See also: 
%
% Version History:
% 14.10.2014 Created (Jussi Korpela, FIOH)
%
% Copyright 2014- Jussi Korpela, FIOH, jussi.korpela@ttl.fi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('Cfg1', @isstruct);
p.addRequired('Cfg2', @isstruct);

p.parse(Cfg1, Cfg2);
Arg = p.Results;


%% Compare
labels = {'fieldName','Cfg1','Cfg2'};
diffData = sbf_get_differences(Cfg1, Cfg2);

 
%% Subfunctions   
    function diffCell = sbf_get_differences(S1,S2)
        % Main function that reports differences
        % Called recursively to traverse the struct

        fnames1 = fieldnames(S1);
        fnames2 = fieldnames(S2);
        fnames = union(fnames1, fnames2);
        diffCell = {};
        
        for i = 1:numel(fnames) %over all fieldnames in either struct
            if (ismember(fnames{i}, fnames1) &&...
                ismember(fnames{i}, fnames2))
                % field in both S1 and S2
                
                if isstruct(S1.(fnames{i}))
                    % field is struct -> recursive call
                    diffLine = sbf_get_differences(S1.(fnames{i}),...
                                            S2.(fnames{i}));
                    if ~isempty(diffLine)
                        diffLine(:,1) = strcat(fnames{i},'.',diffLine(:,1));
                        diffCell = vertcat(diffCell, diffLine);
                    end
                else 
                    % field not struct -> check for differences
                    if ~sbf_eq(S1.(fnames{i}),S2.(fnames{i}))
                        diffLine = {fnames{i},...
                                    sbf_to_string(S1.(fnames{i})),...
                                    sbf_to_string(S2.(fnames{i}))};
                        diffCell = vertcat(diffCell, diffLine);
                    end
                end
                
            else
                % field not in both structs
                if ~(ismember(fnames{i}, fnames1))
                    diffLine = {fnames{i}, 'not present', S2.(fnames{i})};
                else
                    diffLine = {fnames{i}, S1.(fnames{i}), 'not present'};
                end
                diffCell = vertcat(diffCell, diffLine);
            end %if: field in both
        end %for: fnames
        
    end %func: sbf_get_differences

    function tf=sbf_eq(el1, el2)
        % Custom implementation of eq()
        if (ischar(el1) && ischar(el2))
            tf = strcmp(el1,el2);
        elseif (isnumeric(el1) && isnumeric(el2))
            tf = el1==el2;
        elseif (iscell(el1) && iscell(el2))
            tf = all(cellfun(@sbf_eq, el1, el2));
        else
            error();
        end
    end

    function str=sbf_to_string(el)
        % String representations of different objects
       if iscell(el)
           str=cellstr(el);
       elseif isnumeric(el)
           str=num2str(el);
       elseif ischar(el)
           str=el;
       else
           error();
       end
    end


end %of compare_configuration_structs