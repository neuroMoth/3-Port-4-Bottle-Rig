
%% elapsedTime 
% Returns seconds since the first call. Used to check and record session length in MATLAB. 
%   t = ELAPSEDTIME() returns the number of seconds passed since the first call to this function (wall clock time).

function t = elapsedTime()
    persistent t0
    if isempty(t0)
        t0 = tic;   % Start timer on the first call
    end
    t = toc(t0);    % Elapsed time since first call
end