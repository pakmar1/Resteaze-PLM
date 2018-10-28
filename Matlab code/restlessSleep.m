function [restlessScore,restlessStage,restless_u2d1,restless_LM]...
    = restlessSleep(up2Down1,intervalSize,sleepStart,startTime,LM,fs,u2d1Factor,LMFactor)
% intervalSize=15;
% LM=PLMiPod.LM;
% sleepStart=PLMiPod.sleepStart;

step=intervalSize*fs*60-1;
restless_u2d1=zeros(size(up2Down1,1),1);
restless_LM=zeros(size(up2Down1,1),1);


LMmark=zeros(size(up2Down1,1),1);
LMarea=zeros(size(up2Down1,1),1);

for i=1:size(LM,1)
    LMmark(LM(i,1):LM(i,2),1)=1;
    LMarea(LM(i,1):LM(i,2),1)=LM(i,10);
end


for i=sleepStart:step:size(up2Down1,1)
if i+step<=size(up2Down1,1)
    interval=up2Down1(i:i+step,1);
    restless_u2d1(i:i+step,1)=sum(interval==2)/step;
    restless_LM(i:i+step,1)=sum(LMarea(i:i+step,1))/step;
end
end
restless_u2d1=restless_u2d1*u2d1Factor;
restless_LM=restless_LM*LMFactor;

restlessScore=max(restless_u2d1,restless_LM);
restlessScore=min(restlessScore,1);

index=0;
restlessStage=zeros(floor(size(up2Down1,1)/step),1);
for i=sleepStart:step:size(up2Down1,1)
if i+step<=size(up2Down1,1)
    index=index+1;
    restlessStage(index,1)=restlessScore(i,1);
end
end

% figure
% hold on
% plot(plotTime(1:size(restless),fs,startTime),restless_u2d1,'r')
% plot(plotTime(1:size(restless),fs,startTime),restless_LM,'k')
% 
% datetick('x','HH:MM:SS')  
% zoomAdaptiveDateTicks('on')
end


