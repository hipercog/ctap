function [EEG_data, ComponentSummary] = generateSampleERPData()
    % Parameters
    nChannels = 1;
    nTrials = 100;
    fs = 500;                        % Sampling rate in Hz
    preStim = 0.2;                   % 200 ms pre-stimulus
    postStim = 0.8;                  % 800 ms post-stimulus
    totalTime = preStim + postStim;
    nSamples = round(totalTime * fs);
    time = linspace(-preStim*1000, postStim*1000, nSamples);  % ms

    % Define mean component properties: amplitude (uV), latency (ms), width (FWHM ms)
    components = struct( ...
        'N1',  struct('amp', -5, 'lat', 100, 'width', 40), ...
        'P2',  struct('amp', 6,  'lat', 200, 'width', 60), ...
        'P3a', struct('amp', 8,  'lat', 250, 'width', 70), ...
        'P3b', struct('amp', 10, 'lat', 400, 'width', 100) ...
    );

    % Define standard deviations for trial-to-trial variability
    variability = struct( ...
        'amp_sd', 1.5, ...
        'lat_sd', 10, ...
        'width_sd', 10 ...
    );

    % Noise level
    noise_level = 5;

    % Initialize EEG data array and component summary
    EEG_data = zeros(nChannels, nSamples, nTrials);
    comp_names = fieldnames(components);
    ComponentSummary = struct();
    for i = 1:length(comp_names)
        ComponentSummary.(comp_names{i}) = struct('PeakTimes', [], 'WindowStart', [], 'WindowEnd', []);
    end

    % Generate trials
    for trial = 1:nTrials
        erp = zeros(1, nSamples);

        for i = 1:length(comp_names)
            name = comp_names{i};
            comp = components.(name);

            % Introduce variability
            amp = comp.amp + variability.amp_sd * randn();
            lat = comp.lat + variability.lat_sd * randn();
            width = comp.width + variability.width_sd * randn();

            % Convert to Gaussian sigma
            sigma = width / 2.355;

            % Generate component waveform
            wave = amp * exp(-((time - lat).^2) / (2 * sigma^2));
            erp = erp + wave;

            % Record component window and peak time
            ComponentSummary.(name).PeakTimes(end+1) = lat;
            ComponentSummary.(name).WindowStart(end+1) = lat - width/2;
            ComponentSummary.(name).WindowEnd(end+1) = lat + width/2;
        end

        % Add noise
        EEG_data(1, :, trial) = erp + noise_level * randn(1, nSamples);
    end

    % Plot the grand average and components
    avgERP = mean(squeeze(EEG_data(1, :, :)), 2);
    figure;
    plot(time, avgERP, 'k', 'LineWidth', 2); hold on;
    title('Simulated ERP with Trial-to-Trial Variability and Component Markers');
    xlabel('Time (ms)');
    ylabel('Amplitude (\muV)');
    grid on;

    % Plot peak time markers and labels
    for i = 1:length(comp_names)
        name = comp_names{i};
        peakTimes = ComponentSummary.(name).PeakTimes;
        meanPeak = mean(peakTimes);
        yval = interp1(time, avgERP, meanPeak);
        plot(meanPeak, yval, 'o', 'DisplayName', name);
        text(meanPeak + 5, yval, name, 'Color', 'b', 'FontSize', 8);
    end
    legend;
end
