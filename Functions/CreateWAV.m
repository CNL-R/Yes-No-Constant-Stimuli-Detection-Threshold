function [] = CreateWAV( Frequency, Duration, SampleRate, Filename)
%Generates a sine wave and converts to audio WAV file. 
%   Frquency in Hz
%   Duration in ms
%   Sample Rate in Hz

    %Converting Duration from ms to seconds (because Hz is used as units in frequency and sample rate)
    Duration = Duration / 1000;
    
    t = 0:1/SampleRate:Duration;
    y = sin(2*pi*Frequency*t);
    
    audiowrite(Filename, y, SampleRate);
end

