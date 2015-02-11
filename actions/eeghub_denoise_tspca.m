function fname_spm = denoise_tspca(param)
%   
%    Apply time shifted PCA on epoched data, extract highest variance
%    components (blinks, saccades, etc...) and remove them from the signal
%    
%    ATTENTION : 
%       outliers trials (e.g. sd > 2) have to be removed before calling this
%       function !!!!!!
%    
%    input parameters :
%       param.denoise.time_shifts (default 10)
%           - array of shifts to apply
%       param.denoise.tspca_threshold (default 0.1)
%           - discard PCs with eigenvalues below this
%
%    See: 
%     de Cheveign\'e, A. and Simon, J. Z. (2007). "Denoising based on  
%     time-shift PCA". Journal of Neuroscience Methods, 165: 297-305.
%    
%   Author: Romain Trachel (adapted from Alain Cheveigne - NoiseTools)
%   
    
    plot_pca_topo = false;
    
    if isfield(param.denoise,'time_shifts')
        shifts = param.denoise.time_shifts;
    else
        shifts = 10;
    end
    
    if isfield(param.denoise,'tspca_threshold')
        threshold = param.denoise.tspca_threshold;
    else
        threshold = 0.1;
    end
    
    % load data and reshape it
    D = spm_eeg_load(param.fname_spm);
    
    x = permute(D(:,:,:),[2,1,3]);
    
    % extract PCA components
    [z, maps] = nt_pca(x, shifts, [], threshold);
    
    if plot_pca_topo
        topo_name = D.fname;
        topo_name(topo_name == '_') = '-';
        topo_name = topo_name(1:end-4);
        for i = 1:size(maps,2)
            h = figure();
            topoplot(maps(:,i),'egi256_GSN_HydroCel.sfp')
            title([topo_name sprintf('-topo%i',i)]);
            saveas(h, [param.data.path '/figures/' param.datafolderprefix '/' topo_name sprintf('_topo%i',i)], 'png')
            close()
        end
    end
    % regress out the PCA components
    clean = nt_tsr(x(shifts+1:length(D.time),:,:), z);
    
    % duplicate D and save cleaned signals in a new spm structure
    Dnew = clone(D, ['tspca_' fnamedat(D)], [D.nchannels length(D.time)-shifts D.ntrials]);
    Dnew(:,:,:) = permute(clean,[2,1,3]);
    
    % save file name for future use
    Dnew.save;
    fname_spm = fullfile(param.spm_datapath, Dnew.fname);
end