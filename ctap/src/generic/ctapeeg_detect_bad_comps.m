function [EEG, varargout] = ctapeeg_detect_bad_comps(EEG, varargin)
%CTAPEEG_DETECT_BAD_COMPS use some given method to find bad ICA components
%
% Syntax:
%   [EEG, varargout] = ctapeeg_detect_bad_comps(EEG, varargin)
% 
% Input:
%   'EEG'         EEG file to process
% 
% varargin:
%   'outdir'      output directory
%   'method'      choose method from options (default depends on component 
%                 count, count<32=rejspec, count>32=recufast) -
%             'faster' - one use of FASTER indices (non-recursive)
%             'recufast' - recursive use of FASTER indices
%             'adjust' - use the ADJUST toolbox
%             'extreme_values' - thresholding based on standard deviations,
%                             replaces eegthresh()
%             'abnormal_spectra' - detect abnormal spectra
%             'blink_template' - detect blink related IC's based on "blink ERP"
%
%   FOR 'FASTER' method
%   'bounds'      sigma thresholds to detect bad components with FASTER method
%                 Default = [-2 2]
% 
%   FOR 'recufast' recursive FASTER method
%   'bounds'      sigma thresholds to detect bad components with recufast method
%                 Default = [-3 3]
%   'iters'       number of iterations to use in 'recufast' method
%                 Default = 5
%   'report'      false or true, produce/save visuals of bad comps
%                 Default = false
%   'outdir'      directory to save report outputs
%                 Default = ''
% 
%   FOR 'adjust' method
%   'adjustargs'  cell array of ADJUST specific arguments
%
%   FOR 'extreme_values' reject outliers by threshold method
%   'frame_size'  Default = EEG sample rate
%   'comps'       components to test.
%                 Default = all within EEG.icaact; or if empty = eeg_getica()
%   'thr'         [lower upper] standard deviation limit(s).
%                 Default = [-2 2]
%
%   FOR 'abnormal_spectra', reject channel spectra method
%   'frame_size'   Defatul=EEG sample rate
%   'freq_lims'    [lower upper] frequency limit(s) in Hz. Rows denote
%                 multiple frequency bands.
%                 Default=[0 2; 20 40]
%   'thr'         [lower upper] threshold limit(s). Can be in rows.
%                 Default=[5 -5; -3 3]
%   'cmpSpcMethod'  ['fft'|'multitaper'] method to compute spectrum.
%                 Default='multitaper'
%
% Output:
%   'EEG'         struct, modified input EEG
% varargout:
%   {1}           struct, the complete list of arguments actually used
%   {2}         : struct, 3 fields: 
%                 .comps - indices of independent components marked as bad
%                 .scores - table with scores for badness of ICs
%                 .method_data - optional method specific data
%
% NOTE:     to extend this function with additional methods of detecting
%           bad ICs, note that internal variable 'comp_match' must be
%           logical vector [1:size(EEG.icaact,1)], and 'result.method_data'
%           must be a table with rows for each IC and columns of scores for
%           each method testing IC badness
%
% CALLS     recufast_badness_detector, ctapeeg_ADJUST, reject_extreme_values,
%           reject_component_spectrum, sbf_detect_ICs_blinktemplate
%
% REFERENCE:
%   Delorme, A., Sejnowski, T., & Makeig, S. (2007). Enhanced detection of 
%   artifacts in EEG data using higher-order statistics and independent 
%   component analysis. NeuroImage, 34(4), 1443-9.
%   Nolan, H., Whelan, R., & Reilly, R. B. (2010). FASTER: Fully Automated 
%   Statistical Thresholding for EEG artifact Rejection. Journal of Neuroscience 
%   Methods, 192(1), 152–162.
%   Mognon, A., Jovicich, J., Bruzzone, L., & Buiatti, M. (2011). ADJUST: An 
%   automatic EEG artifact detector based on the joint use of spatial and
%   temporal features. Psychophysiology, 48(2), 229–240.
%
% Version History:
% 20.10.2014 Created (Benjamin Cowley, FIOH)
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

icacomps = 1:size(EEG.icaact,1);

sbf_check_input() % parse the varargin, set defaults

result = struct('method_data', '', 'scores', []);

%% Call the CHOSEN method
% from simple to complex methods
switch Arg.method
    case 'extreme_values'
        [rejval, ~] = reject_extreme_values(...
            EEG, Arg.frame_size, Arg.thr, Arg.comps);
        bad_comp_match = rejval > Arg.std_ratio_thr;
        result.scores = table(rejval...
            , 'RowNames', cellstr(num2str(Arg.comps'))...
            , 'VariableNames', {sprintf('prop_of_%d_sample_bins_lt%d_gt%d_stdev'...
            , Arg.frame_size, Arg.thr(1), Arg.thr(2))});
        
    case 'abnormal_spectra'
        [rejval, ~] = reject_component_spectrum(...
            EEG, 'frame_size', Arg.frame_size, 'thr', Arg.thr,...
            'freq_lims', Arg.freq_lims, 'comp_list', icacomps,...
            'method', Arg.cmpSpcMethod);
        bad_comp_match = rejval > 0;
        result.scores = table(rejval...
            , 'RowNames', cellstr(num2str(icacomps'))...
            , 'VariableNames', {'numBinsXBandsthr'});
        
    case 'faster'
        % latent parameters: blink, any|all, metric
        EOG = get_eeg_inds(EEG, {'EOG'});
        icbad = component_properties(EEG, EOG, 1, icacomps);
        [~, all_bad, ~] = min_z(icbad, struct('z', Arg.bounds(2)));
        bad_comp_match = icacomps(all_bad');
        result.scores =...
            table(icbad(:,1), icbad(:,2), icbad(:,3), icbad(:,4), icbad(:,5)...
            , 'RowNames', cellstr(num2str(icacomps'))...
            , 'VariableNames'...
            , {'corICxEOG' 'kurtosis' 'spectralSlope' 'Hurst' 'medianGrad'});
        
    case 'recufast'
        recu_out = recufast_badness_detector(...
                    EEG, struct(), icacomps, Arg.bounds, Arg.iters, 'comp',...
                    'outdir', Arg.outdir, 'report', Arg.report );
        bad_comp_match = recu_out.bad_bin(2, :) > 0;
        result.scores =...
            table(recu_out.bad_bin(2, :)' ...
            , 'RowNames', cellstr(num2str(icacomps'))...
            , 'VariableNames', {'recursiveFASTER'});
        
    case 'adjust'
        if ~iscell(Arg.adjustarg), Arg.adjustarg = {Arg.adjustarg}; end
        [bad_comp_match, horiz, verti, blink, disco] = ctapeeg_ADJUST(EEG...
            , 'detect', Arg.adjustarg...
            , 'icomps', icacomps);
        tmp = table(horiz', verti', blink', disco'...
            , 'RowNames', cellstr(num2str(icacomps'))...
            , 'VariableNames', {'horizntl' 'vertical' 'blinks' 'disconts'});
        idx = ismember({'horiz' 'verti' 'blink' 'disco'}, Arg.adjustarg);
        result.scores = tmp(:, idx);

    case 'blink_template'
        [bad_comp_match, tmp] = sbf_detect_ICs_blinktemplate();
        result.method_data = tmp.blinkERP;
        result.scores = table(tmp.thArr...
            , 'RowNames', cellstr(num2str(icacomps'))...
            , 'VariableNames', {'blinkSimilarityRads'});

end


%% check and return results.
if islogical(bad_comp_match)
    result.comps = find(bad_comp_match);
else
    result.comps = bad_comp_match;
end

if ~istable(result.scores)
    error('ctapeeg_detect_bad_comps:bad_output',...
        'Bad IC scores returned by ''%s'' must be in table format', Arg.method)
end

varargout{1} = Arg;
varargout{2} = result;


%% Subfunctions
    function sbf_check_input() % parse the varargin, set defaults
        % Unpack and store varargin
        if isempty(varargin)
            vargs = struct;
        elseif numel(varargin) > 1 %(assume parameter/name pairs)
            vargs = cell2struct(varargin(2:2:end), varargin(1:2:end), 2);
        else
            vargs = varargin{1}; %(assume a struct wrapped in a cell)
        end

        % If desired, the default values can be changed here:
        try Arg.method = vargs.method;
        catch
            if numel(icacomps) > 32, Arg.method = 'recufast';
            else Arg.method = 'extreme_values';
            end
        end

        switch Arg.method %#ok<*ALIGN>
            case 'recufast'
                Arg.bounds = [-3 3];
                Arg.iters  = 5;
                Arg.report = false;
                Arg.outdir = '';
                
            case 'faster'
                Arg.bounds = [-2 2];

            case 'adjust'
                Arg.adjustarg = {'horiz' 'verti' 'blink' 'disco'};

            case 'extreme_values'
                Arg.frame_size = EEG.srate;
                Arg.thr = [0 2];
                Arg.comps = icacomps;
                Arg.std_ratio_thr = .6;

            case 'abnormal_spectra'
                Arg.frame_size = EEG.srate;
                Arg.thr = [-90 100];
                Arg.freq_lims = [25 45];
                Arg.cmpSpcMethod = 'multitaper';
                
            case 'blink_template'
                Arg.thr = 0.7; %threshold value (def=radians)
                
            otherwise
                error('ctapeeg_detect_bad_comps:bad_method',...
                    'Method %s not recognised, aborting', Arg.method)

        end
        
        % Arg fields are canonical, vargs values are canonical: intersect-join
        Arg = intersect_struct(Arg, vargs);
    end


    function [comp_match, method_data] = sbf_detect_ICs_blinktemplate()
        % Add blinks if missing
        if ( ~ismember('blink',unique({EEG.event.type})) )
            error('ctapeeg_detect_bad_comps:noBlinkEvents',...
                ['No events of type ''blink'' found. Cannot proceed with'...
                ' blink template matching. Run CTAP_blink2event() to fix.'])
        end
        % Detect components
        [comp_match, th_arr] = eeglab_detect_icacomps_blinktemplate(EEG...
            , 'leqThreshold', Arg.thr);

        % Compute blink ERP for future reference
        EEGbl = pop_epoch( EEG, {'blink'}, [-0.3, 0.3]);
        EEGbl = pop_rmbase( EEGbl, [-300, 0]);
        blERPdf = create_dataframe(mean(EEGbl.data,3),...
            {'channel','time'},...
            {{EEGbl.chanlocs.labels}, EEGbl.times});

        method_data.thArr = th_arr;
        method_data.blinkERP = blERPdf;
        
    end %sbf_detect_ICs_blinktemplate()

end % ctapeeg_detect_bad_comps()
