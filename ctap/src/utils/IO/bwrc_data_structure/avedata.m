function [SEGMENT, Var] = avedata(SEGMENT, classifier, Var, varargin)
% AVEDATA - Average data in an ATTK data structure variable
%
% TODO: Muuta funktiota s.e. sellaiset SEGMENT struktuurin metadata sarakkeet,
%       jotka eiv�t ole uniikkeja valitun luokittelijan osajoukoissa, poistetaan
%       automaattisesti. N�in v�ltet��n virheilt� huolimattoman k�ytt�j�n
%       k�ytt�ess� funktiota.
%
% Description:
%   Averages ATTK data struct data over one classifier variable. Returns
%   averaged results for data variable 'Var' as well as modified SEGMENT
%   struct.
%
% Syntax:
%   [SEGMENT, Var] = avedata(SEGMENT, classifier, Var, varargin);
%
% Inputs:
%   SEGMENT     struct, SEGMENT struct as described in ATTK data structure [1]
%   classifier  string, A column name from SEGMENT to be used as averaging
%               basis. See SEGMENT.labels for a list of available
%               classifiers.
%   Var         struct, ATTK data structure variable, e.g. S, BP, EIND
%
%   varargin    Keyword-value pairs
%   Keyword     Type, description, value
%   'avefun'    function handle, Function to use in averaging, Function 
%               'avefun' should operate on a numeric vector and return 
%               scalar, defaults to @nansumean but can also be e.g. @nansuvar,
%               @nansumedian, @mean, @var, @median
%   'classifiersToDrop' [1,k] cell of strings, column names from SEGMENT to
%                       exclude from the modified SEGMENT struct (see Outputs).
%                       Define here all the classifiers that lose their
%                       meaning as a result of averaging.
%
% Outputs:
%   SEGMENT     struct, A modified SEGMENT struct that matches the averaged
%               data. Metadata columns in SEGMENT that are not unique
%               within subsets defined by metadata column 'classifier' 
%               should be excluded from the results. Currently this 
%               exclusion is not automatic but happens via the varargin 
%               option 'classifierToDrop'.   
%
% Assumptions:
%
% References:
%
% Example:
%  [NEWSEGMENT, Avgvar] = avedata(SEGMENT, 'block', S,...
%                         'classifiersToDrop',{'cs_n','cs_start','cs_end'},...
%                         'avefun', @nansuvar);
%
% Notes:
%
% See also:
%
% Version History:
% 2008 Created (Jussi Korpela, TTL)
%
% Copyright 2008- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default parameter values
% Field names of 'Arg' can be used as keywords.

% Function 'Arg.avefun' will operate on a 2D matrix, It should operate on 
% a numeric vector and return scalar.
Arg.avefun = @nansumean; %e.g. @nansumean, @nansuvar, @nansumedian, @mean, @var, @median

Arg.classifiersToDrop = {''};


%% Interpret 'varargin'
% Overwrite default parameter values with user-defined ones
if ~isempty(varargin)
    Arg = input_interp(varargin, Arg);
end


%% Classifier position and levels
cfmatch = strcmp(SEGMENT.labels, classifier);
cflevels = unique(SEGMENT.data(:,cfmatch));


%% Average data in 'Var'
if (Var.sublevels.n == 0)
    % 'Var' has no sublevels
   
    % Average
    tmpdata = NaN(length(cflevels), length(Var.labels)); 
    for n = 1:length(cflevels)
        n_cfmatch = strcmp(SEGMENT.data(:,cfmatch), cflevels{n});
        
        % Function 'Arg.avefun' will operate on a 2D matrix
        % Function Arg.avefun should operate on a numeric vector and 
        % return scalar.
        tmpdata(n,:) = colapply(Arg.avefun, Var.data(n_cfmatch,:));
        clear('n_');
    end
    Var.data = tmpdata;
    
elseif (Var.sublevels.n == 1)
    % 'Var' has 1 sublevel
    
    % Find out sublevel names
    fields = fieldnames(Var);
    non_sb_match = strArrayFind(fields, {'labels','units','parameters','sublevels'});
    sublevels = fields(~non_sb_match);
    
    % Average for every sublevel
    for k = 1:length(sublevels)
        k_tmpdata = NaN(length(cflevels), length(Var.labels)); 
        for n = 1:length(cflevels)
            n_cfmatch = strcmp(SEGMENT.data(:,cfmatch), cflevels{n});
            
            % Function 'Arg.avefun' will operate on a 2D matrix
            % Function Arg.avefun should operate on a numeric vector and 
            % return scalar.
            k_tmpdata(n,:) = colapply(Arg.avefun, Var.(sublevels{k}).data(n_cfmatch,:));            
            clear('n_');
        end
        Var.(sublevels{k}).data = k_tmpdata;
        clear('k_');
    end
    
else
    % No support for more than one sublevels ... yet
   error('avedata:inputTypeError','Variables with more than one sublevel are not yet supported.'); 
end
    

%% Modify 'SEGMENT'

% Define columns to keep
cf_drop_match = strArrayFind(SEGMENT.labels, Arg.classifiersToDrop);
cf_keep_pos = find(~cf_drop_match);

% Initialize variables
tmpdata = cell(length(cflevels), length(cf_keep_pos));
n_avg = NaN(length(cflevels),1);


for n = 1:length(cflevels)
    % Rows that belong to subset: classifier==cflevels{n}
    n_cfmatch = strcmp(SEGMENT.data(:,cfmatch), cflevels{n});
    n_avg(n) = sum(n_cfmatch);
    
 
    for m = 1:length(cf_keep_pos) % over columns (=classifiers) to keep
        
        % m:th classifier data at subset: classifier==cflevels{n}
        test = SEGMENT.data(n_cfmatch, cf_keep_pos(m));
        
        % Convert numeric values to strings for comparison
        if isnumeric(test{1})
            test = cellfun(@num2str, test, 'UniformOutput', false);
        end
        
        % Test if m:th classifier is unique in subset: classifier==cflevels{n}
        test = unique(test);
        if length(test) == 1
            tmpdata(n,m) = test;
        else
            % Classifier m is not constant in subset => issue warning
            % User should drop variables that are not constant within
            % subsets of 'classifier'. 
            msg = ['Classifier ', SEGMENT.labels{cf_keep_pos(m)} ,...
                ' is not constant when ', classifier,'==',cflevels{n},'.\n',...
                'Consider dropping ', SEGMENT.labels{cf_keep_pos(m)}, ...
                ' completely.'];
            warning('avedata:nonUniqueSet', msg); 
            tmpdata(n,m) = test(1);
        end
    end
    
    clear('n_');
end

SEGMENT.data = horzcat(tmpdata, mat2cell(n_avg, ones(1,length(n_avg),1)));
SEGMENT.labels = horzcat(SEGMENT.labels(cf_keep_pos), 'n_avg');
SEGMENT.units = horzcat(SEGMENT.units(cf_keep_pos), 'count');