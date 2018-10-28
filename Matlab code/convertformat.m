function [ Y ] = convertformat(X)
%takes file in iPod format and converts it to format that the new script
%can take as input

%% counter ID
Y(:,1) = X(:,1);
Y(:,2) = 0;
%timestamp in milliseconds
Y(:,3) = 0;
Y(:,4) = X(:,10)*1000;
Y(:,5) = 0;
Y(:,6) = 0;
Y(:,7) = 0;
%% accelerometer data
Y(:,8) = X(:,2);
Y(:,9) = X(:,3);
Y(:,10) = X(:,4);
%% gyroscope data
Y(:,11) = X(:,11);
Y(:,12) = X(:,12);
Y(:,13) = X(:,13);
%% magnetometer data
Y(:,14) = 0;
Y(:,15) = 0;
Y(:,16) = 0;
z = X(:,10);
for i=1:length(z)
    [y, m, d, h, mi, s] = datevec(datenum([1970 1 1 0 0 z(i)]) - 4/24);
    %% year, month, day, hour, minute, seconds, millseconds
    Y(i,17) = y; 
    Y(i,18) = m;
    Y(i,19) = d;
    Y(i,20) = h;
    Y(i,21) = mi;
    Y(i,22) = floor(s);
    Y(i,23) = (s - floor(s))*1000;
end

%% sync
Y(:,24) = 0;

%%sensor status
Y(:,25) = 0;

Y(:,26) = X(:,6);

end

