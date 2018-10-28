function [PLMt,CLMt]= getPLMtiPod(CLM,minIMIDuration,fs,maxIMIDuration,minNumIMI)

CLMt = removeShortIMI(CLM,minIMIDuration); 
%% Recalculate IMI
CLMt(1,4)=9999;
if (size(CLMt,1)>1)
    CLMt(2:size(CLMt,1),4)=(CLMt(2:size(CLMt,1),1)-CLMt(1:size(CLMt,1)-1,1))/fs;
end

%% Add break points where IMI > maxIMIDuration, 
%  Removing shortIMI LM could make some IMI greater than max
%  Old breakpoints will still remain. Some may be added
CLMt(:,9) = CLMt(:,4) > maxIMIDuration | CLMt(:,9);

%% Mark PLM in 5th Col
CLMt(:,5) = 0; % Restart PLM
runStart=find(CLMt(:,9)==1);
runLength=[runStart(2:end,1)-runStart(1:end-1,1);size(CLMt,1)-runStart(end,1)+1]; %Assumes next break point is immediately after the last row
PLMrunLength=runLength(runLength(:,1)>minNumIMI);
PLMrunStart=runStart(runLength(:,1)>minNumIMI);
for i=1:size(PLMrunStart,1)
    for ii=1:PLMrunLength(i,1)
        CLMt(PLMrunStart(i,1)+ii-1,5)=1;
    end
end

%% Extract PLMt from CLMt
PLMt = CLMt(CLMt(:,5) == 1,:);

end