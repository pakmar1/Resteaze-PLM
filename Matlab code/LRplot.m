function [ output_val ] = LRplot(val1,val2,val3,val4,val5,val6,val7,val8,val9,val10,val11,val12,val13,val14,val15,val16,val17)
data = load('coefficients.mat');
coefficients = data.coefficients;
    
Intercept=  coefficients(1);
duration=  coefficients(2);
AUC=  coefficients(3);
MAX_Activity= coefficients(4);
GYRORMS_AUC=  coefficients(5);
GYRORMS_MAX_Activity= coefficients(6);
GYROX_AUC=  coefficients(7);
GYROX_MAX_Activity= coefficients(8);
GYROY_AUC=  coefficients(9);
GYROY_MAX_Activity= coefficients(10);
GYROZ_AUC=  coefficients(11);
GYROZ_MAX_Activity= coefficients(12);
ACC_STD=  coefficients(13);
GYRO_STD= coefficients(14);
CAP1_STD=  coefficients(15);
CAP2_STD=  coefficients(16);
CAP3_STD=  coefficients(17);
CLM_OR_PLM = coefficients(18);
% 
val = Intercept+ (duration*val1) + (AUC*val2) + (val3*MAX_Activity) + (GYRORMS_AUC*val4) + (val5*GYRORMS_MAX_Activity) + (GYROX_AUC*val6) + (val7*GYROX_MAX_Activity) + (GYROY_AUC*val8) + (val9*GYROY_MAX_Activity) + (GYROZ_AUC*val10) + (val11*GYROZ_MAX_Activity) + (ACC_STD*val12) + (val13*GYRO_STD)+ (CAP1_STD*val14) + (val15*CAP2_STD)+ (CAP3_STD*val16)+(CLM_OR_PLM*val17);
output_val = (exp(val)/(1+exp(val)));
end