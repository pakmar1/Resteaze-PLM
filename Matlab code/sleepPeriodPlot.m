function sleepPeriodPlot(input)
sleepStart=input.sleepStart; %mins
sleepEnd=input.sleepEnd; %mins

shiftX_sleepPeriod=input.shiftX_sleepPeriod;
shiftY_sleepPeriod=input.shiftY_sleepPeriod;
numIntervals = floor(input.TRT/input.intervalSize); % Minutes

if sleepStart<12*60
   sleepStart(2,1)=sleepStart+24*60; 
end
if sleepEnd<12*60
   sleepEnd(2,1)=sleepEnd+24*60;
end
sleepStart=[0;sleepStart];
sleepEnd=[sleepEnd;36*60];
sleepStart(:,2)=1;
sleepEnd(:,2)=2;
sleepPts=[sleepStart;sleepEnd];
sleepPts=sortrows(sleepPts,1);

hold on
%Dark Grey Bar for dark times
dark1=bar(15*60/36/60*numIntervals/3+input.shiftX_sleepPeriod, 3,10*60/36/60*numIntervals/3);
dark2=bar(35*60/36/60*numIntervals/3+input.shiftX_sleepPeriod, 3,2*60/36/60*numIntervals/3);
set(dark1,'facecolor',[0.2,0.2,0.2]*4)
set(dark1,'edgecolor',[0.2,0.2,0.2]*4)
set(dark2,'facecolor',[0.2,0.2,0.2]*4)
set(dark2,'edgecolor',[0.2,0.2,0.2]*4)
%Lines for sleep period
for i=find(sleepPts(:,2)==1)'
    if sleepPts(i+1,2)==2
        if sleepPts(i,1)>0
        line([sleepPts(i,1), sleepPts(i,1)]/36/60*numIntervals/3+shiftX_sleepPeriod, [-.5 .5]+shiftY_sleepPeriod,'LineWidth',1)
        end
        if sleepPts(i+1,1)<36*60
        line([sleepPts(i+1,1), sleepPts(i+1,1)]/36/60*numIntervals/3+shiftX_sleepPeriod, [-.5 .5]+shiftY_sleepPeriod,'LineWidth',1)
        end
        line([sleepPts(i,1), sleepPts(i+1,1)]/36/60*numIntervals/3+shiftX_sleepPeriod, [0 0]+shiftY_sleepPeriod,'LineWidth',1)
    end
end
line([0 36*60]/36/60*numIntervals/3+shiftX_sleepPeriod, [3 3],'Color','k','LineWidth',1)
line([0 36*60]/36/60*numIntervals/3+shiftX_sleepPeriod, [0 0],'Color','k','LineWidth',1)
line([0 0]/36/60*numIntervals/3+shiftX_sleepPeriod, [0 3],'Color','k','LineWidth',1)
line([36*60 36*60]/36/60*numIntervals/3+shiftX_sleepPeriod, [0 3],'Color','k','LineWidth',1)


end