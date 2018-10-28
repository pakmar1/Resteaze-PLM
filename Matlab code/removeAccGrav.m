function accel=removeAccGrav(accel)
accel=accel/4096;
k = 0.2; % this is from Nilanjen
g = zeros(size(accel,1),3);
g(2:end,:) = k * accel(2:end,:) + (1-k) * accel(1:end-1,:);
accel = accel - g;
accel(1,:)=0;
end