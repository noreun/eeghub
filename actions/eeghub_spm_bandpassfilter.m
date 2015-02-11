function fname_spm = core_bandpassfilter(param)

    D = spm_eeg_load(param.fname_spm);

    S = [];
    S.D = D;
    S.filter.band = 'bandpass';
    S.filter.type = 'but';
    S.filter.order = 5;
    S.filter.dir = 'twopass';
    S.filter.PHz = param.erpfilter;
    D = spm_eeg_filter(S);
    D.save;
    
    % save file name for future use
    D.save;
    fname_spm = fullfile(param.spm_datapath,D.fname);

end