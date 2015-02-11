function fname_spm = core_freqtime(param)

    % Time-Freq decomposition
    S = [];
    S.D = param.fname_spm;
    S.channels = {'all'};
    S.frequencies = param.freqtime.frequencies;
    S.phase = param.freqtime.phase;

    S.method = param.freqtime.method;

    switch S.method

        case 'morlet'
            % here using wavelt method (morlet mother wave)
            if isfield(param.freqtime.morlet, 'timewin')
                S.timewin = param.freqtime.morlet.timewin;
            end
            S.settings.ncycles = param.freqtime.morlet.ncycles;
            S.settings.timeres = param.freqtime.morlet.timeres;
            S.settings.subsample = param.freqtime.morlet.subsample;

        case 'mtmspec'
            % Time-Freq decomposition ; here using multitaper
            S.settings.bandwidth = param.freqtime.mtmspec.bandwidth; % time bandwidth parameter determining the degree of spectral smoothing (typically 3 or 4).
            S.settings.timeres = param.freqtime.mtmspec.timeres; % time resolution in ms (length of the sliding time-window)
            S.settings.timestep = param.freqtime.mtmspec.timestep; % time step (in ms) to slide the time-window by.
        case 'hilbert'
            S.settings.subsample   = param.freqtime.hilbert.subsample; % factor by which to subsample the time axis (default - 1)
            S.settings.freqres     = param.freqtime.hilbert.freqres; % frequency resolutions (plus-minus for each frequency, can be a vector with a value per frequency)
            S.settings.frequencies = param.freqtime.hilbert.frequencies; % vector of frequencies
            S.settings.order       = param.freqtime.hilbert.order; % butterworth filter order (can be a vector)

        otherwise
            error('unknown time-frequency method');
    end
    D = spm_eeg_tf(S);
    D.save;

    % Rescaling and baseline correction
    if ~strcmp(param.freqtime.scale, 'none')
        S = [];
        S.D = D;
        S.tf.Db = [];
        S.tf.method = param.freqtime.scale; 
        S.tf.Sbaseline = param.freqtime.baselinewind;
        D = spm_eeg_tf_rescale(S);
        D.save;
    end

    % save file name for future use
    fname_spm = fullfile(param.spm_datapath,D.fname);
    
end