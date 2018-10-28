%Start time is in datapoints
function plotRMSiPod(RMS,up2Down1,PLMt,fs,lowThreshold, highThreshold,startTime)
addpath 'reduceplot'
figure;
RMSplot = reduce_plot(plotTime(1:size(RMS,1),fs,startTime),RMS,'b');
hold on
ltplot = plot(plotTime([1,size(RMS,1)],fs,startTime),[lowThreshold,lowThreshold],'r:');
htplot = plot(plotTime([1,size(RMS,1)],fs,startTime),[highThreshold,highThreshold],'r:');
u2d1plot = plot(plotTime([1:size(RMS,1)],fs,startTime),up2Down1,'r-');

PLMtplot = plot(plotTime([1,1],fs,startTime),[0,0]); %This is in case there are no PLMt
for i=1:size(PLMt,1)
    PLMtplot = plot(plotTime([PLMt(i,1),PLMt(i,2)],fs,startTime),...
    [highThreshold+0.025,highThreshold+0.025],'g-','LineWidth',3);
end

datetick('x','HH:MM:SS')  
zoomAdaptiveDateTicks('on')
title('PLM Markings')
xlabel('Time of Night')
ylabel('Activity')
legend([RMSplot,ltplot,u2d1plot,PLMtplot],{'RMS Acceleration','Thresholds','Position (Up or Down)','PLMt'})
end

function x=plotTime(x,fs,startTime)
x=x+startTime-1;
x=x/fs/24/3600;
end