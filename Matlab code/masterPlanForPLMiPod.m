%%Outputs are stored in data structure PLMiPod
%%Creates LM by finding location of EMG indices (from dsEMG) that meets the low Threshold, high Threshold, minLowDuration, minHighDuration
%%Creates CLM from LM by removing leg movements that are too long
%%Creates PLM from CLM using maximum inter-movement intervals and minRunLength
function [PLMiPod]=masterPlanForPLMiPod(RMS,up2Down1, lowThreshold,highThreshold,...
 minLowDuration,minHighDuration,minIMIDuration,maxIMIDuration,...
 maxLMDuration,fs,minNumIMI,minSleepTime)
%% Matrices
LM  = getLMiPod(RMS,up2Down1,lowThreshold,highThreshold,minLowDuration,minHighDuration,fs);
CLM = getCLMiPod(LM,maxLMDuration,maxIMIDuration,minNumIMI,fs);
PLM = CLM(CLM(:,5)==1,:);
PLMIMI = PLM(PLM(:,4)<=maxIMIDuration,:);

CLMS = CLM(CLM(:,6)== 1,:); %Leg is down
PLMS = PLM(PLM(:,6)==1,:);
PLMW = PLM(PLM(:,6)==2,:);
PLMSIMI = PLMS(PLMS(:,4)<=maxIMIDuration,:);

[PLMt,CLMt] = getPLMtiPod(CLM,minIMIDuration,fs,maxIMIDuration,minNumIMI);

CLMSt = CLMt(CLMt(:,6) ==1,:);
CLMWt = CLMt(CLMt(:,6) ==2,:);

PLMSt = PLMt(PLMt(:,6) ==1,:);
PLMWt = PLMt(PLMt(:,6) ==2,:);
PLMSIMIt = PLMSt(PLMSt(:,4)<=maxIMIDuration,:);

%% Quantitative measures
 [WASO] = calculateWASO(up2Down1,minSleepTime,fs);
 TRT =(size(RMS,1)/fs)/60; %Total rest time in mins
 if ~isnan(WASO.sleepStart)
     TST = sum(up2Down1(WASO.sleepStart:end,1)==1)/fs/60; %Total sleep time in mins
 else
     TST=0;
 end
 
PLMiPod.sleepStart=WASO.sleepStart;
PLMiPod.WASOnum=WASO.num;
PLMiPod.WASOdur=WASO.dur;
PLMiPod.WASOavgdur=WASO.avgdur;  
 
PLMiPod.TRT=TRT;
PLMiPod.TST=TST;
PLMiPod.sleepEff=TST/TRT; %%%%

PLMiPod.avglogPLMSIMIt=mean(log(PLMSIMIt(:,4)));
PLMiPod.stdlogPLMSIMIt=std(log(PLMSIMIt(:,4)));

PLMiPod.avglogPLMSIMI=mean(log(PLMSIMI(:,4)));
PLMiPod.stdlogPLMSIMI=std(log(PLMSIMI(:,4)));

PLMiPod.avgPLMStDuration=mean(PLMSt(:,3));
PLMiPod.stdPLMStDuration=std(PLMSt(:,3));

PLMiPod.PLMthr = size(PLMt,1)/(TRT/60);
PLMiPod.PLMSthr=size(PLMSt,1)/(TST/60); 
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
PLMiPod.CLMS=CLMS;
PLMiPod.PLM = PLM;
PLMiPod.PLMW=PLMW;
PLMiPod.PLMS=PLMS;

PLMiPod.PLMIMI = PLMIMI;

PLMiPod.CLMt=CLMt;
PLMiPod.PLMt = PLMt;
PLMiPod.PLMSt = PLMSt;

PLMiPod.PLMSIMIt = PLMSIMIt;

end