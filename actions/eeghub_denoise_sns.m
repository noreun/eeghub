function fname_spm = denoise_sns(param)
%   
%    Apply Sensor Noise Suppression to continuous or epoched data 
%    to remove artefacts from isolated sensors
%    
%    input parameters :
%       param.denoise.sns_neighbors (default 10)
%           - number of channels to use in projection
%
%     See: 
%     de Cheveign\'e, A. and Simon, J. Z. (2007). "Sensor Noise Suppression." 
%     Journal of Neuroscience Methods, 168: 195-202.
%     
%   Author: Romain Trachel (adapted from Alain Cheveigne - NoiseTools)
%
    D = spm_eeg_load(param.fname_spm);
    if isfield(param.denoise,'sns_neighbors')
        nneighbors = param.denoise.sns_neighbors;
    else
        nneighbors = 10;
    end
    
    % call sns function
    clean = nt_sns(permute(D(:,:,:),[2,1,3]), nneighbors);
    
    % duplicate D and save cleaned signals in a new spm structure
    Dnew = clone(D, ['sns_' fnamedat(D)], [D.nchannels length(D.time) D.ntrials]);
    Dnew(:,:,1) = clean';
    
    % save file name for future use
    Dnew.save;
    fname_spm = fullfile(param.spm_datapath, Dnew.fname);
end