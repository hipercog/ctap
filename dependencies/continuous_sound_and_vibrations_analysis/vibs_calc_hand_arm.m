function [arms_w, arms8h_w, Dy_w, Dy_50_w, armf4_w, armf4_8h_w, Dy4_w, Dy4_50_w, peak_a_w, crest_factor_w, akurtosis_w, arms_un, arms8h_un, Dyun, Dyun_50, armf4_un, armf4_8h_un, Dy4_un, Dy4_un_50, peak_a_un, crest_factor_un, akurtosis_un, vibs_metrics_description, vibs_metrics_units]=Vibs_calc_hand_arm(vibs2hw_ha, vibs2, Fs)
% % Vibs_calc_hand_arm: Calculates the metrics for the hand arm vibrations
% % 
% % Syntax;
% % 
% % [awrms, awrms8h, Dy, Dy_50, awhr4, awhr4_8h, Dy4, Dy4_50, peak_a, ...
% % crest_factor, awhkurtosis, arms, arms8h, Dyun, Dyun_50, ahr4, ...
% % ahr4_8h, Dy4un, Dy4un_50, peak_aun, crest_factorun, akurtosis, ...
% % vibs_metrics_description, vibs_metrics_units ...
% % ]=Vibs_calc_hand_arm(vibs2hw_ha, vibs2, Fs);
% % 
% %
% % ********************************************************************
% %
% % Description
% % 
% % This program calculates the continuous and impulsive hand arm 
% % vibration metrics and outputs the numeric metric values, and a
% % description and units for each metric.  Currenlty there are no metrics 
% % for individual impulsive vibration peaks such as blunt trauma to the
% % hand.  
% % 
% % 
% % 
% % ********************************************************************
% %
% % Input Variables
% % 
% % vibs2hw_ha=randn(1, 10000); % (m/s^2) Hand-Arm weighted rms acceleration 
% % 
% % vibs2=randn(1, 10000);      % (m/s^2) Linear weighted rms acceleration 
% % 
% % Fs=5000;                    % (Hz) Sampling Rate          
% % 
% % ********************************************************************
% %
% % Output Variables
% % 
% % Hand-Arm Weighted Outputs
% % 
% % arms_w                      (m/s^2) Hand-Arm weighted rms acceleration 
% % 
% % arms8h_w                    (m/s^2) 8 hour rms acceleration 
% % 
% % Dy_w                        (Years) Time until 10% chance of finger
% %                                     blanching
% % 
% % Dy_50_w                     (Years) Time until 10% chance of finger
% %                                     blanching using a 50% rest exposure
% % 
% % armf4_w                     (m/s^2) rmf^4 acceleration 
% % 
% % armf4_8h_w                  (m/s^2) 8 hour rmf^4 acceleration 
% % 
% % Dy4_w                       (Years) Time until 10% chance of finger
% %                                     blanching
% % 
% % Dy4_50_w                    (Years) Time until 10% chance of finger
% %                                     blanching
% % 
% % peak_a_w                    (m/s^2) Maximum Acceleration Value 
% % 
% % crest_factor_w              (No Units) crest factor of acceleration 
% % 
% % akurtosis_w                 (No Units) kurtosis of acceleration 
% % 
% % 
% % 
% % UnWeighted Outputs 
% % 
% % arms_un                     (m/s^2) Linear weighted rms acceleration 
% % 
% % arms8h_un                   (m/s^2) 8 hour rms acceleration 
% % 
% % Dyun                        (Years) Time until 10% chance of finger
% %                                     blanching
% % 
% % Dyun_50                     (Years) Time until 10% chance of finger
% %                                     blanching using a 50% rest exposure
% % 
% % armf4_un                    (m/s^2) rmf^4 acceleration 
% % 
% % armf4_8h_un                 (m/s^2) 8 hour rmf^4 acceleration 
% % 
% % Dy4_un                      (Years) Time until 10% chance of finger
% %                                     blanching
% % 
% % Dy4_un_50                   (Years) Time until 10% chance of finger
% %                                     blanching using a 50% rest exposure
% % 
% % peak_a_un                   (m/s^2) Maximum Acceleration Value 
% % 
% % crest_factor_un             (No Units) crest factor of acceleration 
% % 
% % akurtosis_un                (No Units) kurtosis of acceleration 
% % 
% % vibs_metrics_description    Cell Array of description of the vibrations
% %                                     metrics
% % 
% % vibs_metrics_units          Cell Array of Units of the vibrations
% %                                     metrics
% % 
% % ********************************************************************
% % 
% % 
% % 
% % Subprograms
% % 
% % 
% % List of Dependent Subprograms for 
% % Vibs_calc_hand_arm
% % 
% % FEX ID# is the File ID on the Matlab Central File Exchange
% % 
% % 
% % Program Name   Author   FEX ID#
% % 1) kurtosis_excess2		Edward Zechmann			
% % 
% % 
% % 
% % ********************************************************************
% %
% % Program Written by Edward L. Zechmann
% % 
% %     date    July        2007
% % 
% % modified  3 September   2008
% %
% % modified  9 October     2009    Updated Comments
% %
% % 
% % ********************************************************************
% %
% % Please Feel Free to Modify This Program
% %
% % See Also: hand_arm_fil2 Vibs_calc_hand_arm
% %

if (nargin < 1 || isempty(vibs2hw_ha)) || ~isnumeric(vibs2hw_ha) 
    vibs2hw_ha=randn(1, 10000);
end

if (nargin < 2 || isempty(vibs2)) || ~isnumeric(vibs2) 
    vibs2=randn(1, 10000);  
end

if (nargin < 2 || isempty(Fs)) || ~isnumeric(Fs) 
    Fs=5000;
end

vibs_metrics_description=cell(1, 22);
vibs_metrics_units=cell(1, 22);

%vibs_metrics_description2={ 'arms_w',  'arms8h_w', 'Dy_w',    '50% Dy_w', 'armf_w^4', 'armf8h_w^4', 'Dy_w^4', '50% Dy_w^4', 'Peak Accel_w', 'Crest Factor_w', 'akurtosis_w', 'arms_un',  'arms8h_un', 'Dy_un',  '50% Dy_un', 'armf_un^4', 'armf8h_un^4', 'Dy_un^4', '50% Dy_un^4', 'Peak Accel_un', 'Crest Factor_un', 'akurtosis_un' };
%vibs_metrics_units2={ '(m/s^2)', '(m/s^2)',  '(Years)', '(Years)', '(m/s^2)',   '(m/s^2)',    'Years',  'Years',      '(m/s^2)',    'No Units',       'No Units',    '(m/s^2)',  '(m/s^2)',  '(Years)', '(Years)',  '(m/s^2)',   '(m/s^2)',     'Years',   'Years',       '(m/s^2)',    'No Units',        'No Units' };

aa=length(vibs2hw_ha);

% Continuous vibration Analysis

% ******************************************************************
% Weighted Metrics
arms_w=sum(vibs2hw_ha'.^2).^(1/2)./(aa.^(1/2));
vibs_metrics_description{1}='arms_w';
vibs_metrics_units{1}='(m/s^2)';

arms8h_w= arms_w*sqrt(aa/Fs/(8*3600));
vibs_metrics_description{2}='arms8h_w';
vibs_metrics_units{2}='(m/s^2)';

Dy_w=31.8*(arms8h_w)^(-1.06);
vibs_metrics_description{3}='Dy_w';
vibs_metrics_units{3}='(Years)';

Dy_50_w=31.8*(0.5*arms8h_w)^(-1.06);
vibs_metrics_description{4}='50% Dy_w';
vibs_metrics_units{4}='(Years)';

%Impulsive Weighted vibration analysis
armf4_w=(sum(vibs2hw_ha'.^4).^(1/4))/(aa.^(1/4));
vibs_metrics_description{5}='armf_w^4';
vibs_metrics_units{5}='(m/s^2)';

armf4_8h_w=armf4_w*((aa/Fs/(8*3600)).^(1/4));
vibs_metrics_description{6}='armf8h_w^4';
vibs_metrics_units{6}='(m/s^2)';

Dy4_w=31.8*(armf4_8h_w)^(-1.06);
vibs_metrics_description{7}='Dy_w^4';
vibs_metrics_units{7}='(Years)';

Dy4_50_w=31.8*(0.5*armf4_8h_w)^(-1.06);
vibs_metrics_description{8}='50% Dy_w^4';
vibs_metrics_units{8}='(Years)';

peak_a_w=max(abs(vibs2hw_ha'));
vibs_metrics_description{9}='Peak Accel_w';
vibs_metrics_units{9}='(m/s^2)';

crest_factor_w=peak_a_w/arms_w;
vibs_metrics_description{10}='Crest Factor_w';
vibs_metrics_units{10}='No Units';

akurtosis_w=kurtosis_excess2(vibs2hw_ha, 2);
vibs_metrics_description{11}='akurtosis_w';
vibs_metrics_units{11}='No Units';

% ******************************************************************
% Unweighted Metrics
arms_un=sum(vibs2'.^2).^(1/2)/(aa.^(1/2));
vibs_metrics_description{12}='arms_un';
vibs_metrics_units{12}='(m/s^2)';

arms8h_un= arms_un*sqrt(aa/Fs/(8*3600));
vibs_metrics_description{13}='arms8h_un';
vibs_metrics_units{13}='(m/s^2)';

Dyun=31.8*(arms8h_un)^(-1.06);
vibs_metrics_description{14}='Dy_un';
vibs_metrics_units{14}='(Years)';

Dyun_50=31.8*(0.5*arms8h_un)^(-1.06);
vibs_metrics_description{15}='50% Dy_un';
vibs_metrics_units{15}='(Years)';

%Impulsive Unweighted vibration analysis
armf4_un=(sum(vibs2'.^4).^(1/4))/(aa.^(1/4));
vibs_metrics_description{16}='armf_un^4';
vibs_metrics_units{16}='(m/s^2)';

armf4_8h_un=armf4_un*((aa/Fs/(8*3600)).^(1/4));
vibs_metrics_description{17}='armf8h_un^4';
vibs_metrics_units{17}='(m/s^2)';

Dy4_un=31.8*(armf4_8h_un)^(-1.06);
vibs_metrics_description{18}='Dy_un^4';
vibs_metrics_units{18}='(Years)';

Dy4_un_50=31.8*(0.5*armf4_8h_un)^(-1.06);
vibs_metrics_description{19}='50% Dy_un^4';
vibs_metrics_units{19}='(Years)';

peak_a_un=max(abs(vibs2'));
vibs_metrics_description{20}='Peak Accel_un';
vibs_metrics_units{20}='(m/s^2)';

crest_factor_un=peak_a_un/arms_un;
vibs_metrics_description{21}='Crest Factor_un';
vibs_metrics_units{21}='No Units';

akurtosis_un=kurtosis_excess2(vibs2, 2);
vibs_metrics_description{22}='akurtosis_un';
vibs_metrics_units{22}='No Units';

