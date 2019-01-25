function [WASO] = calculateWASO_RE(wake,minSleepTime,fs)
%WASO calculates the number of awakenings and total wake-after-sleep-onset duration.
%
%inputs (default values):
%up2Down1=whether they are in sleep or not
%minSleepTime=5 minutes
%fs=20Hz
%
%outputs:
%WASO.sleepStart=datapoint where sleep begins
%WASO.num=number of times wake after sleep began
%WASO.dur=total duration of wake after sleep began
%WASO.avgdur=average duration of each waking period

wake=wake+1; %convert it to 'up2down1' format ie if awake, wake ==2 else  wake==1

minSleepTime=minSleepTime*60*fs; %convert from minutes to datapoints
%If they were never awake record number and duration at 0.
if sum(wake==2)==0
WASO.sleepStart=1;
WASO.num=0;
WASO.dur=0;
WASO.avgdur=0;
%If they were always awake record number and duration at NaN.
elseif sum(wake==1)==0
WASO.sleepStart=NaN;
WASO.num=NaN;
WASO.dur=NaN;
WASO.avgdur=NaN;
%If they were sleeping less than the minSleepTime record number and duration at NaN.
elseif minSleepTime>=sum(wake==1)
    WASO.sleepStart=NaN;
    WASO.num=NaN;
    WASO.dur=NaN;
    WASO.avgdur=NaN;
else
sleepBreakPoints=[1;abs(diff(wake))]; %1 when fall asleep/wake up
runStart=find(sleepBreakPoints(:,1)==1);
runLength=[runStart(2:end,1)-runStart(1:end-1,1);size(wake,1)-(runStart(end,1)+1)]; %Assumes next break point is immediately after the last row

sleepStart=runStart(find((runLength(:,1)>=minSleepTime)&(wake(runStart,1)==1),1,'first'),1);
WASO.sleepStart=sleepStart;

%% RunStart is now all runs from start of sleep
runStart=find(sleepBreakPoints(sleepStart:end,1)==1)+sleepStart-1;
runLength=[runStart(2:end,1)-runStart(1:end-1,1);size(wake,1)-runStart(end,1)+1]; %Assumes next break point is immediately after the last row

WASO.sleepStart=sleepStart;
WASO.num=sum(wake(runStart,1)==2);
WASO.dur=sum(runLength(wake(runStart,1)==2,1))/fs/60;
WASO.avgdur=mean(runLength(wake(runStart,1)==2,1))/fs/60;
end