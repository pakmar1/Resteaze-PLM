function [Handles,nightData]=generateClinicalReport_RE(nightData)
figure
set(gcf,'OuterPosition',[0 0 1.8*700 1.8*500])
if size(nightData,1)>5
    error('selected more than 5 nights'); %%%% could add loop here to deal with this later - do this in REdash
end

%set up avg bar

for i=1:size(nightData,2)
    input=nightData(i);
    
    input.numIntervals = floor(input.TRT/input.intervalSize); % Minutes
    input.shiftX_RETable=input.numIntervals*4/3;
    input.shiftY_RETable=1.5; % put the numbers in the middle
    
    
    input.shiftX_sleepPeriod=-5/419*input.numIntervals;
    input.shiftY_sleepPeriod=1.5; % put the lines in the middle
    
    input.shiftX_restless=-5/419*input.numIntervals;
    input.barHeight_restless=2; % put the numbers in the middle
    
    input.shiftX_PLM=input.numIntervals*1/3;
    input.barHeight_PLM=1; % put the numbers in the middle
    
    numIntervals = floor(input.TRT/input.intervalSize); % Minutes
    intervalSize=input.intervalSize;
    
    subplot(8,1,i)
    hold on
    sleepPeriodPlot(input)
    %Box sleep period
    line([0 36*60]/36/60*numIntervals/3+input.shiftX_sleepPeriod, [3 3],'Color','k','LineWidth',1)
    line([0 36*60]/36/60*numIntervals/3+input.shiftX_sleepPeriod, [0 0],'Color','k','LineWidth',1)
    line([0 0]/36/60*numIntervals/3+input.shiftX_sleepPeriod, [0 3],'Color','k','LineWidth',1)
    line([36*60 36*60]/36/60*numIntervals/3+input.shiftX_sleepPeriod, [0 3],'Color','k','LineWidth',1)
    
    %Middle plots
    [Handles.RestlessMark_Handles]=restlessMark(input);
    input.SQ=sum(Handles.RestlessMark_Handles.restless==0)/size(Handles.RestlessMark_Handles.restless,1);
    nightData(i).SQ=input.SQ;
    
    %calculate sleep quality for every hour using histcounts
    edges=[1:round(60/input.intervalSize):size(Handles.RestlessMark_Handles.restless,1) ]; %edges for beginning of each hr and last one is shorter than an hr
    nightData(i).SQhrs=histcounts(find(Handles.RestlessMark_Handles.restless==0),edges); %count num intervals where they have restful sleep (currently no distinction in this metric between sleep/arousal/restless)
    nightData(i).SQhrs= [nightData(i).SQhrs(1,1:end-1)/60, nightData(i).SQhrs(1,end)/60/(mod(size(Handles.RestlessMark_Handles.restless,1),round(60/input.intervalSize))*intervalSize) ];
    [Handles.PLMMark_Handles]=PLMMarkPlot(input);
    sleepPosPlot(input)
    %Box Middle
    line([0 numIntervals]+input.shiftX_PLM, [3 3],'Color','c','LineWidth',.2)
    line([0 numIntervals]+input.shiftX_PLM, [0 0],'Color','c','LineWidth',.2)
    line([0 0]+input.shiftX_PLM, [0 3],'Color','c','LineWidth',.2)
    line([numIntervals numIntervals]+input.shiftX_PLM, [0 3],'Color','c','LineWidth',.2)
    
    [Handles.Table_Handles]=RETable(input);
    
    xlim([input.shiftX_sleepPeriod,(numIntervals+1)*2])
    ylim([0 3])
    %Axis Label
    emptyTicks=cell(size(numIntervals/3+60/intervalSize:60/intervalSize:numIntervals*4/3-1,2),1);
    emptyTicks(:,1)={' '};
    set(gca,'xtick',[input.shiftX_sleepPeriod numIntervals/9+input.shiftX_sleepPeriod numIntervals*2/9+input.shiftX_sleepPeriod numIntervals/3+input.shiftX_sleepPeriod numIntervals/3 numIntervals/3+60/intervalSize:60/intervalSize:numIntervals*4/3-1 numIntervals*4/3])
    ticklabelarray=cell(6+size(emptyTicks,1),1);
    ticklabelarray(1:4,1)={'12'; '0 '; '12 '; ' '};
    ticklabelarray{5,1}=sleepText(input.sleepStart);
    for ii=6:size(ticklabelarray,1)-2
        ticklabelarray{ii,1}=sleepText(input.sleepStart+60*(ii-5));
    end
    ticklabelarray{end,1}=sleepText(input.sleepEnd);
    set(gca,'xticklabel',ticklabelarray);
    set(gca,'ytick',[])
    set(gca,'yticklabel',[])
    set(gca,'TickDir','out')
    set(gca,'TickLength',[0.005 0.005]);
    %
    set(gca,'XColor','k')
    set(gca,'YColor','k')
    set(gca,'FontSize',8)
end

%% Last row (averages)
avgNightData.date='Average';
avgNightData.sleepStart = mean([nightData.sleepStart]);
avgNightData.sleepEnd = mean([nightData.sleepEnd]);

avgNightData.sleepEff=mean([nightData.sleepEff]);
avgNightData.TST=mean([nightData.TST]);
avgNightData.TRT=mean([nightData.TRT]);
avgNightData.WASOdur=mean([nightData.WASOdur]);
avgNightData.PLMSI=mean([nightData.PLMSI]);
avgNightData.ArI=mean([nightData.ArI]);
avgNightData.PLMSArI=mean([nightData.PLMSArI]);
avgNightData.SQ=mean([nightData.SQ]);

avgNightData.intervalSize=nightData(1).intervalSize;
% avgNightData.numIntervals=nightData(1).numIntervals;

input=avgNightData;
subplot(8,1,6)
hold on


%%%%%%%%%%%%%%%%%%% avg bars


input.numIntervals = floor(input.TRT/input.intervalSize); % Minutes
input.shiftX_RETable=input.numIntervals*4/3;
input.shiftY_RETable=1.5; % put the numbers in the middle


input.shiftX_sleepPeriod=-5/419*input.numIntervals;
input.shiftY_sleepPeriod=1.5; % put the lines in the middle

input.shiftX_restless=-5/419*input.numIntervals;
input.barHeight_restless=2; % put the numbers in the middle

input.shiftX_PLM=input.numIntervals*1/3;
input.barHeight_PLM=1; % put the numbers in the middle

input.numIntervals = floor(input.TRT/input.intervalSize); % Minutes


xlim([input.shiftX_sleepPeriod,(numIntervals+1)*2])
ylim([0 3])
sleepPeriodPlot(input);
%Box sleep periodwh
line([0 36*60]/36/60*numIntervals/3+input.shiftX_sleepPeriod, [3 3],'Color','k','LineWidth',1)
line([0 36*60]/36/60*numIntervals/3+input.shiftX_sleepPeriod, [0 0],'Color','k','LineWidth',1)
line([0 0]/36/60*numIntervals/3+input.shiftX_sleepPeriod, [0 3],'Color','k','LineWidth',1)
line([36*60 36*60]/36/60*numIntervals/3+input.shiftX_sleepPeriod, [0 3],'Color','k','LineWidth',1)
%
[Handles.Table_Handles]=RETable(input);
xlim([input.shiftX_sleepPeriod,(numIntervals+1)*2])

%Axis Label
ylim([0 3])
set(gca,'xtick',[input.shiftX_sleepPeriod, numIntervals/9+input.shiftX_sleepPeriod, numIntervals*2/9+input.shiftX_sleepPeriod, numIntervals/3+input.shiftX_sleepPeriod])
set(gca,'xticklabel',{'12'; '0 '; '12 '; '0 '});
set(gca,'TickDir','out')
set(gca,'TickLength',[0.005 0.005]);
set(gca,'ytick',[])
set(gca,'yticklabel',[])
set(gca,'XColor','k')
set(gca,'YColor','k')
text(-55*numIntervals/419,1.5,input.date)

box on



%Column Labels
subplot(8,1,1)
numIntervals=floor(nightData(1).TRT/nightData(1).intervalSize);
text(numIntervals/10,3.5,'\underline{Sleep Times}', 'FontSize', 9, 'Interpreter', 'latex')
text(numIntervals*1/3+numIntervals/2.5,3.5,'\underline{Sleep Events}', 'FontSize', 9, 'Interpreter', 'latex')
text(numIntervals*4/3+numIntervals*2/3*0.06,3.5,'\underline{SE}', 'FontSize', 8, 'Interpreter', 'latex')
text(numIntervals*4/3+numIntervals*2/3*0.19,3.5,'\underline{TST}', 'FontSize', 8, 'Interpreter', 'latex')
text(numIntervals*4/3+numIntervals*2/3*0.315,3.5,'\underline{WASO}', 'FontSize', 8, 'Interpreter', 'latex')
text(numIntervals*4/3+numIntervals*2/3*0.461,3.5,'\underline{PLMSI}', 'FontSize', 8, 'Interpreter', 'latex')
text(numIntervals*4/3+numIntervals*2/3*0.635,3.5,'\underline{ArI}', 'FontSize', 8, 'Interpreter', 'latex')
text(numIntervals*4/3+numIntervals*2/3*0.725,3.5,'\underline{PLMSArI}', 'FontSize', 8, 'Interpreter', 'latex')
text(numIntervals*4/3+numIntervals*2/3*0.9,3.5,'\underline{SQ}', 'FontSize', 8, 'Interpreter', 'latex')

%Row Labels

%rowLabels={'11/09/16';'1/13/15';'1/14/15';'1/15/15';'1/16/15';'1/17/15';'1/18/15'};
for i=1:size(nightData,2)
    subplot(8,1,i)
    %text(-55*numIntervals/419,1.5,rowLabels{i,1})
    text(-55*numIntervals/419,1.5,nightData(i).date)
end
% subplot(8,1,8)
%    text(-40*nightData(8).numIntervals/419,1.5,'Mean')
%Title
subplot(8,1,1)
text(0,5,nightData(1).fileName, 'FontSize', 15)


%%Label

x=419/1.8/700; %size of label divided by number of pixes on screen = percentage of fig length
y=135/1.8/500;
reportLegend= imread('Label.png');
axes('position',[0.170,0.125,x,y])
image(reportLegend);
axis off

end

function output=sleepText(sleepTime)
sleepHr=mod(floor(sleepTime/60)+12,24) ;
sleepMin=floor(rem(sleepTime,60));
if sleepHr<10
    sleepHr=['0' num2str(sleepHr)];
else
    sleepHr=num2str(sleepHr);
end
if sleepMin<10
    sleepMin=['0' num2str(sleepMin)];
else
    sleepMin=num2str(sleepMin);
end
output=[sleepHr ':' sleepMin];
end

function [PLMMark_Handles]=PLMMarkPlot(input)
PLM=input.PLM;
fs=input.fs;
intervalSize=input.intervalSize;
numIntervals = floor(input.TRT/input.intervalSize); % Minutes
shiftX=input.shiftX_PLM;
barHeight=input.barHeight_PLM;

PLMMarkings=zeros(numIntervals,1);
for i=2:numIntervals+1
    for ii=1:size(PLM,1)
        if PLM(ii,1)>= (i-1)*intervalSize*60*fs && PLM(ii,1)< i*intervalSize*60*fs
            PLMMarkings(i-1,1)=PLMMarkings(i-1,1)+1;
        end
    end
end
PLMMarkings=PLMMarkings/intervalSize; %convert to density

%%Plotting
hold on
h_barPLMBackground=bar(numIntervals/2+shiftX,barHeight,numIntervals);
set(h_barPLMBackground,'edgecolor','w');
set(h_barPLMBackground,'facecolor','w');
for k = find(PLMMarkings)'
    h_barPLM(k) = bar(k+shiftX,barHeight,1);
    set(h_barPLM(k),'edgecolor',[1,max(1-PLMMarkings(k,1)/max(PLMMarkings),0),0]);
    set(h_barPLM(k),'facecolor',[1,max(1-PLMMarkings(k,1)/max(PLMMarkings),0),0]);
end


PLMMark_Handles.barPLM=h_barPLM;
PLMMark_Handles.PLMMarkings=PLMMarkings;
end

function [Table_Handles]=RETable(input)
shiftX_RETable=input.shiftX_RETable;
shiftY_RETable=input.shiftY_RETable;
numIntervals = floor(input.TRT/input.intervalSize); % Minutes
k=.05: .14:1;
Table_Handles(1)=text(k(1)*2*numIntervals/3+shiftX_RETable,0+shiftY_RETable,[num2str(round(input.sleepEff*100,0)) '%']);
Table_Handles(2)=text(k(2)*2*numIntervals/3+shiftX_RETable,0+shiftY_RETable,[num2str(round(input.TST/60,2))]);
Table_Handles(3)=text(k(3)*2*numIntervals/3+shiftX_RETable,0+shiftY_RETable,num2str(round(input.WASOdur/60,2)));
Table_Handles(4)=text(k(4)*2*numIntervals/3+shiftX_RETable,0+shiftY_RETable,num2str(round(input.PLMSI,2)));
Table_Handles(5)=text(k(5)*2*numIntervals/3+shiftX_RETable,0+shiftY_RETable,num2str(round(input.ArI,2)));
Table_Handles(6)=text(k(6)*2*numIntervals/3+shiftX_RETable,0+shiftY_RETable,num2str(round(input.PLMSArI,2))); %%UPDATE
Table_Handles(7)=text(k(7)*2*numIntervals/3+shiftX_RETable,0+shiftY_RETable,[num2str(round(input.SQ*100)) '%']);

end

function [RestlessMark_Handles]=restlessMark(input)
GLM=input.GLM;
Arousal=input.Arousal;
fs=input.fs;
intervalSize=input.intervalSize;
numIntervals = floor(input.TRT/input.intervalSize); % Minutes
shiftX=input.shiftX_PLM;
barHeight=input.barHeight_restless;


WAKE_INTERVAL_SIZE=0.5; %Hardcode
numWakeIntervals=floor(input.TRT/WAKE_INTERVAL_SIZE);

[wake]=input.wake;%scoreSleep(input.fs,input.lRMS,input.PLM,input.bCLM);
wakeIdx=find(wake);

ArousalMarkings=zeros(numIntervals,1);
GLMMarkings=zeros(numIntervals,1);
for i=2:numIntervals+1
    for ii=1:size(GLM,1)
        if GLM(ii,1)>= (i-1)*intervalSize*60*fs && GLM(ii,1)< i*intervalSize*60*fs
            GLMMarkings(i-1,1)=1;
        end
    end
    
    for kk=1:size(Arousal,1)
        if Arousal(kk,1)>= (i-1)*intervalSize*60*fs && Arousal(kk,1)< i*intervalSize*60*fs
            ArousalMarkings(i-1,1)=1;
        end
    end
   
end

WakeMarkings=zeros(numWakeIntervals,1);
for i=2:numWakeIntervals+1
    for kk=1:size(Arousal,1)
        if Arousal(kk,1)>= (i-1)*WAKE_INTERVAL_SIZE*60*fs && Arousal(kk,1)< i*WAKE_INTERVAL_SIZE*60*fs
            WakeMarkings(i-1,1)=WakeMarkings(i-1,1)+Arousal(kk,3);
        end
    end
    for kk=1:size(wakeIdx,1)
       if wakeIdx(kk,1)>= (i-1)*WAKE_INTERVAL_SIZE*60*fs && wakeIdx(kk,1)< i*WAKE_INTERVAL_SIZE*60*fs
            WakeMarkings(i-1,1)=15; %%ie. if 'scoresleep' detects wake, make whole epoch wake
       end
    end
end
WakeMarkings=find(WakeMarkings(:,1)>=15); %15s in 30s interval to be considered wake
WakeMarkings=histcounts(WakeMarkings,1:floor(numWakeIntervals/numIntervals):numWakeIntervals+1)'; 
WakeMarkings=(WakeMarkings>0)+0;
%%Plot
hold on
%RestlessMark_Handles.restful=bar(find(GLMMarkings==0&ArousalMarkings==0&WakeMarkings==0)+shiftX,barHeight*ones(sum(GLMMarkings==0&ArousalMarkings==0&WakeMarkings==0),1),1,'FaceColor','c');
RestlessMark_Handles.restful=bar(numIntervals/2+shiftX,barHeight,numIntervals,'c');
RestlessMark_Handles.GLM=bar(find(GLMMarkings)+shiftX,barHeight*ones(sum(GLMMarkings>0),1),1,'FaceColor',[244,164,96]/255);
RestlessMark_Handles.arousal=bar(find(ArousalMarkings)+shiftX,barHeight*ones(sum(ArousalMarkings>0),1),1,'FaceColor',[139,69,19]/256);%'FaceColor',[55/255 161/255 255/255]);
RestlessMark_Handles.wake=bar(find(WakeMarkings)+shiftX,barHeight*ones(sum(WakeMarkings>0),1),1,'FaceColor','k');

RestlessMark_Handles.restless=GLMMarkings+ArousalMarkings+WakeMarkings;

%Axis Properties
set(RestlessMark_Handles.GLM,'edgecolor',[244,164,96]/255);
set(RestlessMark_Handles.arousal,'edgecolor',[139,69,19]/256);
set(RestlessMark_Handles.wake,'edgecolor','k');
set(RestlessMark_Handles.restful,'edgecolor','c');

% xlim([0,numIntervals+1]*2)
%set(gca,'Color','c');
% set(gca,'xtick',[])
% set(gca,'xticklabel',[])
set(gca,'ytick',[])
set(gca,'yticklabel',[])
%set(gca,'XColor','w')
%set(gca,'YColor','w')
end

function sleepPosPlot(input)
pos=input.pos;
shiftX=input.shiftX_PLM;
intervalSize=input.intervalSize;
numIntervals = floor(input.TRT/input.intervalSize); % Minutes
fs=input.fs;
output=zeros(numIntervals,1);
for i=1:numIntervals
  output(i,1)=[mode(pos((i-1)*intervalSize*fs*60+1:i*intervalSize*fs*60),1)];
end
pos=output;
hold on
% plot(find(pos<4)+input.shiftX_PLM,2+(pos(pos<4,1)-0.5)/3,'k','LineWidth',1.25)
% plot(find(pos==4)+input.shiftX_PLM,2+(pos(pos==4,1)-2.5)/3,'k:','LineWidth',1.25)

 [leftPoshandle]=plotPosition(pos,1,shiftX);
 [backPoshandle]=plotPosition(pos,2,shiftX);
 [rightPoshandle]=plotPosition(pos,3,shiftX);
 [bellyPoshandle]=plotPosition(pos,4,shiftX);
    %
% hold on
% %sleep position plot
% 
% l=pos==1;
% if sum(l)>0
% l(1,1)=0;
% start=find([l(2:end);0]==1&l(1:end)==0)+1;
% stop= find([l(2:end);0]==0&l(1:end)==1);
% plot([start,stop]+shiftX,([1,1]-0.5)/3+2,'k','LineWidth',1)
% end
% 
% m=pos==2;
% if sum(m)>0
% m(1,1)=0;
% start2=find([m(2:end);0]==1&m(1:end)==0)+1;
% stop2= find([m(2:end);0]==0&m(1:end)==1);
% plot([start2,stop2]+shiftX,([2,2]-0.5)/3+2,'k','LineWidth',1)
% end
% 
% n=pos==3;
% if sum(n)>0
% n(1,1)=0;
% start3=find([n(2:end);0]==1&n(1:end)==0)+1;
% stop3= find([n(2:end);0]==0&n(1:end)==1);
% plot([start3,stop3]+shiftX,([3,3]-0.5)/3+2,'k','LineWidth',1)
% end
% 
% o=pos==4;
% if sum(o)>0
% o(1,1)=0;
% start4=find([o(2:end);0]==1&o(1:end)==0)+1;
% stop4= find([o(2:end);0]==0&o(1:end)==1);
% plot([start4,stop4]+shiftX,([2,2]-0.5)/3+2,'k:','LineWidth',1)
% end
% 
for i=1:size(pos,1)-1
    if(pos(i,1)==4 || pos(i,1)==2) && pos(i+1,1)==3
        plot([i i+1]+shiftX, ([2 3]-0.5)/3+2,'k','LineWidth',1);
    elseif (pos(i,1)==4 || pos(i,1)==2) && pos(i+1,1)==1
        plot([i i+1]+shiftX, ([2 1]-0.5)/3+2,'k','LineWidth',1);
    elseif pos(i,1)==3 && (pos(i+1,1)==4 || pos(i+1,1)==2)
        plot([i i+1]+shiftX, ([3 2]-0.5)/3+2,'k','LineWidth',1);
    elseif pos(i,1)==1 && (pos(i+1,1)==4 || pos(i+1,1)==2)
        plot([i i+1]+shiftX, ([1 2]-0.5)/3+2,'k','LineWidth',1);
    elseif pos(i,1)==1 && pos(i+1,1)==3
        plot([i i+1]+shiftX, ([1 3]-0.5)/3+2,'k','LineWidth',1);
    elseif pos(i,1)==3 && pos(i+1,1)==1
        plot([i i+1]+shiftX, ([3 1]-0.5)/3+2,'k','LineWidth',1);
    end
    hold on
end

    function [plotHandle]=plotPosition(pos,positionNum,shiftX)
        
        runs=pos==positionNum;
        if sum(runs)>0
            runs(1,1)=0;
            startstop(:,1)=find(([runs(2:end);0]==1)&(runs(1:end)==0))+1;
            startstop(:,2)= find([runs(2:end);0]==0&runs(1:end)==1);
            if positionNum~=4
                for ii=1:size(startstop,1)
                    plotHandle(ii)=plot([startstop(ii,1),startstop(ii,2)]...
                        +shiftX,([positionNum,positionNum]-0.5)/3+2,'k',...
                        'LineWidth',1.25);
                end
            else
                for ii=1:size(startstop,1)
                    plotHandle(ii)=plot([startstop(ii,1),...
                        startstop(ii,2)]+shiftX,([2,2]-0.5)/3+2,'k:',...
                        'LineWidth',1.25);
                end
            end
        else
            plotHandle=0;
        end
        
        
    end
end
