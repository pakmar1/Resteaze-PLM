import sys
import os
import numpy as np
from numpy import mean, sqrt, square
from utilities import  rms, find


"""
 The LM matrix is made based on paramsiPod strucutre, RMS values, and
 up2Down1 vlaues.
 
 Input
 paramsiPod -input structure that define criteria for scoring (The WASM criteria
             for scoring different leg movements)
 RMS - root mean value square of accelometer data.
 up2Down1 - showing if the patient whether the patient is in sleep or awake.

 Output
 LM - matrix of leg movement having minimum duration of 0.5 seconds and no 
      max duration. The structure include differnet type of variables.
"""
def getLMiPod(paramsiPod,RMS,up2Down1):
    #print("start of: getLMiPod")
    if RMS[0] == None:
        LM = None
        return
    LM = findIndices(RMS,paramsiPod.lowThreshold,paramsiPod.highThreshold,paramsiPod.minLowDuration,paramsiPod.minHighDuration,paramsiPod.fs)
    
    if LM.size == 0:
        return
    
    #%% Median must pass lowthreshold
    if paramsiPod.morphologyCriteria == 'on':
        LM = cutLowMedian(RMS,LM,paramsiPod.lowThreshold,paramsiPod.fs)
    
    #%% Add Duration in 3rd column
    LM = np.insert(LM, 2, values = (LM[:,1]-LM[:,0])/paramsiPod.fs, axis = 1)

    #Add IMI in sec in 4th column
    col_4=[]
    col_4.append(9999)
    col_4.extend((LM[1:LM.shape[0],0] - LM[0:LM.shape[0]-1,0])/paramsiPod.fs)
    
    if LM.shape[0] > 1:
        LM = np.insert(LM, 3, values = col_4, axis = 1)

    #5th column as zeros (reserved for PLM)
    LM = np.insert(LM,4,values=np.empty(LM.shape[0]),axis=1)
    LM_i = np.array(LM, dtype='i')

    # Add Up2Down1 in 6th Column (5th col reserved for PLM)
    LM = np.insert(LM,5,values = up2Down1[LM_i[:,0],0], axis = 1)
    LM_i = np.array(LM, dtype='i')

    # Convert beginning of LMs to mins in 7th Column
    LM = np.insert(LM,6,values = LM[:,0]/(paramsiPod.fs*60), axis=1)
    LM_i = np.array(LM, dtype='i')
    
    # Record epoch number of LM in 8th Column
    LM = np.insert(LM,7,values = np.round(LM[:,6]*2 + 0.5),axis=1)
    LM_i = np.array(LM, dtype='i')
    #print("LM 8th col:",LM)

    # Record breakpoints after long LM in 9th column
    col_9=[]
    col_9.append(1)
    col_9.extend(LM[0:LM_i.shape[0]-1,2] > paramsiPod.maxCLMDuration)
    LM = np.insert(LM,8,values=col_9,axis=1)
 

    LM_i = np.array(LM, dtype='i')
    # Record area of LM in 10th Column 
    col_10 = []
    for i in range(LM.shape[0]):
        col_10.append(np.sum(RMS[LM_i[i,0]:LM_i[i,1]])/paramsiPod.fs)
    LM = np.insert(LM,9,values=col_10,axis=1)

    return LM
#########################################################


#Remove leg movements whose median activity is less than noise level
def cutLowMedian(dsEMG,LM1,min,fs,**kwargs):
    LM1 = LM1.astype(float) #np.array(LM1, dtype='f')
    opt = kwargs.get('opt', 1)
    if opt:
        opt = 1
    
    # Calculate duration, probably don't need this though
    LM1 = np.insert(LM1,2,values = (LM1[:,1]-LM1[:,0])/fs,axis=1)

    # Add column with median values
    LM_i = np.array(LM1, dtype='i')
    median_col=[]
    for i in range(LM1.shape[0]):
        temp = np.median(dsEMG[LM_i[i,0]:LM_i[i,1]])
        median_col.append(temp)
    LM1 = np.insert(LM1,3,values=median_col,axis=1)

    if opt == 1:
        LM = shrinkWindow(LM1,dsEMG,fs,min)
    elif opt == 2:
        LM = tryShrinking(LM1,dsEMG,fs,min)
    elif opt == 3:
        LM = LM1


    # Exclude movements that still are empty
    LM = LM[LM[:,3] > min,0:2]
    return LM
    
#A different method of checking for a movement within the movement. This
# searches for any 0.5 second window where the median is above noise level.
def shrinkWindow(LM,dsEMG,fs,min):
    
    empty = find(LM[:,3], lambda x: x < min)
    #print("empty ",empty)
    for i in range(len(empty)):
        initstart = int(LM[empty[i],0])
        initstop = int(LM[empty[i],1])
        a = np.median(dsEMG[initstart:initstop])
        start = int(LM[empty[i]][0])
        stop = int(start + fs/2)
        while a < min and stop < initstop:
            a =  np.median(dsEMG[start:stop])
            start = int(start + fs/10)
            stop = int(start + fs/2)
        LM[empty[i],3] = a
    return LM

#Attempt to reduce the duration of the event in order to find a movement
#that fits minimum density requirement.
def tryShrinking(LM1,dsEMG,fs,min):
    short = find(LM1[:,3], lambda x: x < min)
    for i in range(len(short)):
        start = int(LM1[short[i]][0])
        stop = int(LM1[short[i]][1])
        while (start - stop)/fs > 0.6 and np.median(dsEMG[start:stop]) < min:
            stop = stop - fs/10
        LM1[short[i],3] = np.median(dsEMG[start:stop])
    return short

def findIndices(data,lowThreshold,highThreshold,minLowDuration,minHighDuration,fs):
    fullRuns = np.empty([2,2])# [[-1 for x in range(2)] for y in range(2)] 
    minLowDuration = minLowDuration * fs
    minHighDuration = minHighDuration * fs
    lowValues = find(data, lambda x: x < lowThreshold) 
    highValues = find(data, lambda x: x > highThreshold)

    if len(highValues) < 1:
        fullRuns[0][0] = 0
        fullRuns[0][1] = 0
    elif len(lowValues) < 1:
        fullRuns[0][0] = 1
        fullRuns[0][1] = 0

    lowRuns = returnRuns(lowValues,minLowDuration)
    highRuns = []
    numHighRuns = 0
    searchIndex = highValues[0]
    while searchIndex < data.shape[0]:
        distToNextLowRun,lengthOfNextLowRun = calcDistToRun(lowRuns,searchIndex)
        if distToNextLowRun == -1: ## Then we have hit the end, record our data and stop 
            highRuns.append([searchIndex , data.shape[0]])
        else: ##We have hit another low point, so record our data, 
            highRuns.append([searchIndex , searchIndex + distToNextLowRun-1])            
            searchIndex = searchIndex + distToNextLowRun + lengthOfNextLowRun
            highValues = np.asarray(highValues)
            temp = np.argwhere(highValues > searchIndex)
            if temp.size != 0:
                searchIndex = highValues[int(temp[0])]
        numHighRuns = numHighRuns + 1
    #Implement a quality control to only keep highRuns > minHighDuration
    highRuns = np.array(highRuns)
    runLengths = highRuns[:,1]-highRuns[:,0]
    ind = find(runLengths, lambda x: x > minHighDuration)
    fullRuns = highRuns[ind]
    #print("fullRuns ",fullRuns)
    return fullRuns




def returnRuns(vals,duration): 
    vals = np.asarray(vals)
    k = (np.diff(vals) != 1).astype(int)
    k = np.insert(k, 0, 1, axis=0)
    s = np.cumsum(k)
    x = np.histogram(s,np.arange(1,s[-1]+2))[0]
    idx = find(k, lambda x: x != 0) 
    idx = np.asarray(idx)
    startIndices = vals[idx[x>=duration]]
    stopIndices = startIndices + x[x>=duration] - 1
    runs = [startIndices,stopIndices]
    return runs

"""
 This Function finds the closest next (sequential) run from the current
 position.  It does include prior runs.  If there is no run it returns a
 distance of -1, otherwise it returns the distance to the next run.  It
 will also return the length of that run.  If there is no run it returns a
 length of -1.
 """
def calcDistToRun(run,position):
    distList = run[:][0] - position
    distPos = distList[distList>0]
    if distPos.all():
        dist = min(distPos)
        runIndex = int(np.where(distList == dist)[0])
        length = run[1][runIndex] - run[0][runIndex] + 1
    else:
        length = -1
        dist = -1
    return dist,length
