import sys
import os
import numpy as np

"""
 This function synchronizes each leg
 Only points with very close time stamps are kept. This assumes sampling
 rate is constant
"""
def syncRE(leftLeg,rightLeg):
    #print("in syncRE")
    leftLegsize = leftLeg.shape[0]
    rightLegsize = rightLeg.shape[0]
    
    #print("leftsize ",leftLegsize,"leftLeg " , leftLeg[:,3])
    #print("rightsize ",rightLegsize,"rightLeg ",rightLeg[:,3])

    # start of sync
    if leftLeg[0,3] > rightLeg[0,3]:
        rightstart = 0
        for i in range(leftLegsize-1,-1,-1):
            if leftLeg[0,3] <= rightLeg[i,3]:
                rightstart = i
        
        if rightstart > 0:
            rightLeg = rightLeg[rightstart:,:]
        else:
            rightstart = None

    elif leftLeg[0,3] < rightLeg[0,3]:
        leftstart = 0
        for i in range(rightLegsize-1,-1,-1):
            if leftLeg[i,3] >= rightLeg[0,3]:
                leftstart = i
        
        if leftstart > 0:
            leftLeg = leftLeg[leftstart:,:]
        else:
            leftstart = None
    # end of sync
    
    #Just make the dimensions equal since sampling rate is the same and start time is synched
    leftLegsize = leftLeg.shape[0]
    rightLegsize = rightLeg.shape[0]

    #Delete rows that come before the sync time
    if leftLegsize > rightLegsize:
        leftLeg = leftLeg[0:rightLegsize,:]
        leftminusright = leftLeg[rightLegsize-1,3] - rightLeg[rightLegsize-1,3]
    elif leftLegsize < rightLegsize:
        rightLeg = rightLeg[0:leftLegsize,:]
        leftminusright = leftLeg[leftLegsize-1,3] - rightLeg[leftLegsize-1,3]
    #print("legs data synchronized...")
    #print("leftlegSize ",leftLeg,"rightLegSize ",rightLeg)
    return leftLeg,rightLeg
