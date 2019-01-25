 function [CLM,PLM]= getPLMRE(paramsiPod,CLM);
 % The Periodic leg movement matrix is extracted from CLM matrix by
 % IMI greater than 10 sec criteria.                                     
 %
 % Input 
 % paramsiPod -input structure that define criteria for scoring (The WASM criteria
 %             for scoring different leg movements)
 % CLM - candidate leg movement matrix. Run by getCLMiPod
 %
 % Output
 % PLM - periodic leg movement matrix. Having minimum inter movement interval(IMI)
 %       of 10 seconds. Adding breakpoints with IMI greater than 90 seconds
if isnan(CLM(1,1))
    PLM=NaN;
    return ;
elseif isempty(CLM)
    PLM=[];
    return;
end
minIMIDuration=paramsiPod.minIMIDuration;
fs=paramsiPod.fs;
maxIMIDuration=paramsiPod.maxIMIDuration;
minNumIMI=paramsiPod.minNumIMI;

%% Remove CLM with IMI<10s to construct CLMt (an intermediate variable)
% also mark break point to movement after if paramsiPod.iLMbp is on (1)
index=1;
for i = 1:size(CLM,1)
    if CLM (i,4) >= paramsiPod.minIMIDuration;   %% find any PLM that have IMI>=minIMIdur from CLM and place it in the new array CLMt
        CLMt (index,:) = CLM (i,:);
        index = index +1;
    elseif i<size(CLM,1)
        CLM(i+1,4)= CLM(i+1,4)+CLM(i,4);   %this adjusts the IMI to be from the previous movement to the next
        if strcmp(paramsiPod.iLMbp,'on')
            CLM(i,9)=1;
            CLM(i+1,9)=1; %Add iLM breakpoint
        end
    end
end

if isempty(CLMt)
    PLM=[];
    return
end
%% Recalculate IMI [already recalculated in removeshortimi]
% CLMt(1,4)=9999;
% if (size(CLMt,1)>1)
%     CLMt(2:size(CLMt,1),4)=(CLMt(2:size(CLMt,1),1)-CLMt(1:size(CLMt,1)-1,1))/fs;
% end

%% Add break points where IMI > maxIMIDuration, 
%  Removing shortIMI LM could make some IMI greater than max
%  Old breakpoints will still remain. Some may be added
CLMt(:,9) = CLMt(:,4) > maxIMIDuration | CLMt(:,9);
CLM(:,9) = CLM(:,4) > maxIMIDuration | CLM(:,9);

%% Mark PLM in 5th Col
CLMt(:,5) = 0; % Restart PLM
runStart=find(CLMt(:,9)==1);
runLength=[runStart(2:end,1)-runStart(1:end-1,1);size(CLMt,1)-(runStart(end,1)+1)]; %Assumes next break point is immediately after the last row
PLMrunLength=runLength(runLength(:,1)>minNumIMI);
PLMrunStart=runStart(runLength(:,1)>minNumIMI);
for i=1:size(PLMrunStart,1)
   for ii=1:PLMrunLength(i,1)
        CLMt(PLMrunStart(i,1)+ii-1,5)=1;
    end
end

%do it for original CLM
CLM(:,5) = 0; % Restart PLM
runStart=find(CLM(:,9)==1);
runLength=[runStart(2:end,1)-runStart(1:end-1,1);size(CLM,1)-(runStart(end,1)+1)]; %Assumes next break point is immediately after the last row
PLMrunLength=runLength(runLength(:,1)>minNumIMI);
PLMrunStart=runStart(runLength(:,1)>minNumIMI);
for i=1:size(PLMrunStart,1)
   for ii=1:PLMrunLength(i,1)
        CLM(PLMrunStart(i,1)+ii-1,5)=1;
    end
end

%% Extract PLMt from CLMt
PLM = CLMt(CLMt(:,5) == 1,:); %should be same as extracting from CLM?
end