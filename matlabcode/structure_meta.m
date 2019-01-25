function [LM, GLM, Arousal, epochs] = structure_meta()

fs = 50; 
[f, p] = uigetfile('*.csv');
out = readtable([p,f]);

% Well, if there's an event on the very first data point we might be in
% trouble. I don't know how this could possibly happen... Actually, I'm
% gonna force it to not happen
out.PLM(1) = 0;
LM = find(out.PLM(2:end) == 1 & out.PLM(1:end-1) == 0) + 1;
LM(:,2) = find(out.PLM(2:end) == 0 & out.PLM(1:end-1) == 1);

LM(:,3) = (LM(:,2) - LM(:,1))/fs;
LM(2:end,4) = (LM(2:end,1) - LM(1:end-1,1))/fs;


out.GLM(1) = 0;
GLM = find(out.GLM(2:end) == 1 & out.GLM(1:end-1) == 0) + 1;
GLM(:,2) = find(out.GLM(2:end) == 0 & out.GLM(1:end-1) == 1);

GLM(:,3) = (GLM(:,2) - GLM(:,1))/fs;
GLM(2:end,4) = (GLM(2:end,1) - GLM(1:end-1,1))/fs;

out.Arousal(1) = 0;
Arousal = find(out.Arousal(2:end) == 1 & out.Arousal(1:end-1) == 0) + 1;
Arousal(:,2) = find(out.Arousal(2:end) == 0 & out.Arousal(1:end-1) == 1);

Arousal(:,3) = (Arousal(:,2) - Arousal(:,1))/fs;
Arousal(2:end,4) = (Arousal(2:end,1) - Arousal(1:end-1,1))/fs;

% get the epoch stage vector - mode of Up2Down1 over a 30 second window
epochs = out.Up2Down1;
pad_l = ceil(size(epochs,1)/(fs * 30));
pad = zeros(pad_l * fs * 30 - size(epochs,1),1);
epochs = [epochs ; pad];
epochs = reshape(epochs, [pad_l, fs*30]);
epochs = mode(epochs')';
end