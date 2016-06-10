function [EEG, Cfg] = CTAP_template_function(EEG, Cfg)
%CTAP_template_function - A template for creating CTAP wrapper functions
%
% Description:
%   CTAP wrapper function philosophy is that wrappers provide all code that
%   is specific to a single function AND to the CTAP pipeline. Generic code
%   should be higher in the call stack. Non-CTAP code should be in the 'core'
%   functions. Specifically a wrapper function:
%     1. makes a mapping between the parameters in Cfg and the inputs of
%        the core functions. Two core functions might have an input called 
%        "method" but with a different meaning. The wrapper layer defines 
%        which Cfg parameter changes which core function input.
%     2. allows one to combine several small core functions into a single 
%        larger analysis step.
%     3. provides a consistent interface that makes looping over analysis 
%        steps possible.
%     4. gives a place to (a) implement pipeline-related tests, (b) write logs
%
% Syntax:
%   [EEG, Cfg] = CTAP_template_function(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct should be updated with parameter values
%                       actually used
%
% Notes: 
%
% See also: <function 1>, <function 2>  
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% create Arg and assign any defaults to be chosen at the CTAP_ level
Arg = struct;
Arg.var = 'default';
% check and assign the defined parameters to structure Arg, for brevity
if isfield(Cfg.ctap, 'template_function')
    Arg = joinstruct(Arg, Cfg.ctap.template_function);%override with user params
end


%% ASSIST Perform any initialisation, helping or checking functionality.
%   Functionality can be set to happen automatically, or only if pipeline
%   flag is set
if isfield(Cfg.ctap, 'ASSIST')
end


%% CORE Call the desired core function. The default is hard-coded, but if
%   the author wants, he can set the wrapper to listen for a core function
%   defined in the pipeline as a handle alongside the function parameters
%   which will replace the default. Thus users can choose to use the
%   wrapper layer but not the core layer (not recommended, unstable).
if isfield(Arg, 'coreFunc')
    funHandle = Arg.coreFunc;
    fun_varargs = rmfield(Arg, 'coreFunc');
    [EEG, Arg, result] = funHandle(EEG, fun_varargs);
else
    % define the fixed core function(s), e.g. from ctap/src/core/ctapeeg_[...]
    % core function can further edit Arg, and returns anything else in 'result'
    [EEG, Arg, result] = default_core_function(EEG, Arg);
end
handle(Arg);
handle(result);


%% ERROR/REPORT
%... the complete parameter set from the function call ...
Cfg.ctap.template_function = Arg;
%log outcome to console and to log file
msg = myReport(sprintf('Informative message refers to args %s, %s.',...
    Arg.arg1, Arg.arg2), Cfg.env.logFile);
%create an entry to the history struct, with 
%   1. informative message, 
%   2. function filename
%   3. %the complete parameter set from the function call, for reference
EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);

%% MISC Miscellaneous additional actions following core function success
