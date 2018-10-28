
function output=sleepText(sleepTime)
sleepHr=mod(floor(sleepTime/60)+12,24) ;
sleepMin=floor(rem(sleepTime,60));
if sleepHr<10
    sleepHr=['0' num2str(sleepHr)];
else
    sleepHr=num2str(sleepHr);
end
if sleepMin<10
    sleepMin=['0' num2str(sleepMin)];
else
    sleepMin=num2str(sleepMin);
end
output=[sleepHr ':' sleepMin];
end