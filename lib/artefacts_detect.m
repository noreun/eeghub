function [badCh,badTrl,badChAbs,badChgrad] = artefacts_detect(data,opts,cond)
%==========================================================================
% Filename: artefacts_detect.m (function).
%
% Description: Performing artefact detection
%
% Input:    data: EEG data in uV, channels x time x trials (epoched).
%           opts
%             .thresh: Absoulut threshold value in uV. Default is 200 (uV).
%             .LevelBadCh   : The ratio of bad channels within a trial before
%                          the trial is declared as bad. Default is 25%.
%             .InitbadCh    : Indices on channels already defined as bad channels
%             .InitbadTrl   : Indices on trials already defined as bad trials.
%             .gradwin      : window for the gradient artefacts (in samples
%             .gradthresh   : threashold for the gradient
%             .gradand      : optional, can mark channels as bad if BOTH
%             absolute and gradient are present (default is false)
%
% Output:
%           badCh: Indices on bad channels
%           badTrl:Indices on bad trials
%
% Example:
%
% Special remarks:
%
% Authors:
%   Carsten Stahlhut, Technical University of Denmark, DTU Informatics
%   Sid Kouider, ???cole Normale Sup???rieure
%==========================================================================
i = 1;
if length(opts.thresh) > 1, i = cond; end

try thresh = opts.thresh(i); catch thresh = 200; end
try LevelBadCh = opts.LevelBadCh(i); catch LevelBadCh = 0.25; end
try InitbadCh = opts.InitbadCh(i); catch InitbadCh = []; end
try InitbadTrl = opts.InitbadTrl(i); catch InitbadTrl = []; end

try gradwin = opts.gradwin(i); catch gradwin = 0; end
try gradthresh = opts.gradthresh(i); catch gradthresh = 0; end
try gradloop = opts.gradloop(i); catch gradloop = 1; end
try gradand = opts.gradand(i); catch gradand = 0; end
% try gradslope = opts.gradslope(i); catch slope = 0; end

try borderthresh = opts.borderthresh(i); catch borderthresh = 0; end

Nc = size(data,1);

% Detect bad channels maximum treshold
badChAbs = squeeze(max(abs(data),[],2) > thresh);
badChAbs(InitbadCh,:) = true;

% Detec bad channels by gradient
badChgrad = false(size(badChAbs));
if gradwin
    % calculate derivative
%     ddata = diff(data,gradwin, 2);
ddata=data(:,1:end-gradwin+1,:)-data(:,gradwin:end,:);
    badChgrad=logical(squeeze(max(abs(ddata)> gradthresh,[],2)));
    
    %%%% OLD VERSION
%     plot(data(1,:,1))
%     hold on
    % find where it change signal
%     sddata = ddata(:,1:end-1,:) .* ddata(:,2:end,:);
% %     plot((ddata(1,:,1)/max(ddata(1,:,1)))*max(data(1,:,1)), 'r')
% 
%     for n=1:size(data,3)
%         for m=1:size(data,1)
%             % find the peaks
%             peaks = find(sddata(m,:,n) < 0) + 1;
%     %       plot(peaks, data(1,peaks,1), 'r+')
%     
%             % calculate the value between the peaks
%             hpeaks = data(m,peaks(1:end-1),n) - data(m,peaks(2:end),n);
%             
% %             if gradslope~=0
% %                 % calculate the distance between peaks
% %                 dpeaks = diff(peaks);
% %                 
% %                 % calculate the slope between peaks
% %                 speaks=hpeaks./dpeaks;
% %                 
% %                 nbad = sum(abs(speaks) > gradslope);
% %                 badChgrad(m,n) = nbad >= gradloop;
% %                 
% %             else %old version
%                 % count the number of peaks distance bigger then wanted
%                 nbad = sum(abs(hpeaks(hpeaks <gradwin)) > gradthresh);
%                 
%                 % update channel status
%                 badChgrad(m,n) = nbad >= gradloop;
% %             end
%         end
%     end
    
%     for i = 1:gradwin
%         if gradand
%             badCh = badCh & logical (squeeze(max(abs(data(:,1:end-i,:)-data(:,i+1:end,:)), [], 2) > gradthresh));
%         else
%             badCh = badCh | logical (squeeze(max(abs(data(:,1:end-i,:)-data(:,i+1:end,:)), [], 2) > gradthresh));
%         end
%     end
end

if gradand
    badCh = badChgrad & badChAbs;
else
    badCh = badChgrad | badChAbs;
end


% Detect for bad trials
ratioBadCh = squeeze(sum(badCh,1)/Nc);
badTrl = ratioBadCh > LevelBadCh;
badTrl(InitbadTrl) = true;