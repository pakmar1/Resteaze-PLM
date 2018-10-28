% Combined LM is all movements from both legs.
% Keep unilateral LM.
% Remove shorter movements that occur within a longer movement on opposite leg.
% Extend times that begin on one leg and continue on the other.
function [filteredLM] = removeOverlap(combinedLM,fs)

% First and second movement indeces.
i = 1;
j = 2;

% Index in new array.
newIdx = 1;

% Instantiate an array that is the size of the total combined LM.
arrLength = size(combinedLM,1);
filteredLM = zeros(arrLength,size(combinedLM,2));

while (i < arrLength)
    % Isolated movement with no overlap.
    if (combinedLM(i,2) < (combinedLM(j,1) - fs/2))
        filteredLM(newIdx,1) = combinedLM(i,1);
        filteredLM(newIdx,2) = combinedLM(i,2);
        filteredLM(newIdx,13) = combinedLM(i,13);
        i = i+1;
        j = j+1;
        newIdx = newIdx + 1;
    % Movement begins on one leg and continues on the other.
    elseif (combinedLM(i,2) > (combinedLM(j,1) - fs/2) && combinedLM(i,2) < combinedLM(j,2))
        filteredLM(newIdx,1) = combinedLM(i,1);
        
        while (combinedLM(i,2) > (combinedLM(j,1) - fs/2) && j < arrLength)
            i = i + 1; j = j + 1;
        end
        
        filteredLM(newIdx,2) = combinedLM(i,2);
        filteredLM(newIdx,13) = 3;
        i = i+1;
        j = j+1;
        newIdx = newIdx + 1;
    % Strange case where movements end at same time...
    elseif (combinedLM(i,2) == combinedLM(j,2))
        filteredLM(newIdx,1) = combinedLM(i,1);
        filteredLM(newIdx,2) = combinedLM(i,2);
        filteredLM(newIdx,13) = 3;
        
        i = i+1;
        j = j+1;
    % Movement occurs within a longer movement.
    else
        while (combinedLM(j,2) < combinedLM(i,2) && j < arrLength) % While end is within first LM
            j = j+1;
        end
        filteredLM(newIdx,1) = combinedLM(i,1);
        if (combinedLM(j,1) < combinedLM(i,2) && combinedLM(j,2) > combinedLM(i,2))
            filteredLM(newIdx,2) = combinedLM(j,2);
        else
            filteredLM(newIdx,2) = combinedLM(i,2);
        end
        filteredLM(newIdx,13) = 3;
        i = j;
        j = j+1;
        newIdx = newIdx + 1;
    end
end

% Remove trailing zeroes
filteredLM(all(filteredLM==0,2),:)=[];


end