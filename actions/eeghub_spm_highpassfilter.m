function fname_spm = core_highpassfilter(param)            

    type = 'butterworth';
    %type = 'fir';
    order = 5;
    %order = 250; %5*(param.minfilter*250);
    dir = 'twopass';
    
    if isfield(param, 'minfiltertype')
        type = param.minfiltertype;
    end
        
    if isfield(param, 'minfilterorder')
        order = param.minfilterorder;
    end
        
    if isfield(param, 'minfilterdir')
        dir = param.minfilterdir;
    end
                
    S = [];
    S.D = param.fname_spm;
    S.filter.band = 'high';
    S.filter.type = type;
    S.filter.order = order;
    S.filter.dir = dir;
    S.filter.PHz = param.minfilter;
    D = spm_eeg_filter(S);

    if isfield(param,'minfilter_emg')
        S = [];
        S.D = D;
        S.filter.band = 'high';
        S.filter.type = type;
        S.filter.order = order;
        S.filter.dir = dir;
        S.filter.PHz = param.minfilter_emg;
        D = spm_emg_filter(S);
        fprintf('>>>> Filtering EMG as well!\n')
    end
    % save file name for future use
    D.save;
    fname_spm = fullfile(param.spm_datapath,D.fname);
    
end