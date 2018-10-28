function plotRestless(restlessScore,fs,startTime)
figure
plot(plotTime(1:size(restlessScore),fs,startTime),restlessScore)
datetick('x','HH:MM:SS')  
zoomAdaptiveDateTicks('on')
end