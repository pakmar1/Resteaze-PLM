function [PI]= calculatePI(CLMt)
%Adds breakpoints when changing between up/down to calculate PI
CLMt(:,9)=CLMt(:,9)+[1;abs(diff(CLMt(:,6)))]>0; 

minNumIMI=3; %For PI, need at least 3 IMI to be between 10-90

runStart=find(CLMt(:,9)==1);
runLength=[runStart(2:end,1)-runStart(1:end-1,1);size(CLMt,1)-runStart(end,1)+1]; %Assumes next break point is immediately after the last row
PLMrunLength=runLength(runLength(:,1)>minNumIMI);
PLMrunStart=runStart(runLength(:,1)>minNumIMI);

numIMI=PLMrunLength-3;

PI=sum(numIMI)/(size(CLMt,1)-1);

end