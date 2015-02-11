function fname_spm = denoise_jumps(param)
%   
%    Detection and correction of amplitude jumps in EEG signals.
%    First compute time diffence (using diff) on low pass filtered signals. 
%    Then find the peaks of this difference to detect the jumps and replace
%    the peak by zero at the corresponding time location (+/- n_sample).
%    Finally compute time integral (using cumsum) to compute the jumps 
%    corrected signals.
%    
%    input parameters :
%       param.denoise.jump_size (default 10)
%           - min amplitude of the jump
%       param.denoise.jump_threshold (default 7)
%           - threshold for jump detection (nb of standard deviation)
%       param.denoise.n_sample (default 2)
%           - number of sample to correct around the jump
%     
%    Authors: Romain Trachel
%             Lorna le Stanc
%
    
    if isfield(param.denoise,'jump_size')
        js = param.denoise.jump_size;
    else
        js = 10;
    end
    
    if isfield(param.denoise,'n_sample')
        n_sample = param.denoise.n_sample;
    else
        n_sample = 2;
    end
    
    if isfield(param.denoise,'jump_threshold')
        th = param.denoise.jump_threshold;
    else
        th = 7;
    end
    
    D = spm_eeg_load(param.fname_spm);
    % duplicate D and save cleaned signals in a new spm structure
    Dnew = clone(D, ['rmjump_' fnamedat(D)], [D.nchannels length(D.time) D.ntrials]);
    clean = zeros(size(D));
    for iEEG = 1:D.nchannels
        % compute raw difference
        raw_diff = diff(D(iEEG,:));
        
        % compute low pass filtered difference
        filt_diff = diff(conv(D(iEEG,:),gausswin(js))./sum(gausswin(js)));
        
        % compute peaks detection threshold 
        % as a function of param.denoise.jump_threshold
        filt_th = th*std(filt_diff(js/2:end-js/2));
        
        % find peaks behind this threshold (aka jump location)
        [pks, locs] = findpeaks(abs(filt_diff(js/2:end-js/2)),'MINPEAKHEIGHT', filt_th);
        
        % fprintf('EEG%i: found %i jumps \n ', iEEG, length(locs));
        for l = locs
            if l > n_sample
                % remplace raw diff by zero
                raw_diff(l-n_sample:l) = 0;
            end
        end
        
        % compute cumsum of raw diff and add first sample (to save offset)
        clean(iEEG,2:end) = cumsum(raw_diff) + D(iEEG, 1);
    end
    
    Dnew(:,:,:) = clean;
    % save file name for future use
    Dnew.save;
    fname_spm = fullfile(param.spm_datapath, Dnew.fname);
end