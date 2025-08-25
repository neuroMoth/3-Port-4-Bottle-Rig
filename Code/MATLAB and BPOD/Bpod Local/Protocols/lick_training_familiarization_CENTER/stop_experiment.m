function stop_experiment(A, W)
    A.scope_StartStop;
    A.endAcq; % Close Oscope GUI
    A.stopReportingEvents; % Stop sending events to state machine
    clear A
    clear W
    return
end
