function fname_spm = core_lowpassfilter(param)

    D = spm_eeg_load(param.fname_spm);

    S = [];
    S.D = D;
    S.filter.band = 'low';
    S.filter.type = 'butterworth';
    S.filter.order = 5;
    S.filter.dir = 'twopass';
    S.filter.PHz = param.maxfilter;
    D = spm_eeg_filter(S);

    if isfield(param,'maxfilter_emg')
        S = [];
        S.D = D;
        S.filter.band = 'low';
        S.filter.type = 'butterworth';
        S.filter.order = 5;
        S.filter.dir = 'twopass';
        S.filter.PHz = param.maxfilter_emg;
        D = spm_emg_filter(S);
        fprintf('>>>> Filtering EMG as well!\n')
    end
    % save file name for future use
    D.save;
    fname_spm = fullfile(param.spm_datapath,D.fname);

end