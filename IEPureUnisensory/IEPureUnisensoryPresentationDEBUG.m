%Inverse Effectiven                                                                                                                                                                                                     ess Pure Block Trials Only. Constant Stimuli. Paints Psychometric curve for A and V. 
% Clear the workspace and the screen
%Latest Addition - Red Fixation Cross in both auditory and visual blocks
close all;
clearvars;

%------------------------
% Participant Information
%------------------------
participant = 'Allison';                                                    %name of the participant.
filepath = 'C:\Users\lhshaw\Desktop\Psychophysics DATA'; 
         
%--------------------
% Initial PTB Set-up
%--------------------
PsychDefaultSetup(2);                                                       % Setup PTB with some default values
screenNumber = max(Screen('Screens'));                                      % Set the screen number to the external secondary monitor if there is one connected
white = WhiteIndex(screenNumber);                                           % Define black, white and grey
black = BlackIndex(screenNumber);
grey = white / 2;
PsychDebugWindowConfiguration(1, 1);
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey, [], 32, 2, [], [],  kPsychNeed32BPCFloat); % Open the screen
%Screen('ColorRange', window, 1);
ifi = Screen('GetFlipInterval', window);                                    %Query the monitor flip interval
refreshRate = 1/ifi;
Screen('TextFont', window, 'Ariel');                                        %Set the text font and size
Screen('TextSize', window, 40);
topPriorityLevel = MaxPriority(window);                                     %Query the maximum priority level
[xCenter, yCenter] = RectCenter(windowRect);                                %Get the center coordinate of the window
rand('seed', sum(100 * clock));                                             %random seed
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');  % Set up alpha-blending for smooth (anti-aliased) lines
InitializePsychSound(1);                                                    % Initialize Sounddriver
nrchannels = 2;                                                             % Number of channels and sample rate
sampleFreq = 48000;
volume = 0.5;
startCue = 0;
repetitions = 1;
waitForDeviceStart = 1;


%---------------------
% Block Params & Logic
%---------------------
numberConditions = 2;
blocksPerCondition = 8;
numberBlocks = numberConditions * blocksPerCondition;
blockMatrix = repmat(1:numberConditions, 1, blocksPerCondition);         % blockMatrix contains block order instructions. 1D matrix with numbers indicating block type
shuffler = randperm(numberBlocks);                                         % Declaring shuffler matrix to shuffle blockMatrix
blockMatrix = blockMatrix(shuffler);                                      % Using shuffler shuffle blockMatrix

% Within Block Params & Logic                                              % Enter your within block experiment specific parameters here
gradationsPerCondition = 15;                                               % 
setsPerBlock = 1;                                                         % How many sets of gradationss per block? i.e 5 sets of 10 gradationss = 50 non-catch trials per block
stimuliPerBlock = gradationsPerCondition * setsPerBlock;
catchTrialsPerBlock = 0;                                                  % How many catch trials do you want in a block?
numberTrialsPerBlock = stimuliPerBlock + catchTrialsPerBlock;

%-------------------
% Stimuli Parameters
%-------------------
%Timing Information
startDuration = 2000;                                          % Interval before first stimulus of each block in ms
startDurationAuditory = (fix(startDuration/1000*refreshRate)) * (1/refreshRate) * 1000;
isiDurationPossible = [1400 2800];                                     % Inter-stimulus-interval duration in ms
stimulusDuration = 60;                                         % Duration stimulus is on screen in ms
stimulusDurationAuditory = (fix(stimulusDuration/1000*refreshRate)) *  (1/refreshRate) * 1000;

blockMaxDuration = startDuration + numberTrialsPerBlock*(max(isiDurationPossible)+stimulusDuration);

sizeX = 500;                                                   % Dimmensions of the square noise patch
sizeY = 500;  
%Generating Pure Fixation Cross
crossLength = 10;
crossWidth = 1;
cross = zeros(sizeX);
cross(:,:) = 0.5;
crossCenter = size(cross, 1) / 2;
cross = repmat(cross, 1, 1, 3);
cross(crossCenter - crossWidth:crossCenter+crossWidth,crossCenter - crossLength:crossCenter + crossLength,1) = 1;
cross(crossCenter - crossWidth:crossCenter+crossWidth,crossCenter - crossLength:crossCenter + crossLength,2:3) = 0;
cross(crossCenter - crossLength:crossCenter + crossLength, crossCenter-crossWidth:crossCenter+crossWidth, 1) = 1;
cross(crossCenter - crossLength:crossCenter + crossLength, crossCenter-crossWidth:crossCenter+crossWidth, 2:3) = 0;
crossTexture = Screen('MakeTexture', window, cross);

%Generating Visual Noise                                                % This code creates noise by pregenerating a pool of noise images which are sampled randomly
numberNoiseTextures = 100;                                     %    to create the animated noise. numberNoiseTextures is the size of that pool
noiseMatrix = zeros(sizeY, sizeX, 3, numberNoiseTextures);
for i = 1:numberNoiseTextures
    noise = rand(sizeY, sizeX);
    noise = repmat(noise, 1, 1, 3);
    noise(crossCenter - crossWidth:crossCenter+crossWidth,crossCenter - crossLength:crossCenter + crossLength,1) = 1;
    noise(crossCenter - crossWidth:crossCenter+crossWidth,crossCenter - crossLength:crossCenter + crossLength,2:3) = 0;
    noise(crossCenter - crossLength:crossCenter + crossLength, crossCenter-crossWidth:crossCenter+crossWidth, 1) = 1;
    noise(crossCenter - crossLength:crossCenter + crossLength, crossCenter-crossWidth:crossCenter+crossWidth, 2:3) = 0;
    noiseMatrix(:,:,:,i) = noise;
    noiseTextures(i) = Screen('MakeTexture', window, noiseMatrix(:,:,:,i));
end
 

%Generating Base Gabor
gaborSize = 300;                                               % This is the diameter/length of any side of the gabor pixel matrix. 
sigma = 50;                                                    % Standard deviation of gaussian window in pixels
lambda = 20;                                                   % Wavelength of sine wave grating in pixels per cycle
orientation = 0;                                               % Orientation of gabor from 0 -> 2pi
phase = pi;                                                    % Phase of spatial sine wave from 0 -> 2pi
amplitude = 1;                                                 % Amplitude is a variable that changes peak values of the spatial sine wave. Change to 0.5
                                                               %  to make spatial sine wave take values from -.5 to .5   

gaborMatrix = CreateGabor2(gaborSize, sigma, lambda, orientation, phase, amplitude); %CreateGabor2 takes all of these parameters and spits out a pixel matrix for a gabor

%Visual Stimuli Parameters
visualParameters = zeros(3, gradationsPerCondition);          % Matrix to keep track of parameters of each generated visual stimuli.
visualParameters(1,:) = [.5 .4 .35 .3 .205 .2 .105 .1 .095 .09 .085 .08 .075 .07 0];  % Assigning coherences
visualParameters(2,:) = orientation;                           % Assigning orientations. 0->2pi
visualParameters(3,:) = phase;                                 % Assigning phases. 0->2pi

%Auditory Stimuli Parameters
frequency1 = 1000;                                             %To create a ripple, two sine waves are multiplied with each other 
frequency2 = 200;
audioParameters = zeros(1, gradationsPerCondition);
audioParameters(1,:) = [.3 .25 .15 .1 .05 .045 .04 .035 .03 .025 .02 .015 .01 .005 0];

%Centering texture in center of window
xPos = xCenter;
yPos = yCenter;
baseRect = [0 0 sizeX sizeY];
rectCenter = CenterRectOnPointd(baseRect, xPos, yPos);
%--------------------------------
% Experimental Loop & Trial Logic
%--------------------------------
 
 visualTrialMatrix = [repmat(visualParameters, 1, setsPerBlock) zeros(3, catchTrialsPerBlock)];   % Creates a single row matrix to act as a base matrix for presenting a single block
 audioTrialMatrix = [repmat(audioParameters, 1, setsPerBlock) zeros(1, catchTrialsPerBlock)];
 trialsPerBlock = size(visualTrialMatrix, 2);
 trialCell = cell(4, numberBlocks);                                                               % Expands the single row matrix into a cell. One matrix for each block.
 responseMatrix = zeros(numberBlocks, trialsPerBlock);
 for block = 1:numberBlocks
     shuffler = randperm(trialsPerBlock);                                                         % generates shuffle matrix to randomly permute trial history matrices
     if blockMatrix(block) == 1
         trialCell{1,block} = 1;
         trialCell{2,block} = visualTrialMatrix(:,shuffler);
     elseif blockMatrix(block) == 2
         trialCell{1,block} = 2;
         trialCell{2, block} = audioTrialMatrix(:, shuffler);
     end
 end

for block = 1:numberBlocks
    ['block ' int2str(block)]
    %Generating Animation Matrices for this block
    visualCell = cell(1,trialsPerBlock);
    audioCell = cell(1,trialsPerBlock);
    visualTrialMatrix = [];                                                                       % Initializing visualTrialMatrix, a 1D array containing textures for the entire block.
    audioTrialMatrix = [];                                                                        % Initializing audioTrialMatrix, a 2xtrials array containing audio information for the entire block
    frameToTrialMatrix = [];                                                               % Initializing frameToTrialMatrix, a 2D array containing response windows for the entire block
    tempResponseMatrix = zeros(1, trialsPerBlock);
    [pinkNoiseMatrix, sampleFreq] = audioread('PinkNoise.WAV');
    pinkNoiseMatrix = pinkNoiseMatrix';
    pinkNoiseMatrix(2,:) = pinkNoiseMatrix(1,:);
    auditorySampleIndex = uint64(1);                                                                                            % [RWStart#1 RWStart#2...]
    
    %Building animation matrices for all trials per block
    for trial = 1:trialsPerBlock
        visualTrialMatrix = [];
        audioTrialMatrix = [];
        coherence = trialCell{2, block}(1, trial);                                           % Loading parameters from trialMatrix for code readability
        if blockMatrix(block) == 1
            orientation = trialCell{2, block}(2, trial);
            phase = trialCell{2, block}(3, trial);
        end
        %Building animation matrices for start interval before first presentation
        % Defining start of block period as being part of trial 1
        if trial == 1
            if blockMatrix(block) == 1 %Pure Visual Block                                           % Checking block type and filling animation matrices with initial isi before first stimuli presentation
                [visualTrialMatrix, frameToTrialMatrix]= AnimateVisualNoise(visualTrialMatrix, noiseTextures, frameToTrialMatrix, trial, startDuration, ifi); % Adding visual noise to visualTrialMatrix
                audioTrialMatrix = AnimateAuditorySilence(audioTrialMatrix, startDurationAuditory, sampleFreq);       % Adding silence to audioTrialMatrix
            elseif blockMatrix(block) == 2 %Pure Auditory Block
                [visualTrialMatrix, frameToTrialMatrix]= AnimateFixationCross(visualTrialMatrix, crossTexture, frameToTrialMatrix, trial, startDuration, ifi);  % Adding fixation cross
                [audioTrialMatrix, auditorySampleIndex] = AnimateAuditoryPinkNoise(audioTrialMatrix, pinkNoiseMatrix, startDurationAuditory, sampleFreq, auditorySampleIndex);         % Adding Auditory Noise
            end
        end

         %Stimulus
        if blockMatrix(block) == 1
            [visualTrialMatrix, frameToTrialMatrix] = AnimateNoisyGabor(visualTrialMatrix, gaborMatrix, noiseMatrix, crossLength, crossWidth, frameToTrialMatrix, trial, coherence, stimulusDuration, ifi, window); % Adding noisy gabor stimulus to visualTrialMatrix
            audioTrialMatrix = AnimateAuditorySilence(audioTrialMatrix, stimulusDurationAuditory, sampleFreq);                                                     % Adding silence to audioTrialMatrix
%             figure
%             imshow(stimulusMatrix)
        elseif blockMatrix(block) == 2
            [visualTrialMatrix, frameToTrialMatrix]= AnimateFixationCross(visualTrialMatrix, crossTexture, frameToTrialMatrix, trial, stimulusDuration, ifi);                     % Adding fixation cross to visualTrialMatrix
            [audioTrialMatrix, auditorySampleIndex]= AnimatePinkNoisyRipple(audioTrialMatrix, pinkNoiseMatrix, frequency1, frequency2, coherence, stimulusDurationAuditory, sampleFreq, auditorySampleIndex);                     % Adding noisy ripple sound to audioTrialMatrix
          
        end                                                                           
        
        %Building ISI Response Interval
        if numel(isiDurationPossible) > 1
            isiDuration1 = isiDurationPossible(1);
            isiDuration2 = isiDurationPossible(2);
            isiDuration = rand(1) * (isiDuration2 - isiDuration1) + isiDuration1;
        else
            isiDuration = isiDurationPossible;
        end
        trialCell{4, block}(trial) = isiDuration;
        isiDurationAuditory = (fix(isiDuration/1000*refreshRate)) *  (1/refreshRate) * 1000;
        
        if blockMatrix(block) == 1
            [visualTrialMatrix, frameToTrialMatrix] = AnimateVisualNoise(visualTrialMatrix, noiseTextures, frameToTrialMatrix, trial, isiDuration, ifi);  % Adding visual noise to visualTrialMatrix. Retrieve Response window, the interval during which to tell the presentation function to get responses
                                                                                    % Adding silence to audioTrialMatrix                                        
        elseif blockMatrix(block) == 2
            [visualTrialMatrix, frameToTrialMatrix] = AnimateFixationCross(visualTrialMatrix, crossTexture, frameToTrialMatrix, trial, isiDuration, ifi);   % Adding fixation cross to visualTrialMatrix
            [audioTrialMatrix, auditorySampleIndex]= AnimateAuditoryPinkNoise(audioTrialMatrix, pinkNoiseMatrix, isiDurationAuditory, sampleFreq, auditorySampleIndex);                                                           % Adding Auditory Noise          
          
        end
        visualCell{trial} = visualTrialMatrix;
        audioCell{trial} = audioTrialMatrix;
    end
    DrawFormattedText(window, 'Ready to Start Next Block. Press any key to continue...', 'center', 'center', white);
    Screen('Flip', window);
    KbStrokeWait;
    %Playing back the animation that was just generated
    pahandle = PsychPortAudio('Open', [], 1, 1, sampleFreq, nrchannels, [], [], [], []);
    tempResponseMatrix = PlayAVAnimation(visualCell, audioCell, tempResponseMatrix, frameToTrialMatrix, pahandle, volume, window, ifi, rectCenter);
    responseMatrix(block,:) = tempResponseMatrix;
    PsychPortAudio('Close', pahandle);
    DrawFormattedText(window, 'End of Block! Please Wait...', 'center', 'center', white);
    Screen('Flip', window);
    
    dataCell = trialCell;
    for i = 1:numberBlocks
        dataCell{3, i} = responseMatrix(i,:);
    end
    numberTrialTypes = size(visualParameters,2);                              % Number of trial types
    %Calculating Psychometric Threshold
    yAxis = zeros(numberConditions, numberTrialTypes);
    numberOccurrences = zeros(numberConditions, numberTrialTypes);
    titles = ['Visual', 'Auditory'];
    
    figure;
    for condition = 1:numberConditions
        plots(condition) = subplot(2,1,condition);
    end
    for condition = 1:numberConditions
        %setting xAxis for plot
        if condition == 1
            xAxis(condition,:) = visualParameters(1,:);
            trialTypes = visualParameters(1,:);
        elseif condition == 2
            xAxis(condition,:) = audioParameters;
            trialTypes = audioParameters;
        end
        
        
        %setting yAxis for plot
        for trialType = 1:numberTrialTypes
            for i = 1:numberBlocks
                for trial = 1:size(dataCell{2,1}, 2)
                    if (dataCell{1, i}(1) == condition) && (dataCell{2, i}(1, trial) == trialTypes(trialType))
                        numberOccurrences(condition, trialType) = numberOccurrences(condition, trialType) + 1;
                        if dataCell{3, i}(trial) == 1
                            yAxis(condition, trialType) = yAxis(condition, trialType) + 1;
                        end
                    end
                end
            end
        end
        yAxis(condition,:) = yAxis(condition,:) ./ numberOccurrences(condition,:);
        
        
        
        plot(plots(condition), xAxis(condition,:), yAxis(condition,:), '-o');
        title(plots(condition), titles(condition));
        drawnow;
    end
    
end

%Creating dataCell - cell that contains all information about stimuli and responses. Row one - Blocl Type. row two - Stimuli Info. Row three - respones.
dataCell = trialCell;
for block = 1:numberBlocks
    dataCell{3, block} = responseMatrix(block,:);
end

%% ------------------
% PLOTTING DATA
%--------------------
numberTrialTypes = size(visualParameters,2);                              % Number of trial types
%Calculating Psychometric Threshold
yAxis = zeros(numberConditions, numberTrialTypes);
numberOccurrences = zeros(numberConditions, numberTrialTypes);
titles = ['Visual', 'Auditory'];

figure;
for condition = 1:numberConditions
    plots(condition) = subplot(2,1,condition);
end 
for condition = 1:numberConditions
    %setting xAxis for plot
    if condition == 1
        xAxis(condition,:) = visualParameters(1,:);
        trialTypes = visualParameters(1,:);
    elseif condition == 2
        xAxis(condition,:) = audioParameters;
        trialTypes = audioParameters;
    end
   
 
    %setting yAxis for plot
    for trialType = 1:numberTrialTypes
        for block = 1:numberBlocks
            for trial = 1:size(dataCell{2,1}, 2)
                if (dataCell{1, block}(1) == condition) && (dataCell{2, block}(1, trial) == trialTypes(trialType))
                    numberOccurrences(condition, trialType) = numberOccurrences(condition, trialType) + 1;
                    if dataCell{3, block}(trial) == 1
                        yAxis(condition, trialType) = yAxis(condition, trialType) + 1;
                    end                   
                end
            end
        end
    end
    yAxis(condition,:) = yAxis(condition,:) ./ numberOccurrences(condition,:);
    
  
    
    plot(plots(condition), xAxis(condition,:), yAxis(condition,:), '-o');
    title(plots(condition), titles(condition));
end 
%% ------------------
% SAVING DATA
%--------------------
%filesaving

filename = [participant '.mat']; %TIMING CODE: remove '_timing'

save(fullfile(filepath, filename), 'xAxis','yAxis', 'dataCell', 'visualParameters', 'audioParameters');
sca;
Screen('CloseAll')
