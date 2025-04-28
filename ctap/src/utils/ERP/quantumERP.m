% Quantum and Component Analysis of ERP - MATLAB Version
% Input: EEG_data (3D array: electrodes x time x trials)
%        fs, sampling rate
%        stim_time, event-locking time within the fixed 2 sec window
% TODO: parameterise the window length
% TODO: refactor to inputParameter syntax
% Output: Identified ERP components, synthetic averages, elicitation rates

function [Comps, SynthAvgs, ElicitationRates] = quantumERP(EEG_data, fs, stim_time)
    % Parameters
    [nChannels, nTime, nTrials] = size(EEG_data);
    time = (-1000:1000)*(1000/fs); % Assuming 2s window, 1s pre and 1s post-stimulus
    t0_idx = find(time == stim_time);
    
    % Component parameter bounds
    latency_wnd = struct('P3a', [240, 299], 'P3b', [300, 360]);
    amp_bounds = [2, 45]; % in uV
    shape_bounds = [8, 50]; % in ms
    
    % Storage
    Comps = struct();
    SynthAvgs = struct();
    ElicitationRates = struct();

    for ch = 1:nChannels
        for trial = 1:nTrials
            segment = squeeze(EEG_data(ch, :, trial));
            filtered = bandpassFilter(segment, fs, 0.5, 50);
            EHWs = segmentHalfWaves(filtered, fs);
            
            for k = 1:length(EHWs)
                w = EHWs{k};
                [sigma, eta] = fitSpectrum(w, fs);
                psi = constructHWF(sigma, eta);
                peak_idx = find(w == max(w));
                g = w(peak_idx) / psi(peak_idx);
                
                % Convert to component parameters
                L = (peak_idx - 1) * 1000/fs;
                A = g * psi(peak_idx);
                rho = eta;

                % Classify component
                compTypes = fieldnames(latency_wnd);
                for c = 1:length(compTypes)
                    comp = compTypes{c};
                    [L1, L2] = deal(latency_wnd.(comp)(1), latency_wnd.(comp)(2));
                    if L >= L1 && L < L2 &&...
                            A >= amp_bounds(1) && A < amp_bounds(2) &&...
                            rho >= shape_bounds(1) && rho < shape_bounds(2)
                        Comps.(comp)(end+1).g = g;
                        Comps.(comp)(end).eta = eta;
                        Comps.(comp)(end).sigma = sigma;
                        Comps.(comp)(end).tau = (peak_idx - 1) * (1000/fs);
                        Comps.(comp)(end).channel = ch;
                        Comps.(comp)(end).trial = trial;
                    end
                end
            end
        end
    end

    % Create synthetic averages
    compTypes = fieldnames(Comps);
    for c = 1:length(compTypes)
        comp = compTypes{c};
        Mi = length(Comps.(comp));
        SynthAvgs.(comp) = zeros(1, nTime);
        trials_present = zeros(1, nTrials);
        
        for i = 1:Mi
            comp_i = Comps.(comp)(i);
            psi = constructHWF(comp_i.sigma, comp_i.eta);
            wave = comp_i.g * psi;
            t_start = round(comp_i.tau * fs / 1000);
            idx = t_start + (1:length(wave));
            idx = idx(idx <= nTime);
            
            SynthAvgs.(comp)(idx) = SynthAvgs.(comp)(idx) + wave(1:length(idx));
            trials_present(comp_i.trial) = 1;
        end
        SynthAvgs.(comp) = SynthAvgs.(comp) / Mi;
        ElicitationRates.(comp) = sum(trials_present) / nTrials;
    end
end

function filtered = bandpassFilter(signal, fs, low_cut, high_cut)
    d = designfilt('bandpassiir','FilterOrder',4, ...
        'HalfPowerFrequency1',low_cut,'HalfPowerFrequency2',high_cut, ...
        'SampleRate',fs);
    filtered = filtfilt(d, signal);
end

function EHWs = segmentHalfWaves(signal, fs)
    zc = findZeroCrossings(signal);
    EHWs = cell(length(zc)-1, 1);
    for k = 1:length(zc)-1
        EHWs{k} = signal(zc(k):zc(k+1));
    end
end

function zc = findZeroCrossings(signal)
    zc = find(diff(sign(signal)) ~= 0);
end

function [sigma, eta] = fitSpectrum(w, fs)
    L = length(w);
    t = (0:L-1)/fs;
    W = fft(w);
    freq = (0:L-1)*fs/L;
    amp = abs(W);
    amp = amp / max(amp);

    % Fit Gaussian: amp(f) ≈ exp(-(σ * 2πf)^2 / 2)
    f_use = freq(freq > 0 & freq < 40);
    amp_use = amp(freq > 0 & freq < 40);
    gaussian = @(s, f) exp(-((2*pi*f*s).^2)/2);
    cost = @(s) sum((amp_use - gaussian(s, f_use)).^2);
    sigma = fminsearch(cost, 0.01);

    % Phase function: φ(f) ≈ η * 2πf (assume linear phase)
    phase = angle(W);
    phase = unwrap(phase);
    coeffs = polyfit(2*pi*f_use, phase(2:length(f_use)+1), 1);
    eta = coeffs(1);
end

function psi = constructHWF(sigma, eta)
    t = linspace(-500, 500, 1000); % in ms
    psi_P = exp(-((t - eta).^2) / (2 * sigma^2));
    psi_S = exp(-((t + eta).^2) / (2 * sigma^2));
    psi = (1 / (sigma * sqrt(2 * pi))) * (psi_P - psi_S);
end
