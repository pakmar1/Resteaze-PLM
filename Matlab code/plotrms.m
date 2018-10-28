function plotrms(  )
bandData_left=readtable('Tablet_Left_with_Remlogic_Time.csv');
timeStamps_left=bandData_left.Android_Time/1000;
accel_left=rms(removeAccGrav([bandData_left.Acc_X,bandData_left.Acc_Y,bandData_left.Acc_Z]),2);
xtime=datetime(bandData_left.Android_Time/1000+bandData_left.RemLogic_Relative_Time_sec,'convertfrom','posixtime','TimeZone','EST');
h=plot(xtime,accel_left,'DateTimeTickFormat','HH:mm:ss');
end
function accel=removeAccGrav(accel)
accel=accel/4096;
k = 0.2;
g = zeros(size(accel,1),3);
g(2:end,:) = k * accel(2:end,:) + (1-k) * accel(1:end-1,:);
accel = accel - g;
accel(1,:)=0;
end