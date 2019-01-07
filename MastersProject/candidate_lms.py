import sys
import os
import numpy as np
from numpy import mean, sqrt, square
from utilities import  rms, find

"""
 Determine candidate leg movements for PLM from monolateral LM arrays. If
 either rLM or lLM is empty ([]), this will return monolateral candidates,
 otherwise if both are provided they will be combined according to current
 WASM standards. Adds other information to the CLM table, notably
 breakpoints to indicate potential ends of PLM runs, sleep stage, etc. Of
 special note, the 13th column of the output array indicates which leg the
 movement is from: 1 is right, 2 is left and 3 is bilateral.


 inputs:
   - rLM - array from right leg (needs start and stop times)
   - lLM - array from left leg

"""

def candidate_lms(rLM,lLM,params):
    CLM=[]
    #print("lLM ",lLM.shape)
    #print("rLM ",rLM.shape)
    print("CLM sha before",lLM.shape, rLM.shape)

    if rLM.size != 0 and lLM.size != 0:
        #print("both full")
        # Reduce left and right LM arrays to exclude too long movements, but add
        # breakpoints to the following movement
        rLM[:,2] = (rLM[:,1]-rLM[:,0])/params.fs
        lLM[:,2] = (lLM[:,1]-lLM[:,0])/params.fs

        rLM = rLM[rLM[:,2]>=0.5,:]
        lLM = lLM[lLM[:,2]>=0.5,:]

        rLM[rLM[:,2]>params.maxCLMDuration,8] = 4
        lLM[lLM[:,2]>params.maxCLMDuration,8] = 4

        # Combine left and right and sort.
        CLM = rOV2(lLM,rLM,params.fs)
        #print("CLM after rOV2")
        #print(CLM.shape)
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
    for i in range(len(contains_too_long)-1):
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
        #print("CLM out of candidate_lms(): ",CLM.shape)
    return CLM

def rOV2(lLM,rLM,fs):
    #Combine bilateral movements if they are separated by < 0.5 seconds

    # zeros for column 11 and 12
    rLM = np.insert(rLM,10,values = np.zeros(rLM.shape[0]),axis=1)
    lLM = np.insert(lLM,10,values = np.zeros(lLM.shape[0]),axis=1)
    rLM = np.insert(rLM,11,values = np.zeros(rLM.shape[0]),axis=1)
    lLM = np.insert(lLM,11,values = np.zeros(lLM.shape[0]),axis=1)

    #combine and sort LM arrays
    rLM = np.insert(rLM,12,values = np.ones(rLM.shape[0]),axis=1)
    lLM = np.insert(lLM,12,values = np.full((lLM.shape[0]),2),axis=1)

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
    print("CLM rvo2",CLM.shape)
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
            CLMt[rc][:] = CLM[rl][:]
            rc = rc + 1
        elif rl < CLM.shape[0]-1:
            CLM[rl+1,3] = CLM[rl+1,3]+CLM[rl,3]

    CLMt = getIMI(CLMt,params.fs)
    return CLMt