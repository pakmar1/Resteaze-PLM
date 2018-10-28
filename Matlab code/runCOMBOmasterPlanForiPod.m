%% Load parameters
paramsiPod = COMBOinputPLMiPod();
llowThreshold=paramsiPod.lLowThreshold;
lhighThreshold=paramsiPod.lHighThreshold;
rlowThreshold=paramsiPod.rLowThreshold;
rhighThreshold=paramsiPod.rHighThreshold;
minLowDuration=paramsiPod.MinLowDuration;
minHighDuration=paramsiPod.MinHighDuration;
minIMIDuration=paramsiPod.MinIMIDuration;
maxIMIDuration=paramsiPod.MaxIMIDuration;
maxLMDuration=paramsiPod.MaxLMDuration;
fs=paramsiPod.SamplingRate;
minNumIMI=paramsiPod.MinNumIMI;
minSleepTime=paramsiPod.minSleepTime;

%% Load left leg file
[fileName,filePath] =uigetfile('*.csv','Select LEFT csv data file');
pathToFile = fullfile(filePath,fileName);
[liPodData]=csvread(pathToFile,1,0);
%% Load right leg file
[fileName,filePath] =uigetfile('*.csv','Select RIGHT csv data file');
pathToFile = fullfile(filePath,fileName);
[riPodData]=csvread(pathToFile,1,0);
disp('Running program:');
disp(fileName);
disp(['Min IMI Duration = ' num2str(minIMIDuration)]);

%%Synch Start time
[liPodData,riPodData]=synch(liPodData,riPodData);

lRMS=liPodData(:,5);
lup2Down1=liPodData(:,6);
rRMS=riPodData(:,5);
rup2Down1=riPodData(:,6);
startTime=[riPodData(1,7), riPodData(1,8), riPodData(1,9)]*[3600;60;1]*fs;

%% Merge up2Down1: if 1 leg is up then both are up
up2Down1=max(rup2Down1,lup2Down1);

%% Run COMBOmasterplan
[PLMiPod] = COMBOmasterPlanForPLMiPod(rRMS, rlowThreshold,rhighThreshold,...
 lRMS, llowThreshold,lhighThreshold,...
 minLowDuration,minHighDuration,minIMIDuration,maxIMIDuration,...
 maxLMDuration,fs,minNumIMI,minSleepTime,up2Down1);

%% Plots
% PLMt Markings
plotRMSiPod((rRMS+lRMS)/2,up2Down1,PLMiPod.PLMt,fs,llowThreshold, lhighThreshold,startTime);

% Scatter plot
figure
scatter(PLMiPod.CLMS(PLMiPod.CLMS(:,4)<=90,3),log(PLMiPod.CLMS(PLMiPod.CLMS(:,4)<=90,4)));
xlabel('LM Duration (s)')
ylabel('log IMI')
title('CLMS Duration vs log IMI')

% Histogram
figure
hist(log(PLMiPod.CLMS(PLMiPod.CLMS(:,4)<=90,4)),200)
title('Histogram: log IMI CLMS')


% clearvars -except PLMiPod
