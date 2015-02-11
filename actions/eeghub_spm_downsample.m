function fname_spm = downsample(param)            
    
    % downsample data
    S = [];
    S.D = param.fname_spm;
    S.fsample_new = param.fsample_new;
    S.prefix = 'D';
    D = spm_eeg_downsample(S);
    D.save;

    % save file name for future use
    fname_spm = fullfile(param.spm_datapath,D.fname);
end