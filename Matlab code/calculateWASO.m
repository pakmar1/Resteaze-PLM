function [WASO] = calculateWASO(up2Down1,minSleepTime,fs)
%minSleepTime is in mins
%sleepStart is in datapoints
%durWASO is in mins

minSleepTime=minSleepTime*60*fs; %convert from minutes to datapoints
if sum(up2Down1==2)==0
WASO.sleepStart=1;
WASO.num=0;
WASO.dur=0;
WASO.avgdur=0;
elseif sum(up2Down1==1)==0
WASO.sleepStart=NaN;
WASO.num=NaN;
WASO.dur=NaN;
WASO.avgdur=NaN;
elseif minSleepTime>=sum(up2Down1==1)
    WASO.sleepStart=NaN;
    WASO.num=NaN;
    WASO.dur=NaN;
    WASO.avgdur=NaN;
else
sleepBreakPoints=[1;abs(diff(up2Down1))]; %1 when fall asleep/wake up
runStart=find(sleepBreakPoints(:,1)==1);
runLength=[runStart(2:end,1)-runStart(1:end-1,1);size(up2Down1,1)-runStart(end,1)+1]; %Assumes next break point is immediately after the last row

sleepStart=runStart(find((runLength(:,1)>=minSleepTime)&(up2Down1(runStart,1)==1),1,'first'),1);
WASO.sleepStart=sleepStart;

%% RunStart is now all runs from start of sleep
runStart=find(sleepBreakPoints(sleepStart:end,1)==1);
runLength=[runStart(2:end,1)-runStart(1:end-1,1);size(up2Down1,1)-runStart(end,1)+1]; %Assumes next break point is immediately after the last row

WASO.sleepStart=sleepStart;
WASO.num=sum(up2Down1(runStart,1)==2);
WASO.dur=sum(runLength(up2Down1(runStart,1)==2,1))/fs/60;
WASO.avgdur=mean(runLength(up2Down1(runStart,1)==2,1))/fs/60;
end
end