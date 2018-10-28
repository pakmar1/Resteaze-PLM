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
    %sleepPosPlot(input)
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