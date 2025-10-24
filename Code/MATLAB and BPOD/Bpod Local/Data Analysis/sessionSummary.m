%% sessionSummary.m by TVD
% Function to provide summary for session. 
% Can be used without arguments to default to the most recent
% animal+session. 
% Can specify the animal, or the animal and a particular date in the
% datetime format (datetime(YYYY,MM,DD)). 

function sessionSummary(animal, date)
    dataPath = 'C:\Users\Chad Samuelsen\Documents\Github\Bpod Local\Data'; % Where Bpod data is stored
    
    % Load data (either most recent session for a specific animal and protocol, 
    % the most recent session of any protocol for an animal, or the most recent 
    % session for any animal/protocol. 

    fprintf('---------------SESSION SUMMARY---------------\n') 
    % Just to separate input in the command window - make results more visible

    if nargin == 2 % This will run if the animal and the date are entered
        % Get directory for this animal, then find the folders modified on
        % this day. If the day is for a protocol which was modified since
        % the session the input is aiming for, then this code will not be
        % able to find it. 
        
        if ~ischar(animal)
            error('First input should be the animal designation in the form of a character vector (string).');
        end
        if ~isa(date, 'datetime')
            error('Second input should be the date in the datetime format: datetime(YYYY,MM,DD)');
        end

        fileList=dir(fullfile([dataPath,'\',animal], '**', '*.mat'));
        fileList=fileList(~ismember({fileList.name},{'DefaultSettings.mat'}));

        folderDates = datetime({fileList.date}, 'InputFormat', 'dd-MMM-yyyy HH:mm:ss'); 
        idx = isbetween(folderDates, date, date + days(1) - seconds(1));

        if sum(idx) ~= 1; error('Error: more than one session on that day.'); end
        fileName=fileList(idx).name; 
        folderPath=fileList(idx).folder; 

        splitPath = strsplit(folderPath,'\'); %split path to get folder names
        protocol = splitPath{9};

        % Get file
        load([folderPath,'\',fileName]);

        fprintf('Session for %s on %s: \nProtocol: %s\n', animal, date, protocol);
    elseif nargin == 1 % This will run if only the animal is entered
        if ~ischar(animal)
            error('First input should be the animal designation in the form of a character vector (string).');
        end

        fileList=dir(fullfile([dataPath,'\',animal], '**', '*.mat'));
        fileList=fileList(~ismember({fileList.name},{'DefaultSettings.mat'}));
        [~,iLast]=max([fileList(:).datenum]);
        fileName=fileList(iLast).name; 
        folderPath=fileList(iLast).folder; 

        % Get some info from folder names
        splitPath = strsplit(folderPath,'\'); %split path to get folder names
        protocol = splitPath{9};

        % Get file
        load([folderPath,'\',fileName]);

        fprintf('The most recent session for %s: \nProtocol: %s\n', animal, protocol);
    else % This will run if there are no input arguments
        % Find recently created file (any animal, any protocol)
        fileList=dir(fullfile(dataPath, '**', '*.mat'));
        fileList=fileList(~ismember({fileList.name},{'DefaultSettings.mat'}));
        [~,iLast]=max([fileList(:).datenum]);
        fileName=fileList(iLast).name; 
        folderPath=fileList(iLast).folder; 

        % Get some info from folder names
        splitPath = strsplit(folderPath,'\'); %split path to get folder names
        animal = splitPath{8}; protocol = splitPath{9}; 

        % Get file
        load([folderPath,'\',fileName]);

        fprintf('The most recent session was for %s using protocol %s\n', animal, protocol);
    end

    %% Even if you can't get this function to find the right session data, you can load the .mat file and run the code below to get the info
    % Get values
    sessionDate=SessionData.Info.SessionDate;
    sessionTime=SessionData.Info.SessionStartTime_UTC;
    sessionMinutes=round(SessionData.TrialEndTimestamp(end)/60); 
    sessionSeconds=round(rem(SessionData.TrialEndTimestamp(end),60));
    nTotalTr=length(SessionData.TrialStartTimestamp);
    nCorrectTr=sum(SessionData.correctTrials==1);
    nEngagedTr=sum(SessionData.trialsEngaged); 
    consEstimate = (nEngagedTr+nCorrectTr)*30/1000; 

    % Print to command window
    fprintf('Date: %s   Start time: %s   ',sessionDate,sessionTime)
    fprintf('Duration: %dm %ds\n', sessionMinutes, sessionSeconds);
    fprintf('# Engaged: %d/%d. # Not engaged: %d/%d.\n', ...
        nEngagedTr,nTotalTr,nTotalTr-nEngagedTr,nTotalTr);
    fprintf('# Correct/Engaged: %d/%d or %.2f%%.\n',nCorrectTr,nEngagedTr,(100*round(nCorrectTr/nEngagedTr,4)));
    fprintf('Estimated amount consumed: %.1fml.\n',consEstimate); 
    fprintf('---------------------------------------------\n'); 
end 
