function [PLMiPod] = COMBOmasterPlanForPLMiPod(rRMS, rlowThreshold,rhighThreshold,...
 lRMS, llowThreshold,lhighThreshold,...
 minLowDuration,minHighDuration,minIMIDuration,maxIMIDuration,...
 maxLMDuration,fs,minNumIMI,minSleepTime,up2Down1)
rLM = getLMiPod(rRMS,up2Down1,rlowThreshold,rhighThreshold,minLowDuration,minHighDuration,fs);
lLM = getLMiPod(lRMS,up2Down1,llowThreshold,lhighThreshold,minLowDuration,minHighDuration,fs);

%% Mark long LM with breakpoints before combining
rLM(:,9)=rLM(:,3)>maxLMDuration|[1;rLM(1:end-1,3)>maxLMDuration];
lLM(:,9)=lLM(:,3)>maxLMDuration|[1;lLM(1:end-1,3)>maxLMDuration];

%% Median must pass lowthreshold
rLM = cutLowMedian(rRMS,rLM,rlowThreshold,fs);
lLM = cutLowMedian(lRMS,lLM,llowThreshold,fs);
%% Combine left and right and sort.
rLM(:,13) = 1; lLM(:,13) = 2;
combLM = [rLM;lLM];
combLM = sortrows(combLM,1);
LM = removeOverlap(combLM,fs);

if (~isempty(LM))

%% Add Duration in 3rd column
LM(:,3)=(LM(:,2)-LM(:,1))/fs;
%% Add IMI in sec in 4th column
LM(1,4)=9999;
if (size(LM,1)>1)
    LM(2:size(LM,1),4)=(LM(2:size(LM,1),1)-LM(1:size(LM,1)-1,1))/fs;
end
%% Add Up2Down1 in 6th Column (5th col reserved for PLM)
LM(:,6)=up2Down1(LM(:,1),1);
%% Convert beginning of LMs to mins in 7th Column
LM (:,7) = LM(:,1)/(fs*60);
%% Record epoch number of LM in 8th Column
LM (:,8) = round (LM (:,7)*2 +0.5);
%% Record area of LM in 10th Column (9th Col reserved for breakpoints in PLM series)
RMS=(rRMS+lRMS)/2;
for i=1:size(LM,1)
    LM(i,10)=sum(RMS(LM(i,1):LM(i,2),1))/fs;
end

end
%% In COMBO, CLM indices are same as LM b/c long LM are kept
CLM=LM;
CLM(:,9)=CLM(:,4)>maxIMIDuration |CLM(:,9);
%% Mark PLM in 5th Col
runStart=find(CLM(:,9)==1);
runLength=[runStart(2:end,1)-runStart(1:end-1,1);size(CLM,1)-runStart(end,1)+1]; %Assumes next break point is immediately after the last row
PLMrunLength=runLength(runLength(:,1)>minNumIMI);
PLMrunStart=runStart(runLength(:,1)>minNumIMI);
for i=1:size(PLMrunStart,1)
    for ii=1:PLMrunLength(i,1)
        CLM(PLMrunStart(i,1)+ii-1,5)=1;
    end
end
%% Create PLMS, CLMS
PLM = CLM(CLM(:,5)==1,:);
PLMIMI = PLM(PLM(:,4)<=maxIMIDuration,:);

CLMS = CLM(CLM(:,6)== 1,:); %Leg is down
PLMS = PLM(PLM(:,6)==1,:);
PLMW = PLM(PLM(:,6)==2,:);
PLMSIMI = PLMS(PLMS(:,4)<=maxIMIDuration,:);

%% Make PLMt,CLMt (can't use getPLMtiPod b/c long LM are allowed here)
CLMt = removeShortIMI(CLM,minIMIDuration); 
%Recalculate IMI
CLMt(1,4)=9999;
if (size(CLMt,1)>1)
    CLMt(2:size(CLMt,1),4)=(CLMt(2:size(CLMt,1),1)-CLMt(1:size(CLMt,1)-1,1))/fs;
end
%Mark PLM in 5th Col
CLMt(:,5) = 0; % Restart PLM
runStart=find(CLMt(:,9)==1);
runLength=[runStart(2:end,1)-runStart(1:end-1,1);size(CLMt,1)-runStart(end,1)+1]; %Assumes next break point is immediately after the last row
PLMrunLength=runLength(runLength(:,1)>minNumIMI);
PLMrunStart=runStart(runLength(:,1)>minNumIMI);
for i=1:size(PLMrunStart,1)
    for ii=1:PLMrunLength(i,1)
        CLMt(PLMrunStart(i,1)+ii-1,5)=1;
    end
end

%Extract PLMt from CLMt
PLMt = CLMt(CLMt(:,5) == 1,:);

CLMSt = CLMt(CLMt(:,6) ==1,:);
CLMWt = CLMt(CLMt(:,6) ==2,:);

PLMSt = PLMt(PLMt(:,6) ==1,:);
PLMWt = PLMt(PLMt(:,6) ==2,:);
PLMSIMIt = PLMSt(PLMSt(:,4)<=maxIMIDuration,:);

%% Quantitative measures

[WASO] = calculateWASO(up2Down1,minSleepTime,fs);
TRT =(size(RMS,1)/fs)/60; %Total rest time in mins
TST = sum(up2Down1(WASO.sleepStart:end,1)==1)/fs/60; %Total sleep time in mins

PLMiPod.sleepStart=WASO.sleepStart;
PLMiPod.WASOnum=WASO.num;
PLMiPod.WASOdur=WASO.dur;
PLMiPod.WASOavgdur=WASO.avgdur;

PLMiPod.TRT=TRT;
PLMiPod.TST=TST;
PLMiPod.sleepEff=TST/TRT; %%%%

PLMiPod.PLMSthr=size(PLMSt,1)/(TST/60); 
PLMiPod.avglogPLMSIMIt=mean(log(PLMSIMIt(:,4)));
PLMiPod.stdlogPLMSIMIt=std(log(PLMSIMIt(:,4)));

PLMiPod.avglogPLMSIMI=mean(log(PLMSIMI(:,4)));
PLMiPod.stdlogPLMSIMI=std(log(PLMSIMI(:,4)));

PLMiPod.avgPLMStDuration=mean(PLMSt(:,3));
PLMiPod.stdPLMStDuration=std(PLMSt(:,3));

PLMiPod.PLMhr = size(PLM,1)/(TRT/60);
PLMiPod.PLMShr=size(PLMS,1)/(TST/60); 
PLMiPod.PLMWhr=size(PLMW,1)/((TRT-TST)/60);
PLMiPod.PLMWthr=size(PLMWt,1)/((TRT-TST)/60);
try
PLMiPod.PIsleep = calculatePI(CLMSt);
PLMiPod.PIwake = calculatePI(CLMWt);
catch
    disp('Periodicity Index could not be calculated');
end
%% Which matrices to include in output structure
PLMiPod.LM = LM;
PLMiPod.CLM = CLM;
PLMiPod.PLM = PLM;
PLMiPod.PLMt = PLMt;
PLMiPod.PLMIMI = PLMIMI;
PLMiPod.PLMSt = PLMSt;

PLMiPod.CLMt=CLMt;
PLMiPod.PLMW=PLMW;
PLMiPod.PLMS=PLMS;
PLMiPod.CLMS=CLMS;
end