%Plays Pure block of 100% coherent AV stimuli to test timing. No thresholds
%collected. Black background instead of noise. 

close all;
clearvars;

%--------------------
% Initial PTB Set-up
%--------------------
%A whole bunch of initial set-up stuff mostly involving PTB parameters. 
PsychDefaultSetup(2);                                                       % Setup PTB with some default values
screenNumber = max(Screen('Screens'));                                      % Set the screen number to the external secondary monitor if there is one connected
white = WhiteIndex(screenNumber);                                           % Define black, white and grey
black = BlackIndex(screenNumber);
grey = white / 2;
%PsychDebugWindowConfiguration(1, 1);
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey, [], 32, 2, [], [],  kPsychNeed32BPCFloat); % Open the screen
%Screen('ColorRange', window, 1);
ifi = Screen('GetFlipInterval', window);                                    %Query the monitor flip interval
refreshRate = 1/ifi;
Screen('TextFont', window, 'Ariel');                                        %Set the text font and size
Screen('TextSize', window, 40);
topPriorityLevel = MaxPriority(window);                                     %Query the maximum priority level
Priority(topPriorityLevel);
[xCenter, yCenter] = RectCenter(windowRect);                                %Get the center coordinate of the window
rand('seed', sum(100 * clock));                                             %random seed
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');  % Set up alpha-blending for smooth (anti-aliased) lines
InitializePsychSound(1);                                                    % Initialize Sounddriver
nrchannels = 2;                                                             % Number of channels and sample rate
volume = 0.5;
startCue = 0;
repetitions = 1;
waitForDeviceStart = 1;


%-------------------------
% Block Logic & Parameters
%-------------------------
numberConditions = 3;                                                      %V,A,AV
blocksPerCondition = 1;                                                    
%numberBlocks = numberConditions * blocksPerCondition;
numberBlocks = 1 * blocksPerCondition;
%blockMatrix = repmat(1:numberConditions, 1, blocksPerCondition);           % blockMatrix contains block order instructions. 1D matrix with numbers indicating block type
blockMatrix = repmat(3,1,blocksPerCondition);
shuffler = randperm(numberBlocks);                                         % Declaring shuffler matrix to shuffle blockMatrix
blockMatrix = blockMatrix(shuffler);                                       % Using shuffler shuffle blockMatrix

% Within Block Parameters & Logic                                          % Enter your within block experiment specific parameters here
gradationsPerCondition = 1;                                            
setsPerBlock = 100;                                                          %How many sets of gradations per block? i.e 5 sets of 10 gradations = 50 non-catch trials per block
stimuliPerBlock = gradationsPerCondition * setsPerBlock;
catchTrialsPerBlock = 0;                                                   % How many catch trials do you want in a block?
numberTrialsPerBlock = stimuliPerBlock + catchTrialsPerBlock;

%-------------------
% Stimuli Parameters
%-------------------
%Timing Information
startDuration = 2000;                                                                                 % Interval before first stimulus of each block in ms
startDurationAuditory = (round(startDuration/1000*refreshRate)) * 1/refreshRate * 1000;                 % Keeping startDuration length consistent with frame rate cosntrictions in visual
isiDurationPossible = [1400 2800];                                                                    % Inter-stimulus-interval duration in ms
stimulusDuration = 60;                                                                                % Duration stimulus is on screen in ms
stimulusDurationAuditory = (round(stimulusDuration/1000*refreshRate)) *  1/refreshRate * 1000;          % Keeping stimulusDuration consistent with frame rate constrictions in visual 

%VISUAL STIMULI 
%Size of square noise patch
sizeX = 500;                    
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

%Generating Visual Noise 
    %This code creates noise by pregenerating a pool of noise images which are sampled randomly 
    %to create the animated noise.  
    %Each noise frame has a fixation cross embedded in the center
numberNoiseTextures = 25;                                                 %numberNoiseTextures is the size of that pool 
noiseMatrix = zeros(sizeY, sizeX, 3, numberNoiseTextures);                 %initializing matrix that will hold the pixel value matrices for the noise
for i = 1:numberNoiseTextures
    noise = rand(sizeY, sizeX);
    noise = repmat(noise, 1, 1, 3);
    %embedding cross
    noise(crossCenter - crossWidth:crossCenter+crossWidth,crossCenter - crossLength:crossCenter + crossLength,1) = 1;   %red channel of the cross horozontal = 1 
    noise(crossCenter - crossWidth:crossCenter+crossWidth,crossCenter - crossLength:crossCenter + crossLength,2:3) = 0; %green & blue channel of the horozontal = 0
    noise(crossCenter - crossLength:crossCenter + crossLength, crossCenter-crossWidth:crossCenter+crossWidth, 1) = 1;   %red channel of the cross vertical = 1
    noise(crossCenter - crossLength:crossCenter + crossLength, crossCenter-crossWidth:crossCenter+crossWidth, 2:3) = 0; %green & blue channel of the cross vertical = 0
    noiseMatrix(:,:,:,i) = noise;
    noiseTextures(i) = Screen('MakeTexture', window, noiseMatrix(:,:,:,i));                                             %converts pixel matrix to textures
end
 
%Generating Black Screen (for timing testing)
blackMatrix = zeros(sizeY, sizeX);
blackTexture = Screen('MakeTexture', window, blackMatrix); 

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
visualParameters(1,:) = 1;                                    % Assigning coherences
visualParameters(2,:) = orientation;                          % Assigning orientations. 0->2pi
visualParameters(3,:) = phase;                                % Assigning phases. 0->2pi



%Auditory Stimuli Parameters
    %To create a ripple, two sine waves are multiplied with each other 
frequency1 = 1000;                                                         %in Hz                                           
frequency2 = 200;
audioParameters = zeros(1, gradationsPerCondition);
audioParameters(1,:) = 1;                                                  % Generate Parameters function creates 16 gradations based inputted values  


%Centering texture in center of window
xPos = xCenter;
yPos = yCenter;
baseRect = [0 0 sizeX sizeY];
rectCenter = CenterRectOnPointd(baseRect, xPos, yPos);
%--------------------------------
% Experimental Loop & Trial Logic
%--------------------------------
 %Handles creating the trial logic for presenting stimuli
 visualTrialMatrix = [repmat(visualParameters, 1, setsPerBlock) zeros(3, catchTrialsPerBlock)];   % Creates a single row matrix to act as a base matrix for presenting a single block
 audioTrialMatrix = [repmat(audioParameters, 1, setsPerBlock) zeros(1, catchTrialsPerBlock)];     % Auditory version
 trialsPerBlock = size(visualTrialMatrix, 2);
 trialCell = cell(4, numberBlocks);                                                               % Expands the single row matrix into a cell. One matrix for each block.
 responseMatrix = zeros(numberBlocks, trialsPerBlock); %+3                                      % +3 is to put a few supraliminal stimuli in beginning
 for block = 1:numberBlocks
     shuffler = randperm(trialsPerBlock);                                                         % generates shuffle matrix to randomly permute trial history matrices
     if blockMatrix(block) == 1
         trialCell{1,block} = 1;                                                                                                % block type (1=visual, 2=auditory)                                       
         trialCell{2,block} = visualTrialMatrix(:,shuffler);
%          trialCell{2,block} = [trialCell{2,block}(1,:); trialCell{2,block}(2,:); trialCell{2,block}(3,:)]; %+3: adding a few supras to the beginning
     elseif blockMatrix(block) == 2
         trialCell{1,block} = 2;
         trialCell{2, block} = audioTrialMatrix(:, shuffler);
         trialCell{2, block} = trialCell{2,block}(1,:); %+3
     elseif blockMatrix(block) == 3 %Here, i've put audiotrialmatrix to be on the third row. Now pure auditory blocks use row three instead of row 2. 
         trialCell{1,block} = 3;
         trialCell{2,block} = visualTrialMatrix(:,shuffler);
         trialCell{3,block} = audioTrialMatrix(:,shuffler);
         
     end
 end

audioTrialMatrix = [audioTrialMatrix]; 

%PREGENERATION OF THE ENTIRE EXPERIMENT
for block = 1:numberBlocks
    ['block ' int2str(block)]                                              % Displaying block # to console
    %Generating Animation Matrices for this block
    visualCell = cell(1,trialsPerBlock);                                  
    audioCell = cell(1,trialsPerBlock);
    visualTrialMatrix = [];                                                % Initializing visualTrialMatrix, a 1D array containing textures for the entire block.
    audioTrialMatrix = [];                                                 % Initializing audioTrialMatrix, a 2xtrials array containing audio information for the entire block
    frameToTrialMatrix = [];                                               % Initializing frameToTrialMatrix, a 2D array containing response windows for the entire block
    tempResponseMatrix = zeros(1, trialsPerBlock); %+3
    [pinkNoiseMatrix, sampleFreq] = audioread('PinkNoise.WAV');
    pinkNoiseMatrix = pinkNoiseMatrix';
    pinkNoiseMatrix(2,:) = pinkNoiseMatrix(1,:);
    auditorySampleIndex = uint64(1);                                                                                            % [RWStart#1 RWStart#2...]
    
    %Building animation matrices for all trials per block
        %animation matrices:
            %visualTrialMatrix = Matrix of textures to be presented
            %auditoryTrialMatrix = Raw instructions to sound card. 2-channels.
            %frametoTrialMatrix = alligns the frame the visual stimuli is on to what trial this is 
    for trial = 1:trialsPerBlock
        visualTrialMatrix = [];
        audioTrialMatrix = [];
        % Loading parameters from trialMatrix for code readability
        
        if blockMatrix(block) == 1    
            coherence = trialCell{2, block}(1, trial);                         % grab coherence% if visual block, grab orientation and phase
            orientation = trialCell{2, block}(2, trial);
            phase = trialCell{2, block}(3, trial);
        elseif blockMatrix(block) == 2
            audIntensity = trialCell{3, block}(1, trial);
        elseif blockMatrix(block) == 3
            coherence = trialCell{2, block}(1, trial);                         % grab coherence% if visual block, grab orientation and phase
            orientation = trialCell{2, block}(2, trial);
            phase = trialCell{2, block}(3, trial);
            audIntensity = trialCell{3, block}(1, trial);
        end
        %Building animation matrices for start interval before first presentation
        % Defining start of block period as being part of trial 1
        if trial == 1
            if blockMatrix(block) == 1     %Pure Visual Block                                                                                                                       % Checking block type and filling animation matrices with initial isi before first stimuli presentation
                %[visualTrialMatrix, frameToTrialMatrix]= AnimateVisualNoise(visualTrialMatrix, noiseTextures, frameToTrialMatrix, trial, startDuration, ifi);                   % Adding visual noise to visualTrialMatrix
                [visualTrialMatrix, frameToTrialMatrix] = AnimateBlackBackground (visualTrialMatrix, blackTexture, frameToTrialMatrix, trial, startDuration, ifi);
                audioTrialMatrix = AnimateAuditorySilence(audioTrialMatrix, startDurationAuditory, sampleFreq);                                                                 % Adding silence to audioTrialMatrix
            elseif blockMatrix(block) == 2 %Pure Auditory Block
                %[visualTrialMatrix, frameToTrialMatrix]= AnimateFixationCross(visualTrialMatrix, crossTexture, frameToTrialMatrix, trial, startDuration, ifi);                  % Adding fixation cross
                [visualTrialMatrix, frameToTrialMatrix] = AnimateBlackBackground (visualTrialMatrix, blackTexture, frameToTrialMatrix, trial, startDuration, ifi);
                %[audioTrialMatrix, auditorySampleIndex] = AnimateAuditoryPinkNoise(audioTrialMatrix, pinkNoiseMatrix, startDurationAuditory, sampleFreq, auditorySampleIndex);  % Adding Auditory Noise
                audioTrialMatrix = AnimateAuditorySilence(audioTrialMatrix, startDurationAuditory, sampleFreq);                                                                 % Adding silence to audioTrialMatrix
            elseif blockMatrix(block) == 3 %Pure AV Block
                %[visualTrialMatrix, frameToTrialMatrix]= Anim, noiseTextures, frameToTrialMatrix, trial, startDuration, ifi);                   % Adding visual noise to visualTrialMatrix
                [visualTrialMatrix, frameToTrialMatrix] = AnimateBlackBackground (visualTrialMatrix, blackTexture, frameToTrialMatrix, trial, startDuration, ifi);
                %[audioTrialMatrix, auditorySampleIndex] = AnimateAuditoryPinkNoise(audioTrialMatrix, pinkNoiseMatrix, startDurationAuditory, sampleFreq, auditorySampleIndex);  % Adding Auditory Noise
                audioTrialMatrix = AnimateAuditorySilence(audioTrialMatrix, startDurationAuditory, sampleFreq); 
            end
        end

        %Stimulus
        if blockMatrix(block) == 1
            [visualTrialMatrix, frameToTrialMatrix] = AnimateNoisyGabor(visualTrialMatrix, gaborMatrix, noiseMatrix, crossLength, crossWidth, frameToTrialMatrix, trial, coherence, stimulusDuration, ifi, window); % Adding noisy gabor stimulus to visualTrialMatrix
            audioTrialMatrix = AnimateAuditorySilence(audioTrialMatrix, stimulusDurationAuditory, sampleFreq);                                                                                                      % Adding silence to audioTrialMatrix
        elseif blockMatrix(block) == 2
            %[visualTrialMatrix, frameToTrialMatrix]= AnimateFixationCross(visualTrialMatrix, crossTexture, frameToTrialMatrix, trial, stimulusDuration, ifi);                                                       % Adding fixation cross to visualTrialMatrix
            [visualTrialMatrix, frameToTrialMatrix] = AnimateBlackBackground (visualTrialMatrix, blackTexture, frameToTrialMatrix, trial, stimulusDuration, ifi);
            %[audioTrialMatrix, auditorySampleIndex]= AnimatePinkNoisyRipple(audioTrialMatrix, pinkNoiseMatrix, frequency1, frequency2, audIntensity, stimulusDurationAuditory, sampleFreq, auditorySampleIndex);       % Adding noisy ripple sound to audioTrialMatrix     
            [audioTrialMatrix, auditorySampleIndex]= AnimateNoiselessRipple(audioTrialMatrix, pinkNoiseMatrix, frequency1, frequency2, audIntensity, stimulusDurationAuditory, sampleFreq, auditorySampleIndex);       % Adding noisy ripple sound to audioTrialMatrix     
        elseif blockMatrix(block) == 3
            [visualTrialMatrix, frameToTrialMatrix] = AnimateNoisyGabor(visualTrialMatrix, gaborMatrix, noiseMatrix, crossLength, crossWidth, frameToTrialMatrix, trial, coherence, stimulusDuration, ifi, window); % Adding noisy gabor stimulus to visualTrialMatrix
            %[audioTrialMatrix, auditorySampleIndex]= AnimatePinkNoisyRipple(audioTrialMatrix, pinkNoiseMatrix, frequency1, frequency2, audIntensity, stimulusDurationAuditory, sampleFreq, auditorySampleIndex);       % Adding noisy ripple sound to audioTrialMatrix     
            [audioTrialMatrix, auditorySampleIndex]= AnimateNoiselessRipple(audioTrialMatrix, pinkNoiseMatrix, frequency1, frequency2, audIntensity, stimulusDurationAuditory, sampleFreq, auditorySampleIndex);       % Adding noisy ripple sound to audioTrialMatrix     
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
        isiDurationAuditory = (round(isiDuration/1000*refreshRate)) *  (1/refreshRate) * 1000;
        
        if blockMatrix(block) == 1
            %[visualTrialMatrix, frameToTrialMatrix] = AnimateVisualNoise(visualTrialMatrix, noiseTextures, frameToTrialMatrix, trial, isiDuration, ifi);                % Adding visual noise to visualTrialMatrix. Retrieve Response window, the interval during which to tell the presentation function to get responses
            [visualTrialMatrix, frameToTrialMatrix] = AnimateBlackBackground (visualTrialMatrix, blackTexture, frameToTrialMatrix, trial, isiDuration, ifi); 
            audioTrialMatrix = AnimateAuditorySilence(audioTrialMatrix, isiDurationAuditory, sampleFreq);                                                                      % Adding silence to audioTrialMatrix                                        
        elseif blockMatrix(block) == 2
            %[visualTrialMatrix, frameToTrialMatrix] = AnimateFixationCross(visualTrialMatrix, crossTexture, frameToTrialMatrix, trial, isiDuration, ifi);               % Adding fixation cross to visualTrialMatrix
            [visualTrialMatrix, frameToTrialMatrix] = AnimateBlackBackground (visualTrialMatrix, blackTexture, frameToTrialMatrix, trial, isiDuration, ifi); 
            %[audioTrialMatrix, auditorySampleIndex]= AnimateAuditoryPinkNoise(audioTrialMatrix, pinkNoiseMatrix, isiDurationAuditory, sampleFreq, auditorySampleIndex); % Adding Auditory Noise                
            audioTrialMatrix = AnimateAuditorySilence(audioTrialMatrix, isiDurationAuditory, sampleFreq);                                                                      % Adding silence to audioTrialMatrix                                        
        elseif blockMatrix(block) == 3
            %[visualTrialMatrix, frameToTrialMatrix] = AnimateVisualNoise(visualTrialMatrix, noiseTextures, frameToTrialMatrix, trial, isiDuration, ifi);                % Adding visual noise to visualTrialMatrix. Retrieve Response window, the interval during which to tell the presentation function to get responses
            [visualTrialMatrix, frameToTrialMatrix] = AnimateBlackBackground (visualTrialMatrix, blackTexture, frameToTrialMatrix, trial, isiDuration, ifi);
            %[audioTrialMatrix, auditorySampleIndex]= AnimateAuditoryPinkNoise(audioTrialMatrix, pinkNoiseMatrix, isiDurationAuditory, sampleFreq, auditorySampleIndex); % Adding Auditory Noise                
            audioTrialMatrix = AnimateAuditorySilence(audioTrialMatrix, isiDurationAuditory, sampleFreq);                                                                      % Adding silence to audioTrialMatrix                                        
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
end 
Screen('CloseAll')
%     %Calculating Psychometric Threshold
%     yAxis = zeros(numberConditions, numberTrialTypes);
%     numberOccurrences = zeros(numberConditions, numberTrialTypes);
%     titles = {'Visual', 'Auditory'};
%     
%     %figure;
%     for condition = 1:numberConditions
%         plots(condition) = subplot(2,1,condition);
%     end
%     for condition = 1:numberConditions
%         %setting xAxis for plot
%         if condition == 1
%             xAxis(condition,:) = visualParameters(1,:);
%             trialTypes = visualParameters(1,:);
%         elseif condition == 2
%             xAxis(condition,:) = audioParameters;
%             trialTypes = audioParameters;
%         end
%         
%         
%         %setting yAxis for plot
%         for trialType = 1:numberTrialTypes
%             for i = 1:numberBlocks
%                 for trial = 1:size(dataCell{2,1}, 2)
%                     if (dataCell{1, i}(1) == condition) && (dataCell{2, i}(1, trial) == trialTypes(trialType))
%                         numberOccurrences(condition, trialType) = numberOccurrences(condition, trialType) + 1;
%                         if dataCell{3, i}(trial) > 0
%                             yAxis(condition, trialType) = yAxis(condition, trialType) + 1;
%                         end
%                     end
%                 end
%             end
%         end
%         %yAxis(condition,:) = yAxis(condition,:) ./ numberOccurrences(condition,:);
%         
%         
%         
%         plot(plots(condition), xAxis(condition,:), yAxis(condition,:), '-o');
%         title(plots(condition), strjoin(titles(condition)));
%         drawnow;
%     end
%     
% end
% 
% %Creating dataCell - cell that contains all information about stimuli and responses. Row one - Block Type. Row two - Stimuli Info. Row three - respones.
% dataCell = trialCell;
% for block = 1:numberBlocks
%     dataCell{3, block} = responseMatrix(block,:);
% end
% 
% %% ------------------
% % PLOTTING DATA
% %--------------------
% numberTrialTypes = size(visualParameters,2);                               % Number of trial types
% %Calculating Psychometric Threshold
% yAxis = zeros(numberConditions, numberTrialTypes);
% numberOccurrences = zeros(numberConditions, numberTrialTypes);
% titles = {'Visual', 'Auditory'};
% 
% fig = figure;
% hold on;
% 
% for condition = 1:numberConditions
%     plots(condition) = subplot(2,1,condition);
%     %setting xAxis for plot
%     if condition == 1
%         xAxis(condition,:) = visualParameters(1,:);
%         trialTypes = visualParameters(1,:);
%     elseif condition == 2
%         xAxis(condition,:) = audioParameters;
%         trialTypes = audioParameters;
%     end
%    
%  
%     %setting yAxis for plot
%     for trialType = 1:numberTrialTypes
%         for block = 1:numberBlocks
%             for trial = 1:size(dataCell{2,1}, 2)
%                 if (dataCell{1, block}(1) == condition) && (dataCell{2, block}(1, trial) == trialTypes(trialType))
%                     numberOccurrences(condition, trialType) = numberOccurrences(condition, trialType) + 1;
%                     if dataCell{3, block}(trial) > 0
%                         yAxis(condition, trialType) = yAxis(condition, trialType) + 1;
%                     end                   
%                 end
%             end
%         end
%     end
%     yAxis(condition,:) = yAxis(condition,:) ./ numberOccurrences(condition,:);
%     
%   
%     [param, stat] = sigm_fit(xAxis(condition,:), yAxis(condition,:), [], [], 1);
%     set(gca, 'ylim', [0 1]);
%     hold on;
%     plot(plots(condition), xAxis(condition,:), yAxis(condition,:));
% 
%     title(plots(condition), strjoin(titles(condition)));
% end 
% ax = gca;
% ax.YLim = [0 1];
% savefig(fig, strcat(filepath, '\',participant, '_curve.fig'));
% saveas(fig, strcat(filepath, '\',participant, '_curve.png'));
% %% ------------------
% % SAVING DATA
% %--------------------
% %filesaving
% 
% filename = [participant '.mat']; 
% 
% save(fullfile(filepath, filename), 'xAxis','yAxis', 'dataCell', 'visualParameters', 'audioParameters', 'participant', 'numberConditions', 'numberTrialTypes','numberBlocks');
% sca;
% Screen('CloseAll')
