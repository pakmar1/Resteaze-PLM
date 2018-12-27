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

    bandData_left = np.genfromtxt(left,delimiter=',',skip_header=1)
    #print(bandData_left)
    bandData_right = np.genfromtxt(right,delimiter=',',skip_header=1)

    #print(bandData_right.shape[0])
    #print(bandData_right[0][3])

    leftLeg,rightLeg = syncRE(bandData_left,bandData_right)
    print("leftleg,rightleg after syncRE: ")
    print(leftLeg.shape[0])
    print(rightLeg.shape[0])

    output.up2down1 = np.ones((leftLeg.shape[0],1)) 
    
    print("dimension going in for rms")
    print(leftLeg[:,[1,2,3]].shape)

    output.lRMS = rms(leftLeg[:,[1,2,3]])
    output.rRMS = rms(rightLeg[:,[1,2,3]])

    print("output of rms:")
    print(output.lRMS.shape)
    print(output.rRMS.shape)


def init_output(subjectid):
    output = Output()
    output.filename = subjectid
    output.up2down1 = []
    output.rRMS =0
    output.lRMS =0
    return output

def init_params():
    # Initialize default parameters, if we want to allow them to change, modify here.
    params = Param()

    params.iLMbp='on'
    params.morphologyCriteria='on'

    #%% this is for the RestEaZe data.
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

if __name__ == '__main__':
    resteaze_dash(sys.argv[1],sys.argv[2],sys.argv[3])