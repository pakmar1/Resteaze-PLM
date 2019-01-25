function LM = getLMiPod(paramsiPod,RMS,up2Down1)
% The LM matrix is made based on paramsiPod strucutre, RMS values, and
% up2Down1 vlaues.
% 
% Input
% paramsiPod -input structure that define criteria for scoring (The WASM criteria
%             for scoring different leg movements)
% RMS - root mean value square of accelometer data.
% up2Down1 - showing if the patient whether the patient is in sleep or awake.
%
% Output
% LM - matrix of leg movement having minimum duration of 0.5 seconds and no 
%      max duration. The structure include differnet type of variables.

if isnan(RMS(1,1))
    LM=NaN;
    return;
end
   
LM=findIndices(RMS,paramsiPod.lowThreshold,paramsiPod.highThreshold,paramsiPod.minLowDuration,paramsiPod.minHighDuration,paramsiPod.fs);
if isempty(LM)
   return; 
end
%% Median must pass lowthreshold
if strcmp(paramsiPod.morphologyCriteria,'on')
    LM = cutLowMedian(RMS,LM,paramsiPod.lowThreshold,paramsiPod.fs);
end
%% Add Duration in 3rd column
LM(:,3)=(LM(:,2)-LM(:,1))/paramsiPod.fs;
%% Add IMI in sec in 4th column
LM(1,4)=9999;
if (size(LM,1)>1)
    LM(2:size(LM,1),4)=(LM(2:size(LM,1),1)-LM(1:size(LM,1)-1,1))/paramsiPod.fs;
end
%% Add Up2Down1 in 6th Column (5th col reserved for PLM)
LM(:,6)=up2Down1(LM(:,1),1);
%% Convert beginning of LMs to mins in 7th Column
LM (:,7) = LM(:,1)/(paramsiPod.fs*60);
%% Record epoch number of LM in 8th Column
LM (:,8) = round (LM (:,7)*2 +0.5);
%% Record breakpoints after long LM in 9th column
LM(:,9)=[1;LM(1:end-1,3)>paramsiPod.maxCLMDuration];
%% Record area of LM in 10th Column 
for i=1:size(LM,1)
    LM(i,10)=sum(RMS(LM(i,1):LM(i,2),1))/paramsiPod.fs;
end

end







%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%getLM Subfunctions
%% Cut low median
function [LM] = cutLowMedian(dsEMG,LM1,min,fs,opt)
%% Remove leg movements whose median activity is less than noise level
% [LM] = cutLowMedian(dsEMG,LM1,min,fs,opt)
%
% cutLowMedian can either remove movements immediately or attempt to find a
% subsection with median above noise.
%
% Inputs: 
%   dsEMG - filtered and rectified EMG signal
%   LM1 - the initial LM array, with at least start and stop times
%   min - the minimum value (noise level) that medians must pass
%   fs - sampling rate
%   opt - (1) moving 1/2 second window (2) shrinking window, starting at
%       the original bounds of the movement(3) immediately discard. If no
%       option is selected, default is (1).
%
% Outputs:
%   LM - the new array with movements that did not pass the median test
%       removed

if ~exist('opt','var')
    opt = 1;
end

% Calculate duration, probably don't need this though
LM1(:,3) = (LM1(:,2) - LM1(:,1))/fs;

% Add column with median values
for i = 1:size(LM1,1)
    LM1(i,4) = median(dsEMG(LM1(i,1):LM1(i,2)));
end

%tic

switch (opt)
case 1
    LM = shrinkWindow(LM1,dsEMG,fs,min);
case 2
    LM = tryShrinking(LM1,dsEMG,fs,min);
case 3
    LM = LM1;
end

%fprintf('It took %.2f seconds to shrink this\n',toc);

% Exclude movements that still are empty
LM = LM(LM(:,4) > min,1:2);
end

% Attempt to reduce the duration of the event in order to find a movement
% that fits minimum density requirement.

function LM1 = tryShrinking(LM1,dsEMG,fs,min)
short = find(LM1(:,4) < min);

med = @(a,b) median(dsEMG(a:b)); % macro to get median

for i = 1:size(short,1)
    
    start = LM1(short(i),1); stop = LM1(short(i),2);
    
    % Continuously reduce the stop time of the movement and check the
    % median again to see if it passes the minimum
    while (stop - start)/fs > 0.6 && med(start,stop) < min
        stop = stop - fs/10;
    end
    
    % Mark the new median in the original array
    LM1(short(i),4) = med(start,stop);
end
end


% A different method of checking for a movement within the movement. This
% searches for any 0.5 second window where the median is above noise level.
function LM = shrinkWindow(LM,dsEMG,fs,min)

empty = find(LM(:,4) < min);

med = @(a,b) median(dsEMG(a:b)); % macro to get median

for i = 1:size(empty,1)
    
    % Record the original start, stop and median
    initstart = LM(empty(i),1);
    initstop = LM(empty(i),2);
    a = med(initstart,initstop);
    
    % Now, the start and stop times that will shift
    start = LM(empty(i),1); stop = start + fs/2;
    
    % Loop through 1/2 second windows of the movement, skipping along at
    % 1/10 second.
    while a < min && stop < initstop;
        a = med(start,stop);
        start = start + fs/10; stop = start + fs/2;
    end
    
    % Mark the new median in the original array
    LM(empty(i),4) = a;
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%findIndices

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