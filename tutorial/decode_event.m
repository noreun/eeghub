function event = decode_event(fname,datapath)

    TaskLabel = {'FT' 'AT'};
    VisiLabel = {'Subli', 'Supra'};
    CategLabel = {'Filler', 'Face', 'Watch', 'Flower', 'Blank'};
    
    % Find out if this is a watch or flower subject
    sub = regexp(fname, '\d', 'match');
    sub = str2num(sub{1});
    if isempty(sub)
        error ('Could not identify alternative task for subject %s', fname);
    end
    
    if mod(sub-1,2)+1==1  % true for sub 1,3,... ; false for 2,4,...
        alterntask = 'Watch';
    else
        alterntask = 'Flower';
    end
    
    % First, decode the .evt file to get the trial info such as soundcue, face or non face, etc
    evtfile = fullfile(datapath,[fname '.evt']);

    fid = fopen(evtfile);
    
    % if we have multiple raw files, read the correct block from the event file
    eventblock = 0;
    
    readnewline = true;
    line = 0;
    trialinfocount = 0;
    event.sessonset = 0;
    event.firstonset = -1;
    
    rawfile = fullfile(datapath,[fname '.raw']);
    rawevent = ft_read_event(rawfile, 'detectflank', 'both', 'eventformat', []);
    % find the epoch's beginning samples
    epochs = cell(6,1);
    nepochs = 0;
    nfixc = 0;
    for i=1:size(rawevent,2)
        if strcmp(rawevent(i).value,'epoc')
            nepochs = nepochs + 1;
            epochs{nepochs} = rawevent(i).sample;
        end
        if strcmp(rawevent(i).value,'FixC')
            nfixc = nfixc + 1;
            fixcs{nfixc} = rawevent(i).sample;
        end
    end
    thediff = zeros(nfixc,1);
    
%     d = 3;
    nfixc = 0;
    while 1
        line=line+1;
        
        if readnewline
            tline = fgetl(fid); % lit le fichier une ligne a la fois
        end
        readnewline = true;
        
        if ~ischar(tline), break,end % s'arrete a la fin du fichier (EOF => tline=-1)

        % check if the epoch changed
        if ~isempty(regexp(tline, '^sync\tAmp time', 'match'))
            eventblock = eventblock+1;
        end

        % Get the FixC events
        % trialtype=regexp(tline, 'type[\s]+[\S]+', 'match');
        % if  ~isempty(trialtype)  && trialtype{1}(end)=='1';
        if ~isempty(regexp(tline, '^FixC', 'once'))

            nfixc = nfixc + 1;
            
            if eventblock > 1 % first epoch is training epoch

                trialinfocount=trialinfocount+1;

                % Adults always watch
                event.watc(trialinfocount,:) = 1;

                % default onset
                fixc_onset = regexp(tline,'_[\[0-9\]\s0-9.:]+', 'match');
                offsetshift = 0;
                epoch = str2num(fixc_onset{1}(3));
                onset = fixc_onset{1}(6:end);

                % Task type is in this FixC line
                task=regexp(tline,'Task[\s]+[\S]+', 'match');
                event.task(trialinfocount,:) = str2num(task{1}(5:end));

                % while dfidnt find DIN2 and ObjC, keep looking
                din2 = 0;
                objc = 0;
                done = false;
                while ~done
                    tNext = fgetl(fid);

                    done = ~ischar(tNext) || ~isempty(regexp(tNext, '^sync\tAmp time', 'match')) || ~isempty(regexp(tNext, '^FixC', 'once')) || (din2 && objc);

                    try
                        if ~done && ~isempty(regexp(tNext, '^Objc', 'once'))

                                % Stimulus type and Visibility is in this line
                                stim=regexp(tNext,'Stim[\s]+[\S]+', 'match');
                                visi=regexp(tNext,'Visi[\s]+[\S]+', 'match');

                                event.stim(trialinfocount,:) = str2num(stim{1}(5:end));
                                event.visi(trialinfocount,:) = str2num(visi{1}(5:end));

                                objc_onset=regexp(tNext,'_[\[0-9\]\s0-9.:]+', 'match');
                                epoch = str2num(objc_onset{1}(3));
                                onset = objc_onset{1}(6:end);

                                objc = 1;

                            elseif ~isempty(regexp(tNext,'^DIN2', 'once')) % DIN2
    
        %                         if ~objc
        %                             fprintf ('DIN2 before objc! %d : %s \n', trialinfocount, onset);
        %                         end
    
                                % best onset is in this line
                                photodin_onset=regexp(tNext,'_[\[0-9\]\s0-9.:]+', 'match');
                                epoch = str2num(photodin_onset{1}(3));
                                onset = photodin_onset{1}(6:end);
    
                                offsetshift = 0;
    
                                %fprintf ('DIN2 OK : %s \n', objc_onset{1});
    
                                din2 = 1;
                        end
                    catch e
                        error('Error parsing subject %s raw file %s line %s', fname, fnameraw, tNext);
                    end

                end

                % found another FixC event, dont read line next time
                if ~ischar(tNext) || ~isempty(regexp(tNext, '^sync\tAmp time', 'match')) || ~isempty(regexp(tNext, '^FixC', 'once')) 
                    % and go to next next event or end of file
                    tline = tNext;
                    readnewline = false;
                end

                % if couldnt find DIN2, uses Objc onset
                event.nodin(trialinfocount,:) = 0;
                if ~din2 && objc
                    epoch = str2num(objc_onset{1}(3));
                    onset = objc_onset{1}(6:end);
                    % mean diff (din2 onset - objc onset) : 8.529443 (1.674103)
                    offsetshift = 8;
                        fprintf ('DIN2 NOT OK %d : %s \n', trialinfocount, onset);
                    event.nodin(trialinfocount,:) = 1;
                end

                % if didnt find Objc nor DIN2, throws a warning
                if ~din2 && ~objc
                    fprintf ('Event FixC at %s didnt have Objc nor DIN2\n', onset);
                    error ('Event without FixC nor DIN2. Dont use the event...\n');
                    event.watc(trialinfocount,:) = 0;
                end

    %                 rawevent(line-d).value, int32(rawevent(line-d).sample), epoch, trialcode{1}, 

                newOnset = str2num(onset(:,1:2))*60*60*1000 +...
                    str2num(onset(:,4:5))*60*1000 +...
                    str2num(onset(:,7:8))*1000 +...
                    str2num(onset(:,10:12));     

                newOnset = ((newOnset+offsetshift)/1000)*250;
                newOnset = epochs{epoch}+int32(newOnset);
                
                
                
                
                
                
                
                
                % THIS IS THE IMPORTANT INFORMATION TO RETURN TO EEGHUB
                % ------------------------
                
                event.onset(trialinfocount,:) = newOnset;

                try 
                    catlabel = CategLabel{event.stim(trialinfocount)+1};
                catch
                    keyboard;
                end
                if strcmp(catlabel, 'Watch') || strcmp(catlabel, 'Flower')
                    if strcmp(catlabel, alterntask)
                        catlabel = 'Alternative';
                    else
                        catlabel = 'Control';
                    end
                end

                event.label{trialinfocount} = [VisiLabel{event.visi(trialinfocount)+1} catlabel '_' TaskLabel{event.task(trialinfocount)} ];
                
                % --------------------------
                
                
                
                
                
                
                
                
                

            end
        end
    end
    fclose(fid); % ferme le fichier a convertir
    
%     hist(thediff);
    if max(abs(thediff)) > 1 || length(fixcs) ~= nfixc
        error('subject %s has problems synchronizing the .raw and the .evt samples', fname);
    end
end
