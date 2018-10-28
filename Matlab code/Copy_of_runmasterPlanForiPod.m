%run masterPlanForPLMiPod

%% Load parameters
paramsiPod = inputPLMiPod();
lowThreshold=paramsiPod.LowThreshold;
highThreshold=paramsiPod.HighThreshold;
minLowDuration=paramsiPod.MinLowDuration;
minHighDuration=paramsiPod.MinHighDuration;
minIMIDuration=paramsiPod.MinIMIDuration;
maxIMIDuration=paramsiPod.MaxIMIDuration;
maxLMDuration=paramsiPod.MaxLMDuration;
fs=paramsiPod.SamplingRate;
minNumIMI=paramsiPod.MinNumIMI;
minSleepTime=paramsiPod.minSleepTime;

%% Restless Params
restless_u2d1Factor=paramsiPod.restless_u2d1Factor;
restless_IntervalSize=paramsiPod.restless_IntervalSize;
restless_LMFactor=paramsiPod.restless_LMFactor;
restfulThreshold=paramsiPod.restfulThreshold;
%% Load Files
[fileName,filePath] =uigetfile('*.csv','Select csv data file');
pathToFile = fullfile(filePath,fileName);
[iPodData]=csvread(pathToFile,1,0);

disp('Running program:');
disp(fileName);
disp(['Min IMI Duration = ' num2str(minIMIDuration)]);

RMS=iPodData(:,5);
up2Down1=iPodData(:,6);
startTime=[iPodData(1,7), iPodData(1,8), iPodData(1,9)]*[3600;60;1]*fs;

[PLMiPod]=masterPlanForPLMiPod(RMS,up2Down1,lowThreshold,highThreshold,...
 minLowDuration,minHighDuration,minIMIDuration,maxIMIDuration, ...
 maxLMDuration,fs,minNumIMI,minSleepTime);

%% Restless Measure
[restlessScore,restlessStage] = restlessSleep(up2Down1,restless_IntervalSize,PLMiPod.sleepStart,startTime,PLMiPod.LM,fs,restless_u2d1Factor,restless_LMFactor);
PLMiPod.restlessavg=mean(restlessStage);
PLMiPod.restfulMins=sum(restlessStage<=restfulThreshold)*restless_IntervalSize;
PLMiPod.restlessScore=restlessScore;

%% Plots
% PLMt Markings
plotRMSiPod(RMS,up2Down1,PLMiPod.PLMt,fs,lowThreshold, highThreshold,startTime);
% hold on
% plot(plotTime(1:size(restlessScore),fs,startTime),PLMiPod.restless*5+5)

% Scatter plot
figure
scatter(PLMiPod.CLMS(PLMiPod.CLMS(:,4)<=90& PLMiPod.CLMS(:,3)<=10,3),log(PLMiPod.CLMS(PLMiPod.CLMS(:,4)<=90& PLMiPod.CLMS(:,3)<=10,4)));
xlabel('LM Duration (s)')
ylabel('log IMI')
title('CLMS Duration vs log IMI')

% Histogram
figure
hist(log(PLMiPod.CLMS(PLMiPod.CLMS(:,4)<=90 & PLMiPod.CLMS(:,3)<=10,4)),200)
title('Histogram: log IMI CLMS')




%% Print to file
% Write numerical outputs to a text file
fileID = fopen([ fileName '.txt'],'w');
fprintf(fileID,'PatientID: %s\n',fileName);

fprintf(fileID,'Periodicity Index (Sleep): %.2f\n',PLMiPod.PIsleep);
fprintf(fileID,'PLMWthr: %.2f\n',PLMiPod.PLMWthr);
fprintf(fileID,'PLMSthr: %.2f\n',PLMiPod.PLMSthr);
fprintf(fileID,'PLMthr: %.2f\n',PLMiPod.PLMthr);

fprintf(fileID,'Average PLMStDuration: %.2f\n',PLMiPod.avgPLMStDuration);
fprintf(fileID,'Standard deviation PLMStDuration: %.2f\n',PLMiPod.stdPLMStDuration);

fprintf(fileID,'Average logPLMSIMIt: %.2f\n',PLMiPod.avglogPLMSIMIt);
fprintf(fileID,'Standard deviation logPLMSIMIt: %.2f\n',PLMiPod.stdlogPLMSIMIt);

fprintf(fileID,'Sleep Efficiency: %.2f\n',PLMiPod.sleepEff);
fprintf(fileID,'Total Sleep Time: %.2f\n',PLMiPod.TST);
fprintf(fileID,'Total Rest Time: %.2f\n',PLMiPod.TRT);

fprintf(fileID,'Restful Sleep Time: %.2f\n',PLMiPod.restfulMins);
fprintf(fileID,'Restless Index: %.2f\n',PLMiPod.restlessavg);

fprintf(fileID,'Average WASO Duration: %.2f\n',PLMiPod.WASOavgdur);
fprintf(fileID,'Total WASO Duration: %.2f\n',PLMiPod.WASOdur);
fprintf(fileID,'Number of times WASO: %.2f\n',PLMiPod.WASOnum);


% clearvars -except PLMiPod

