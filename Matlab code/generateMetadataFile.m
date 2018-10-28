%% Load tag files and write to metadata file: Sample Number, PLM - 0|1, Sleep Position - Dummy, Arousal 0|1, GLM - 0|1, Up Down - 2|1
function [ ] = generateMetadataFile(A,SampleSize,patientID)

% readFile = true;
percentVal = 0.45;
patientDir = strcat(patientID,'_Trimmed/');
bandFile = strcat(patientDir,patientID,'.csv.bandTrim.txt');
metaDataFile = strcat(patientDir,'metadata.csv');% csv file with Capacitance, Accelerometer, Gyroscope values


filename = strcat(patientID,'final.mat');
data = load(filename);
final_s = data.final_s;
finalCLMArousalArr = final_s.CLM_with_Arousal;
finalArousalCLMArr = final_s.Arousal_with_CLM;

finalPLMArousalArr = final_s.PLM_with_Arousal;
finalArousalPLMArr = final_s.Arousal_with_PLM;

finalALL_LMArousalArr = final_s.ALL_LM_with_Arousal;
finalArousal_ALL_LMArr = final_s.Arousal_with_ALL_LM;

LM_Val = 'ALL LM';
finalLMArousalArr = finalALL_LMArousalArr;
finalArousalLMArr = finalArousal_ALL_LMArr;

CLM_OR_PLM = [];
for k=1:length(finalCLMArousalArr(:,[1]))
    CLM_OR_PLM = [CLM_OR_PLM;0];
end
for k=1:length(finalPLMArousalArr(:,[1]))
	CLM_OR_PLM = [CLM_OR_PLM;1];
end

% if readFile == true
%     A = tblread(bandFile,'\t');
%     SampleSize = size(A,1);
% end
PLM = zeros(SampleSize,1);
GLM = zeros(SampleSize,1); 
Sleep_Position = zeros(SampleSize,1);
Up2Down1 = ones(SampleSize,1);
Arousal = zeros(SampleSize,1);

Sample_Number = 1:SampleSize;
Sample_Number = Sample_Number';
    
%% Create an Array for PLM - 0 or 1
PLMStartIndex = finalPLMArousalArr(:,1);
PLMEndIndex = finalPLMArousalArr(:,2);

for i=1:length(PLMStartIndex)
    startIndex = PLMStartIndex(i);
    endIndex = PLMEndIndex(i);
    for j=startIndex:endIndex
        PLM(j) = 1;
    end
end



%% Create an array for GLM - 0 or 1
GLMStartIndex = finalCLMArousalArr(:,1);
GLMEndIndex = finalCLMArousalArr(:,2);

for i=1:length(GLMStartIndex)
    startIndex = GLMStartIndex(i);
    endIndex = GLMStartIndex(i);
    for j=startIndex:endIndex
        GLM(j) = 1;
    end
end


%% Create an array for Sleep Position - Dummy Poisiton
% Write the logic to access the sleep position and change it


%% Create an array for Up/Down - Up 2, Down 1
% Write the logic to access the Up/Down and change it


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
    if val>=percentVal
        Start_LM_With_Arousal_Tags = [Start_LM_With_Arousal_Tags;StartLM(i)];
        End_LM_With_Arousal_Tags = [End_LM_With_Arousal_Tags;EndLM(i)];
    end
end


% Arousal Array - update it

for i=1:length(Start_LM_With_Arousal_Tags)
    startIndex = Start_LM_With_Arousal_Tags(i);
    endIndex = End_LM_With_Arousal_Tags(i);
    for j=startIndex:endIndex
        Arousal(j) = 1;
    end
end

METADATA_TABLE = table(Sample_Number,Arousal,PLM,GLM,Sleep_Position,Up2Down1);
writetable(METADATA_TABLE,metaDataFile)
end
