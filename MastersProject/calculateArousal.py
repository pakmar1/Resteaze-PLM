import sys
import os
import numpy as np
from numpy import mean, sqrt, square
from utilities import  rms, find



def calculateArousal(bCLM,leftBandData,rightBandData):
    percentVal = 0.45
    Arousal = bCLM[:,[0,1]]
    
    if len(leftBandData) != 0:    
        leftrmsAcc = rms(removeAccGrav(leftBandData[:,7:10]))
        leftrmsGyr = rms(leftBandData[:,10:13])
    if len(rightBandData) != 0:
        rightrmsAcc = rms(removeAccGrav(rightBandData[:,7:10]))
        rightrmsGyr = rms(rightBandData[:,10:13])
    
    DurationArr = bCLM[:,2]
    CLM_OR_PLM = bCLM[:,4]
   
    AUCArr = []
    MAXActivityArr = []
    GYRORMS_AUCArr = []
    GYRORMS_MAXActivityArr = []
    GYROX_AUCArr = []
    GYROX_MAXActivityArr = []
    GYROY_AUCArr = []
    GYROY_MAXActivityArr = []
    GYROZ_AUCArr = []
    GYROZ_MAXActivityArr = []
    ACC_STD_Arr = []
    GYRO_STD_Arr = []
    CAP1_STD_Arr = []
    CAP2_STD_Arr = []
    CAP3_STD_Arr = []
    
    arousal_col_2 = []
    for i in range(bCLM.shape[0]):
        if bCLM[i,12] == 2:
            AUCArr.append(np.sum(leftrmsAcc[int(bCLM[i,0]):int(bCLM[i,1])])) 
            MAXActivityArr.append(np.max(leftrmsAcc[int(bCLM[i,0]):int(bCLM[i,1])])) 
            GYRORMS_AUCArr.append(np.sum(leftrmsGyr[int(bCLM[i,0]):int(bCLM[i,1])])) 
            GYRORMS_MAXActivityArr.append(np.max(leftrmsGyr[int(bCLM[i,0]):int(bCLM[i,1])]))  
            GYROX_AUCArr.append(np.sum(leftBandData[int(bCLM[i,0]):int(bCLM[i,1]),10])) 
            GYROX_MAXActivityArr.append(np.max(leftBandData[int(bCLM[i,0]):int(bCLM[i,1]),10])) 
            GYROY_AUCArr.append(np.sum(leftBandData[int(bCLM[i,0]):int(bCLM[i,1]),11])) 
            GYROY_MAXActivityArr.append(np.max(leftBandData[int(bCLM[i,0]):int(bCLM[i,1]),11]))  
            GYROZ_AUCArr.append(np.sum(leftBandData[int(bCLM[i,0]):int(bCLM[i,1]),12])) 
            GYROZ_MAXActivityArr.append(np.max(leftBandData[int(bCLM[i,0]):int(bCLM[i,1]),12])) 
            ACC_STD_Arr.append(np.std(leftrmsAcc[int(bCLM[i,0]):int(bCLM[i,1])])) 
            GYRO_STD_Arr.append(np.std(leftrmsGyr[int(bCLM[i,0]):int(bCLM[i,1])])) 
            CAP1_STD_Arr.append(np.std(leftBandData[int(bCLM[i,0]):int(bCLM[i,1]),4])) 
            CAP2_STD_Arr.append(np.std(leftBandData[int(bCLM[i,0]):int(bCLM[i,1]),5])) 
            CAP3_STD_Arr.append(np.std(leftBandData[int(bCLM[i,0]):int(bCLM[i,1]),6])) 
        elif bCLM[i,12] == 1:
            AUCArr.append(np.sum(rightrmsAcc[int(bCLM[i,0]):int(bCLM[i,1])]))
            MAXActivityArr.append(np.max(rightrmsAcc[int(bCLM[i,0]):int(bCLM[i,1])])) 
            GYRORMS_AUCArr.append(np.sum(rightrmsGyr[int(bCLM[i,0]):int(bCLM[i,1])])) 
            GYRORMS_MAXActivityArr.append(np.max(rightrmsGyr[int(bCLM[i,0]):int(bCLM[i,1])])) 
            GYROX_AUCArr.append(np.sum(rightBandData[int(bCLM[i,0]):int(bCLM[i,1]),10])) 
            GYROX_MAXActivityArr.append(np.max(rightBandData[int(bCLM[i,0]):int(bCLM[i,1]),10])) 
            GYROY_AUCArr.append(np.sum(rightBandData[int(bCLM[i,0]):int(bCLM[i,1]),11])) 
            GYROY_MAXActivityArr.append(np.max(rightBandData[int(bCLM[i,0]):int(bCLM[i,1]),11])) 
            GYROZ_AUCArr.append(np.sum(rightBandData[int(bCLM[i,0]):int(bCLM[i,1]),12])) 
            GYROZ_MAXActivityArr.append(np.max(rightBandData[int(bCLM[i,0]):int(bCLM[i,1]),12])) 
            ACC_STD_Arr.append(np.std(rightrmsAcc[int(bCLM[i,0]):int(bCLM[i,1])])) 
            GYRO_STD_Arr.append(np.std(rightrmsGyr[int(bCLM[i,0]):int(bCLM[i,1])])) 
            CAP1_STD_Arr.append(np.std(rightBandData[int(bCLM[i,0]):int(bCLM[i,1]),4])) 
            CAP2_STD_Arr.append(np.std(rightBandData[int(bCLM[i,0]):int(bCLM[i,1]),5])) 
            CAP3_STD_Arr.append(np.std(rightBandData[int(bCLM[i,0]):int(bCLM[i,1]),6]))
        else:
            AUCArr.append(np.mean([np.sum(leftrmsAcc[int(bCLM[i,0]):int(bCLM[i,1])]),np.sum(rightrmsAcc[int(bCLM[i,0]):int(bCLM[i,1])])])) 
            MAXActivityArr.append(np.mean([np.max(leftrmsAcc[int(bCLM[i,0]):int(bCLM[i,1])]),np.max(rightrmsAcc[int(bCLM[i,0]):int(bCLM[i,1])])])) 
            GYRORMS_AUCArr.append(np.mean([np.sum(leftrmsGyr[int(bCLM[i,0]):int(bCLM[i,1])]),np.sum(rightrmsGyr[int(bCLM[i,0]):int(bCLM[i,1])])])) 
            GYRORMS_MAXActivityArr.append(np.mean([np.max(leftrmsGyr[int(bCLM[i,0]):int(bCLM[i,1])]),np.max(rightrmsGyr[int(bCLM[i,0]):int(bCLM[i,1])])])) 
            GYROX_AUCArr.append(np.mean([np.sum(leftBandData[int(bCLM[i,0]):int(bCLM[i,1]),10]),np.sum(rightBandData[int(bCLM[i,0]):int(bCLM[i,1]),10])])) 
            GYROX_MAXActivityArr.append(np.mean([np.max(leftBandData[int(bCLM[i,0]):int(bCLM[i,1]),10]),np.max(rightBandData[int(bCLM[i,0]):int(bCLM[i,1]),10])])) 
            GYROY_AUCArr.append(np.mean([np.sum(leftBandData[int(bCLM[i,0]):int(bCLM[i,1]),11]),np.sum(rightBandData[int(bCLM[i,0]):int(bCLM[i,1]),11])])) 
            GYROY_MAXActivityArr.append(np.mean([np.max(leftBandData[int(bCLM[i,0]):int(bCLM[i,1]),11]),np.max(rightBandData[int(bCLM[i,0]):int(bCLM[i,1]),11])])) 
            GYROZ_AUCArr.append(np.mean([np.sum(leftBandData[int(bCLM[i,0]):int(bCLM[i,1]),12]),np.sum(rightBandData[int(bCLM[i,0]):int(bCLM[i,1]),12])])) 
            GYROZ_MAXActivityArr.append(np.mean([np.max(leftBandData[int(bCLM[i,0]):int(bCLM[i,1]),12]),np.max(rightBandData[int(bCLM[i,0]):int(bCLM[i,1]),12])])) 
            ACC_STD_Arr.append(np.mean([np.std(leftrmsAcc[int(bCLM[i,0]):int(bCLM[i,1])]),np.std(rightrmsAcc[int(bCLM[i,0]):int(bCLM[i,1])])])) 
            GYRO_STD_Arr.append(np.mean([np.std(leftrmsGyr[int(bCLM[i,0]):int(bCLM[i,1])]),np.std(rightrmsGyr[int(bCLM[i,0]):int(bCLM[i,1])])])) 
            CAP1_STD_Arr.append(np.mean([np.std(leftBandData[int(bCLM[i,0]):int(bCLM[i,1]),4]),np.std(rightBandData[int(bCLM[i,0]):int(bCLM[i,1]),4])])) 
            CAP2_STD_Arr.append(np.mean([np.std(leftBandData[int(bCLM[i,0]):int(bCLM[i,1]),5]),np.std(rightBandData[int(bCLM[i,0]):int(bCLM[i,1]),5])])) 
            CAP3_STD_Arr.append(np.mean([np.std(leftBandData[int(bCLM[i,0]):int(bCLM[i,1]),6]),np.std(rightBandData[int(bCLM[i,0]):int(bCLM[i,1]),6])])) 
        """
        print("calculated values:")
        print(AUCArr[i])
        print(MAXActivityArr[i])
        print(GYRORMS_AUCArr[i])
        print(GYRORMS_MAXActivityArr[i])
        print(GYROX_AUCArr[i])
        print(GYROX_MAXActivityArr[i])
        print(GYROY_AUCArr[i])
        print(GYROY_MAXActivityArr[i])
        print(GYROZ_AUCArr[i])
        print(GYROZ_MAXActivityArr[i])
        print(ACC_STD_Arr[i])
        print(GYRO_STD_Arr[i])
        print(CAP1_STD_Arr[i])
        print(CAP2_STD_Arr[i])
        print(CAP3_STD_Arr[i])
        """
        val = LRplot(DurationArr[i],AUCArr[i],MAXActivityArr[i],GYRORMS_AUCArr[i],GYRORMS_MAXActivityArr[i],GYROX_AUCArr[i],GYROX_MAXActivityArr[i],GYROY_AUCArr[i],GYROY_MAXActivityArr[i],GYROZ_AUCArr[i],GYROZ_MAXActivityArr[i],ACC_STD_Arr[i],GYRO_STD_Arr[i],CAP1_STD_Arr[i],CAP2_STD_Arr[i],CAP3_STD_Arr[i],CLM_OR_PLM[i])
        arousal_col_2 = np.append(arousal_col_2, np.array(val > percentVal))
    Arousal = np.insert(Arousal,2, arousal_col_2, 1)    
    return Arousal

def removeAccGrav(accel):
    k = 0.2
    g = np.zeros(accel.shape)    
    g[1:g.shape[0],:] = k * accel[1:accel.shape[0],:] + (1-k) * accel[0:accel.shape[0]-1,:]
    accel = accel - g
    accel[0,:] = np.zeros(accel.shape[1])
    return accel

def LRplot(val1,val2,val3,val4,val5,val6,val7,val8,val9,val10,val11,val12,val13,val14,val15,val16,val17):
    
    coefficients = [-7.26071921174945,-1.63495844368173,4.12112328164108e-06,0.000307550213228846,-2.25291668515951e-06,-0.000296449861658441,-4.25363370848999e-06,-7.11370115182980e-05,-6.21629692944963e-06,0.000111605764350175,7.33668581844596e-07,0.000388852009829072,-0.00199518504774808,0.00370318074433064,9.46982846482890e-06,0.000100640871621468,-1.07690156038127e-05,-0.423981247009446]
    
    Intercept=  coefficients[0]
    duration=  coefficients[1]
    AUC=  coefficients[2]
    MAX_Activity= coefficients[3]
    GYRORMS_AUC=  coefficients[4]
    GYRORMS_MAX_Activity= coefficients[5]
    GYROX_AUC=  coefficients[6]
    GYROX_MAX_Activity= coefficients[7]
    GYROY_AUC=  coefficients[8]
    GYROY_MAX_Activity= coefficients[9]
    GYROZ_AUC=  coefficients[10]
    GYROZ_MAX_Activity= coefficients[11]
    ACC_STD=  coefficients[12]
    GYRO_STD= coefficients[13]
    CAP1_STD=  coefficients[14]
    CAP2_STD=  coefficients[15]
    CAP3_STD=  coefficients[16]
    CLM_OR_PLM = coefficients[17]
    
    val = Intercept+ (duration*val1) + (AUC*val2) + (val3*MAX_Activity) + (GYRORMS_AUC*val4) + (val5*GYRORMS_MAX_Activity) + (GYROX_AUC*val6) + (val7*GYROX_MAX_Activity) + (GYROY_AUC*val8) + (val9*GYROY_MAX_Activity) + (GYROZ_AUC*val10) + (val11*GYROZ_MAX_Activity) + (ACC_STD*val12) + (val13*GYRO_STD)+ (CAP1_STD*val14) + (val15*CAP2_STD)+ (CAP3_STD*val16)+(CLM_OR_PLM*val17)
    output_val = (np.exp(val)/(1+np.exp(val)))

    return output_val

