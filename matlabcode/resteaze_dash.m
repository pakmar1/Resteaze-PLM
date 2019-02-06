function output = resteaze_dash(left, right, subjectid)

% Add Paths
addpath subroutines
addpath RestEaze_11_09
addpath 'Calculate Arousal'
addpath 'export_fig'

warning('off','all')
left = convertCharsToStrings(left);
right = convertCharsToStrings(right);

% Check for File exixtence
if exist('left', 'var') && exist(left, 'file') == 2
     % File exists.
     [filepath,name,ext] = fileparts(left);
     leftFileNames = strcat(name, ext);
     leftPath = filepath;
else
     % File does not exist.
     leftFileNames = [];
     leftPath = [];
end

if exist('right', 'var') && exist(right, 'file') == 2
     % File exists.
     [filepath,name,ext] = fileparts(right);
     rightFileNames = strcat(name, ext);
     rightPath = filepath;
else
     % File does not exist.
     rightFileNames = [];
     rightPath= [];
end

% scoring options
params = init_params();

% arrays and stats to output and generate report
output=struct();

%[output.fileName,path]=uigetfile('*.csv');

% TODO: obv make a better file name.
output.fileName=subjectid;

% Should have date in beginning of filename so they are sorted from old->new
if isempty(leftFileNames)
    [leftFileNames,leftPath]=uigetfile('*.csv','LEFT FILES','multiselect','on'); 
    if ~iscell(leftFileNames)
        if size(leftPath,2)==1
            if leftPath==0
                params.side='right';
                disp('Right Leg Only')
            end
        else
            leftFileNames={leftFileNames}; %Inserts single fileName str into array
        end
    end
end


if isempty(rightFileNames)
    [rightFileNames,rightPath]=uigetfile('*.csv','RIGHT FILES','multiselect','on');
    if ~iscell(rightFileNames)
        if size(rightPath,2)==1
            if rightPath==0
                if strcmp(params.side,'both')
                    params.side='left';
                    disp('Left Leg Only')

                elseif strcmp(params.side,'right')
                    error('no data');
                end
            end
        else
            rightFileNames={rightFileNames}; %Inserts single fileName str into array
        end
    end
end


clear nightData

% it appears this will fail if there are not the same number of nights for
% each leg. TODO: make this more safe
for i=1:max([size(leftFileNames,2) size(rightFileNames,2)])
    
    if strcmp(params.side,'both')
        bandData_left=readtable(fullfile(leftPath,leftFileNames{1,i}));
        bandData_right=readtable(fullfile(leftPath,rightFileNames{1,i}));
    elseif    strcmp(params.side,'right')
        bandData_right=readtable(fullfile(rightPath,rightFileNames{1,i}));
        bandData_left=readtable(fullfile(rightPath,rightFileNames{1,i}));
    elseif strcmp(params.side,'left')
        bandData_right=readtable(fullfile(leftPath,leftFileNames{1,i}));
        bandData_left=readtable(fullfile(leftPath,leftFileNames{1,i}));
    else
        error('Which side?')
    end
    leftdata=table2array(bandData_left);
    rightdata=table2array(bandData_right);
    [leftLeg,rightLeg]=synchRE(leftdata,rightdata);
    
    output.up2Down1=ones(size(leftLeg,1),1); %%%%%%%%%%%%%%%%%% ALL DOWN FOR NOW WILL HAVE TO UPDATE LATER

    output.rRMS=rms(rightLeg(:,2:4),2);
    output.lRMS=rms(leftLeg(:,2:4),2);
    
    %factor = 8/32767; % factor for conversion of accelerometer value in terms of g. 
    % the dynamic range is (+/-) 8g and the ADC is 16 bit.
    %output.rRMS=rms(removeAccGrav(rightLeg(:,4:6))*factor,2);
    %output.lRMS=rms(removeAccGrav(leftLeg(:,4:6))*factor,2);
    
    %output.rRMS=rms(rightLeg(:,4:6)*factor,2);
    %output.lRMS=rms(leftLeg(:,4:6)*factor,2);
    
    %% Compute LM:
    % Activity above high threshold, ending when there is continuous 0.5s below low threshold
    rLM=getLMiPod(params,output.rRMS,output.up2Down1);
    lLM=getLMiPod(params,output.lRMS,output.up2Down1);
    
    %% Start Patrick''s standard scoring stuff %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    bCLM = candidate_lms(rLM,lLM,params);
    Arousal=calculateArousal(bCLM,leftLeg,rightLeg);
    output.Arousal=Arousal(Arousal(:,3)==1,:);
   
    bCLM(:,11)=Arousal(:,3);
    [PLM, bCLM] = periodic_lms(bCLM,params);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %% score sleep/wake
    output.wake=scoreSleep(params.fs,output.lRMS,PLM,bCLM);
    [WASO] = calculateWASO_RE(output.wake,params.minSleepTime,params.fs); %%% NEED TO UPDATE OUTPUT MATRICES AFTER HERE
    rLM(:,6)=output.wake(rLM(:,1),1)+1; %still using up2down1 format
    lLM(:,6)=output.wake(lLM(:,1),1)+1; %still using up2down1 format
    bCLM(:,6)=output.wake(bCLM(:,1),1)+1; %still using up2down1 format
    PLM(:,6)=output.wake(PLM(:,1),1)+1; %still using up2down1 format
    
    
    
    
    %% Matrices to output
    output.rLM=rLM;
    output.lLM=lLM;
    
    output.bCLM=bCLM;
    output.PLM=PLM;
    output.PLMS=PLM(PLM(:,6)==1,:);
    
    %% Quantitative measures to output
    output.TRT =(size(output.up2Down1,1)/params.fs)/60; %Total rest time in mins
    output.TST = output.TRT-WASO.dur; %Total sleep time in mins
    output.sleepEff=output.TST/output.TRT;
    output.WASOnum=WASO.num;
    output.WASOdur=WASO.dur;
    output.WASOavgdur=WASO.avgdur;
    output.PI=sum((output.PLMS(:,9)==0)/(size(output.bCLM,1)-1));
    
    output.avglogCLMSIMI=mean(log(bCLM(bCLM(:,6)==1,4)));
    output.stdlogCLMSIMI=std(log(bCLM(bCLM(:,6)==1,4)));
    
    output.avgCLMSDuration=mean(bCLM(bCLM(:,6)==1,3));
    output.stdCLMSDuration=std(bCLM(bCLM(:,6)==1,3));
    
    output.avglogPLMSIMI=mean(log(PLM(PLM(:,6)==1|PLM(:,9)==0,4)));
    output.stdlogPLMSIMI=std(log(PLM(PLM(:,6)==1|PLM(:,9)==0,4)));
    
    output.avgPLMSDuration=mean(PLM(PLM(:,6)==1,3));
    output.stdPLMSDuration=std(PLM(PLM(:,6)==1,3));
    
    output.CLMhr = size(bCLM,1)/(output.TRT/60);
    output.CLMShr = sum(bCLM(:,6)==1)/(output.TST/60);
    output.CLMWhr = sum(bCLM(:,6)==2)/((output.TRT-output.TST)/60);
    
    output.PLMhr = size(PLM,1)/(output.TRT/60);
    output.PLMShr=sum(PLM(:,6)==1)/(output.TST/60);
    output.PLMWhr=sum(PLM(:,6)==2)/((output.TRT-output.TST)/60);
    
    output.CLMnum = size(bCLM,1);
    output.CLMSnum = sum(bCLM(:,6)==1);
    output.CLMWnum = sum(bCLM(:,6)==2);
    
    output.PLMnum = size(PLM,1);
    output.PLMSnum=sum(PLM(:,6)==1);
    output.PLMWnum=sum(PLM(:,6)==2);
    
    output.PLMSArI=sum(output.PLMS(:,11))/(output.TST/60); %num plms arousals per hr of sleep
    
    output.GLM=bCLM(bCLM(:,5)==0,:);
    
    %some more stuff needed for report %%%%%%%%%%%
    output.intervalSize=1;
    output.GLM=bCLM(bCLM(:,5)==0,:);
    output.Arousal=output.Arousal;
    output.fs=params.fs;
    output.pos=2*ones(size(leftLeg,1),1); %%%%%%%%%%%%%%%%%%%%% ALL BACKSIDE RIGHT NOW SINCE NO POS VECTOR YET
    output.ArI=size(output.Arousal,1)/(output.TST/60);
    output.PLMSI=output.PLMShr;
    warning('off','all') %suppress timezonewarning
    leftStart=datevec(datetime(leftLeg(1,4)/1000,'ConvertFrom','PosixTime','TimeZone','EST'));
    warning('on','all')
    output.sleepStart=mod(leftStart(1,4)*60+leftStart(1,5)-12*60,24*60); %% took mod for sleep before noon
    output.sleepEnd=output.sleepStart+output.TRT;
    output.date=[num2str(leftStart(1,2)) '/' num2str(leftStart(1,3)) '/' num2str(mod(leftStart(1,1),100))];
    output.SQ=0;
    output.SQhrs=[];

    nightData(i)=output;
    
end


%Generate report
%not called only used for debugging.
if (false)
    for i=1:ceil(size(nightData,2)/5)
        if (i-1)*5+5<=size(nightData,2)
            [Handles,nightData((i-1)*5+1:(i-1)*5+5)]=generateClinicalReport_RE(nightData((i-1)*5+1:(i-1)*5+5));
            export_fig 'graphs.pdf' -transparent;
            figure_list{1,1} = 'graphs.pdf';

        else
            [Handles,nightData((i-1)*5+1:end)]=generateClinicalReport_RE(nightData((i-1)*5+1:end));
            export_fig 'graphs.pdf' -transparent;
            figure_list{1,1} = 'graphs.pdf';

        end

        %% Combine all figures in list into one pdf
         append_pdfs([output.fileName '.pdf'], figure_list{1,:});
    end
end 

%% Write to text file

for i=1:size(nightData,2)
    fileID = fopen([ output.fileName num2str(i) '.txt'],'w');
    fprintf(fileID,'PatientID: %s\n',output.fileName);
    fprintf('PatientID: %s\n',output.fileName);
    fprintf(fileID,['Record Start: ' sleepText(nightData(i).sleepStart) '\n']);
    fprintf(['Record Start: ' sleepText(nightData(i).sleepStart) '\n']);
    fprintf(fileID,['Record Stop: ' sleepText(nightData(i).sleepEnd) '\n']);
    fprintf(['Record Stop: ' sleepText(nightData(i).sleepEnd) '\n']);
    fprintf(fileID,'Sleep Efficiency: %.2f\n',nightData(i).sleepEff);
    fprintf('Sleep Efficiency: %.2f\n',nightData(i).sleepEff);
    fprintf(fileID,'Total Sleep Time: %.2f\n',nightData(i).TST);
    fprintf('Total Sleep Time: %.2f\n',nightData(i).TST);
    fprintf(fileID,'PLMS/hr: %.2f\n',nightData(i).PLMShr);
    fprintf('PLMS/hr: %.2f\n',nightData(i).PLMShr);
    fprintf(fileID,'Arousals/hr: %.2f\n',nightData(i).ArI);
    fprintf('Arousals/hr: %.2f\n',nightData(i).ArI);
    fprintf(fileID,'Sleep Quality: %.2f\n',nightData(i).SQ);
    fprintf('Sleep Quality: %.2f\n',nightData(i).SQ);
    fprintf(fileID,'WASO: %.2f\n',nightData(i).WASOdur);
    fprintf('WASO: %.2f\n',nightData(i).WASOdur);
    fprintf(fileID,'Sleep_quality_per_hr : ');
    fprintf('Sleep_quality_per_hr : ');
    for ii=1:size(nightData(i).SQhrs,2)
        fprintf(fileID, '%.2f ', nightData(i).SQhrs(1,ii));
        fprintf('%.2f ', nightData(i).SQhrs(1,ii));
    end
    fclose(fileID);

end

end


function params = init_params()
% Initialize default parameters, if we want to allow them to change,
% modify here.
params = struct();

params.iLMbp='on';
params.morphologyCriteria='on';

%% this is for the RestEaZe data.
%params.lowThreshold=0.005;
%params.highThreshold=0.01;
params.lowThreshold=0.05;
params.highThreshold=0.1;


params.minLowDuration=0.5;
params.minHighDuration=0.5;
params.minIMIDuration=10;
params.maxIMIDuration=90;
params.maxCLMDuration=10;

% params.fs=50;
%sampling rate for the RestEaZe data
params.fs=25;

params.minNumIMI=3;
params.minSleepTime=5;
params.maxOverlapLag=0.5;
params.maxbCLMOverlap=4;
params.maxbCLMDuration=15;
params.side='both';

end