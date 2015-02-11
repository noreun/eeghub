function D = interpolate_channels(D, interp_method, badTrl, badChAll, sensfile)

    sens = D.sensors('EEG');

    %----------------------------------------
    %Change path to fieldtrip private's dir
    path_work = pwd;

    switch interp_method
        case {'nearest','sphere_avg','sphere_weighteddistance'} % uses fieldtrip

            %                     interp_method = 'nearest';     %'nearest', 'sphere_avg', 'sphere_weighteddistance'
            % fitshpere only relevant fo the interp_method:
            if strcmp(interp_method,'nearest')
                sphere_radius = NaN;
            else
                cd(fullfile(spm('Dir'),['external' filesep 'fieldtrip' filesep 'forward' filesep 'private']))
                [sphere_center,sphere_radius] = fitsphere(sens.pnt); %#ok<ASGLU>
                cd(path_work)
            end

            cd(fullfile(spm('Dir'),['external' filesep 'fieldtrip' filesep 'private']))
            for itrial=1:D.ntrials;
                if badTrl(itrial), continue, end;
                ic_bad = find(badChAll(D.meegchannels,itrial));
                if isempty(ic_bad), continue, end;
                ic_good = find(~badChAll(D.meegchannels,itrial));
                
                % fix for newer fersions of fieldtrip
                if isfield(sens, 'pnt')
                    pnt1 = sens.pnt(ic_good,:);
                    pnt2 = sens.pnt(ic_bad,:);
                elseif isfield(sens, 'elecpos')
                    pnt1 = sens.elecpos(ic_good,:);
                    pnt2 = sens.elecpos(ic_bad,:);
                elseif isfield(sens, 'chanpos')
                    pnt1 = sens.chanpos(ic_good,:);
                    pnt2 = sens.chanpos(ic_bad,:);
                else
                    error('Unknown sensor structure in D');
                end
                warning off %#ok<*WNOFF>
                data2 = interp_ungridded_modified(pnt1,pnt2,...
                    'projmethod',interp_method,...
                    'sphereradius',sphere_radius,...
                    'data',D(ic_good,:,itrial));
                warning on %#ok<*WNON>
                D(ic_bad,:,itrial) = data2;
                %                         keyboard
            end
            D.save;
            cd(path_work)
            %Change back to original working path
            %----------------------------------------

        case {'invdist','spherical','spacetime'} % uses eeglab
            %                         interp_method = 'invdist';
            %                         interp_method = 'spherical';  %uses superfast spherical interpolation.
            %                         interp_method = 'spacetime';  %uses griddata3 to interpolate both in space
            %                                                       %and time (very slow and cannot be interupted).
            %                     keyboard
            %                     eeglab
            eeglab;
            for itrial=1:D.ntrials;
                % PARFORLIM
                %                                 clear Dad EEG

                bad_elec = find(badChAll(:,itrial));
                if isempty(bad_elec), continue, end;    %If empty no need for interpolation
                if badTrl(itrial), continue, end;

                S = [];
                S.D = D;
                S.newname = 'tempFile4artefactDetect';
                Dad = spm_eeg_copy(S);

                badtrialind = 1:D.ntrials;
                badtrialind(itrial) = [];
                Dad = reject(Dad, badtrialind,1);
                S = [];
                S.D = Dad;
                Dad = spm_eeg_remove_bad_trials(S);
                Dad.save;

                %  disp('--------------------------------------------------------------------------')
                %  disp('Warning: Make sure that channels are loaded correct to EEGLAB after axis in SPM8 have reordered')
                %  fprintf('Now starting interpolation of bad channels in trial number: %.0f ....\n',itrial)

                [~, fname_workingFile] = fileparts(Dad.fname);
                EEG = pop_fileio(fullfile(spm_datapath,[fname_workingFile '.mat']));
                %  clear S
                %  EEG = eeg_checkset( EEG );
                %  EEG = pop_editset(EEG, 'xmin', [-0.2]);
                %  EEG = eeg_checkset( EEG );
                %  EEG = pop_chanedit(EEG,  'load',{ 'channel_BB_128channelFile_EEGLAB.xyz', 'filetype', 'xyz'});
                %  EEG = eeg_checkset( EEG );
                %  EEG.setname=fname;
                %  EEG = eeg_checkset( EEG );
                %  eeglab redraw
                EEG.chanlocs = pop_chanedit(EEG.chanlocs,'load',{fullfile(pwd, [sensfile '.sfp']), 'filetype', 'autodetect'});
                EEGnew = pop_interp(EEG, bad_elec, interp_method);
                %EEGnew = eeg_interp(EEG, bad_elec, interp_method);
                %               % delete all other epochs than itrial in EEG-structure
                fprintf('Interpolation of bad channels in trial number: %.0f - done\n',itrial)

                D(:,:,itrial) = EEGnew.data;
                %                         keyboard
            end
            D.save;
        otherwise
            error('Not supported')
    end

    %             D(D.badchannels,:,:) = data2;
    %             D = badchannels(D,D.badchannels,0);

end