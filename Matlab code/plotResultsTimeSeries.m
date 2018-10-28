p6Limit = 20000;
p7Limit = 26000;
p8Limit = 20000;
p9Limit = 30000;
p6Time = '2015-11-08 21:50:51';
p7Time = '2015-11-18 21:39:00';
p8Time = '2015-11-21 21:37:04';
p9Time = '2015-11-25 21:30:31';

dontcheckForArousalLM = false;
patientIDs = [7];
endLimit = p7Limit;
pTime = p7Time;
percentVal = 0.39;

t1 = datetime(pTime);

finalLMArousalArr = [];
finalArousalLMArr = [];
All_Arousal_Indexes = [];
PatientText = 'All Patients:: ';
CLM_OR_PLM = [];
for i=1:length(patientIDs)
    patientID = patientIDs(i);
    filename = strcat('P',num2str(patientID),'final.mat');
    data = load(filename);
    final_s = data.final_s;
    offset=100;
    finalCLMArousalArr = final_s.CLM_with_Arousal;
    finalArousalCLMArr = final_s.Arousal_with_CLM;

    finalPLMArousalArr = final_s.PLM_with_Arousal;
    finalArousalPLMArr = final_s.Arousal_with_PLM;

    finalALL_LMArousalArr = final_s.ALL_LM_with_Arousal;
    finalArousal_ALL_LMArr = final_s.Arousal_with_ALL_LM;
    
    
    % TO BE CHANGED
    LM_Val = 'All LM';
    finalLMArousalArr = [finalLMArousalArr;finalCLMArousalArr];
%     finalArousalLMArr = [finalArousalLMArr;finalArousalCLMArr];
    
    finalLMArousalArr = [finalLMArousalArr;finalPLMArousalArr];
    finalArousalLMArr = [finalArousalLMArr;finalArousal_ALL_LMArr];
    for k=1:length(finalCLMArousalArr(:,[1]))
        CLM_OR_PLM = [CLM_OR_PLM;0];
    end
    for k=1:length(finalPLMArousalArr(:,[1]))
        CLM_OR_PLM = [CLM_OR_PLM;1];
    end
end

%% Logistic Regression
countLMRelatedtoArousal = 0;
countLMNotRelatedtoArousal = 0;
All_Arousal_Indexes = isnan(finalLMArousalArr(:,[8]));
for i=1:length(All_Arousal_Indexes)
	if All_Arousal_Indexes(i)==0
        All_Arousal_Indexes(i) = 1;
        countLMRelatedtoArousal = countLMRelatedtoArousal+1;
    else
        All_Arousal_Indexes(i) = 0;
        countLMNotRelatedtoArousal = countLMNotRelatedtoArousal+1;
	end
end
disp('Percentage of LM related to Arousals:')
disp((countLMRelatedtoArousal/length(All_Arousal_Indexes))*100)
sp = categorical(All_Arousal_Indexes);

% All Three - Max Activtiy, AUC and Duration
resultArr = [];
StartLM = finalLMArousalArr(:,[1]);
EndLM = finalLMArousalArr(:,[2]);
DurationArr= finalLMArousalArr(:,[3]);
AUCArr= finalLMArousalArr(:,[4]);
MAXActivityArr= finalLMArousalArr(:,[5]);
GYRORMS_AUCArr= finalLMArousalArr(:,[16]);
GYRORMS_MAXActivityArr= finalLMArousalArr(:,[17]);
GYROX_AUCArr= finalLMArousalArr(:,[18]);
GYROX_MAXActivityArr= finalLMArousalArr(:,[19]);
GYROY_AUCArr= finalLMArousalArr(:,[20]);
GYROY_MAXActivityArr= finalLMArousalArr(:,[21]);
GYROZ_AUCArr= finalLMArousalArr(:,[22]);
GYROZ_MAXActivityArr= finalLMArousalArr(:,[23]);

CAP1_AUCArr= finalLMArousalArr(:,[28]);
CAP1_MAXActivityArr= finalLMArousalArr(:,[29]);
CAP2_AUCArr= finalLMArousalArr(:,[30]);
CAP2_MAXActivityArr= finalLMArousalArr(:,[31]);
CAP3_AUCArr= finalLMArousalArr(:,[32]);
CAP3_MAXActivityArr= finalLMArousalArr(:,[33]);

ACC_STD_Arr= finalLMArousalArr(:,[34]);
GYRO_STD_Arr= finalLMArousalArr(:,[35]);
CAP1_STD_Arr= finalLMArousalArr(:,[36]);
CAP2_STD_Arr= finalLMArousalArr(:,[37]);
CAP3_STD_Arr= finalLMArousalArr(:,[38]);

myTable = table(DurationArr,AUCArr,MAXActivityArr,GYRORMS_AUCArr,GYRORMS_MAXActivityArr,GYROX_AUCArr,GYROX_MAXActivityArr,GYROY_AUCArr,GYROY_MAXActivityArr,GYROZ_AUCArr,GYROZ_MAXActivityArr,ACC_STD_Arr,GYRO_STD_Arr,CAP1_STD_Arr,CAP2_STD_Arr,CAP3_STD_Arr,CLM_OR_PLM, sp);

sum =0;
acc_val = 0;
count=0;

positiveProb = [];
negativeProb = [];
Start_LM_With_Arousal_Tags = [];
End_LM_With_Arousal_Tags = [];
for i=1:length(DurationArr)
    val = LRplot(DurationArr(i),AUCArr(i),MAXActivityArr(i),GYRORMS_AUCArr(i),GYRORMS_MAXActivityArr(i),GYROX_AUCArr(i),GYROX_MAXActivityArr(i),GYROY_AUCArr(i),GYROY_MAXActivityArr(i),GYROZ_AUCArr(i),GYROZ_MAXActivityArr(i),ACC_STD_Arr(i),GYRO_STD_Arr(i),CAP1_STD_Arr(i),CAP2_STD_Arr(i),CAP3_STD_Arr(i),CLM_OR_PLM(i));
    resultArr = [resultArr;val];
    if sp(i)=='true'
    	count=count+1;
        positiveProb = [positiveProb;val];
    else
        negativeProb = [negativeProb;val];
    end
    if val>=percentVal
        Start_LM_With_Arousal_Tags = [Start_LM_With_Arousal_Tags;StartLM(i)];
        End_LM_With_Arousal_Tags = [End_LM_With_Arousal_Tags;EndLM(i)];
        if sp(i)=='true'
           acc_val = acc_val+1; 
        end
        sum = sum+1;
    end
end
disp('Total Predicted Value')
disp(sum)

disp('Total Correct Value')
disp(acc_val)
% figure
% plot(positiveProb,'o')
% hold on
% plot(negativeProb,'o')
% legend('true','false')
% view(-90,90)
% set(gca,'ydir','reverse')
% hold on
% title(PatientText)
% ylabel('Threshold')
% hold off

disp('Percentage arousals correctly identified in the classification: ')
disp(acc_val/sum * 100)
disp('True Positive Rate: ')
disp(acc_val/count * 100)
disp('False Positive Rate: ')
disp((sum-acc_val)/countLMNotRelatedtoArousal * 100)



% get Arousal without LM- AUC and Alpha Sum
All_AROUSAL_Start_Values = finalArousalLMArr(:,[1]);
All_AROUSAL_End_Values = finalArousalLMArr(:,[2]);
Actual_Arousal_Start_Val = [];
Actual_Arousal_End_Val = [];
All_LM_Indexes = isnan(finalArousalLMArr(:,[8]));
for i=1:length(All_LM_Indexes)
	if dontcheckForArousalLM==true
        Actual_Arousal_Start_Val = [Actual_Arousal_Start_Val;All_AROUSAL_Start_Values(i)];
        Actual_Arousal_End_Val = [Actual_Arousal_End_Val;All_AROUSAL_End_Values(i)];
    elseif All_LM_Indexes(i)==0
        Actual_Arousal_Start_Val = [Actual_Arousal_Start_Val;All_AROUSAL_Start_Values(i)];
        Actual_Arousal_End_Val = [Actual_Arousal_End_Val;All_AROUSAL_End_Values(i)];
    end
end
% Prediction accuracy Actual Arousal
totalCount = length(Actual_Arousal_Start_Val);
predictedCount = 0;
for i=1:length(Actual_Arousal_Start_Val)
    count = 0;
    start = Actual_Arousal_Start_Val(i);
    endVal = Actual_Arousal_End_Val(i);
    for j=1:length(Start_LM_With_Arousal_Tags)
        LMstart = Start_LM_With_Arousal_Tags(j);
        LMendVal = End_LM_With_Arousal_Tags(j);
        if start<LMstart && endVal>LMendVal
            count = 1;
            break;
        elseif LMstart<start && LMendVal>start
            count = 1;
            break;
        elseif LMstart<endVal && LMendVal>endVal
            count = 1;
            break;
        elseif  LMstart<start && endVal<LMendVal
            count = 1;
            break;
        end
    end
    if count==1
        predictedCount = predictedCount+1;
    end
end
disp('Total arousal with leg movements')
disp(totalCount)
disp('Predicted arousal with leg movements')
disp(predictedCount)
disp('percentage')
disp(predictedCount/totalCount*100)

% Prediction accuracy Actual Arousal
totalCount = length(Start_LM_With_Arousal_Tags);
falsePositiveCount = 0;
for i=1:length(Start_LM_With_Arousal_Tags)
    count = 0;
    start = Start_LM_With_Arousal_Tags(i);
    endVal = End_LM_With_Arousal_Tags(i);
    for j=1:length(Actual_Arousal_Start_Val)
        LMstart = Actual_Arousal_Start_Val(j);
        LMendVal = Actual_Arousal_End_Val(j);
        if start<LMstart && endVal>LMendVal
            count = 1;
            break;
        elseif LMstart<start && LMendVal>start
            count = 1;
            break;
        elseif LMstart<endVal && LMendVal>endVal
            count = 1;
            break;
        elseif  LMstart<start && endVal<LMendVal
            count = 1;
            break;
        end
    end
    if count==0
        falsePositiveCount = falsePositiveCount+1;
    end
end
disp('Total predicted arousal')
disp(totalCount)
disp('No Arousal')
disp(falsePositiveCount)
disp('percentage')
disp(falsePositiveCount/totalCount*100)


ActualArousalPLot = [];
ActualSleepPLot = [];
PredictedArousalPLot = [];
PredictedSleepPLot = [];
for i =1:endLimit
    disp(i)
    PredictedArousalPLot = [PredictedArousalPLot;0];
    ActualArousalPLot = [ActualArousalPLot;0];
    
    PredictedSleepPLot = [PredictedSleepPLot;1];
    ActualSleepPLot = [ActualSleepPLot;1];
end
% Predicted Arousal
for i=1:length(Start_LM_With_Arousal_Tags)
    start = round(Start_LM_With_Arousal_Tags(i)/50);
    endVal = round(End_LM_With_Arousal_Tags(i)/50);
    for j=start:endVal
        disp(length(PredictedArousalPLot))
        if j<=length(PredictedArousalPLot)
            PredictedArousalPLot(j) = 2;
            PredictedSleepPLot(j) = 0;
        end
    end
end

% Actual Arousal
for i=1:length(Actual_Arousal_Start_Val)
    start = round(Actual_Arousal_Start_Val(i)/50);
    endVal = round(Actual_Arousal_End_Val(i)/50);
    for j=start:endVal
        if j<=length(ActualArousalPLot)
            ActualArousalPLot(j) = 2;
            ActualSleepPLot(j) = 0;
        end
    end
end



% plotSleepData(ActualArousalPLot,'sleepdata1.fig',1);
% figure
% bar(ActualArousalPLot)
% title('Actual Arousal')
% figure
% bar(PredictedArousalPLot)
% title('Predicted Arousal')
t2 = t1 + seconds(1:endLimit/10:endLimit);
DateString = datestr(t2,'HH:MM');
NumTicks = 10;

figure
subplot(2,1,1) 
h = bar(ActualArousalPLot,'r');
L = get(gca,'XLim');
set(gca,'XTick',linspace(L(1),L(2),NumTicks))
set(gca,'XTickLabel',DateString)
set(gca,'YTick',[])
% set(h,'FaceColor',[255/255 39/255 101/255],'EdgeColor',[255/255 39/255 101/255]);
hold on

set(gca,'fontsize',18);
hold on

% h = bar(ActualSleepPLot);
% set(h,'FaceColor',[0 204/255 205/255],'EdgeColor',[0 204/255 205/255]);
title('Patient 4: Actual Arousal asociated with LM')
hold off

subplot(2,1,2)
h=bar(PredictedArousalPLot,'r');
L = get(gca,'XLim');
set(gca,'XTick',linspace(L(1),L(2),NumTicks))
set(gca,'XTickLabel',DateString)
set(gca,'YTick',[])
% set(h,'FaceColor',[255/255 39/255 101/255],'EdgeColor',[255/255 39/255 101/255]);
hold on

set(gca,'fontsize',18);
hold on
% h=bar(PredictedSleepPLot);
% set(h,'FaceColor',[0 204/255 205/255],'EdgeColor',[0 204/255 205/255]);
title('Patient 4: Predicted Arousal')
hold off

clearvars
