%%%%
%%  [Indices] = findIndices(data,lowThreshold,highThreshold,minLowDuration,minHighDuration)
%%  returns array of indices defining the periods of data above the highThreshold that last for
%%  a minimum length of minHighDuration, without an interruption below lowThreshold that lasts for
%%  a minimum length of minLow Duration,
%%%%minHighDuration
function [fullRuns] = findIndices(data,lowThreshold,highThreshold,minLowDuration,minHighDuration,fs)
    minLowDuration = minLowDuration * fs;
    minHighDuration = minHighDuration * fs;
    lowValues = find(data < lowThreshold);          
    highValues = find(data > highThreshold);
    if size(highValues,1) < 1
        fullRuns(1,1) = 0;                  %ends function if no highvalues detected 
        fullRuns(1,2) = 0                   %sets array with runs to  0  0               
        return;
    end
    if size(lowValues,1) < 1
        fullRuns(1,1) = 1;                  %ends function if not lowValues detected
        fullRuns(1,2) = 0                   % sets array with runs to 1  0
        return;
    end 

    lowRuns = returnRuns(lowValues,minLowDuration);
    %highRuns = returnRuns(highValues,minHighDuration);

    numHighRuns = 0;
    searchIndex = highValues(1);
    while (searchIndex < size(data,1))
        numHighRuns = numHighRuns + 1;
        [distToNextLowRun,lengthOfNextLowRun] = calcDistToRun(lowRuns,searchIndex);
        if (distToNextLowRun == -1)  %%Then we have hit the end, record our data and stop 
            highRuns(numHighRuns,1) = searchIndex;
            highRuns(numHighRuns,2) = size(data,1);
            searchIndex = size(data,1);
        else %%We have hit another low point, so record our data, 
            highRuns(numHighRuns,1) = searchIndex;
            highRuns(numHighRuns,2) = searchIndex + distToNextLowRun-1;
            %%And then search again with the next high value after this low Run.
            searchIndex = searchIndex+distToNextLowRun+lengthOfNextLowRun;
            searchIndex = highValues(find(highValues>searchIndex,1,'first'));
        end
    end
      
    %%Implement a quality control to only keep highRuns > minHighDuration
    runLengths = highRuns(:,2)-highRuns(:,1);
    fullRuns = highRuns(find(runLengths > minHighDuration),:);
    
    
    
    
        
    
    %%%CREATE GRAPHICAL OUTPUT SO THAT I CAN SEE THAT IT"S WORKING
    
%     Indices = highRuns;
%     figure;
%     hold on;
%     plot(data,'b')
%     plot([1,size(data,1)],[lowThreshold,lowThreshold],'r--');
%     plot([1,size(data,1)],[highThreshold,highThreshold],'r--');
%     for i=1:size(Indices,1)
%         plot([Indices(i,1),Indices(i,2)],[highThreshold,highThreshold],'g-','LineWidth',5);
%     end
%     
%     Indices = lowRuns;
%     for i=1:size(Indices,1)
%         plot([Indices(i,1),Indices(i,2)],[lowThreshold,lowThreshold],'m-','LineWidth',5);
%     end
%     
%     Indices = fullRuns;
%     for i=1:size(Indices,1)
%         plot([Indices(i,1),Indices(i,2)],[mean([highThreshold,lowThreshold]),mean([highThreshold,lowThreshold])],'r-','LineWidth',5);
%     end
%     

end





function [runs] = returnRuns(vals,duration)
    k = [true;diff(vals(:))~=1 ];
    s = cumsum(k);
    x =  histc(s,1:s(end));
    idx = find(k);
    startIndices = vals(idx(x>=duration));
    stopIndices = startIndices + x(x>=duration) -1;
    runs =  [startIndices,stopIndices];
end



%%This Function finds the closest next (sequential) run from the current
%%position.  It does include prior runs.  If there is no run it returns a
%%distance of -1, otherwise it returns the distance to the next run.  It
%%will also return the length of that run.  If there is no run it returns a
%%length of -1.
function [dist,length] = calcDistToRun(run,position)
    distList = run(:,1) - position;
    distPos = distList(distList > 0);
    if (distPos) 
        dist = min(distPos);
        runIndex = find(distList == dist);
        length = run(runIndex,2)-run(runIndex,1)+1;
    else
        length = -1;
        dist = -1;
    end
end

