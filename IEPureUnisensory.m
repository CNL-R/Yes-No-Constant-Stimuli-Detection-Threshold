%Inverse Effectiveness Pure Block Trials Only. Constant Stimuli. Paints Psychometric curve for A and V. 

% Clear the workspace and the screen
sca;
close all;
clearvars;

%------------------------
% Participant Information
%------------------------
participant = 'plswork';                                                    %name of the participant.

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
ifi = Screen('GetFlipInterval', window);                                    %Query the monitor flip interval
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
blocksPerCondition = 5;
numberBlocks = numberConditions * blocksPerCondition;
blockMatrix = [1 1 1 1 1 1 1 1 1 1];%repmat(1:numberConditions, 1, blocksPerCondition);           % blockMatrix contains block order instructions. 1D matrix with numbers indicating block type
shuffler = randperm(numberBlocks);                                          % Declaring shuffler matrix to shuffle blockMatrix
blockMatrix = blockMatrix(shuffler);                                      % Using shuffler shuffle blockMatrix

% Within Block Params & Logic                                               % Enter your within block experiment specific parameters here
graduationsPerCondition = 10;                                               % 
setsPerBlock = 1;                                                           % How many sets of graduations per block? i.e 5 sets of 10 graduations = 50 non-catch trials per block
stimuliPerBlock = graduationsPerCondition * setsPerBlock;
catchTrialsPerBlock = stimuliPerBlock;                                      % How many catch trials do you want in a block?
numberTrialsPerBlock = stimuliPerBlock + catchTrialsPerBlock;

%-------------------
% Stimuli Parameters
%-------------------
%Timing Information
startDuration = 2000;                                          % Interval before first stimulus of each block in ms
isiDuration = [1000 3000];                                     % Inter-stimulus-interval duration in ms
stimulusDuration = 60;                                         % Duration stimulus is on screen in ms
blockMaxDuration = startDuration + numberTrialsPerBlock*(isiDuration(2)+stimulusDuration);


sizeX = 500;                                                   % Dimmensions of the square noise patch
sizeY = 500;  
%Generating Pure Fixation Cross
crossLength = 50;
crossWidth = 3;
crossCenter = crossLength/2;
cross = zeros(crossLength);
cross(:,:) = 0.5;
cross(crossCenter-crossWidth:crossCenter+crossWidth, 1:crossLength) = 1;
cross( 1:crossLength, crossCenter-crossWidth:crossCenter+crossWidth) = 1;
cross = EmbedInApperature(cross, 'rect', sizeX, sizeY, 0.5, 0.5);

crossTexture = Screen('MakeTexture', window, cross);

%Generating Visual Noise
                                                 % This code creates noise by pregenerating a pool of noise images which are sampled randomly
numberNoiseTextures = 100;                                     %    to create the animated noise. numberNoiseTextures is the size of that pool
noiseMatrix = rand(sizeY, sizeX, numberNoiseTextures);         % Pixel value matrices are converted to textures and stored in noiseTextures
for noiseTexture = 1:numberNoiseTextures
    noiseTextures(noiseTexture) = Screen('MakeTexture', window, noiseMatrix(:,:,noiseTexture));
    for i = 1:sizeY
        for j = 1:sizeX
            if rand(1) < .5
                noiseMatrix(i,j, noiseTexture) = -1  * noiseMatrix(i,j, noiseTexture);
            end
        end
    end
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
visualParameters = zeros(3, graduationsPerCondition);          % Matrix to keep track of parameters of each generated visual stimuli.
visualParameters(1,:) = [1 1 1 1 1 1 1 1 1 1];  % Assigning coherences
visualParameters(2,:) = orientation;                           % Assigning orientations. 0->2pi
visualParameters(3,:) = phase;                                 % Assigning phases. 0->2pi

%Auditory Stimuli Parameters
frequency1 = 1000;                                             %To create a ripple, two sine waves are multiplied with each other 
frequency2 = 200;
audioParameters = zeros(1, graduationsPerCondition);
audioParameters(1,:) = [.75 1 .5 .2 .1 .3 .4 .1 .1 .15];

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
 trialCell = cell(1, numberBlocks);                                                               % Expands the single row matrix into a cell. One matrix for each block.
 for block = 1:numberBlocks
     shuffler = randperm(trialsPerBlock);                                                         % generates shuffle matrix to randomly permute trial history matrices
     if blockMatrix(block) == 1
         trialCell{1,block} = visualTrialMatrix(:,shuffler);
     elseif blockMatrix(block) == 2
         trialCell{1, block} = audioTrialMatrix(:, shuffler);
     end
 end
 
for block = 1:3%numberBlocks
    
    %Generating Animation Matrices for this block
    visualMatrix = [];                                                                       % Initializing visualMatrix, a 1D array containing textures for the entire block.
    audioMatrix = [];                                                                        % Initializing audioMatrix, a 2xtrials array containing audio information for the entire block
    responseWindowMatrix = [];                                                               % Initializing responseWindowMatrix, a 2D array containing response windows for the entire block
    if blockMatrix(block) == 2
        pinkNoiseMatrix = GenerateAuditoryPinkNoise(blockMaxDuration, sampleFreq);             % Generating all of the pink noise for this block
        auditorySampleIndex = 1;                                                                                           % [RWStart#1 RWStart#2...]
    end
    
    %Building animation matrices for start interval before first presentation
    if blockMatrix(block) == 1 %Pure Visual Block                                           % Checking block type and filling animation matrices with initial isi before first stimuli presentation
        [visualMatrix, responseWindowMatrix]= AnimateVisualNoise2(visualMatrix, noiseTextures, responseWindowMatrix, startDuration, ifi, 0); % Adding visual noise to visualMatrix
        audioMatrix = AnimateAuditorySilence(audioMatrix, startDuration, sampleFreq);       % Adding silence to audioMatrix
    elseif blockMatrix(block) == 2 %Pure Auditory Block
        [visualMatrix, responseWindowMatrix]= AnimateVisualNoise2(visualMatrix, crossTexture, responseWindowMatrix, startDuration, ifi, 0);  % Adding fixation cross
        [audioMatrix auditorySampleIndex] = AnimateAuditoryPinkNoise(audioMatrix, pinkNoiseMatrix, startDuration, sampleFreq, auditorySampleIndex);         % Adding Auditory Noise

    end
                                           
    
    %Building animation matrices for all trials per block
    for trial = 1:trialsPerBlock
        coherence = trialCell{1, block}(1, trial);                                           % Loading parameters from trialMatrix for code readability
        if blockMatrix(block) == 1
            orientation = trialCell{1, block}(2, trial);
            phase = trialCell{1, block}(3, trial);
        end
        %Building stimulus
        if blockMatrix(block) == 1
            [visualMatrix responseWindowMatrix] = AnimateNoisyGabor2(visualMatrix, gaborMatrix, noiseMatrix, responseWindowMatrix, coherence, stimulusDuration, ifi, window, 1); % Adding noisy gabor stimulus to visualMatrix
            audioMatrix= AnimateAuditorySilence(audioMatrix, stimulusDuration, sampleFreq);                                                     % Adding silence to audioMatrix
%             figure
%             imshow(stimulusMatrix)
        elseif blockMatrix(block) == 2
            [visualMatrix responseWindowMatrix]= AnimateVisualNoise2(visualMatrix, crossTexture, responseWindowMatrix, stimulusDuration, ifi, 1);                     % Adding fixation cross to visualMatrix
            [audioMatrix auditorySampleIndex]= AnimatePinkNoisyRipple(audioMatrix, pinkNoiseMatrix, frequency1, frequency2, coherence, stimulusDuration, sampleFreq, auditorySampleIndex);                     % Adding noisy ripple sound to audioMatrix
        end                                                                           
        
        %Building ISI Response Interval
        if blockMatrix(block) == 1
            [visualMatrix responseWindowMatrix] = AnimateVisualNoise2(visualMatrix, noiseTextures, responseWindowMatrix, isiDuration, ifi, 1);  % Adding visual noise to visualMatrix. Retrieve Response window, the interval during which to tell the presentation function to get responses
            audioMatrix = AnimateAuditorySilence(audioMatrix, isiDuration, sampleFreq);                                                         % Adding silence to audioMatrix                                        
        elseif blockMatrix(block) == 2
            [visualMatrix responseWindowMatrix] = AnimateVisualNoise2(visualMatrix, crossTexture, responseWindowMatrix, isiDuration, ifi, 1);   % Adding fixation cross to visualMatrix
            [audioMatrix auditorySampleIndex]= AnimateAuditoryPinkNoise(audioMatrix, pinkNoiseMatrix, isiDuration, sampleFreq, auditorySampleIndex);                                                           % Adding Auditory Noise          
        end                                                                                                                                                                                              
    end 
    %Open audio port
    pahandle = PsychPortAudio('Open', [], 1, 1, sampleFreq, nrchannels, [], [], [], []);
    %Playing back the animation that was just generated
    PlayAVAnimation(visualMatrix, audioMatrix, responseWindowMatrix, pahandle, volume, window, 0, ifi, 0, 0, 0, 0, rectCenter)
    PsychPortAudio('Close', pahandle);
    
end 
    sca;
    Screen('CloseAll')
