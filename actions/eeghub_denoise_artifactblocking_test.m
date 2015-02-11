function fname_spm = denoise_artifactblocking_test(param)
%   
%   adapted from : A simple and fast algorithm for automatic suppression of
%   High-Amplitude artifacts in EEG Data, N. Mourad, 2007
%
%   Author Lorna Le Stanc
%

%     param.fname_spm = '/datab/visattention/12mois/23-Oct-2014_12months_Thresh_500_LowPass_0.2_HighPass_40/efXefdss50Hz_Mspm8_BB58.mat';
%     param.denoise = [];
%     param.spm_datapath = '/datab/visattention/12mois/23-Oct-2014_12months_Thresh_500_LowPass_0.2_HighPass_40/';
    D = spm_eeg_load(param.fname_spm);
    
     if isfield(param.denoise,'AB_threshold')
        theta = param.denoise.AB_threshold;
    else
        theta = 150; 
     end
     
    % duplicate D 
     Dnew = clone(D, ['AB' num2str(theta) '_'  fnamedat(D)], [D.nchannels length(D.time) D.ntrials]);
    
    % trial by trial
    
    for i = 1:D.ntrials
        data = D(:,:,i);
        [r,c]=size(data);
        % set data points above threshold to threshold
        IM1 = theta*ones(r,c);
        IM3 = data-IM1;
        I = find(IM3>0);
        reference_matrix = data;
        reference_matrix(I)= 0; %theta/2;
        clear IM3 I
        % set data points below -threshold to -threshold
        IM3 = data+IM1;
        I = find(IM3<0);
        reference_matrix(I)= 0; %-theta/2;
        %approximate cleaned data
        Autocorrelation_matrix = data*data';
        Crosscorrelation_matrix = reference_matrix*data';
        Smoothing_matrix = Crosscorrelation_matrix*pinv(Autocorrelation_matrix);
        Cleaned_data = Smoothing_matrix*data;
        
        %  save cleaned signals in a new spm structure
        Dnew(:,:,i) = Cleaned_data;
    end
    
    % save file name for future use
    Dnew.save;
    fname_spm = fullfile(param.spm_datapath, Dnew.fname);    
        
end   
