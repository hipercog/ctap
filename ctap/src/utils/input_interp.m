function Arg = input_interp(vararginArray, Defaults, varargin)
%INPUT_INTERP - Convert varargin keyword-value pair input into struct
%
% Description:
%   Converts a "varargin" cell array, that contains property-value -pairs,
%   into struct.
%   'vararginArray' is converted into a struct 'Arg' whose field names are 
%   strings extracted from 'vararginArray'. The field created from 
%   'vararginArray{i}' gets the value vararginArray{i+1}, 
%   where i=1:2:length(vararginArray).
%   If default values for the vararginArray keys are provided using 
%   argument 'Defaults', the output 'Arg' will be initialized with these 
%   default values. Any default values also defined in vargarginArray will 
%   be substituted with the value present in vararginArray.
%   If 'Defaults' is present, 'vararginArray' will also be checked for any
%   keys without a default value. If such keys are found, they most likely
%   are incorrectly typed. This key checking can be turned off using
%   varargin 'useKeyChecking'.
%
% Syntax:
%   Arg = input_interp(vararginArray, Defaults, varargin);
%
% Inputs:
%   vararginArray   1-by-m cell of strings, varargin keyword-value -pairs
%   Defaults             struct [optional], Default values for different
%                   varargin keywords. If missing, input_interp simply
%                   converts 'vararginArray' into struct.
%   varargin        Keyword-value pairs
%   Keyword             Type, description, values
%   'useKeyChecking'    logical, Should vararginArray keys be checked for 
%                       default values. If true, key checking takes 
%                       place if 'Defaults' is provided. {true (default),
%                       false}
%
% Outputs:
%   Arg             struct, 'vararginArray' data in struct form or a
%                   combination of data from 'Defaults' and 'vararginArray' 
%
% Example:
%   Defaults.keyword1 = 2;
%   Defaults.keyword2 = 'test';
%   Arg = input_interp({'keyword1',3}, Defaults);
%
% See also:
%
% Version History:
%   Check for varargin keys that do not have default value added (21.7.2009, jkor, TTL)
%   Optional input variable 'Defaults' added (29.5.2007, jkor, TTL))
%   Created (25.1.2007, Jussi Korpela, TTL)
%
% Copyright 2007- Jussi Korpela, TTL 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Default values for varargin & create struct
Arguments.useKeyChecking = true; %{true, false}

% Create struct
% Override any defaults above with varargin values. No "spellchecking"
% here. :)
if ~isempty(varargin)
    for i=1:2:length(varargin)
       Arguments.(varargin{i}) = varargin{i+1}; 
    end
end

%% Initialize 'Arg'
if exist('Defaults','var')
    Arg = Defaults; %initialize with defaults
    check_keys = true;
else
    Arg = struct(); %create a new array
    check_keys = false;
end

%% Check for keywords with missing default values
% Usually when input_interp is called with two arguments, the second
% argument contains default values for all allowed varargin keys. Keys with
% missing default value are usually misspelled and cause hard-to-detect odd
% behaviour! Hence the warning. Use varargin 'useKeyChecking' to turn this
% feature off.
if check_keys && Arguments.useKeyChecking
    keyword_inds = 1:2:length(vararginArray);
    common_keys = intersect(fieldnames(Defaults),vararginArray(keyword_inds));
    keys_with_missing_default = setdiff(vararginArray(keyword_inds), common_keys);

    if ~isempty(keys_with_missing_default)
        msg = ['Varargin keys ''', catcellstr(keys_with_missing_default, 'sep', ''', '''),...
               ''' have no default value set. Check that these keys are not misspelled!'];
       warning('intput_interp:keysLackDefaults', msg); 
    end
end


%% Assign 'vararginArray' into 'Arg'
i = 1;
stop = 0;
while stop == 0 
    if  i >= length(vararginArray) 
         stop = 1;
         
    elseif ischar(vararginArray{i})
        Arg.(vararginArray{i}) = vararginArray{i+1};
        i = i+2;
        
    else
        i=1+i;
    end
end