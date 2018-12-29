import sys
import os
import numpy as np
from numpy import mean, sqrt, square

class Param:
    pass

class Output:
    pass

class nightData:
    pass

def resteaze_dash(left,right,subjectid):

    params = init_params()
    output = init_output(subjectid)

    if os.path.exists(left):
        leftPath = os.path.splitext(left)[0]

        leftFileNames = os.path.splitext(left)[1]
        ext = os.path.splitext(left)[1]

        #print(left)
        #print("\n") 
        print("leftpath: "+leftPath)
        print("leftFileNames: "+leftFileNames)
        print("ext: "+ext)       
    else:
        print("lefterror")
    if os.path.exists(right):
        print("right")    
    else:
        print("righterror")

    """ read data from csv files """
    bandData_left = np.genfromtxt(left,delimiter=',',skip_header=1)
    #print(bandData_left)
    bandData_right = np.genfromtxt(right,delimiter=',',skip_header=1)

    #print(bandData_right.shape[0])
    #print(bandData_right[0][3])

    """synching signals from two legs"""
    leftLeg,rightLeg = syncRE(bandData_left,bandData_right)
    print("leftleg,rightleg after syncRE: ")
    print(leftLeg.shape[0])
    print(rightLeg.shape[0])

    output.up2Down1 = np.ones((leftLeg.shape[0],1)) 
    
    print("dimension going in for rms")
    print(leftLeg[:,[1,2,3]].shape)

    """calculating root-mean-square of the acclerometer movements for both legs"""
    output.lRMS = rms(leftLeg[:,[1,2,3]])
    output.rRMS = rms(rightLeg[:,[1,2,3]])

    print("output of rms:")
    print(output.lRMS.shape)
    print(output.rRMS.shape)

    """ compute LM(leg movement)"""
    rLM=getLMiPod(params,output.rRMS,output.up2Down1)
    #lLM=getLMiPod(params,output.rRMS,output.up2Down1)

def init_output(subjectid):
    output = Output()
    output.filename = subjectid
    #output.up2down1 = []
    #output.rRMS =0
    #output.lRMS =0
    return output

def init_params():
    # Initialize default parameters, if we want to allow them to change, modify here.
    params = Param()

    params.iLMbp='on'
    params.morphologyCriteria='on'

    # this is for the RestEaZe data.
    #params.lowThreshold=0.005;
    #params.highThreshold=0.01;
    params.lowThreshold=0.05
    params.highThreshold=0.1
    params.minLowDuration=0.5
    params.minHighDuration=0.5
    params.minIMIDuration=10
    params.maxIMIDuration=90
    params.maxCLMDuration=10
    #sampling rate for the RestEaZe data
    #params.fs=50;
    params.fs=25
    params.minNumIMI=3
    params.minSleepTime=5
    params.maxOverlapLag=0.5
    params.maxbCLMOverlap=4
    params.maxbCLMDuration=15
    params.side='both'
    print("params initialized")
    return params

def syncRE(leftLeg,rightLeg):
    print("in syncRE")
    leftLegsize = leftLeg.shape[0]
    rightLegsize = rightLeg.shape[0]
    
    # start of sync
    if leftLeg[0][3] > rightLeg[0][3]:
        rightstart=0
        for i in range(leftLegsize,-1,-1):
            if leftLeg[0][3] <= rightLeg[0][3]:
                rightstart = i
        
        if rightstart > 0:
            rightLeg = rightLeg[rightstart:][:]
        else:
            rightstart = None

    elif leftLeg[0][3] < rightLeg[0][3]:
        leftstart = 0
        for i in range(rightLegsize,-1,-1):
            if leftLeg[i][3] >= rightLeg[0][3]:
                leftstart = i
        
        if leftstart > 0:
            leftLeg = leftLeg[leftstart:][:]
        else:
            leftstart = None
    # end of sync
    
    #Just make the dimensions equal since sampling rate is the same and start time is synched
    leftLegsize = leftLeg.shape[0]
    rightLegsize = rightLeg.shape[0]

    #Delete rows that come before the sync time
    if leftLegsize > rightLegsize:
        leftLeg = leftLeg[0:rightLegsize][:]
        leftminusright = leftLeg[rightLegsize][3] - rightLeg[rightLegsize][3]
    elif leftLegsize < rightLegsize:
        rightLeg = rightLeg[0:leftLegsize][:]
        leftminusright = rightLeg[leftLegsize][3] - rightLeg[leftLegsize][3]

    return leftLeg,rightLeg

def rms(x):
    y = sqrt(mean(square(x),axis=1))
    return y

""" this LM calculation """
def getLMiPod(paramsiPod,RMS,up2Down1):
    print("start of: getLMiPod")
    if RMS[0] == None:
        LM = None
        return
    LM = findIndices(RMS,paramsiPod.lowThreshold,paramsiPod.highThreshold,paramsiPod.minLowDuration,paramsiPod.minHighDuration,paramsiPod.fs)
    print("end of: getLMiPod")
    if LM.size == 0:
        return
    #%% Median must pass lowthreshold
    if paramsiPod.morphologyCriteria == 'on':
        LM = cutLowMedian(RMS,LM,paramsiPod.lowThreshold,paramsiPod.fs)
    
    #%% Add Duration in 3rd column
    LM = LM.insert(LM, 2, values = (LM[:,1]-LM[:,0])/paramsiPod.fs, axis = 1)

    #Add IMI in sec in 4th column
    LM = LM.insert(LM, 3, values = )

    return LM

#Remove leg movements whose median activity is less than noise level
def cutLowMedian(dsEMG,LM1,min,fs,**kwargs):
    print("in curLowMedian()")
    LM1 = np.array(LM1, dtype='f')
    opt = kwargs.get('opt', 1)
    if opt:
        opt = 1
    print("opt")
    print(opt)
    # Calculate duration, probably don't need this though
    LM1 = np.insert(LM1,2,values = (LM1[:,1]-LM1[:,0])/fs,axis=1)

    # Add column with median values
    LM_i = np.array(LM1, dtype='i')
    median_col=[]
    for i in range(LM1.shape[0]):
        temp=np.median(dsEMG[LM_i[i,0]:LM_i[i,1]])
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
    print("shrinkWindow():")
    empty = find(LM[:,3], lambda x: x < min)
    for i in range(len(empty)):
        initstart =int(LM[empty[i]][0])
        initstop = int(LM[empty[i]][1])
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
    print("tryShrinking():")
    short = find(LM1[:,3], lambda x: x < min)
    for i in range(len(short)):
        start = int(LM1[short[i]][0])
        stop = int(LM1[short[i]][1])
        while (start - stop)/fs > 0.6 and np.median(dsEMG[start:stop]) < min:
            stop = stop - fs/10
        LM1[short[i],3] = np.median(dsEMG[start:stop])
    return short

def findIndices(data,lowThreshold,highThreshold,minLowDuration,minHighDuration,fs):
    print("start of: findIndices")
    fullRuns = [[-1 for x in range(2)] for y in range(2)] 
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
    print("searchIndex:")
    print(searchIndex)
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
    
    return fullRuns

def find(a, func):
    return [i for (i, val) in enumerate(a) if func(val)]


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


if __name__ == '__main__':
    resteaze_dash(sys.argv[1],sys.argv[2],sys.argv[3])