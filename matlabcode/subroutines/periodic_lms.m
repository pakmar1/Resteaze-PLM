function [PLM, CLMt] = periodic_lms(CLM,params)
%% PLM = periodic_lms(CLM,params)
%  find periodic leg movements from the array of CLM. Can either ignore
%  intervening LMs or add breakpoints. Contains subfunctions for ignoring
%  iLMs, restructuring breakpoint locations to find PLM runs and marking
%  the CLM which occur in periodic series.

% Create CLMt array of all CLM with IMI greater than the minimum allowable
% if intervening lm option is not selected, we remove CLMs whose IMI are
% too short. Really, new standards say that these should always be
% breakpoint, so the first case is only for posterity.
if ~strcmp(params.iLMbp, 'on')
    CLMt = removeShortIMI(CLM,params.minIMIDuration,params.fs);
else
    CLMt = CLM;
end

CLMt(:,5) = 0; % Restart PLM

BPloct = BPlocAndRunsArray(CLMt,params.minNumIMI);
CLMt = markPLM3(CLMt,BPloct);

PLM = CLMt(CLMt(:,5) == 1,:);
end


function CLMt = removeShortIMI(CLM,minIMIDuration,fs)
%% CLMt = removeShortIMI(CLM,minIMIDuration,fs)
% This function removes CLM with IMI that are too short to be considered
% PLM. This is according to older standards, and hopefully this code will
% not be necessary in the future.

i = 2; % skip the first movement
CLMt = CLM;
while i < size(CLMt,1)
    if CLMt(i,4) >= minIMIDuration
        i = i+1;
    else
        CLMt(i,:) = [];
        CLMt(i,4) = (CLMt(i,1) - CLMt(i-1,1))/fs;
    end
end

end


function BPloc = BPlocAndRunsArray(CLM,minNumIMI)
%% BPloc = BPlocAndRunsArray(CLM,minNumIMI)
%  col 1: Break point location
%  col 2: Number of leg movements
%  col 3: PLM =1, no PLM = 0
%  col 4: #LM if PLM
% This is really only for internal use, nobody wants to look at this BPloc
% array, but it is necessary to get our PLM.

BPloc(:,1)=find(CLM(:,9)); %% BP locations

% Add number of movements until next breakpoint to column 2
BPloc(1:end-1,2) = BPloc(2:end,1) - BPloc(1:end-1,1);
BPloc(end,2) = size(CLM,1) - BPloc(end,1) + 1;

% Mark whether a run of LM meets the minimum requirement for number of IMI
BPloc(:,3) = 0;
BPloc(BPloc(:,2) > minNumIMI,3) = 1;

% Mark the number of movements in each PLM series
BPloc(:,4) = 0;
BPloc(BPloc(:,3) == 1,4) = BPloc(BPloc(:,3) == 1,2);

end

function CLM = markPLM3(CLM,BPloc)
%% CLM = markPLM3(CLM,BPloc,fs)
% places a 1 in column 5 for all movements that are part of a run
% of PLM. Again, used internally, you'll never really need to run this
% independent of periodic_lms.

bpPLM = BPloc(BPloc(:,3) == 1,:);

% can this be done without a for loop?
for i = 1:size(bpPLM,1)
    CLM(bpPLM(i,1):bpPLM(i,1) + bpPLM(i,2) - 1,5) = 1;
end

end
