function fname_spm = denoise_dss50Hz(param)
%   
%    Apply DSS to continuous data to remove power-line noise
%    Finds components that are most dominated by 50 Hz and 
%    harmonics, regresses them out to obtain clean data
%
%    See:
%       de Cheveign\'e, A. and Simon J.Z. (2008), "Denoising 
%       based on spatial filtering", J Neurosci Methods 171: 331-339.
%       and:
%       J. S\"arel\"a, J. and Valpola, H. (2005), Denoising source separation. 
%       Journal of Machine Learning Research 6: 233-272.See: 
%     
%   Author: Romain Trachel (adapted from Alain Cheveigne - NoiseTools)
%
    D = spm_eeg_load(param.fname_spm);
    
    sr  = D.fsample;
    %eeg = squeeze(D(:,:,:))';
    
    % covariance matrices of full band (c0) and filtered to 50 Hz & harmonics (c1)
    if 150/sr < 0.5
        [c0,c1]=nt_bias_fft(squeeze(D(:,:,:))',[50, 100, 150]/sr, 512);
    else
        [c0,c1]=nt_bias_fft(squeeze(D(:,:,:))',[50, 100]/sr, 256);
    end
    
    % DSS matrix
    [todss,pwr0,pwr1]=nt_dss0(c0,c1); 
    p1=pwr1./pwr0; % score, proportional to power ratio of 50Hz & harmonics to full band

    % DSS components
    z=nt_mmat(squeeze(D(:,:,:))',todss);

    % first components are most dominated by 50Hz & harmonics
    NREMOVE=20;
    clean=nt_tsr(squeeze(D(:,:,:))',z(:,1:NREMOVE,:)); % regress them out
    
    % duplicate D and save cleaned signals in a new spm structure
    Dnew = clone(D, ['dss50Hz_' fnamedat(D)], [D.nchannels length(D.time) D.ntrials]);
    Dnew(:,:,1) = clean';
    
    % save file name for future use
    Dnew.save;
    fname_spm = fullfile(param.spm_datapath, Dnew.fname);
end