function [SWEEG, PARAMS] = CTAP_pipeline_sweeper(EEGin, Pipe, PipeParams, Cfg, SweepParams)
%CTAP_pipeline_sweeper - Parameter sweep for a short pipe
%
% Description:
%   Implements parameter sweep for a (short) analysis pipe.
%   Only one parameter can be swept.
%
% Syntax:
%   SWEEG = CTAP_pipeline_sweeper(EEGin, Pipe, PipeParams, Cfg, SweepParams);
%
% Inputs:
%   'EEGin'         struct, EEGLAB dataset
%   'Pipe'          function handle array, specifies the pipe funtions
%   'PipeParams'    struct, Parameters for pipe functions
%   'SweepParams'   struct, What to sweep
%       .funName    string, name of function
%       .paramName  string, name of parameter
%       .values     [1,m] cell, parameter values to use in sweep
%   varargin    Keyword-value pairs
%   Keyword     Type, description, values
%
% Outputs:
%   SWEEG [1,m] struct, Processed EEG datasets, one per sweep value
%
% Assumptions:
%
% References:
%
% Example:
%
% Notes: 
%
% See also: 
%
% Version History:
% 10.2.2017 Created (Jussi Korpela, FIOH)
%
% Copyright(c) 2017 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


pipeFun = strrep(SweepParams.funName, 'CTAP_', '');
SWEEG = {};
PARAMS = {};

for i=1:numel(SweepParams.values) %over sweep values
    EEG = EEGin;
    
    % Update pipe parameters
    PipeParams.(pipeFun).(SweepParams.paramName) = SweepParams.values{i};
    Cfg.ctap.(pipeFun) = PipeParams.(pipeFun);
    
    %todo: add test that SweepParams.paramName is a valid parameter of
    %pipeFun
    
    % Run pipe
    for k = 1:numel(Pipe) %over step sets
        for m = 1:numel(Pipe(k).funH) %over analysis steps
            Cfg.pipe.current.set = k;
            Cfg.pipe.current.funAtSet = m;
            [EEG, Cfg] = Pipe(k).funH{m}(EEG, Cfg);
        end
    end
    
    % Collect results
    SWEEG = horzcat(SWEEG, EEG);
    PARAMS = horzcat(PARAMS, Cfg.ctap);
end

end