function [ pos, neg ] = findclusterv2(d, df, clusteralpha)

    function res = getcluster(d, ok)

        clusters = zeros(size(d));
        nelec = size(d,1);
        ntemp = size(d,2);
        res = cell(1,nelec);
    
        % for each electrode...
        for ie = 1:nelec
            
            % first find the clusters
            nclusters = 0;
            cluster = 0;
            for it = 1:ntemp
                if ok(ie, it)
                    if ~cluster
                        nclusters = nclusters + 1;
                        cluster = nclusters;
                    end
                else
                    cluster = 0;
                end
                
                clusters(ie, it) = cluster;
            end

            % then compute a sumary, statistics, etc
            iecluster = struct;
            iecluster.clusters = clusters(ie,:);
            
            tclusters = zeros(1,nclusters);
            nclusters = max(iecluster.clusters);
            for ic =1:nclusters
                tclusters(ic) = sum(d(ie,iecluster.clusters==ic));
            end

            iecluster.nclusters = nclusters;
            iecluster.tclusters = tclusters;

            res{ie} = iecluster;
        end

    end


    maxt = tinv(1-clusteralpha, df);
    ok = d > maxt;
    pos = getcluster(d, ok);

    mint = tinv(clusteralpha, df);
    ok = d < mint;
    neg = getcluster(d, ok);
    
%     bigger = repmat(rd,[1 1 1000]) > pd;
end


