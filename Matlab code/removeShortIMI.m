
function CLMt = removeShortIMI(CLM,minIMIDuration)
index=1;
for i = 1:size(CLM,1)
    if CLM (i,4) > minIMIDuration;   %% find any PLM that have duration greater than minPLMDuration from CLM and place it in the new array CLMt
       CLMt (index,:) = CLM (i,:);
       index = index +1;
    elseif i<size(CLM,1)
        CLM(i+1,4)= CLM(i+1,4)+CLM(i,4);   %this adjusts the IMI to be from the previous movement to the next
    end
end

end
