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
    bandData_right = np.genfromtxt(right,delimiter=',',skip_header=1)

    """synching signals from two legs"""
    leftLeg,rightLeg = syncRE(bandData_left,bandData_right)
    print("leftleg,rightleg after syncRE: ")
    print(leftLeg.shape[0])
    print(rightLeg.shape[0])

    output.up2Down1 = np.ones((leftLeg.shape[0],1)) 
    
    print("dimension going in for rms")
    print(leftLeg[:,[1,2,3]].shape)
    #################################################

    """calculating root-mean-square of the acclerometer movements for both legs"""
    output.lRMS = rms(leftLeg[:,[1,2,3]])
    output.rRMS = rms(rightLeg[:,[1,2,3]])

    print("output of rms:")
    print(output.lRMS.shape)
    print(output.rRMS.shape)
    #################################################
    
    """ compute LM(leg movement)"""
    rLM=getLMiPod(params,output.rRMS,output.up2Down1)
    lLM=getLMiPod(params,output.rRMS,output.up2Down1)
    #################################################

    """ Start Patrick's standard scoring stuff """
    bCLM = candidate_lms(rLM,lLM,params)

    #################################################

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


########################################################################################
########################################################################################
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
    return LM
#########################################################


#Remove leg movements whose median activity is less than noise level
def cutLowMedian(dsEMG,LM1,min,fs,**kwargs):
    print("in cutLowMedian()")
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
        print("both full")
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
    contains_too_long = find(CLM[:,8],lambda x: x ==4)
    for i in range(len(contains_too_long)):
        CLM[contains_too_long[i]+1,8] = 4
    CLM = np.delete(CLM,contains_too_long,0)

    # add breakpoints if the duration of the combined movement is greater
    # than 15 seconds (standard) or if a bilateral movement is made up of
    # greater than 4 (standard) monolateral movements. These breakpoints
    # are actually added to the subsequent movement, and the un-CLM is
    # removed.
    CLM[:,2] = (CLM[:,1]-CLM[:,0])/params.fs
    CLM[find(CLM[0:CLM.shape[0]-1,2], lambda x: x > params.maxbCLMDuration)+1,8] = 3 # too long bclm
    CLM[find(CLM[0:CLM.shape[0]-1,3], lambda x: x > params.maxbCLMOverlap)+1,8] =  5 # too many cmbd mvmts

    CLM[CLM[0:CLM.shape[0],3]>params.maxbCLMOverlap or CLM[0:CLM.shape[0],2]>params.maxbCLMDuration,:] = np.empty(CLM.shape[1])

    CLM[:,3] = np.zeros(CLM.shape[0]) # clear out the #combined mCLM

    # If there are no CLM, return an empty vector
    if CLM.size == 0:
        # Add IMI (col 4), sleep stage (col
        # 6). Col 5 is reserved for PLM marks later
        CLM = getIMI(CLM, params.fs)

        # add breakpoints if IMI < minIMI. This is according to new standards.
        # I believe we also need a breakpoint after this movement, so that a
        # short IMI cannot begin a run of PLM
        if params.iLMbp == 'on':
            CLM[CLM[:,3] < params.minIMIDuration, 9] = 2 #short IMI
        else:
            CLM = removeShortIMI(CLM,params)
        
        # Add movement start time in minutes (col 7) and sleep epoch number
        # (col 8)
        CLM[:,6] = CLM[:,0]/(params.fs * 60)
        CLM[:,7] = np.rint(CLM[:,6] * 2 + 0.5)
     
        # The area of the leg movement should go here. However, it is not
        # currently well defined in the literature for combined legs, and we
        # have omitted it temporarily
        CLM[:,9:11] = np.zeros(CLM.shape[0])

        # 3 add breakpoints if IMI > 90 seconds (standard)    
        CLM[CLM[:,3] > params.maxIMIDuration,8] = 1
        print("CLM out of candidate_lms():")
        print(CLM)
    return CLM

def rOV2(lLM,rLM,fs):
    #Combine bilateral movements if they are separated by < 0.5 seconds
    print("function rOv2():")
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
    CLMt =np.array()
    for rl in range(CLM.shape[0]):
        if CLM[rl,3] >= params.minIMIDuration:
            CLMt[rc,:] = CLM[rl,:]
            rc = rc + 1
        elif rl < CLM.shape[0]:
            CLM[rl+1,3] = CLM[rl+1,3]+CLM[rl,3]

    CLMt = getIMI(CLMt,params.fs)
    return CLMt
##########################################################################################
##########################################################################################


if __name__ == '__main__':
    resteaze_dash(sys.argv[1],sys.argv[2],sys.argv[3])