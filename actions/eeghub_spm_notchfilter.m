function [fname_spm, thesefiles] = notchfilter(param, thesefiles)

    % Copy the file with a diferent name
    D = spm_eeg_load(param.fname_spm);
    S = [];
    S.D = D;
    S.newname = ['f' D.fname];
    D = spm_eeg_copy(S);

    % remove line whoam
    switch param.notchmethod

        case 'sinfit'

            % Subtracting fitted senoid
            data = D(:,:,:);

            % initialize auxiliar variables
            mysin = @(beta,x) beta(1) * sin(beta(2)*x + beta(3));
            w = 2*pi()*50;
            t = D.time;
            fprintf(' cleaning the 50Hz noise for channels : ');
            for i=1:D.nchannels
                fprintf('%d ' , i);
                for j=1:D.ntrials
                    % find the intensity of noise for this channel
                    A = (max(data(i,:,j)) - min(data(i,:,j)))/2;
                    beta =[A w 0];
                    % fits a 50Hz sin
                    [betaf, r, jacob, covb, mse] = nlinfit(t,data(i,:,j),mysin,beta);
                    %                             fprintf('\n%d %d %d', j, betaf(1), mse);
                    % if the error is too big, try to fit counter-phase
                    if mse > 1e+03
                        beta =[A w 180];
                        [betaf, r, jacob, covb, mse] = nlinfit(t,data(i,:,j),mysin,beta);
                        if mse > 1e+04
                            fprintf('\nBad fit for %d %d %d %d', i, j, betaf(1), mse);
                        end
                    end
                    % subtract the 50Hz sin wave from the signal
                    data(i,:,j) = data(i,:,j) - mysin(betaf,t);
                end
            end
            fprintf('done!');
            D(:,:,:) = data;

        case 'iir'
            %% applying notch filter
            fprintf ('\nFinding optimal notch filter parameters...\n');

            %%
            %                             notch = 50; % notch frequncy Hz
            %                             bandwidth = 0.1; % bandwidth of the filter in Hz
            %                             wo = notch/(D.fsample/2);
            %                             bw = wo*bandwidth/notch;
            %
            %                             % frequencies of interest
            %                             nsamp = D.fsample;
            %                             goodwindow = ceil(D.nsamples/2);
            %                             goodwindow = goodwindow:goodwindow+nsamp;
            %                             f = D.fsample / nsamp .* (0:ceil(nsamp/2)-1);
            %                             fleft = f >= 20 & f <= 40;
            %                             fright = f >= 60 & f <= 80;
            %                             f50 = abs(f-50) == min(abs(f-50));
            %
            %                             % find the best decrease value
            % %                             fh1 = figure;
            %
            %                             data = D(:,:,:);
            %
            %                             Y = fft(data(:,goodwindow,:), [], 2);
            %                             TFR = 10*log(mean(mean(abs(Y(:,1:ceil(nsamp/2),:)),1),3));
            %                             inidB = TFR(find(f50)+1) - TFR(f50);
            %                             meandiff = mean(diff(TFR(fleft|fright)));
            %                             dB = inidB;
            %                             x = 0;
            %                             while (dB < meandiff) && x < 100
            %
            %                                 fprintf ('%d.',x);
            %                                 dB = inidB - x;
            %
            %                                 % create the filter
            %                                 [b,a] = iirnotch(wo,bw,dB); % decrease dB
            %                                 %  fvtool(b,a) % view filter magnitude response
            %
            %                                 % apply the filter
            %                                 for i=1:D.nchannels
            %                                     %       fprintf('Removing notch from channel %d of %d\n', i, D.nchannels);
            %                                     for j=1:D.ntrials
            %                                         data(i,:,j) = filter(b,a,data(i,:,j));
            %                                     end
            %                                 end
            %
            %                                 Y = fft(data(:,goodwindow,:), [], 2);
            %                                 TFR = 10*log(mean(mean(abs(Y(:,1:ceil(nsamp/2),:)),1),3));
            %                                 dB = TFR(find(f50)+1) - TFR(f50);
            % %                                 plot_fourier(D, data, fh1);
            %
            %                                 x = x + 1;
            %                             end
            %                             if x == 100
            %                                 warning ('Notch filter was not effective for user %s\n',D.fname);
            %                             end

            % Load the signal
            data = D(:,:,:);
            % set initial notch filter parameters
            bandwidth = 0.1; % bandwidth of the filter in Hz
            % notch frequncy 50 Hz
            notch50 = 50;
            wo50 = notch50/(D.fsample/2);
            bw50 = wo50*bandwidth/notch50;

            % apply the 50 hz
            n = D.nsamples;
            samplrate =D.fsample;
            f = (0:n-1)*(samplrate/n);     % Frequency range
            %                             % frequencies of interest
            %                             goodwindow = ceil(D.nsamples/2);
            %                             goodwindow = goodwindow:goodwindow+samplrate;
            %                             f2 = D.fsample / samplrate .* (0:ceil(samplrate/2)-1);
            %                             fleft = f2 >= 20 & f2 <= 40;
            %                             fright = f2 >= 60 & f2 <= 80;
            %                             f502 = abs(f2-50) == min(abs(f2-50));

            for i=1:D.nchannels
                fprintf ('%d\n', i);
                for j=1:D.ntrials

                    % try to find the best decrease value
                    % run a fourier transformation in the signal
                    % freqwin = f >= 0 & f <= floor(samplrate/2);
                    Y = fft(squeeze(data(i,:,j)),n,2);
                    dBTFR = 10*log(Y.*conj(Y)/n);

                    % decrease the value of 50hz intensit
                    f50 = abs(f-50) == min(abs(f-50));
                    %                                     f50l = abs(f-40) == min(abs(f-40));
                    %                                     f50r = abs(f-60) == min(abs(f-60));
                    %                                     dB50 = mean(dBTFR(f50l)+dBTFR(f50r)) - dBTFR(f50);
                    %
                    dB50 = -0.2 * dBTFR(f50);


                    %                                     Y2 = fft(squeeze(data(i,goodwindow,j)), [], 2);
                    %                                     TFR = 10*log(abs(Y2(1:ceil(samplrate/2))));
                    % %                                     dB502 = TFR(find(f502)+1) - TFR(f502);
                    %                                     dB502 = mean(TFR(fleft)+TFR(fright)) - TFR(f502);


                    [b,a] = iirnotch(wo50,bw50,dB50);
                    data(i,:,j) = filter(b,a,data(i,:,j));
                end
            end
            fprintf ('\n');
    end

    % update SPM variable
    %                     fh = figure;
    %                     plot_fourier(D, data(:,1001:2401,:), fh, 0, 120, 'b');
    %                     title(D.fname);
    D(:,:,:) = data;
    D.save;
    fprintf ('\nNotch filter done!\n');

    % save file name for future use
    fname_spm = fullfile(param.spm_datapath,D.fname);
    thesefiles.notchfilter = D.fname;
    
end