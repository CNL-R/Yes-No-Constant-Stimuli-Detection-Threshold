%This script generates moving noise
%   creates several frames of noise and plays by picking a random one 
Screen('Preference', 'SkipSyncTests', 1) %REMOVE THIS LATER!!!!
%--------------------
% INITIAL SET-UP
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
% Noise Stimuli Params
%--------------------
length = 700;
width = 700;
duration1 = 1000; %duration pure noise in ms
duration2 = 100;
waitframes = 1;

timeSecs = duration2/1000;
timeFrames = round(timeSecs ./ ifi);

%Centering texture in center of window
xPos = xCenter;
yPos = yCenter;
baseRect = [0 0 length width];
rectCenter = CenterRectOnPointd(baseRect, xPos, yPos);

%--------------------
% Generating Noise Textures
%--------------------
numTextures = 100;
noise = rand(width, length, numTextures);
for i = 1:numTextures
    textures(i) = Screen('MakeTexture', window, noise(:,:, i));
end 

%--------------------
% Gabor Stimuli Params
%--------------------
gaborLength = 300;
gaborWidth = gaborLength;
coherence = 1;

sigma = 65;
lambda = 50;
A = 1;

gabor = CreateGabor(gaborWidth, sigma, lambda, 'r', 'r', A);


while coherence > 0
coherence = coherence - .1;
%--------------------
% Generating Moving Gabor Textures
%--------------------

stimulusTextures = GenerateAnimatedNoiseGabor(gabor, noise, coherence, duration2, ifi, window);
% refreshRate = 1/ifi;
% for frame = 1:round(refreshRate*duration2/1000)
%     noised_gabor = EmbedInNoise(gabor, coherence, 0, 0);
%     stim = EmbedInEfficientApperature(noised_gabor, noise(:,:, round(rand(1) * (numTextures - 1) + 1)));
%     stimTexture(frame) = Screen('MakeTexture', window, stim);    
% end

% Playing Back Noise
vbl = PresentAnimatedNoise(textures, window, 0, ifi, duration1, 0, 0, 0, 0, 0, rectCenter);
% Screen('DrawTextures', window, textures(round(rand(1) * (numTextures - 1) + 1)), [], rectCenter, [], [], [], []);
% vbl = Screen('Flip', window);
% for frame = 1:timeFrames - 1
%     
%     Screen('DrawTextures', window, textures(round(rand(1) * (numTextures - 1) + 1)), [], rectCenter, [], [], [], []);
%     vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
%     
 %end

% Playing Back Gabors
vbl = PresentAnimatedNoiseGabor(stimulusTextures, window, vbl, ifi, duration2, 0, 0, 0, 0, 0, rectCenter);
% Screen('DrawTextures', window, stimulusTextures(1) ,[], rectCenter, [], [], [], []);
% vbl = Screen('Flip', window);
% for frame = 1:timeFrames - 1
%     Screen('DrawTextures', window, stimulusTextures(frame + 1), [], rectCenter, [], [], [], []);
%     vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
% end

% Playing Back Noise
vbl = PresentAnimatedNoise(textures, window, vbl, ifi, duration1, 0, 0, 0, 0, 0, rectCenter);
end