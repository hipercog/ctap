function [arms_wb, arms8h_wb, VDV_wb, armq4_wb, armq4_8h_wb, peak_a_wb, crest_factor_wb, akurtosis_wb, MSDV_wb, arms_un, arms8h_un, VDV_un, armq4_un, armq4_8h_un, peak_a_un, crest_factor_un, akurtosis_un, MSDV_un, vibs_metrics_description, vibs_metrics_units]=Vibs_calc_whole_body(vibs2hw_wb, vibs2, Fs)
% % Vibs_calc_whole_body: Calculates the metrics for the whole body vibrations
% % 
% % Syntax;
% % 
% % [arms, arms8h, VDV, awhr4, awhr4_8h, peak_a, crest_factor, awhkurtosis, MSDV, armsun, arms8hun, VDVun, ahr4un, ahr4_8hun, peak_aun, crest_factorun, akurtosisun, MSDVun]=Vibs_calc_whole_body(vibs2hw_wb, vibs2, Fs);
% % 
% % *****************************************************************
% % 
% % Description
% % 
% % This program calculates the continuous and impulsive whole body 
% % vibration metrics and outputs the numeric metric values, and a
% % description and units for each metric.  Currently there are no metrics 
% % for individual impulsive vibration peaks such as blunt trauma
% % due to dropping in an elevator.  
% % 
% % 
% % 
% % *****************************************************************
% % 
% % Input Variables
% % 
% % vibs2hw_wb=randn(1, 10000); % (m/s^2) whole body weighted rms acceleration 
% %                             % default is vibs2hw_wb=randn(1, 10000);
% %  
% %  
% % vibs2=randn(1, 10000);      % (m/s^2) Linear weighted rms acceleration 
% %                             % default is vibs2=randn(1, 10000); 
% %  
% %  
% % Fs=5000;                    % (Hz) Sampling Rate          
% %                             % default is Fs=5000;
% %  
% %  
% % *****************************************************************
% % 
% % Output Variables
% % 
% % Whole Body Weighted Outputs
% % 
% % arms_wb                     (m/s^2) Whole Body rms acceleration 
% % 
% % arms8h_wb                   (m/s^2) 8 hour rms acceleration 
% % 
% % VDV_wb                      (m/s^1.75) Vibration Dose Value (VDV)
% % 
% % armq4_wb                    (m/s^2) rmq acceleration 
% % 
% % armq4_8h_wb                 (m/s^2) 8 hour rmq acceleration 
% % 
% % peak_a_wb                   (m/s^2) Maximum Acceleration Value 
% % 
% % crest_factor_wb             (No Units) crest factor of acceleration 
% % 
% % akurtosis_wb                (No Units) kurtosis of acceleration 
% % 
% % MSDV_wb                     (m/s^1.75) Motion Sickness Dose 
% % 
% % 
% % 
% % UnWeighted Outputs 
% % 
% % arms_un                     (m/s^2) Unweighted rms acceleration 
% % 
% % arms8h_un                   (m/s^2) 8 hour rms acceleration 
% % 
% % VDV_un                      (m/s^1.75) Vibration Dose Value (VDV)
% % 
% % armq4_un                    (m/s^2) rmq acceleration 
% % 
% % armq4_8h_un                 (m/s^2) 8 hour rmq acceleration 
% % 
% % peak_a_un                   (m/s^2) Maximum Acceleration Value 
% % 
% % crest_factor_un             (No Units) crest factor of acceleration 
% % 
% % akurtosis_un                (No Units) kurtosis of acceleration 
% % 
% % MSDV_un                     (m/s^1.75) Motion Sickness Dose 
% % 
% % vibs_metrics_description    Cell Array of description of the vibrations
% %                                     metrics
% % 
% % vibs_metrics_units          Cell Array of Units of the vibrations
% %                                     metrics
% % 
% % *****************************************************************
% %
% % 
% % List of Dependent Subprograms for 
% % Vibs_calc_whole_body
% % 
% % FEX ID# is the File ID on the Matlab Central File Exchange
% % 
% % 
% % Program Name   Author   FEX ID#
% % 1) kurtosis_excess2		Edward Zechmann			
% %
% % 
% % *****************************************************************
% %
% % Program written by Edward Zechmann 
% % 
% %     date  3 August      2007    
% % 
% % modified  3 September   2008    Updated Comemnts
% %
% % modified  9 October     2009    Updated Comments
% %
% % modified 27 April       2010    Fixed a bug in the calculation of VDV 
% %                                 added num_samples to the equation
% %                                 (num_samples/Fs)^(1/4)
% % 
% % modified 27 April       2010    Fixed a bug in the calculation of VDV 
% %                                 (aa/Fs)^(1/4) is now => (1/Fs)^(1/4).  
% %                                 Thanks to Edward Francis of UK for 
% %                                 finding this bug.  
% % 
% % modified  4 January     2012    Bug from 27 April 2010 also found by 
% %                                 Wang Longqi.  Thanks for pointing out
% %                                 the bug so I could update the fix on 
% %                                 Matlab Central. 
% % 
% % 
% % 
% % *****************************************************************
% %
% %
% % Please Feel Free to Modify This Program
% %
% % See Also: whole_Body_Filter, Vibs_calc_whole_body
% %

if (nargin < 1 || isempty(vibs2hw_wb)) || ~isnumeric(vibs2hw_wb) 
    vibs2hw_wb=randn(1, 10000);
end

if (nargin < 2 || isempty(vibs2)) || ~isnumeric(vibs2) 
    vibs2=randn(1, 10000);  
end

if (nargin < 3 || isempty(Fs)) || ~isnumeric(Fs) 
    Fs=5000;
end


vibs_metrics_description=cell(1, 18);
vibs_metrics_units=cell(1, 18);

%vibs_metrics_description2={'arms_wb',  'arms8h_wb', 'VDV_wb',     'armq_wb^4', 'armq_8h_wb^4', 'Peak Accel_wb', 'Crest Factor_wb', 'akurtosis_wb', 'MSDV_wb',   'arms_un', 'arms8h_un', 'VDV_wb',     'armf_wb^4', 'armf_8h_wb^4', 'Peak Accel_wb', 'Crest Factor_wb', 'akurtosis_wb', 'MSDV_un'   };
%vibs_metrics_units2={      '(m/s^2)',  '(m/s^2)',   '(m/s^1.75)', '(m/s^2)',   '(m/s^2)',      '(m/s^2)',       'No Units',        'No Units',     '(m/s^1.5)', '(m/s^2)', '(m/s^2)',   '(m/s^1.75)', '(m/s^2)',   '(m/s^2)',      '(m/s^2)',       'No Units',        'No Units',     '(m/s^1.5)'  };



aa=length(vibs2hw_wb);

% Continuous vibration Analysis

% ******************************************************************
% Weighted Metrics
arms_wb=(sum(vibs2hw_wb'.^2).^(1/2))./(aa.^(1/2));
vibs_metrics_description{1}='arms_wb';
vibs_metrics_units{1}='(m/s^2)';

arms8h_wb= arms_wb*sqrt(aa./Fs./(8*3600));
vibs_metrics_description{2}='arms8h_wb';
vibs_metrics_units{2}='(m/s^2)';

%Vibration dose
VDV_wb=(sum((vibs2hw_wb').^4).^(1/4))*((1./Fs).^(1/4));
vibs_metrics_description{3}='VDV_wb';
vibs_metrics_units{3}='(m/s^1.75)';

%Impulsive vibration analysis
armq4_wb=(sum(vibs2hw_wb'.^4).^(1/4))./(aa.^(1/4));
vibs_metrics_description{4}='armq_wb^4';
vibs_metrics_units{4}='(m/s^2)';

armq4_8h_wb=armq4_wb*((aa./Fs./(8*3600)).^(1/4));
vibs_metrics_description{5}='armq_8h_wb^4';
vibs_metrics_units{5}='(m/s^2)';

peak_a_wb=max(abs(vibs2hw_wb'));
vibs_metrics_description{6}='Peak Accel_wb';
vibs_metrics_units{6}='(m/s^2)';

crest_factor_wb=peak_a_wb./arms_wb;
vibs_metrics_description{7}='Crest Factor_wb';
vibs_metrics_units{7}='No Units';

akurtosis_wb=kurtosis_excess2(vibs2hw_wb, 2);
vibs_metrics_description{8}='akurtosis_wb';
vibs_metrics_units{8}='No Units';

% Motion Sickness Dose
MSDV_wb=arms_wb.*(aa./Fs).^(1/2);
vibs_metrics_description{9}='MSDV_wb';
vibs_metrics_units{9}='(m/s^1.5)';



% ******************************************************************
% Unweighted Metrics
arms_un=(sum(vibs2'.^2).^(1/2))./(aa.^(1/2));
vibs_metrics_description{10}='arms_un';
vibs_metrics_units{10}='(m/s^2)';

arms8h_un= arms_un*sqrt(aa./Fs./(8*3600));
vibs_metrics_description{11}='arms8h_un';
vibs_metrics_units{1}='(m/s^2)';

%Vibration dose
VDV_un=(sum(vibs2'.^4).^(1/4))*((1./Fs).^(1/4));
vibs_metrics_description{12}='VDV_wb';
vibs_metrics_units{12}='(m/s^1.75)';

%Impulsive vibration analysis
armq4_un=(sum(vibs2'.^4).^(1/4))./(aa.^(1/4));
vibs_metrics_description{13}='armf_wb^4';
vibs_metrics_units{13}='(m/s^2)';

armq4_8h_un=armq4_un*((aa./Fs./(8*3600)).^(1/4));
vibs_metrics_description{14}='armf_8h_wb^4';
vibs_metrics_units{14}='(m/s^2)';

peak_a_un=max(abs(vibs2'));
vibs_metrics_description{15}='Peak Accel_wb';
vibs_metrics_units{15}='(m/s^2)';

crest_factor_un=peak_a_un./arms_un;
vibs_metrics_description{16}='Crest Factor_wb';
vibs_metrics_units{16}='No Units';

akurtosis_un=kurtosis_excess2(vibs2, 2);
vibs_metrics_description{17}='akurtosis_wb';
vibs_metrics_units{17}='No Units';

% Motion Sickness Dose
MSDV_un=arms_un.*(aa./Fs).^(1/2);
vibs_metrics_description{18}='MSDV_un';
vibs_metrics_units{18}='(m/s^1.5)';
