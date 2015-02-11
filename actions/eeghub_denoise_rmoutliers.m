function fname_spm = denoise_rmoutliers(param)
%   
%    Apply time shifted PCA on epoched data, extract highest variance
%    components (blinks, saccades, etc...) and remove them from the signal
%    
%    input parameters :
%       param.denoise.threshold (default 'std')
%           - threshold type : 
%               'abs' (absolute value)
%               'std' (standard deviation of the mean)
%               '%'   (percentile) -----> TODO
%       param.denoise.value (default 2)
%           - keep trials having amplitude higher than this value
%    
%   Author: Romain Trachel (adapted from Alain Cheveigne - NoiseTools)
%   
    if isfield(param.denoise,'value')
        value = param.denoise.value;
    else
        value = 2;
    end
    
    if isfield(param.denoise,'threshold')
        if strcmp(param.denoise.threshold,'std')
            threshold = 'std';
        elseif strcmp(param.denoise.threshold,'abs')
            threshold = 'abs';
        elseif strcmp(param.denoise.threshold,'%')
            threshold = '%';
        else
            error('Undefined threshold type : %s',param.denoise.threshold);
        end
    else
        threshold = 'std';
    end
    
    % load data and reshape it
    D = spm_eeg_load(param.fname_spm);
    x = permute(D(:,:,:),[2,1,3]);
    
    % ---------- Hacking core_ARautomatic
    D = reject(D,1:D.ntrials, 0);
    
    switch threshold
        case 'std'
            % remove trials that deviate from the mean by
            % more than "value" times the average deviation from the mean.
            [idx, d] = nt_find_outlier_trials(x, value, false);
            D = reject(D,setdiff(1:D.ntrials,idx),1);
        case 'abs'
            x = abs(x);
            % remove trials in which the absolute amplitude is higher than
            % the thresold value
            [i, j, k] = ind2sub(size(x),find(x > value));
            D = reject(D,unique(k)',1);
        case '%' % -----------> TODO
            idx = [];
    end
    fprintf('Removing %i trials that exceed %i (%s value)\n', sum(D.reject), value, threshold)
    S = [];
    S.D = D;
    Dnew = spm_eeg_remove_bad_trials(S);
    
    % Save the good trials below the critierion threshold
    % save(fullfile(param.spm_datapath,['GoodTrials_' param.fname '.mat']), 'idx');
    
    % save file name for future use
    Dnew.save;
    fname_spm = fullfile(param.spm_datapath, Dnew.fname);
end