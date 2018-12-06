function [comp_match, method_data] = ctapeeg_recudetect_blink_ICs(EEG, varargin)
%CTAPEEG_RECUDETECT_BLINK_ICS measures the effect of removing each blink-like
% IC from the original data by projection.
% 
% Description: Similarity of each IC to the blink template
% is measured by eeglab_detect_icacomps_blinktemplate() and ICs are ordered 
% by this metric. Then the top Arg.test_pc% of ICs are tested in turn: 
%  - blink-locked 1 sec ERPs are generated for the VEOG channel
%  - each IC is removed from the data by projection, and the value by which this 
%    operation moves the quantile band [2.5% 97.5%] toward zero is calculated.
%  - IF this 'toward-zero-movement' vector is significantly different to
%    zero by t-test, AND if its CIs are broader than 2uV (showing
%    meaningful amount of change), AND if the peak change occurs between 250ms 
%    and 750ms (change is blink-related and centre-locked)...
%    THEN the IC is labelled as bad
% 
% Syntax:
%   [comp_match, method_data] = ctapeeg_recudetect_blink_ICs(EEG, varargin)
% 
% Input:
%   EEG             struct, eeg data to test
%
% Varargin:
%   veog            string, channel name for VEOG, default = 'VEOG'
%   test_pc         scalar, percentage of ICs to test, default = 25
%   epoch_len_secs  scalar, half-length of epoch to centre on blink in seconds,
%                   default = 0.3, based on the estimate here - 
%           http://bionumbers.hms.harvard.edu/bionumber.aspx?s=y&id=100706&ver=0
% 
% Output:
%   comp_match      logical, vector of logicals indexing bad ICs
%   method_data     struct, fields are :
%                   'thArr' containing the blink template similarity of each IC, 
%                   'blinkERP' a dataframe with blink ERP of each channel
%
% See also: 
%   eeglab_detect_icacomps_blinktemplate()
%
%
% Version History:
% 10.01.2017 Created (Benjamin Cowley, FIOH)
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('EEG', @isstruct);
p.addParameter('veog', 'VEOG', @iscell);
p.addParameter('test_pc', 25, @isscalar);
p.addParameter('epoch_len_secs', 0.3, @isscalar);

p.parse(EEG, varargin{:});
Arg = p.Results;
els = Arg.epoch_len_secs;


%% measure IC similarity to blink template
% Add blinks if missing
if ( ~ismember('blink',unique({EEG.event.type})) )
    error('ctapeeg_recudetect_blink_ICs:noBlinkEvents',...
        ['No events of type ''blink'' found. Cannot proceed with'...
        ' blink template matching. Run CTAP_blink2event() to fix.'])
end

% Detect components
[~, th_arr] = eeglab_detect_icacomps_blinktemplate(EEG, 'leqThreshold', 0);
comp_match = false(numel(th_arr), 1);


%% Compute blink ERP for comparison to detected ICs
EEGbl = pop_epoch(EEG, {'blink'}, [-els, els]);
EEGbl = pop_rmbase(EEGbl, [-els * 1000, 0]);
veogi = ismember({EEGbl.chanlocs.labels}, Arg.veog);
blERPdf = create_dataframe(mean(EEGbl.data, 3),...
    {'channel', 'time'},...
    {{EEGbl.chanlocs.labels}, EEGbl.times});

%test if detected IC removal gives clean blink ERP
veogd = squeeze(EEGbl.data(veogi, :, :));
blinkERP = ...
 [quantile(veogd', 0.025); blERPdf.data(veogi, :); quantile(veogd', 1 - 0.025)];
[~, test_idx] = sort(th_arr); %ascending sort: lower is better
for i = 1:ceil(numel(th_arr) * Arg.test_pc / 100) %consider only first X% of ICs.
    comp_match(test_idx(i)) = sbf_test_IC_removal(test_idx(i));
end

method_data.thArr = th_arr;
method_data.blinkERP = blERPdf;

    %% Subfunctions
    % test blinkIC against given blink template IC
    function [worked, peakdiff, pdi] = sbf_test_IC_removal(blinkIC)

        worked = false;

        %Compute blinkIC-subtracted ERP for comparison
        EEGcl = pop_subcomp(EEG, blinkIC);
        EEGcl = pop_select(EEGcl, 'channel', Arg.veog);
        EEGcl = pop_epoch(EEGcl, {'blink'}, [-els, els]);
        EEGcl = pop_rmbase(EEGcl, [-els * 1000, 0]);
        cleanERP = [quantile(squeeze(EEGcl.data)', 0.025);...
                    mean(EEGcl.data, 3);...
                    quantile(squeeze(EEGcl.data)', 1 - 0.025)];

        %numerically compare ERPs
        [erqdiff, h, ~, ~] = sbf_compare_erp_quantiles(blinkERP, cleanERP);
        if h
            worked = true;
        end
        %MAYBEDO - other criteria for classifying blink ICs might relate to
        %magnitude and timing of data change, i.e. blink removal should
        %generate changes larger than 1-2 uV, and with latency close to zer0
        [peakdiff, pdi] = max(erqdiff);
    end

    % Helper function to compare quantiles by how much they move toward zero
    function [erqdiff, h, p, ci] = sbf_compare_erp_quantiles(erq1, erq2)
        % working with [3 n] vectors of big quantiles, mean, little quantiles,
        % e.g. [2.5% M 97.5%]
        % measure how much erq2 moves the quantile band toward 0, i.e. denoises
        erqdiff = abs(diff([abs(erq1(1, :)); abs(erq1(3, :))])) -...
            abs(diff([abs(erq2(1, :)); abs(erq2(3, :))]));
        [h, p, ci] = ttest(erqdiff, 0, 'Alpha', 0.00005);
        %MAYBEDO - USE A TEST THAT ACCOMMODATES THE AUTOCORRELATION OF THIS
        %HIGHLY NON-INDEPENDENT SET OF OBSERVATIONS.
    end
    
end %ctapeeg_recudetect_blink_ICs()
