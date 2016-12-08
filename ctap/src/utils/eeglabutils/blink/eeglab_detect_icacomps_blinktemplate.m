function [comps_match, th_arr] = eeglab_detect_icacomps_blinktemplate(EEG, varargin)
%EEG_DETECT_ICACOMPS_BLINK - Detect ICA components that are blink related
%
% Requires events of type 'blink' to be present in EEG.event.
%% Parse input arguments and set varargin defaults
p = inputParser;
p.addRequired('EEG', @isstruct);
p.addParameter('templateCompFun', @sbf_vecangle, @(x)isa(x,'function_handle'));
p.addParameter('leqThreshold', 0.5, @isnumeric); %threshold value (def=radians)
p.addParameter('blinkEventType', 'blink', @ischar);
p.parse(EEG, varargin{:});
Arg = p.Results;


%% Blink template
fprintf(1,'%s\n','Constructing blink template ...');

blink_match = ismember({EEG.event.type}, Arg.blinkEventType);

if sum(blink_match)>0
    blink_inds = int64([EEG.event(blink_match).latency]);
    bAmps = EEG.data(:,blink_inds);
    blinkTemplate = mean(bAmps, 2);
else
    msg = 'Could not construct blink template. Are blink events missing?'; 
    error('eeglab_detect_icacomps_blinktemplate:blinkTemplateError',msg); 
end

% Make zero mean and unit variance to avoid false result due to baseline
% offset and such
blinkTemplate = blinkTemplate / std(blinkTemplate);
blinkTemplate = blinkTemplate - mean(blinkTemplate);
    
%% Compare the vector angle between blink template and component scalp 
%% projection (i.e. ICA "mixing matrix" = A = EEG.icawinv).
%
% Angle threshold selection:
%   1. Fig. 3 in [Li2006] suggests 0.35 rad for a good threshold
%   2. Some TTL studies indicate 0.3. 
%   3. During HOITStress project it was observed that 0.3 is too
%       tight boundary.
%   4. In Uupuneet-project some clearly blink related ICs had angle values 
%       around 0.7. The threshold was increased to get these detected.

% Flag SCs based on blink template
% Flag SCs whose scalp map fits predefined "blink scalp map"


% size(EEG.icawinv) = [nchan, nIC]    
th_arr = NaN(size(EEG.icawinv,2),1);
for i = 1:size(EEG.icawinv, 2) 
    th_arr(i,1) = Arg.templateCompFun(EEG.icawinv(:,i),...
                                        blinkTemplate(EEG.icachansind));
end  
fprintf(1,'Using leqThreshold %3.2f ...\n',Arg.leqThreshold);
comps_match = th_arr <= Arg.leqThreshold;

%{
% Debug:
abs(EEG.icawinv(:,4)'*-blinkTemplate(EEG.icachansind))
abs(EEG.icawinv(:,20)'*blinkTemplate(EEG.icachansind))

[a,b] = min(th_arr);
figure
plot(blinkTemplate(EEG.icachansind)/std(blinkTemplate(EEG.icachansind)),'-b')
hold on
plot(EEG.icawinv(:,4)/std(EEG.icawinv(:,4)),'-r')
plot(EEG.icawinv(:,20)/std(EEG.icawinv(:,4)),'-g')
%}


%% Additional criteria
% If _none_ of the IC's are below the threshold criterion select the one
% with the lowest criterion value
if sum(comps_match)==0
    [~, ind] = min(th_arr);
    comps_match(ind) = true;
end


%% Subfunctions
    function value = sbf_vecangle(vec1, vec2)
        vec1 = vec1(:);
        vec2 = vec2(:);
        value = acos( abs(vec1'*vec2)/(norm(vec1,2) * norm(vec2,2)) );
    end
end