function fname_spm = eeghub_spm_epoching(param)

    % First Epoching: large epochs to avoid filtering
    % artifacts, that will be re-epoched to small epochs
    % latter in epoching2
    
    if ~isfield(param,'fsample_new')
       param.fsample_new=0; 
    end
    if ~isfield(param.epoch,'EGI_jitter') % compensate for EGI anti-alias filter jitter (in ms)
       param.epoch.EGI_jitter=0; 
    end
    
    S = [];

    S.D = spm_eeg_load(param.fname_spm);
    S.fsample = S.D.fsample;
    S.timeonset = 0;
    S.bc = 0;
    S.reviewtrials = 0;
    S.save = 0;
    S.epochinfo.padding = 0;

    % set epoch size
    pretrig = param.epoch.pretrig;
    posttrig = param.epoch.posttrig;

    % get conditions/labels and trials info
    switch nargin(param.epoch.decode)
        case{2}
            event = param.epoch.decode(param.fname,param.rawfiles_datapath);
        case{3}
            event = param.epoch.decode(param.fname,param.rawfiles_datapath,param.group);
        otherwise
            error('Unknow number of parameters for decode_event');
    end

    % if not available from decode_event, default is that
    % the subject watched all tirals
    if ~isfield(event, 'watc')
        event.watc = 1;
    end

    % if decode_event is able to informe epoch info, aka,
    % [begin, end, offset] of each trial, use it
    if isfield(param.epoch, 'epochinfo') && param.epoch.epochinfo

        % Build the intervals for the correct events
        Ntrials = length(event.onset);
        S.epochinfo.trl = zeros(Ntrials,3);
        S.epochinfo.conditionlabels = cell(Ntrials,1);

        % compute the offset and duration in samples
        off = round(0.001*pretrig*S.fsample); % offset in samples
        dur = round(0.001*(-pretrig+posttrig)*S.fsample); % duration in samples;

        % for each trial, get the onset and label
        for i=1:Ntrials
            
            % this parameter tells if decode_event return onset  in samples or absolute time.
            if param.epoch.sampled
                % correct sample from decode_event in case of previouse downsampling
                if param.fsample_new==0
                    sample_ratio = 1;
                else
                    sample_ratio = param.fsample_ori / param.fsample_new;
                end
                beg =   off + ...
                        round(event.onset(i)/sample_ratio) + ...
                        round(param.epoch.EGI_jitter * 0.001 * sample_ratio);
            else
                if param.fsample_new==0
                    beg = off + event.firstsample + round((event.onset(i) - event.firstonset + param.epoch.EGI_jitter) * 0.001 * S.fsample);
                else
                    sample_ratio = param.fsample_ori / param.fsample_new;
                    beg = off + round(event.firstsample/sample_ratio)  + round((event.onset(i) - event.firstonset + param.epoch.EGI_jitter) * 0.001 * S.fsample);
                end
                if isfield(event,'n1blocks')
                    if i<event.n1blocks
                        beg =  round(event.firstsample)  + round((event.onset(i) - event.firstonset + param.epoch.EGI_jitter) * 0.001 * S.fsample);
                    else
                        beg =  round(event.firstsample)  + round((event.onset(i) - event.firstonset - event.lengthBreak + param.epoch.EGI_jitter) * 0.001 * S.fsample );
                    end
                end
            end
            
            fin = beg + dur;
            
            S.epochinfo.trl(i,1) = beg;
            S.epochinfo.trl(i,2) = fin;
            S.epochinfo.trl(i,3) = off;
            
            S.epochinfo.conditionlabels{i} = event.label{i};
        end

        % call the actual SPM functino with the information
        % created above
        D = spm_eeg_epochs(S);
        D.save;

    else
        % Otherwise use SPM automatic epoching, aka,
        % spm_eeg_epochs will call spm_eeg_definetrial
        S.inputformat = [];
        S.pretrig = pretrig;
        S.posttrig = posttrig;
        
        if ~isfield(param.epoch, 'conditionlabel'), 
            param.epoch.conditionlabel = 'unknown'; 
        end
        S.trialdef.conditionlabel = param.epoch.conditionlabel;
        
        if ~isfield(param.epoch, 'eventtype'), 
            param.epoch.eventtype = 'trigger'; 
        end
        S.trialdef.eventtype = param.epoch.eventtype;

        if ~isfield(param.epoch, 'trialvalue'), 
            param.epoch.trialvalue = 'TRSP'; 
        end
        S.trialdef.eventvalue = param.epoch.trialvalue;

        D = spm_eeg_epochs(S);

        %check_events

        % Label the conditions
        condLabels=cell(1,D.ntrials);
        for i=1:length(condLabels)
            if event.ForN(i)==1
                condLabels{i} = ['Face' num2str(event.Tdur(i))];
            else
                condLabels{i} = ['Noface' num2str(event.Tdur(i))];
            end
        end

        % Add condition labels
        condLevels=unique(condLabels);
        for i=1:length(condLevels)
            D = D.conditions(find(strcmp(condLevels(i),condLabels)),condLevels{i}); %#ok<*FNDSB>
        end
        D.save;

    end

    % save file name for future use
    fname_spm = fullfile(param.spm_datapath,D.fname);
    
end
