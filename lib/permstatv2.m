%
% permstatv2(dostat, realdata, permutationdata, 'parameter', value, ...);
% 
% Calculate permutation and cluster statistics for unidimentional data
% 
% Leonardo Barbosa
% 14 10 204
%
% dostat : 0 : simulations and average already done, just cluster and do
%               calculate monte-carlo p-values (needs to specify df!)
% 
%               Implies :
%                     realdata : [electrodes time]
%                     permutationdata : [simulations electrodes time]
% 
%          1 : simulations already done, we need to average and cluster
% 
%               Implies :
%                     realdata : [subjects electrodes time]
%                     permutationdata : [simulations subjects electrodes time]
% 
%          2 : we need to do the simulations, average and cluster 
% 
%               Implies :
%                 realdata : [subjects electrodes time]
%
% Optional parameters (in format 'parameter', value, ...):
%
% montecarloalpha   : monte carlo p-value for cluster level statistics
% clusteralpha      : p-value for single pixel statistics
% df                : degrees of freedon, only needed when dostat = 0
% c                 : cell with colors for each electrode
function [realpos, realneg] = permstatv2(dostat, realdata, permutationdata, varargin)

    plotthis = true;
    electrode_colors = {[0 0 0], [.5 .5 .5], [1 1 0], [0 1 1], [1 0 0], [0 0 1], [0 0 0], [.5 0 .5], [0 .5 0], [.5 .5 0], [0 .5 .5], [.5 0 0], [0 0 .5]};
    % e={'C3-C4' 'CP3-CP4'};
    montecarloalpha=0.05;
    % montecarloalpha=0.1;
    clusteralpha=0.1;
    % clusteralpha=0.05;
    detailed_legend = true;
    
    for iv = 1:2:nargin-3
        eval([ varargin{iv} ' = varargin{iv+1};' ]);
    end

    % permutation stuff already done
    if dostat == 0
        nsim = size(permutationdata,1);
        nelec = size(permutationdata,2);
        ntime = size(permutationdata,3);

        rd = realdata;
        pd = permutationdata;
    else
        
        nsuj = size(realdata,1);
        nelec = size(realdata,2);
        ntime = size(realdata,3);

        df = nsuj-1;
         
        [~,~,~,STATS] = ttest(realdata, 0, clusteralpha, 'both', 1);
        s = size(STATS.tstat); s(1) = [];
        rd = reshape(STATS.tstat,s);

        if dostat == 1
 
            % In the case simulation were done elsewhere (for mean bootstrap
            % for instance), calculate single pixel statistics (probably we
            % have a lot of memory...)

            fprintf('Calculating single pixel stats...');
            tic;

            nsim = size(permutationdata,1);
            [~,~,~,STATS] = ttest(permutationdata, 0, clusteralpha, 'both', 2);
            s = size(STATS.tstat); s(2) = [];
            pd = reshape(STATS.tstat,s);

            x = toc;
            fprintf(' Done in %4.4f seconds\n', x);
  
        elseif dostat == 2
          
            % do the simlations and extract stats, don't store it
            fprintf('Simulating and calculating single pixel stats...');
            tic

            nsim = 500;
            pd = zeros(nsim, nelec, ntime);
            for ib=1:nsim
                % permute random number of subjects
                p = 2*(rand(nsuj,1) > .5)-1;
                bp = repmat(p, [1 nelec ntime]);

                [~,~,~,STATS] = ttest(bp .* realdata, 0, clusteralpha, 'both', 1);
                pd(ib,:,:) = STATS.tstat;
            end
            
            x = toc;
            fprintf(' Done in %4.4f seconds\n', x);

        else
            error('Unknow mode : %d', dostat);
        end
    end
    
    if ~exist('milliTime', 'var'), milliTime = 1:ntime; end
    if ~exist('elecnames', 'var'), 
        elecnames = cell(1, nelec);
        for ie=1:nelec, elecnames{ie} = sprintf('%d', ie); end
    end
    
    % cluster statistics

    fprintf( 'Clustering data and calculating monte carlo stats...\n');
    
    [realpos, realneg] = findclusterv2(rd, df, clusteralpha);

    for ie = 1:nelec
        realpos{ie}.pmonte = zeros(size(realpos{ie}.tclusters));
        realneg{ie}.pmonte = zeros(size(realneg{ie}.tclusters));
    end

    for isim = 1:nsim
        tsim = pd(isim,:,:);
        s = size(tsim); s(1) = [];
        tsim = reshape(tsim,s);
        [simpos, simneg] =  findclusterv2(tsim, df, clusteralpha);
        for ie = 1:nelec

            maxval = max(simpos{ie}.tclusters);
            if ~isempty(maxval)
                realpos{ie}.pmonte = realpos{ie}.pmonte + (realpos{ie}.tclusters < maxval)./nsim;
            end

            minval = min(simneg{ie}.tclusters);
            if ~isempty(minval)
                realneg{ie}.pmonte = realneg{ie}.pmonte + (realneg{ie}.tclusters > minval)./nsim;
            end
        end
    end

    if plotthis
        
%         figure; 
        mylim = ylim;

        h = [];
        l = {};
        barpos = 1.05;
        barsep = 15;

        for ie = 1:nelec
            pmonte = realpos{ie}.pmonte;
            goodc = find(pmonte < montecarloalpha);
            contrast = linspace(.5, 1, length(goodc));
            for i = 1:length(goodc)
                ic = goodc(i);
                samples = realpos{ie}.clusters == ic;
                cint = [min(milliTime(samples)) max(milliTime(samples))];
                [~,peaki] = max(rd(ie,samples));
                cintsamples = find(samples);
                peakt = milliTime(cintsamples(peaki));
                fprintf('\telec %d | pos | p-value : %0.4f | time :  %1.4f %1.4f [peak : %1.4f]; ... \n', ie, pmonte(ic), cint, peakt);
                goodtime = find(realpos{ie}.clusters==ic);
                x = milliTime(goodtime);
                s = mylim(2)/barsep;
                p = mylim(2)/barpos;
                y = (p - abs((1-ie)*s)) * ones(1,length(goodtime));

    %             if nelec < 7 % number of pure colors
    %                 cont = contrast(i);
    %             else
                    cont = 1;
    %             end      
                
                % do the actual plot
                ht = scatter(x,y,50,cont*electrode_colors{ie},'filled');
                lt = sprintf('%s pos : %0.4f', elecnames{ie}, pmonte(ic));
                if detailed_legend
                    h = [h ht];
                    l = [l lt];
                end
            end
        end

        fprintf('\n');

        for ie = 1:nelec
            pmonte = realneg{ie}.pmonte;
            goodc = find(pmonte < montecarloalpha);
            contrast = linspace(.5, 1, length(goodc));
            for i = 1:length(goodc)
                ic = goodc(i);
                samples = realneg{ie}.clusters == ic;
                cint = [min(milliTime(samples)) max(milliTime(samples))];
                [~,peaki] = min(rd(ie,samples));
                cintsamples = find(samples);
                peakt = milliTime(cintsamples(peaki));
                fprintf('\telec %d | neg | p-value : %0.4f | time :  %1.4f %1.4f [peak : %1.4f]; ... \n', ie, pmonte(ic), cint, peakt);
                goodtime = find(realneg{ie}.clusters==ic);
                x = milliTime(goodtime);
                s = mylim(1)/15;
                p = mylim(1)/1.1;
                y = (p + (1-ie)*s) * ones(1,length(goodtime));
    % 
    %             if nelec < 7 % number of pure colors
    %                 cont = contrast(i);
    %             else
                    cont = 1;
    %             end      
                ht = scatter(x,y,25,cont*electrode_colors{ie},'filled');
                lt = sprintf('%s neg : %0.4f', elecnames{ie}, pmonte(ic));
                if detailed_legend
                    h = [h ht];
                    l = [l lt];
                end
            end
        end

        if ~isempty(h), legend(h,l, 'Location', 'Best'); end
        
    %     if iCond < 3
    %         saveas(f(iCond), [img_datapath filesep spm8dataFilesDir '_' condition_labels{iCond}], 'png')
    %     end
    end
end