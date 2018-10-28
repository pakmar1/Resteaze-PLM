%run masterPlanForPLMiPod

function [] = runmasterPlanForiPod(fileName)
% fileName  = 'amit.csv';
%fprintf('starting');
%% Load parameters
params = {'0.048','0.08','0.5','0.5','10','90','10','20','3','5'};
answer = params;
lowThreshold=str2num(answer{1});
highThreshold=str2num(answer{2});
minLowDuration=str2num(answer{3}); 
minHighDuration=str2num(answer{4});
minIMIDuration=str2num(answer{5});
maxIMIDuration=str2num(answer{6});
maxLMDuration=str2num(answer{7});
fs=str2num(answer{8});
minNumIMI=str2num(answer{9});
minSleepTime=str2num(answer{10});

%% Load parameters
%paramsiPod = inputPLMiPod();
%lowThreshold=paramsiPod.LowThreshold;
%highThreshold=paramsiPod.HighThreshold;
%minLowDuration=paramsiPod.MinLowDuration;
%minHighDuration=paramsiPod.MinHighDuration;
%minIMIDuration=paramsiPod.MinIMIDuration;
%maxIMIDuration=paramsiPod.MaxIMIDuration;
%maxLMDuration=paramsiPod.MaxLMDuration;
%fs=paramsiPod.SamplingRate;
%minNumIMI=paramsiPod.MinNumIMI;
%minSleepTime=paramsiPod.minSleepTime;

%% Restless Params
restless_params = {'1','15','0.5','0.2'};
answer = restless_params;

restless_u2d1Factor=str2num(answer{1});
restless_IntervalSize=str2num(answer{2});
restless_LMFactor=str2num(answer{3});
restfulThreshold=str2num(answer{4});

% restless_u2d1Factor=paramsiPod.restless_u2d1Factor;
% restless_IntervalSize=paramsiPod.restless_IntervalSize;
% restless_LMFactor=paramsiPod.restless_LMFactor;
% restfulThreshold=paramsiPod.restfulThreshold;
%% Load Files
% [fileName,filePath] =uigetfile('*.csv','Select csv data file');
% % % pathToFile = fullfile(filePath,fileName);
% [iPodData]=csvread(pathToFile,1,0);

pathToFile = fileName;
[iPodData]=csvread(pathToFile,1,0);

disp('Running program:');
disp(fileName);
disp(['Min IMI Duration = ' num2str(minIMIDuration)]);

RMS=iPodData(:,5);
up2Down1=iPodData(:,6);
startTime=[iPodData(1,7), iPodData(1,8), iPodData(1,9)]*[3600;60;1]*fs;


%%Amit
startHour = iPodData(1,7);
startMin = iPodData(1,8);
startSec = iPodData(1,9);
up1Down0 = up2Down1'-1; %so we can deal with 1 and 0
%dfr = diff(up1Down0);

firstVal = up1Down0(1);
firstIndex = 1;
lastIndex = 1;
ups = [];
downs = [];
for i = 2:length(up1Down0)
  if up1Down0(i) ~= firstVal
      lastIndex = i - 1; 
      if firstVal==1
          ups = [ups; [firstIndex' lastIndex']];
      else
          downs = [downs; [firstIndex' lastIndex']];
      end
      firstVal = up1Down0(i);
      firstIndex = i;
  else
      lastIndex = i;
  end
end 
%end of the file
if lastIndex==length(up1Down0)
      if firstVal==1
          ups = [ups; [firstIndex' lastIndex']];
      else
          downs = [downs; [firstIndex' lastIndex']];
      end
end
%startHour=iPodData(1,7);
%startMin=iPodData(1,8);
%startSec=iPodData(1,9);

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
% plotRMSiPod(RMS,up2Down1,PLMiPod.PLMt,fs,lowThreshold, highThreshold,startTime);
% % hold on
% % plot(plotTime(1:size(restlessScore),fs,startTime),PLMiPod.restless*5+5)
% 
% % Scatter plot
% figure
% scatter(PLMiPod.CLMS(PLMiPod.CLMS(:,4)<=90& PLMiPod.CLMS(:,3)<=10,3),log(PLMiPod.CLMS(PLMiPod.CLMS(:,4)<=90& PLMiPod.CLMS(:,3)<=10,4)));
% xlabel('LM Duration (s)')
% ylabel('log IMI')
% title('CLMS Duration vs log IMI')
% 
% % Histogram
% figure
% hist(log(PLMiPod.CLMS(PLMiPod.CLMS(:,4)<=90 & PLMiPod.CLMS(:,3)<=10,4)),200)
% title('Histogram: log IMI CLMS')




%% Print to file
% Write numerical outputs to a text file
fileID = fopen('data.txt','w');
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


%%Amitanshu
logPLMSIMI = log(PLMiPod.CLMS(PLMiPod.CLMS(:,4)<=90,4));
start = min(logPLMSIMI);
last = max(logPLMSIMI);
step = (last-start)/200;
edges =  start:step:last;
scaled_edges = exp(edges);
counts = histc(logPLMSIMI, edges);

xvals = ((1+startTime:length(RMS)+startTime)/fs/24/3600);
LMs = (PLMiPod.LM(:,1:2)+startTime)/fs/24/3600;
PLMs = (PLMiPod.PLM(:,1:2)+startTime)/fs/24/3600;
% fprintf(fileID,'Legth of RMS: %.1f\n',length(RMS));

fprintf('writing json file');
try
	fid = fopen('data2.json','wt');  % Note the 'wt' for writing in text mode
	fprintf(fid, '{ \"xVals\":[%f', xvals(1));
	fprintf(fid, ',%f', xvals(2:end));
	fprintf(fid, '],\n\"RMS\":[%f', RMS(1));
	fprintf(fid,',%f',RMS(2:end));  % The format string is applied to each element of a
	fprintf(fid, '],\n\"LM\":[[%f,%f]',LMs(1,1:2));
	fprintf(fid, ',[%f,%f]',LMs(2:end,1:2)');
	fprintf(fid, '],\n\"PLM\":[[%f,%f]',PLMs(1,1:2));
	fprintf(fid, ',[%f,%f]',PLMs(2:end,1:2)');
	fprintf(fid, '],\n\"PLMSIMIcounts\":[%f', counts(1));
	fprintf(fid,',%f',counts(2:end));
	fprintf(fid, '],\n\"PLMSIMIedges\":[%f', scaled_edges(1));
	fprintf(fid, ',%f',scaled_edges(2:end));
	if size(ups,1)>0
		fprintf(fid, '],\n\"ups\":[[%f,%f]',ups(1,1:2));
		if size(ups,1)>1
			fprintf(fid, ',[%f,%f]',ups(2:end,1:2)');
		end
	else
		fprintf(fid, '],\n\"ups\":[[]');
	end
	if size(downs,1)>0  
		fprintf(fid, '],\n\"downs\":[[%f,%f]',downs(1,1:2));
		if size(downs,1)>1
		fprintf(fid, ',[%f,%f]',downs(2:end,1:2)');
		end
	else
        	fprintf(fid, '],\n\"downs\":[[]');
	end

	fprintf(fid, ']}');
	fclose(fid);
catch 
	disp('problem');
	error('unable to create file');	
end
fprintf('finished');



quit
% clearvars -except PLMiPod

