function bCLM=getbCLMiPod(paramsiPod,lCLM,rCLM)
% sorting, recalculating, and syncing left and right leg CLM data.
%
% Input
% paramsiPod -input structure that define criteria for scoring (The WASM criteria
%             for scoring different leg movements)
% lCLM - left leg CLM matrix 
% rCLM - right leg CLM matrix 
%
% Output 
% bCLM - the combined CLM matrix with recalculated columns. It include max
%        4mCLM and mCLM have to be overlap in 0.5 seconds. 
if isnan(lCLM(1,1))
   bCLM=rCLM;
   return
elseif isnan(rCLM(1,1))
    bCLM=lCLM;
    return
end
% combine and sort LM arrays
rCLM(:,13) = 1; lCLM(:,13) = 2;
bCLM = [rCLM;lCLM];
bCLM = sortrows(bCLM,1);

numOverlap = ones(size(bCLM,1),1); %Counter for how many monolateral CLM per bilateral CLM
i=1;
while i < size(bCLM,1)
    
    % If no overlap
    if isempty(intersect(bCLM(i,1):bCLM(i,2),(bCLM(i+1,1)-floor(paramsiPod.fs*paramsiPod.maxOverlapLag)):bCLM(i+1,2)))
        i = i+1;   
    else % There is overlap
        numOverlap(i,1) = numOverlap(i,1) + numOverlap(i+1,1);
        bCLM(i,2) = max(bCLM(i,2),bCLM(i+1,2)); %update end of movement
        bCLM(i,9)=max(bCLM(i,9),bCLM(i+1,9)); %update break points
        bCLM(i,13) = 3; %indicate bilateral movement
        
        bCLM(i+1,:) = [];
        numOverlap(i+1,:)=[];
    end
end
%% Add duration in 3rd col
bCLM(:,3) = (bCLM(:,2) - bCLM(:,1))/paramsiPod.fs;
%% Add breakpoint (in next row) for duration >15s or >4 monolateral movements
% and remove those CLM
bCLM(:,9)=bCLM(:,9)|[0;bCLM(1:end-1,3)>paramsiPod.maxbCLMDuration];
bCLM(:,9)=bCLM(:,9)|[0;numOverlap(1:end-1,1)>paramsiPod.maxbCLMOverlap];
bCLM(numOverlap(:,1)>paramsiPod.maxbCLMOverlap,:)=[];
bCLM(bCLM(:,3)>paramsiPod.maxbCLMDuration,:)=[];

% Recalculate other cols in CLM
%% Add IMI in sec in 4th column
bCLM(1,4)=9999;
if (size(bCLM,1)>1)
    bCLM(2:size(bCLM,1),4)=(bCLM(2:size(bCLM,1),1)-bCLM(1:size(bCLM,1)-1,1))/paramsiPod.fs;
end
%% 5th col will be used in getPLM (not included in output at the moment) 
%% up2Down1 in 6th Column is preserved since start time for each CLM does not change
%% Convert beginning of LMs to mins in 7th Column
bCLM (:,7) = bCLM(:,1)/(paramsiPod.fs*60);
%% Record epoch number of LM in 8th Column
bCLM (:,8) = round (bCLM (:,7)*2 +0.5);
%% Record area of LM in 10th Column (9th Col reserved for breakpoints in PLM series)
% skip this for combined CLM
% for i=1:size(LM,1)
%     CLM(i,10)=sum(RMS(CLM(i,1):CLM(i,2),1))/fs;
% end
end


function [leftLeg,rightLeg]=synch(leftLeg,rightLeg)
%This function synchronizes each leg
%Only points with very close time stamps are kept. This assumes sampling
%rate is constant
%
%Intput 
%leftLeg - left leg CLM data
%rightLeg - right leg CLM data
%
%Output
%leftLeg - excluding end and start, a new left leg CLM data that overlaps 
%          with right leg 
%rightLeg - excluding end and start, a new right leg CLM data that overlaps
%           with left leg
leftLegSize = size(leftLeg);
leftLegSize = leftLegSize(1,1); 
   
rightLegSize = size(rightLeg);
rightLegSize = rightLegSize(1,1);

if leftLeg(1,10)>rightLeg(1,10) %%If first left time is after first right time, have to find correct right time 
   rightstart=0;
   for i = rightLegSize:-1:1  %%Find first index in right side where righttimestamp is closest to first left timestamp
       if leftLeg(1,10) <= rightLeg(i,10)
          rightstart = i; 
       end 
   end
   if rightstart > 0 %%If  matching start time is not the original start time
       rightLeg = rightLeg(rightstart:rightLegSize,:);
   else
       rightstart = NaN;
   end

elseif leftLeg(1,10)<rightLeg(1,10) %%If first right time is after first left time
    leftstart=0;
    for i = leftLegSize:-1:1  %% loop for finding first index where left timestamp is closest to the first right timestamp
       if leftLeg(i,10) >= rightLeg(1,10)
          leftstart = i; 
       end 
   end
   if leftstart > 0 %%If matching start time is not original start time
       leftLeg=leftLeg(leftstart:leftLegSize,:);
   else
       leftstart = NaN;
   end
end
%%Sync End

%% Change array sizes to have equal duration of recording.
% Just make the dimensions equal since sampling rate is the same and start time is synched
leftLegSize = size(leftLeg);
leftLegSize = leftLegSize(1,1); 
   
rightLegSize = size(rightLeg);
rightLegSize = rightLegSize(1,1);

%%Delete rows that come before the sync time
if leftLegSize > rightLegSize   
   leftLeg = leftLeg(1:rightLegSize,:);
   leftminusright = leftLeg(rightLegSize,10)-rightLeg(rightLegSize,10);
elseif leftLegSize<rightLegSize
   rightLeg = rightLeg(1:leftLegSize,:);
   leftminusright = leftLeg(leftLegSize,10)-rightLeg(leftLegSize,10);
end


end