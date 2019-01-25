function [leftLeg,rightLeg]=synch(leftLeg,rightLeg)
%This function synchronizes each leg
%Only points with very close time stamps are kept. This assumes sampling
%rate is constant

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

%% Synch up2Down1
leftLeg(:,6)=max([leftLeg(:,6),rightLeg(:,6)],[],2);
rightLeg(:,6)=leftLeg(:,6);
end
