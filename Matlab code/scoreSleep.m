function [wake]=scoreSleep(fs,RMS,LM,GLM)

%Calculate numLMper10epochs - the number of GLM+LM per 10 epochs
dataPtsPerWindow=30*10*fs;
numWindows=ceil(size(RMS,1)/dataPtsPerWindow);
[numLMper10epochs,~] = histcounts([LM(:,1);GLM(:,1)],1:dataPtsPerWindow:numWindows*dataPtsPerWindow+1); %This includes the last window which may be incomplete
numLMper10epochs=numLMper10epochs';

%wakeLM is a logical vector indicating whether there is at least 1 GLM,LM in
%the 10 epochwindow that the current dataPt is in (0=there is LM, 1= no LM) 1 corresponds to wake.
wakeLM=zeros(size(RMS,1),1);
for i=1:numWindows-1
    wakeLM((i-1)*dataPtsPerWindow+1:i*dataPtsPerWindow,:)=numLMper10epochs(i)*ones(dataPtsPerWindow,1);
end
wakeLM((numWindows-1)*dataPtsPerWindow+1:size(RMS,1),:)=...
    numLMper10epochs(numWindows)*ones(mod(size(RMS,1),dataPtsPerWindow),1);
wakeLM=wakeLM==0;


%Acceleration stuff
AccelRMS10epochmax=zeros(size(RMS,1),1);
for i=1:numWindows-1
    AccelRMS10epochmax((i-1)*dataPtsPerWindow+1:i*dataPtsPerWindow,1)=...
        (max(RMS((i-1)*dataPtsPerWindow+1:i*dataPtsPerWindow,1)))*ones(dataPtsPerWindow,1);
end
    AccelRMS10epochmax((numWindows-1)*dataPtsPerWindow+1:size(RMS,1))=...
        (max(RMS((numWindows-1)*dataPtsPerWindow+1:size(RMS,1),1)))*ones(mod(size(RMS,1),dataPtsPerWindow),1);
AccelRMS10epochmax=AccelRMS10epochmax>.15;    
%if the max in that 10 epoch window is <.15 then there is no activity and
%we record sleep, vice versa for wake


%if the max in the 2 epoch window is >.5 then we record wake, even if prior
%LM criteria recorded sleep.
dataPtsPerWindow=30*2*fs;
numWindows=ceil(size(RMS,1)/dataPtsPerWindow);
AccelRMS2epochmax=zeros(size(RMS,1),1);
for i=1:numWindows-1
    AccelRMS2epochmax((i-1)*dataPtsPerWindow+1:i*dataPtsPerWindow,1)=...
        (max(RMS((i-1)*dataPtsPerWindow+1:i*dataPtsPerWindow,1)))*ones(dataPtsPerWindow,1);
end
    AccelRMS2epochmax((numWindows-1)*dataPtsPerWindow+1:size(RMS,1))=...
        (max(RMS((numWindows-1)*dataPtsPerWindow+1:size(RMS,1),1)))*ones(mod(size(RMS,1),dataPtsPerWindow),1);
AccelRMS2epochmax=AccelRMS2epochmax>.5;

%Only if <80% of epochs have LM, include accelerometer criteria
percentLM=1-sum(wakeLM)/(size(wakeLM,1));
if percentLM<.8
    wake=(wakeLM&AccelRMS10epochmax)|AccelRMS2epochmax;
else
    wake=wakeLM;
end

end