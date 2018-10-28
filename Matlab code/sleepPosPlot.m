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

end
function [plotHandle]=plotPosition(pos,positionNum,shiftX)

  runs=pos==positionNum;
 if sum(runs)>0
     runs(1,1)=0;
     startstop(:,1)=find(([runs(2:end);0]==1)&(runs(1:end)==0))+1;
     startstop(:,2)= find([runs(2:end);0]==0&runs(1:end)==1);
     if positionNum~=4
     for i=1:size(startstop,1)
         plotHandle(i)=plot([startstop(i,1),startstop(i,2)]+shiftX,([positionNum,positionNum]-0.5)/3+2,'k','LineWidth',1.25);
     end
     else
         for i=1:size(startstop,1)
         plotHandle(i)=plot([startstop(i,1),startstop(i,2)]+shiftX,([2,2]-0.5)/3+2,'k:','LineWidth',1.25);
     end
     end
 else
     plotHandle=0;
 end
 

end