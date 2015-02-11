function fname_spm = core_useica(param)

    % Use the result of the EEGLAB Visual inspection using ICA
    [pat, fil, ext] = fileparts(param.fname_spm);
    icafile = [param.ica.outputprefix fil ext];
    fname_spm = [pat filesep icafile];

%     % Check if we need to run interpolation or trial rejection in the ICA results
%     mBadTrlICA = fullfile(param.spm_datapath,['mBadTrialsICA_' param.fname '.mat']);
%     mBadChICA = fullfile(param.spm_datapath,['mBadChannelsICA_' param.fname '.mat']);
%     if param.artefact.manualguiICA 
% 
%         S = [];
%         D = spm_eeg_load(fname_spm);
%         S.D = D;
%         S.newname = ['IAr' S.D.fname];
%         D = spm_eeg_copy(S);
% 
%         if exist(mBadTrlICA, 'file') == 2
%             % Load the manualy ICA bad trials
%             bt = load(mBadTrlICA,'badTrl');
%             badtrialind = find(bt.badTrl);
%             if ~isempty(badtrialind)
%                 fprintf('Rejecting extra trials in the ICA results : ');
%                 extra = setdiff(badtrialind, find(D.reject));
%                 fprintf('%d ', extra);
%                 fprintf('\n');
%                 D = reject(D, badtrialind, 1);
%                 D.save;
%             end
%         else
%             bt.badTrl = logical(D.reject);
%         end
% 
%         if exist(mBadChICA, 'file') == 2
%             % Load the manualy ICA bad channels
%             bc = load(mBadChICA,'badChAll');
%             D = interpolate_channels(D, param.artefact.interp_method, bt.badTrl, bc.badChAll, param.fname_sensfile);
%             D.save;
%         end
% 
%         fname_spm = fullfile(param.spm_datapath,D.fname);
%     end
end