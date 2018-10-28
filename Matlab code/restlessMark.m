function [RestlessMark_Handles]=restlessMark(input)
GLM=input.GLM;
Arousal=input.Arousal;
fs=input.fs;
intervalSize=input.intervalSize;
numIntervals = floor(input.TRT/input.intervalSize); % Minutes
shiftX=input.shiftX_PLM;
barHeight=input.barHeight_restless;


WAKE_INTERVAL_SIZE=0.5; %Hardcode
numWakeIntervals=floor(input.TRT/WAKE_INTERVAL_SIZE);

[wake]=input.wake;%scoreSleep(input.fs,input.lRMS,input.PLM,input.bCLM);
wakeIdx=find(wake);

ArousalMarkings=zeros(numIntervals,1);
GLMMarkings=zeros(numIntervals,1);
for i=2:numIntervals+1
    for ii=1:size(GLM,1)
        if GLM(ii,1)>= (i-1)*intervalSize*60*fs && GLM(ii,1)< i*intervalSize*60*fs
            GLMMarkings(i-1,1)=1;
        end
    end
    
    for kk=1:size(Arousal,1)
        if Arousal(kk,1)>= (i-1)*intervalSize*60*fs && Arousal(kk,1)< i*intervalSize*60*fs
            ArousalMarkings(i-1,1)=1;
        end
    end
   
end

WakeMarkings=zeros(numWakeIntervals,1);
for i=2:numWakeIntervals+1
    for kk=1:size(Arousal,1)
        if Arousal(kk,1)>= (i-1)*WAKE_INTERVAL_SIZE*60*fs && Arousal(kk,1)< i*WAKE_INTERVAL_SIZE*60*fs
            WakeMarkings(i-1,1)=WakeMarkings(i-1,1)+Arousal(kk,3);
        end
    end
    for kk=1:size(wakeIdx,1)
       if wakeIdx(kk,1)>= (i-1)*WAKE_INTERVAL_SIZE*60*fs && wakeIdx(kk,1)< i*WAKE_INTERVAL_SIZE*60*fs
            WakeMarkings(i-1,1)=15; %%ie. if 'scoresleep' detects wake, make whole epoch wake
       end
    end
end
WakeMarkings=find(WakeMarkings(:,1)>=15); %15s in 30s interval to be considered wake
WakeMarkings=histcounts(WakeMarkings,1:floor(numWakeIntervals/numIntervals):numWakeIntervals+1)'; 
WakeMarkings=(WakeMarkings>0)+0;
%%Plot
hold on
%RestlessMark_Handles.restful=bar(find(GLMMarkings==0&ArousalMarkings==0&WakeMarkings==0)+shiftX,barHeight*ones(sum(GLMMarkings==0&ArousalMarkings==0&WakeMarkings==0),1),1,'FaceColor','c');
RestlessMark_Handles.restful=bar(numIntervals/2+shiftX,barHeight,numIntervals,'c');
RestlessMark_Handles.GLM=bar(find(GLMMarkings)+shiftX,barHeight*ones(sum(GLMMarkings>0),1),1,'FaceColor',[244,164,96]/255);
RestlessMark_Handles.arousal=bar(find(ArousalMarkings)+shiftX,barHeight*ones(sum(ArousalMarkings>0),1),1,'FaceColor',[139,69,19]/256);%'FaceColor',[55/255 161/255 255/255]);
RestlessMark_Handles.wake=bar(find(WakeMarkings)+shiftX,barHeight*ones(sum(WakeMarkings>0),1),1,'FaceColor','k');

RestlessMark_Handles.restless=GLMMarkings+ArousalMarkings+WakeMarkings;

%Axis Properties
set(RestlessMark_Handles.GLM,'edgecolor',[244,164,96]/255);
set(RestlessMark_Handles.arousal,'edgecolor',[139,69,19]/256);
set(RestlessMark_Handles.wake,'edgecolor','k');
set(RestlessMark_Handles.restful,'edgecolor','c');

% xlim([0,numIntervals+1]*2)
%set(gca,'Color','c');
% set(gca,'xtick',[])
% set(gca,'xticklabel',[])
set(gca,'ytick',[])
set(gca,'yticklabel',[])
%set(gca,'XColor','w')
%set(gca,'YColor','w')
end