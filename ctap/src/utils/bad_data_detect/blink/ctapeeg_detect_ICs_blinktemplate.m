function [comp_match, method_data] = ctapeeg_detect_ICs_blinktemplate(EEG, Arg)
%CTAPEEG_DETECT_ICS_BLINKTEMPLATE
% 

    % Add blinks if missing
    if ( ~ismember('blink',unique({EEG.event.type})) )
        error('ctapeeg_detect_ICs_blinktemplate:noBlinkEvents',...
            ['No events of type ''blink'' found. Cannot proceed with'...
            ' blink template matching. Run CTAP_blink2event() to fix.'])
    end
    % Detect components
    [comp_match, th_arr] = eeglab_detect_icacomps_blinktemplate(EEG...
        , 'leqThreshold', Arg.thr);

    % Compute blink ERP for future reference
    EEGbl = pop_epoch( EEG, {'blink'}, [-0.3, 0.3]);
    EEGbl = pop_rmbase( EEGbl, [-300, 0]);
    blERPdf = create_dataframe(mean(EEGbl.data, 3),...
        {'channel', 'time'},...
        {{EEGbl.chanlocs.labels}, EEGbl.times});

    method_data.thArr = th_arr;
    method_data.blinkERP = blERPdf;

end %ctapeeg_detect_ICs_blinktemplate()
