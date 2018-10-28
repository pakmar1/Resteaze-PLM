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