function [stimulusTextures] = GenerateAnimatedNoiseGabor(gaborMatrix, noiseMatrices, coherence, duration, ifi, window)
%GenerateAnimatedNoiseGabor creates a one dimensional array 'stimulusTextures' that contains the textures for each individual frame of an animation of the Gabor patch
%in animated noise
%   gaborMatrix - pixel value matrix of the gabor
%   noiseMatrices - 3D matrix containing several noise frames to choose randomly from for moving noise apperature of gabor
%   
[x y numNoises] = size(noiseMatrices);
refreshRate = 1/ifi; %calculating monitor refresh rate
for frame = 1:round(refreshRate*duration/1000) %number of frames inside duration of presentation desired
    noised_gabor = EmbedInNoise2(gaborMatrix, coherence, 0, 0);
    stimulusMatrix = EmbedInEfficientApperature(noised_gabor, noiseMatrices(:, :, round(rand(1) * (numNoises- 1) + 1))); 
    stimulusTextures(frame) = Screen('MakeTexture', window, stimulusMatrix);
end 

end

