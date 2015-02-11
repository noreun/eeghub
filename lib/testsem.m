function testsem

    isOpen = matlabpool('size') > 0;
    % Start parallel processing, if necessary
    if ~isOpen
        fprintf('Oppening matlabpool...');
        matlabpool;
        fprintf(' Done\n');
    end
                
    semkey=42; % activate semaphore
%     semkey=-1; % deactivate semaphore
    semaphore('create',semkey,1);
    
    try
        funList = {@f1,@f2,@f3};
        parfor i=1:length(funList)
%             fprintf('running %d...\n', i)
            funList{i}(semkey);
%             fprintf('finished %d.\n', i)
        end
    catch e
        semaphore('destroy',semkey);
        rethrow(e)
    end
    semaphore('destroy',semkey);
end

function f1 (k)
    if k > 0, semaphore('wait',k); end % BLOCK
    ST = dbstack;
    fprintf(['enters function ' ST.name '\n']);
    pause(3);
    fprintf(['leaves function ' ST.name '\n']);
    drawnow
    if k > 0, semaphore('post',k); end % UNBLOCK
end

function f2 (k)
    if k > 0, semaphore('wait',k); end % BLOCK
    ST = dbstack;
    fprintf(['enters function ' ST.name '\n']);
    pause(5);
    fprintf(['leaves function ' ST.name '\n']);
    drawnow
    if k > 0, semaphore('post',k); end % UNBLOCK
end

function f3 (k)
    if k > 0, semaphore('wait',k); end % BLOCK
    ST = dbstack;
    fprintf(['enters function ' ST.name '\n']);
    pause(7);
    fprintf(['leaves function ' ST.name '\n']);
    drawnow
    if k > 0, semaphore('post',k); end % UNBLOCK
end
