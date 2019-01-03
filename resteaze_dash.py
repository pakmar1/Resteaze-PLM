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
        #leftFileNames = os.path.splitext(left)[1]
        ext = os.path.splitext(left)[1]

        print("leftpath: "+leftPath)
        #print("leftFileNames: "+leftFileNames)
        print("ext: "+ext)       
    else:
        print("lefterror")
    if os.path.exists(right):
        
        rightPath = os.path.splitext(right)[0]
        #rightFileNames = os.path.splitext(right)[1]
        right_ext = os.path.splitext(right)[1]
        print("rightpath: " + rightPath)
        #print("rightFileNames: " + rightFileNames)
        print("right ext: " + right_ext)     

    else:
        print("righterror")

    """ read data from csv files """
    bandData_left = np.genfromtxt(left,delimiter=',',skip_header=1)
    bandData_right = np.genfromtxt(right,delimiter=',',skip_header=1)

    """synching signals from two legs"""
    leftLeg,rightLeg = syncRE(bandData_left,bandData_right)
    #print("leftleg,rightleg after syncRE: ")
    #print(leftLeg.shape[0])
    #print(rightLeg.shape[0])

    output.up2Down1 = np.ones((leftLeg.shape[0],1)) 
    
    #print("dimension going in for rms")
    #print(leftLeg[:,[1,2,3]].shape)
    #################################################

    """calculating root-mean-square of the acclerometer movements for both legs"""
    output.lRMS = rms(leftLeg[:,[1,2,3]])
    output.rRMS = rms(rightLeg[:,[1,2,3]])

    #print("output of rms:")
    #print(output.lRMS.shape)
    #print(output.rRMS.shape)
    #################################################
    
    """ compute LM(leg movement)"""
    rLM=getLMiPod(params,output.rRMS,output.up2Down1)
    lLM=getLMiPod(params,output.rRMS,output.up2Down1)
    #################################################

    """ Start Patrick's standard scoring stuff """
    bCLM = candidate_lms(rLM,lLM,params)
    Arousal = calculateArousal(bCLM,leftLeg,rightLeg)
    output.Arousal = Arousal[Arousal[:,2]==1,:]
    bCLM[:,10] = Arousal[:,2]
    PLM, bCLM = periodic_lms(bCLM,params)


    #################################################
    """  score sleep/wake """
    output.wake = scoreSleep(params.fs,output.lRMS,PLM,bCLM)

    
    #################################################


def init_output(subjectid):
    output = Output()
    output.filename = subjectid

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
    #print("params initialized")
    return params

def syncRE(leftLeg,rightLeg):
    #print("in syncRE")
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


########################################################################################
########################################################################################
""" LM calculation """
########################################################################################

def getLMiPod(paramsiPod,RMS,up2Down1):
    print("start of: getLMiPod")
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

    #5th column as zeros
    LM = np.insert(LM,4,values=np.zeros(LM.shape[0]),axis=1)

    LM_i = np.array(LM, dtype='i')

    # Add Up2Down1 in 6th Column (5th col reserved for PLM)
    LM = np.insert(LM,5,values = up2Down1[LM_i[:,0],0], axis = 1)
    LM_i = np.array(LM, dtype='i')

    # Convert beginning of LMs to mins in 7th Column
    LM = np.insert(LM,6,values = LM_i[:,0]/(paramsiPod.fs*60), axis=1)
    LM_i = np.array(LM, dtype='i')
    


    # Record epoch number of LM in 8th Column
    LM = np.insert(LM,7,values = np.round(LM_i[:,6]*2 + 0.5),axis=1)
    LM_i = np.array(LM, dtype='i')
    

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
    #print("final LM:")
    #print(LM)
    print("end of: getLMiPod")
    return LM
#########################################################


#Remove leg movements whose median activity is less than noise level
def cutLowMedian(dsEMG,LM1,min,fs,**kwargs):
    LM1 = np.array(LM1, dtype='f')
    opt = kwargs.get('opt', 1)
    if opt:
        opt = 1
    
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
    #print("shrinkWindow():")
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
    #print("tryShrinking():")
    short = find(LM1[:,3], lambda x: x < min)
    for i in range(len(short)):
        start = int(LM1[short[i]][0])
        stop = int(LM1[short[i]][1])
        while (start - stop)/fs > 0.6 and np.median(dsEMG[start:stop]) < min:
            stop = stop - fs/10
        LM1[short[i],3] = np.median(dsEMG[start:stop])
    return short

def findIndices(data,lowThreshold,highThreshold,minLowDuration,minHighDuration,fs):
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

########################################################################################
########################################################################################




########################################################################################
########################################################################################
""" candidate_lms():
% Determine candidate leg movements for PLM from monolateral LM arrays. If
% either rLM or lLM is empty ([]), this will return monolateral candidates,
% otherwise if both are provided they will be combined according to current
% WASM standards. Adds other information to the CLM table, notably
% breakpoints to indicate potential ends of PLM runs, sleep stage, etc. Of
% special note, the 13th column of the output array indicates which leg the
% movement is from: 1 is right, 2 is left and 3 is bilateral.
%
%
% inputs:
%   - rLM - array from right leg (needs start and stop times)
%   - lLM - array from left leg
%
"""
def candidate_lms(rLM,lLM,params):
    CLM=[]
    if rLM.size != 0 and lLM.size != 0:
        #print("both full")
        # Reduce left and right LM arrays to exclude too long movements, but add
        # breakpoints to the following movement
        rLM[:,2] = (rLM[:,1]-rLM[:,0])/params.fs
        lLM[:,2] = (lLM[:,1]-lLM[:,0])/params.fs

        rLM = rLM[rLM[:,2]>=0.5,:]
        lLM = lLM[lLM[:,2]>=0.5,:]

        rLM[rLM[:rLM.shape[0],2]>params.maxCLMDuration,8] = 4
        lLM[lLM[:lLM.shape[0],2]>params.maxCLMDuration,8] = 4

        # Combine left and right and sort.
        CLM = rOV2(lLM,rLM,params.fs)
        #print("CLM after rOV2")
        #print(CLM)
    elif lLM.size != 0:
        print("left is full")
        lLM[:,2] = (lLM[:,1] - lLM[:,0])/params.fs
        lLM = lLM[lLM[:,2] > 0.5,:]
        lLM[lLM[0:lLM.shape[0]-1,2] > params.maxCLMDuration,8] = 4  #too long mclm
        CLM = lLM
        CLM = np.insert(CLM,10,values = np.zeros(rLM.shape[0]),axis=1)
        CLM = np.insert(CLM,11,values = np.zeros(rLM.shape[0]),axis=1)
        CLM = np.insert(CLM,12,values = np.zeros(rLM.shape[0]),axis=1)

    elif rLM.size != 0:
        print("right is full")
        rLM[:,2] = (rLM[:,1] - rLM[:,0])/params.fs
        rLM = rLM[rLM[:,2] > 0.5,:]
        rLM[rLM[0:rLM.shape[0]-1,2] > params.maxCLMDuration,8] = 4  #too long mclm
        CLM = rLM
        CLM = np.insert(CLM,10,values = np.zeros(rLM.shape[0]),axis=1)
        CLM = np.insert(CLM,11,values = np.zeros(rLM.shape[0]),axis=1)
        CLM = np.insert(CLM,12,values = np.zeros(rLM.shape[0]),axis=1)
    else:
        CLM = []

    if np.sum(CLM) == 0:
        return []
    
    # if a bilateral movement consists of one or more monolateral movements
    # that are longer than 10 seconds (standard), the entire combined movement
    # is rejected, and a breakpoint is placed on the next movement. When
    # inspecting IMI of CLM later, movements with the bp code 4 will be
    # excluded because IMI is disrupted by a too-long LM
    contains_too_long = find(CLM[:,8],lambda x: x == 4)
    for i in range(len(contains_too_long)):
        CLM[contains_too_long[i]+1,8] = 4
    CLM = np.delete(CLM,contains_too_long,0)

    # add breakpoints if the duration of the combined movement is greater
    # than 15 seconds (standard) or if a bilateral movement is made up of
    # greater than 4 (standard) monolateral movements. These breakpoints
    # are actually added to the subsequent movement, and the un-CLM is
    # removed.
    CLM[:,2] = (CLM[:,1]-CLM[:,0])/params.fs
    
    col_9_bclm = find(CLM[0:CLM.shape[0]-1,2], lambda x: x > params.maxbCLMDuration)
    for index in range(len(col_9_bclm)):
        col_9_bclm[index] = col_9_bclm[index] +1

    CLM[col_9_bclm,8] = 3 # too long bclm
    
    col_9_cmbd = find(CLM[0:CLM.shape[0]-1,3], lambda x: x > params.maxbCLMOverlap)
    for index in range(len(col_9_cmbd)):
        col_9_cmbd[index] = col_9_cmbd[index] +1

    CLM[col_9_cmbd,8] =  5 # too many cmbd mvmts

    for value in range(CLM.shape[0]):
        if CLM[value,3] > params.maxbCLMOverlap or CLM[value,2] > params.maxbCLMDuration:
            np.delete(CLM,value,0)

    CLM[:,3] = np.zeros(CLM.shape[0]) # clear out the #combined mCLM

    # If there are no CLM, return an empty vector
    if CLM.size != 0:
        # Add IMI (col 4), sleep stage (col
        # 6). Col 5 is reserved for PLM marks later
        CLM = getIMI(CLM, params.fs)

        # add breakpoints if IMI < minIMI. This is according to new standards.
        # I believe we also need a breakpoint after this movement, so that a
        # short IMI cannot begin a run of PLM
        if params.iLMbp == 'on':
            CLM[CLM[:,3] < params.minIMIDuration, 8] = 2 #short IMI
        else:
            CLM = removeShortIMI(CLM,params)
        
        # Add movement start time in minutes (col 7) and sleep epoch number
        # (col 8)
        CLM[:,6] = CLM[:,0]/(params.fs * 60)
        CLM[:,7] = np.rint(CLM[:,6] * 2 + 0.5)
     
        # The area of the leg movement should go here. However, it is not
        # currently well defined in the literature for combined legs, and we
        # have omitted it temporarily
        CLM[:,9] = np.zeros(CLM.shape[0])
        CLM[:,10] = np.zeros(CLM.shape[0])
        CLM[:,11] = np.zeros(CLM.shape[0])
        # 3 add breakpoints if IMI > 90 seconds (standard)    
        CLM[CLM[:,3] > params.maxIMIDuration,8] = 1
        #print("CLM out of candidate_lms():")
        #print(CLM)
    return CLM

def rOV2(lLM,rLM,fs):
    #Combine bilateral movements if they are separated by < 0.5 seconds
    # zeros for column 11 and 12
    rLM = np.insert(rLM,10,values = np.zeros(rLM.shape[0]),axis=1)
    lLM = np.insert(lLM,10,values = np.zeros(lLM.shape[0]),axis=1)
    rLM = np.insert(rLM,11,values = np.zeros(rLM.shape[0]),axis=1)
    lLM = np.insert(lLM,10,values = np.zeros(lLM.shape[0]),axis=1)

    #combine and sort LM arrays
    rLM = np.insert(rLM,12,values = np.ones(rLM.shape[0]),axis=1)
    lLM = np.insert(lLM,12,values = np.full((rLM.shape[0]),2),axis=1)

    combLM = np.concatenate((rLM,lLM),axis = 0)
    combLM = combLM[combLM[:,0].argsort()]
    
    #distance to next movement
    CLM = combLM
    CLM[:,3] = np.ones(CLM.shape[0])
    #CLM_i  = np.array(CLM, dtype='i')

    i = 0
    while i < CLM.shape[0]-1:
    # make sure to check if this is correct logic for the half second
    # overlap period...
        a1 = np.arange(CLM[i,0],CLM[i,1])
        a2 = np.arange(CLM[i+1,0]-fs/2, CLM[i+1,1])
        intersect = np.intersect1d(a1,a2)
 
        if intersect.size == 0:
            i = i+1
        else:
            CLM[i:1] = np.maximum(CLM[i,1],CLM[i+1,1])
            CLM[i:3] = CLM[i:3] + CLM[i+1,3]
            CLM[i:8] = np.maximum(CLM[i,8],CLM[i+1,8])
            if CLM[i,12] != CLM[i+1,12]:
                CLM[i,12]=3
            CLM[i+1,:] = np.empty(CLM.shape[1])
    return CLM

# getIMI calculates intermovement interval and stores in the fourth column
# of the input array. IMI is onset-to-onset and measured in seconds
def getIMI(LM,fs):
    LM[0,3] = 9999 # archaic... don't know if we need this
    LM[1:LM.shape[0],3] = (LM[1:LM.shape[0],0] - LM[0:LM.shape[0]-1,0])/fs
    return LM


# Old way of scoring - remove movements with too short IMI, then
# recalculate IMI and see if it fits now. There's probably a way to
# vectorize this for speed, but I honestly don't care, no one should use
# this anymore.
def removeShortIMI(CLM,params):
    rc = 0
    CLMt =[]
    for rl in range(CLM.shape[0]):
        if CLM[rl,3] >= params.minIMIDuration:
            CLMt[rc,:] = CLM[rl,:]
            rc = rc + 1
        elif rl < CLM.shape[0]-1:
            CLM[rl+1,3] = CLM[rl+1,3]+CLM[rl,3]

    CLMt = getIMI(CLMt,params.fs)
    return CLMt
##########################################################################################
##########################################################################################


##########################################################################################
##########################################################################################
""" calculating Arousal """

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


##########################################################################################
##########################################################################################


##########################################################################################
##########################################################################################
""" periodic_lms()::

%% PLM = periodic_lms(CLM,params)
%  find periodic leg movements from the array of CLM. Can either ignore
%  intervening LMs or add breakpoints. Contains subfunctions for ignoring
%  iLMs, restructuring breakpoint locations to find PLM runs and marking
%  the CLM which occur in periodic series.

% Create CLMt array of all CLM with IMI greater than the minimum allowable
% if intervening lm option is not selected, we remove CLMs whose IMI are
% too short. Really, new standards say that these should always be
% breakpoint, so the first case is only for posterity. """
def periodic_lms(CLM,params):
    if params.iLMbp != 'on':
        CLMt = removeShortIMI_periodic(CLM,params.minIMIDuration,params.fs)
    else:
        CLMt = CLM
 
    CLMt[:,4] = np.zeros(CLMt.shape[0]) # Restart PLM
    BPloct = BPlocAndRunsArray(CLMt,params.minNumIMI)
    CLMt = markPLM3(CLMt,BPloct)

    #print("CLMt after markPLM3()")
    #print(CLMt)

    PLM = []
    for i in range(CLMt.shape[0]):
        if CLMt[i,4] == 1:
            PLM = np.append(PLM,CLMt[i,:],0)
    #print("PLM after markPLM3()")
    #print(PLM)

    return PLM, CLMt
##########################################################################################

"""
%% CLMt = removeShortIMI(CLM,minIMIDuration,fs)
% This function removes CLM with IMI that are too short to be considered
% PLM. This is according to older standards, and hopefully this code will
% not be necessary in the future.
"""
def removeShortIMI_periodic(CLM,minIMIDuration,fs):
    i = 2 #skip the first movement
    CLMt = CLM
    while i < CLMt.shape[0]:
        if CLMt[i,3] >= minIMIDuration:
            i = i + 1
        else:
            CLMt = np.delete(CLMt,i,0)
            CLMt[i,3] = (CLMt[i,0] - CLMt[i-1,0])/fs
    return CLMt


##########################################################################################
"""
%% BPloc = BPlocAndRunsArray(CLM,minNumIMI)
%  col 1: Break point location
%  col 2: Number of leg movements
%  col 3: PLM =1, no PLM = 0
%  col 4: #LM if PLM
% This is really only for internal use, nobody wants to look at this BPloc
% array, but it is necessary to get our PLM. """
def BPlocAndRunsArray(CLM,minNumIMI):
    #print("BPlocAndRunsArray()")
    #print("CLM")
    #print(CLM)
    
    col_1 = find(CLM[:,8],lambda x: x != 0) # BP locations
    #print(col_1)
    #print("BPloc")
    BPloc = np.empty([len(col_1),0])
    #print(BPloc)
    BPloc = np.insert(BPloc,0,col_1,1)
    

    # Add number of movements until next breakpoint to column 2
    col_2 = []
    for i in range(BPloc.shape[0]-1):
        col_2.append(BPloc[i+1,0] - BPloc[i,0])
    col_2.append(CLM.shape[0] - BPloc[BPloc.shape[0]-1,0])
    #print("col_2")
    #print(col_2)

    BPloc = np.insert(BPloc,1,col_2,1)

    # Mark whether a run of LM meets the minimum requirement for number of IMI
    col_3 = []
    for i in range(BPloc.shape[0]):
        col_3.append(BPloc[i,1] > minNumIMI)
    BPloc = np.insert(BPloc,2,col_3,1)
    #print(col_3)

    # Mark the number of movements in each PLM series
    col_4 = []
    for i in range(BPloc.shape[0]):
        if BPloc[i,2] == 1:
            col_4.append(BPloc[i,1])
        else:
            col_4.append(0)    
        
    BPloc = np.insert(BPloc,3,col_4,1)

    return BPloc

##########################################################################################
"""
%% CLM = markPLM3(CLM,BPloc,fs)
% places a 1 in column 5 for all movements that are part of a run
% of PLM. Again, used internally, you'll never really need to run this
% independent of periodic_lms.
"""
def markPLM3(CLM,BPloc):
    bpPLM = []
    for i in range(BPloc.shape[0]):
        if BPloc[i,2] == 1:
            bpPLM.append(BPloc[i,:])
    

    if len(bpPLM) > 0:
        for i in range(len(bpPLM)):
            CLM[bpPLM[i,0]:bpPLM[i,0]+bpPLM[i,1]-1,4] = 1

    return CLM

##########################################################################################
##########################################################################################


##########################################################################################
##########################################################################################

def scoreSleep(fs,RMS,LM,GLM):
    #Calculate numLMper10epochs - the number of GLM+LM per 10 epochs
    dataPtsPerWindow=30*10*fs
    numWindows = np.ceil(RMS.shape[0]/dataPtsPerWindow)
    print("scoreSleep::")
    print(dataPtsPerWindow)
    print(numWindows)    
    
    LM = np.array(LM)
    GLM = np.array(GLM)
    #print("LM")
    #print(LM[0:LM.shape[0],0])
    #print("GLM")
    #print(GLM[0:GLM.shape[0],0])

    print("concatenate")
    if LM.size != 0:
        b = np.concatenate(LM[0:LM.shape[0],0],GLM[0:GLM.shape[0],0],axis=0)
    else:
        b = GLM[0:GLM.shape[0],0]
    print("b")
    print(b.shape)
    print(b)

    xy = np.arange(0,numWindows*dataPtsPerWindow+1,dataPtsPerWindow)
    print("xy")
    print(xy)
    print(xy.shape)

    numLMper10epochs = np.histogram(b,xy)[0]
    print("numLMper10epochs")
    print(numLMper10epochs)
    print(len(numLMper10epochs))

    # wakeLM is a logical vector indicating whether there is at least 1 GLM,LM in
    # the 10 epochwindow that the current dataPt is in (0=there is LM, 1= no LM) 1 corresponds to wake.
    wakeLM = np.zeros(RMS.shape[0])
    print("wakeLM")
    print(wakeLM.shape)
    print(wakeLM)

    for i in range(numWindows-1):
        wakeLM[(i-1)*dataPtsPerWindow+1:i*dataPtsPerWindow] = numLMper10epochs(i) * np.ones(dataPtsPerWindow)
    print(wakeLM)
##########################################################################################
##########################################################################################

if __name__ == '__main__':
    resteaze_dash(sys.argv[1],sys.argv[2],sys.argv[3])