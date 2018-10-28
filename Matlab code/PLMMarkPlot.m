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