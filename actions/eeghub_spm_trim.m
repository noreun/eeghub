function fname_spm = core_trim(param)            

   % WNL function!
   % load behav file
   load([param.data_path filesep param.group filesep 'Behav' filesep param.fname filesep 'Behav' param.CropWindow '_' param.fname])
    eval(sprintf('DINs=%s_stimDINs;',param.CropWindow));
    D=spm_eeg_load(param.fname_spm);
    epcohmaxWin=D.fsample*max([param.epoch.posttrig/1000 param.epoch.pretrig/1000]);
    
%     % erase events
%     warning('... Erasing all events from spm files. Prevent bug in spm_eeg_cross')
%     ev=[];
%     D= events(D, 1, ev);
    
    S = [];
    S.D = D;
    S.timewin = [0 min([D.nsamples DINs(end)+2*epcohmaxWin])]/D.fsample*1000;
    S.channels = 'all';
    D = spm_eeg_crop(S);
     
        fname_spm = fullfile(param.spm_datapath,D.fname);

end