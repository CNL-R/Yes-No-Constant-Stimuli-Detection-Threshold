%Yes-No Up-Down. Press any key to say that there is a stimulus. 

%Step Size = c/n, c = initial step size, n = trial number. Step size
%shrinks as experiment progresses

%Termination after set number of runs (# reversals)

%Threshold calculated via Wetherill method. Average of all peaks and
%valleys (coherence value at every reversal). 

%--------------------
% Initial Set-up Stuff
%--------------------
% Clear the workspace and the screen
sca;
close all;
clearvars;

% Setup PTB with some default values
PsychDefaultSetup(2);

% Set the screen number to the external secondary monitor if there is one
% connected
screenNumber = max(Screen('Screens'));

% Define black, white and grey
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white / 2;

% Open the screen
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey, [], 32, 2,...
    [], [],  kPsychNeed32BPCFloat);

%Query the time duration
ifi = Screen('GetFlipInterval', window);

%Set the text font and size
Screen('TextFont', window, 'Ariel');
Screen('TextSize', window, 40);

%Query the maximum priority level
topPriorityLevel = MaxPriority(window);

%Get the center coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);

%random seed
rand('seed', sum(100 * clock));

% Set up alpha-blending for smooth (anti-aliased) lines
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
%--------------------
% Experiment Params
%--------------------
%number of blocks per condition
blocksPerCondition = 1;

%number of blocks per condition
blocks = blocksPerCondition * 3;

%blocks Matrix to give experimental loop info about what type of block to play and keep track of psychometric threshold
blockMatrix = repmat([1:3; 0 0 0; 0 0 0], 1, blocksPerCondition);
%blockMatrix(1,:) = condition per each block
    %1 - Visual
    %2 - Auditory
    %3 - Audiovisual

%number of reversals/runs
runs = 2;
 
%initial step size
initialStep = 0.3;

%initial stimulus coherence value
initialCoherence = 0.5;

%preallocated number of trials per block
prealNum = 100;

%matrix for storing trial number and coherence value for that stimulus.
%Initially set to length 'prealNum' for pre-allocation
% 1 - trialNum
% 2 - stimCoherence
stimMat = repmat(1:prealNum, 1, 1, blocks);
stimMat(2,:,:) = 0;
stimMat(2,1,:) = initialCoherence;

%matrix for holding the sign of each trial. 
sign = zeros(prealNum, blocks);

%matrix for holding the UPD TRANSFORMED UpGroup and DownGroup. StartingIndex Matrices for holding what index to start checking from (used to accomodate for NaN's)
upGroup = [[NaN 0 0]; [0 1 0]; [1 0 0];];
upStartingIndex = [2, 1, 1];
downGroup = [[NaN 1 1];[1 0 1];[0 1 1];];
downStartingIndex = [2, 1, 1];

%Maximum number of elements per upGroup and downGroup. 
maxSizeUp = 3;
maxSizeDown = 3;

%catch trial information
catchFrequency = 0; %what percentage of the trials will be catch trials
subFrequency = 0.5; %what percentage of the catch trials will be subliminal (0% coherence). assuming supraFrequency is 1-subFrequency

%initializing catchMat, the matrix that holds data about which trials are
%catch trials, and what type of trial. 
catchMat = zeros(prealNum, blocks);

%--------------------
% Stimuli Params
%--------------------
%apperture window properties
appX = 300; %app size
appY = 300;
appXCenter = appX/2;
appYCenter = appY/2;
appRadius = appX/2;

%gabor stimulus properties
stimLength = 150;
stimRadius = stimLength/2;
stimXPos = appXCenter/2;
stimYPos = appYCenter/2;
lambda = 50; %wavelegnth (number of pixels per cycle)
sigma = 50; %gaussian standard deviation in pixels
imSize = stimLength;
X0 = 1:imSize;                          
X0 = (X0 / imSize) - .5;                 
[Xm Ym] = meshgrid(X0, X0);
s = sigma/imSize;
gauss = exp( -(((Xm.^2)+(Ym.^2)) ./ (2* s^2)));
A = 0.75; %amplitude variable

%Creating Annulus
annulusDiameter = 300;
annulusWidth = 10;
annulusColor = 0.75;
annulusBackgroundColor = 0.5;

%cue stuff
cueColor = 1;
cueFrequency = 1000;

annulusMatrix = CreateAnnulus(annulusDiameter, annulusWidth, annulusColor, annulusBackgroundColor);
annulusTexture = Screen('MakeTexture', window, annulusMatrix);

cueMatrix = CreateAnnulus(annulusDiameter, annulusWidth, 1, annulusBackgroundColor);
cueTexture= Screen('MakeTexture', window, cueMatrix);

%Creating stimuli #1
gaborMatrix = zeros(appY, appX, prealNum);  %matrix containing pixel values for the texture being created. Expands to hold pixel values of all stimuli
gabor = CreateGabor(stimLength, sigma, lambda, 'r', 'r', A);
gabor = EmbedInNoise(gabor, initialCoherence, 1, gauss);
gaborMatrix(:, :, 1) = EmbedInApperature(gabor, 'c', appX, appY, 'n', 0.5);
gaborMatrix(:, :, 1) = EmbedInAnnulus(gaborMatrix(:, :, 1), annulusWidth, annulusColor);

%defining area the texture will be displayed
xPos = xCenter;
yPos = yCenter;
baseRect = [0 0 appX appY];

%Centering texture in center of window
rectCenter = CenterRectOnPointd(baseRect, xPos, yPos);

%create texture and place into textureMatrix. textureMatrix will be
%used by experimental loop to draw stimuli.
noiseTexture = Screen('MakeTexture', window, gaborMatrix(:,:,1));
texMat = zeros(prealNum, blocks);
texMat(1, :) = noiseTexture;

%matrix for holding all the coherence values played for UPDown method of
%finding threshold
UPDCoherenceMat = zeros(prealNum, 1, blocks);
UPDCoherenceMat(1, :) = initialCoherence;
%--------------------
% Timing Information
%--------------------
%Grey Annulus (in ms)
annulusTime = [1000 1000];%[1200, 2400]; 

%Cue Time (in ms)
cueTime = 800;
beepDuration = cueTime;

%Pre-Presentation Grey Annulus Time (in ms)
preStimTime = 200;

%Stimulus Presentation Time (in ms)
stimulusTime = 60;

%Post Stimulus Time
postStimTime = 1000;

%Number of frames to wait before re-drawing
waitframes = 1;

%number of trials to play
trials = 10;

timesCue = zeros(trials + 1, blocks); %TIMING CODE
timesPresentation = timesCue; %TIMING CODE
timesPreP = timesCue; %TIMING CODE
timesPostP = timesCue; %TIMING CODE
timesPreStim = timesCue; %TIMING CODE
timesStim = timesCue; %TIMING CODE
timesPostStim = timesCue; %TIMING CODE
timesISI = timesCue; %TIMING CODE
%--------------------
% AUDITORY SET UP STUFF
%--------------------
% Initialize Sounddriver
InitializePsychSound(1);

% Number of channels and sample rate
nrchannels = 2;
sampleFreq = 48000;

%Volume %
volume = 0.5;

%Open audio port
%pahandle = PsychPortAudio('Open', [], 1, 1, sampleFreq, nrchannels, [], [], [], []);

% Make a beep which we will play back to the user
cueBeep = MakeBeep(1000, cueTime, sampleFreq);
noBeep = MakeBeep(0, cueTime, sampleFreq);
%--------------------
% The Response Matrix
%--------------------
%3D matrix. Row 1 - stimulus Coherence . Row 2 - 1 or 0 for detected or not. Row
%3 - RT if detected. 0 if not detected. Each column is an individual
%stimulus presentation. Third dimmension is block number
respMatrix = nan(3, prealNum, blocks);

%matrix to hold all peaks and valleys of the psychometric function
%(coherence values where a reversal happened)
pvMatrix = zeros(runs + 2,blocks);

%matrix to hold all non-catch trial responses 
nonCatchMatrix = zeros(prealNum, blocks);

%index value matrix to hold index values of different types of responses
indexPRespMatrix = [];
indexNRespMatrix = [];
indexPRevMatrix = [];
indexNRevMatrix = [];
indexCatchMatrix = [];

%matrix to hold calculated psychthresholds
psychThresh = zeros(blocks, 1);
%% --------------------
% The Experimental Loop
%--------------------
for block = 1:blocks
    %counter for how many trials have been played and how many threshold
    %trials there have been (n, how many non-catch trials there have been
    trial = 1;
    n = 1;
    
    %variable to keep track if a response was made
    respMade = false;
 
    %--------------------
    % Initial Trial -  Need to do this first to get initial sign of run
    %--------------------
    if trial == 1
        %variable to keep track of when there is a reversal of step size.
        reverse = 0;
        %if first trial and block 1, present a start screen and wait for a key press.
        if block == 1
%             DrawFormattedText(window, 'Welcome to Allen''s Up-Down
%             Transformed detection task. Press any key to begin.', 'center', 'center', white); %TIMING CODE 
%             Screen('Flip', window);
%             KbStrokeWait;
            %else if first trial and not block 1, present an interblock screen and wait for a key press
        elseif block ~= 1
%             DrawFormattedText(window, ['Finished Block #' num2str(block) - 1 '. Press any key to continue.'], 'center', 'center') %TIMING CODE 
%             Screen('Flip', window);
%             KbStrokeWait;
        end
        
        
        %Presenting Grey Annulus
        vbl = PresentStimulus(annulusTexture, window, 0, ifi, annulusTime(1), annulusTime(2), false, 0, 0, rectCenter);
        
        timeStart = GetSecs; %TIMING CODE
        
       
        cueStart = GetSecs; %TIMING CODE
        %Presenting Cue
        if blockMatrix(1, block) == 1
            %Presenting pure visual cue
            PresentEfficientAVStimulus(cueTexture, cueBeep, 0, window, vbl, ifi, cueTime, 0, 0, 0, 0, rectCenter);
        elseif blockMatrix(1, block) == 2
            %presenting pure audio cue
            PresentEfficientAVStimulus(annulusTexture, cueBeep, 0.5, window, vbl, ifi, cueTime, 0, 0, 0, 0, rectCenter);
        elseif blockMatrix(1, block) == 3
            %presenting AV cue
            PresentEfficientAVStimulus(cueTexture, cueBeep, 0.5, window, vbl, ifi, cueTime, 0, 0, 0, 0, rectCenter);
        end
        timesCue(trial, block) = (GetSecs - cueStart); %TIMING CODE
        
        timePreStim = GetSecs;%TIMING CODE
        %Presenting Pre-Stim Annulus
        vbl = PresentStimulus(annulusTexture, window, 0, ifi, preStimTime, 0, false, 0, 0, rectCenter);
        
        timesPreStim(trial, block) = GetSecs - timePreStim;%TIMING CODE
        %Getting Start Time and Presenting the Stimulus
        tStart = GetSecs;
        [vbl,respMade,rt]= PresentStimulus(texMat(trial, block), window, vbl, ifi, stimulusTime, 0, true, tStart, respMade, rectCenter);
        timesStim(trial,block) = GetSecs - tStart;%TIMING CODE
        
        %Removing Stimulus: Post-Stimulus interval. Participant can make response.
        timePostStim = GetSecs;%TIMING CODE
        [vbl,respMade,rt] = PresentStimulus(annulusTexture, window, vbl, ifi, postStimTime, 0, true, tStart, respMade, rectCenter);
        timesPostStim(trial, block) = GetSecs - timePostStim;%TIMING CODE
        
        %Interstimulus window where participant can make a response about
        %the stimulus that was just played
        timeISI = GetSecs; %TIMING CODE
        [vbl,respMade,rt] = PresentStimulus(annulusTexture, window, vbl, ifi, annulusTime(1), annulusTime(2), true, tStart, respMade, rectCenter);
        timesISI(trial, block) = GetSecs - timeISI; %TIMING CODE
    
        
        timePostP = GetSecs; %TIMING CODE
        %saving response to respMatrix
        %stimulus #
        respMatrix(1, trial, block) = stimMat(1, trial, block);
        %1 or 0 for whether or not a response was made
        if respMade == true
            respMatrix(2, trial, block) = 1;
            nonCatchMatrix(1, block) = 1;
        else
            respMatrix(2, trial, block) = 0;
            nonCatchMatrix(1, block) = 0;
        end
        
        %assigning rt
        respMatrix(3, trial, block) = rt;
        
        %Assigning sign of this trial. -1 for negative. +1 for positive
        if respMade == true
            sign(1, block) = -1;
            indexPRespMatrix = [indexPRespMatrix trial];
        elseif respMade == false
            indexNRespMatrix = [indexNRespMatrix trial];
            sign(1, block) = 1;
        end
        
        %update trial number. 
        timesPostP(trial, block) = GetSecs - timePostP; %TIMING CODE
        timesPresentation(trial, block) = (GetSecs - timeStart); %TIMING CODE   
        trial = trial + 1;
         
    end
    
    %--------------------
    % The Rest of the Trials
    %--------------------
    %while a response is made when the sign is negatve or a response is
    %not made when the sign is positive and trial number is greater than one. (While a response is not a reversal and greater than one)
    run = 1;
    while trial <= trials %TIMING CODE
        timeStart = GetSecs; %TIMING CODE
        %setting respMade to false
        respMade = false;
        
        %setting the contrast level for this trial (step size of
        %initialStep / trial#)
        step = initialStep/(n);
        
        %if this is a catch trial (determined randomly)
        if rand(1) <= catchFrequency
            if rand(1) <= subFrequency
                coherence = 0;
                %catchMat = 1 --> subliminal
                catchMat(trial, block) = 1;
                %indexCatchMatrix(:, block) = [indexCatchMatrix(:, block) trial];
            else
                %coherenceis equal to a random value between 0.5 and 1; 
                coherence = rand(1)*0.5 + 0.5; 
                %catchMat = 2 --> supraliminal
                catchMat(trial, block) = 2;
            end 
        else 
            %updating n: the ntrial number of all NON-Catch trials. 
            n = n + 1;
            
            %calculating new coherence level if this is not a catch trial
            %based off of info from previous non-catch trials ONLY
            UPDCoherenceMat(n, block) = UPDCoherenceMat(n - 1, block) + (step * sign(n-1, block));
            if UPDCoherenceMat(n, block) < 0
                UPDCoherenceMat(n, block) = 0;
            elseif UPDCoherenceMat(n, block) > 1
                UPDCoherenceMat(n, block) = 1;   
            end
            coherence = UPDCoherenceMat(n, block);
        end
        stimMat(2, trial, block) = coherence;
       
        %creating stimulus
        %loop to draw circle with different coherence values for each stimulus type
        %for each stim condition
        gabor = CreateGabor(stimLength, sigma, lambda, 'r', 'r', A);
        gabor = EmbedInNoise(gabor, coherence, 1, gauss);
        gaborMatrix(:, :, trial) = EmbedInApperature(gabor, 'c', appX, appY, 'n', 0.5);
        gaborMatrix(:, :, trial) = EmbedInAnnulus(gaborMatrix(:, :, trial), annulusWidth, annulusColor);
        
        %create texture and place into textureMatrix. textureMatrix will be
        %used by experimental loop to draw stimuli.
        noiseTexture = Screen('MakeTexture', window, gaborMatrix(:,:,trial));
        texMat(trial, block) = noiseTexture;
             
        timesPreP(trial, block) = GetSecs - timeStart; %TIMING CODE
        cueStart = GetSecs; %TIMING CODE
        %Presenting Cue
        if blockMatrix(1, block) == 1
            %Presenting pure visual cue
            PresentEfficientAVStimulus(cueTexture, cueBeep, 0, window, vbl, ifi, cueTime, 0, 0, 0, 0, rectCenter);
        elseif blockMatrix(1, block) == 2
            %presenting pure audio cue
            PresentEfficientAVStimulus(annulusTexture, cueBeep, 0.5, window, vbl, ifi, cueTime, 0, 0, 0, 0, rectCenter);
        elseif blockMatrix(1, block) == 3
            %presenting AV stimulus
            PresentEfficientAVStimulus(cueTexture, cueBeep, 0.5, window, vbl, ifi, cueTime, 0, 0, 0, 0, rectCenter);
        end
        
        
        timesCue(trial, block) = (GetSecs - cueStart); %TIMING CODE
        timePreStim = GetSecs;%TIMING CODE
        %Presenting Pre-Stim Annulus
        vbl = PresentStimulus(annulusTexture, window, 0, ifi, preStimTime, 0, false, 0, 0, rectCenter);
        timesPreStim(trial, block) = GetSecs - timePreStim;%TIMING CODE
        %Getting Start Time and Presenting the Stimulus
        tStart = GetSecs;
        [vbl,respMade,rt]= PresentStimulus(texMat(trial, block), window, vbl, ifi, stimulusTime, 0, true, tStart, respMade, rectCenter);
        timesStim(trial,block) = GetSecs - tStart;%TIMING CODE
        %Removing Stimulus: Post-Stimulus interval. Participant can make response.
        timePostStim = GetSecs;%TIMING CODE
        [vbl,respMade,rt] = PresentStimulus(annulusTexture, window, vbl, ifi, postStimTime, 0, true, tStart, respMade, rectCenter);
        timesPostStim(trial, block) = GetSecs - timePostStim;%TIMING CODE
        %Interstimulus window where participant can make a response about
        %the stimulus that was just played
        timeISI = GetSecs; %TIMING CODE
        [vbl,respMade,rt] = PresentStimulus(annulusTexture, window, vbl, ifi, annulusTime(1), annulusTime(2), true, tStart, respMade, rectCenter);
        timesISI(trial, block) = GetSecs - timeISI; %TIMING CODE
        timePostP = GetSecs; %TIMING CODE
        
        %saving response to respMatrix
        %stimulus #
        respMatrix(1, trial, block) = stimMat(1, trial, block);
        
        %1 or 0 for whether or not a response was made
        if respMade == true
            respMatrix(2, trial, block) = 1;
            indexPRespMatrix = [indexPRespMatrix trial];
            if catchMat(trial, block) == 0
                nonCatchMatrix(n, block) = 1;             
            end
        else
            respMatrix(2, trial, block) = 0;
            indexNRespMatrix = [indexNRespMatrix trial];
            if catchMat(trial, block) == 0
                nonCatchMatrix(n, block) = 0;          
            end
        end
        
        %assigning rt
        respMatrix(3, trial, block) = rt;
        
        
        %If this is not a catch trial, check to see if the UpGroup or
        %DownGroup condition has been satisfied.
        reverse = 0;
        if catchMat(trial, block) == 0
            %Check if conditions are satisfied
            if sign(n - 1, block) == 1
                    %setting index to avoid nonpositive indices in matrices.
                    index = n-maxSizeDown + 1;
                    if index <= 0
                        index = 1;
                    end
                    for sequence = 1:size(downGroup,1)
                        
                        %setting conditionIndex to accomodate for NaNs in downGroup and upGroup
                        conditionIndex = downStartingIndex(sequence);
                        
                        %to account for first few trials, in which nonCatchMatrix 's size is less than the number of stimuli in the up/down Group
                        if size(index + (conditionIndex-1):n) < maxSizeDown
                            %do nothing
                        elseif nonCatchMatrix(index + (conditionIndex-1):n, block) == (downGroup(sequence, conditionIndex:end)')
                            reverse = 1;
                        end
                        
                    end
            elseif sign(n - 1, block) == -1
                %setting index to avoid nonpositive indices in matrices.
                index = n-maxSizeUp + 1;
                if index <= 0
                    index = 1;
                    end 
                for sequence = 1:size(upGroup,1)
                    %setting conditionIndex to accomodate for NaNs in downGroup and upGroup
                    conditionIndex = upStartingIndex(sequence);     
                    if size(nonCatchMatrix(index + (conditionIndex-1):n, block), 1) < maxSizeUp
                        %do nothing
                    elseif nonCatchMatrix(index + (conditionIndex-1):n, block) == (upGroup(sequence, conditionIndex:end)')
                        reverse = 2;
                    end
                end
            end
            
            if reverse > 0
                pvMatrix(trial, block) = coherence;
                run = run + 1;
            end
        end
        

        %Assigning sign. True for negative. False for positive IF this is
        %not a catch trial
        if catchMat(trial, block) == 0
            %reversal is a downgroup
            if reverse == 1
                sign(n, block) = -1;
                indexNRevMatrix = [indexNRevMatrix trial];
            %reversal is an upgroup
            elseif reverse == 2
                sign(n, block) = 1;
                indexPRevMatrix = [indexPRevMatrix trial];
            else
                sign(n, block) = sign(n - 1, block);
                if sign(n, block) == 1
                    indexPRevMatrix = [indexPRevMatrix trial];
                elseif sign(n, block) == -1
                    indexNRevMatrix = [indexNRevMatrix trial];
                end
            end
        end
        
        timesPresentation(trial, block) = (GetSecs - timeStart); %TIMING CODE 
        timesPostP(trial,block) = GetSecs - timePostP; %TIMING CODE
        trial = trial + 1;
    end

%Calculating psychometric threshold using Wetherill method
numReversals = 0;
for i = 1:numel(pvMatrix(:,block))
    if pvMatrix(i, block) ~= 0
        numReversals = numReversals + 1;
    end
end

% DrawFormattedText(window, 'Block Finished! Press any key to continue.','center', 'center', white, window);
% Screen('Flip', window);
% KbStrokeWait;

end


psychThresh(block) = sum(pvMatrix(:,block)) / numReversals;

%end of experiment screen
DrawFormattedText(window, 'Experiment Finished! Press any key to exit.','center', 'center', white, window);
Screen('Flip', window);

%closes all the windows upon key press
KbStrokeWait;
close all;
sca;

%% ------------------
%  Calculating Averages on times Matrices
%--------------------
for i = 1:blocks
    for j = 1:trials
        timesCue(trials + 1, i) = timesCue(trials + 1, i) + timesCue(j, i);
        timesISI(trials + 1, i) = timesISI(trials + 1, i) + timesISI(j, i);
        timesPostP(trials + 1, i) = timesPostP(trials + 1, i) + timesPostP(j, i);
        timesPostStim(trials + 1, i) = timesPostStim(trials + 1, i) + timesPostStim(j, i);
        timesPreP(trials + 1, i) = timesPreP(trials + 1, i) + timesPreP(j, i);
        timesPreStim(trials + 1, i) = timesPreStim(trials + 1, i) + timesPreStim(j, i);
        timesPresentation(trials + 1, i) = timesPresentation(trials + 1, i) + timesPresentation(j, i);
        timesStim(trials + 1, i) = timesStim(trials + 1, i) + timesStim(j, i);
    end
        timesCue(trials + 1, i) = timesCue(trials + 1, i) / trials;
        timesISI(trials + 1, i) = timesISI(trials + 1, i) / trials;
        timesPostP(trials + 1, i) = timesPostP(trials + 1, i) / trials;
        timesPostStim(trials + 1, i) = timesPostStim(trials + 1, i) / trials;
        timesPreP(trials + 1, i) = timesPreP(trials + 1, i) / trials;
        timesPreStim(trials + 1, i) = timesPreStim(trials + 1, i) / trials;
        timesPresentation(trials + 1, i) = timesPresentation(trials + 1, i) / trials;
        timesStim(trials + 1, i) = timesStim(trials + 1, i) / trials;
end
%% 
% %% --------------------
% % Plotting Run History
% %--------------------
% 
% %turning on hold
% hold on;
% 
% %setting dimmensions of plot
% set(gca, 'xlim', [0 trial], 'ylim', [0 1]);
% 
% %plotting
% %trialHistory = plot(indexPRespMatrix, stimMat(2, indexPRespMatrix), indexNRespMatrix, stimMat(2, indexNRespMatrix), indexPRevMatrix, stimMat(2, indexPRevMatrix), indexNRevMatrix, stimMat(2, indexNRevMatrix), indexCatchMatrix, stimMat(2,indexCatchMatrix),'LineStyle', 'none');
% trialHistory = plot(indexPRespMatrix, stimMat(2, indexPRespMatrix, block),'LineStyle', 'none', 'Marker', 'o', 'MarkerFaceColor', 'g');
% trialHistory = plot(indexNRespMatrix, stimMat(2, indexNRespMatrix, block),'LineStyle', 'none', 'Marker', 'o', 'MarkerFaceColor', 'r');
% 
% %setting positives to have + symbol and negatives to have - symbol ;
% 
% % 
% % trialHistory(3).Marker = 'o';
% % trialHistory(3).MarkerFaceColor = 'g';
% % trialHistory(3).MarkerEdgeColor = 'none';
% % 
% % trialHistory(4).Marker = 'o';
% % trialHistory(4).MarkerFaceColor = 'r';
% % trialHistory(4).MarkerEdgeColor = 'none';
% % 
% % trialHistory(5).Marker = 'o';
% % trialHistory(5).MarkerFaceColor = 'b';
% % trialHistory(5).MarkerEdgeColor = 'none';
