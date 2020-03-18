function [outlier_match, th, scores] = mvoutlier(dmat, varargin)
%MVOUTLIER - Multivariate outlier detection
%
% Description:
%   Detects outliers from multivariate datasets.
%   Designed to accomodate a variety of outlier scoring methods and score
%   thresholding methods.
%
% Syntax:
%   outlier_match = mvoutlier(dmat, varargin);
%
% Inputs:
%   dmat [n,m] numeric, n observations of m variables
%
%   varargin    Keyword-value pairs
%   Keyword         Type, description, values
%   'scoreMethod'   str, Method to compute outlier scores,
%                   default:'rbmahalanobis'
%                   other options:
%   'thMethod'      str, Method to determine cut-off for the outlier scores,
%                   default:'hampel'
%                   other options:
%   'factorVal'     int, factor by which to multiply mad of scores
%                   default:3
%
% Outputs:
%   outlier_match   [n,1] logical, A logical vector indicating the outlier
%                   values
%   th              [1,2] numeric, Non-outlier data interval for the
%                   outlier scores
%   scores          [n,1] numeric, Outlier scores for the observations
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
% 25.6.2014 Created (Jussi Korpela, FIOH)
%
% Copyright 2014- Jussi Korpela, FIOH, jussi.korpela@ttl.fi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('dmat', @ismatrix);
p.addParameter('scoreMethod', 'rbmahalanobis', @ischar);
p.addParameter('thMethod', 'hampel', @ischar);
p.addParameter('factorVal', 3, @isnumeric);
p.parse(dmat, varargin{:});
Arg = p.Results;

%% Compute outlier scores
switch Arg.scoreMethod
    case 'rbmahalanobis'
        opts.cor=1; %turns on returning of robust cov matrix
        opts.lts=1; %disables GUI components (undocumented feature)
        fmcdr = fastmcd(dmat, opts);
        scores = sqrt(mahalanobis(dmat, median(dmat,1), 'cov',fmcdr.cov));
        
    otherwise
        error(); %#ok<*LTARG>
end

%% Threshold scores
switch Arg.thMethod
    case 'hampel'
        min_th = 0;
        max_th = median(scores) + Arg.factorVal * olof_mad(scores);
        th = [min_th, max_th];
        
    otherwise
        error();
end

%% Determine match
outlier_match = (scores < min_th) | (max_th < scores);
