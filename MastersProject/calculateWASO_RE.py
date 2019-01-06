import sys
import os
import numpy as np
from numpy import mean, sqrt, square
from utilities import  rms, find, WASO




def calculateWASO_RE(wake,minSleepTime,fs):
    wake = wake + 1 # convert it to 'up2down1' format ie if awake, wake ==2 else  wake==1
    minSleepTime = minSleepTime * 60 * fs # convert from minutes to datapoints

    # If they were never awake record number and duration at 0.
    if sum(wake == 2) == 0:
        WASO.sleepStart = 1
        WASO.num = 0
        WASO.dur = 0
        WASO.avgdur = 0
    elif sum(wake == 1) == 0: # If they were always awake record number and duration at NaN.
        WASO.sleepStart = None
        WASO.num = None
        WASO.dur = None
        WASO.avgdur = None
    else:
        sleepBreakPoints = np.insert(abs(np.diff(wake)), 0, 1)   # 1 when fall asleep/wake up
        
        runStart = find(sleepBreakPoints, lambda x: x==1) 
        #print("runStart 1",runStart)
        runLength = []
        for i in range(len(runStart)-1):
            runLength.append(runStart[i+1] - runStart[i])   # Assumes next break point is immediately after the last row
        
        last = len(wake)-(runStart[-1]+2)
        runLength.append(last)

        #print("runlength 1",runLength)
        nums = []
        for i in range(len(runLength)):
            nums.append(runLength[i] >= minSleepTime and wake[runStart[i]] == 1) 
        
        sleepStart = runStart[find(nums,lambda x: x == 1)[0]]
        WASO.sleepStart = sleepStart

        # RunStart is now all runs from start of sleep
        runStart = []
        runStart_lst = find(sleepBreakPoints[sleepStart:len(sleepBreakPoints)],lambda x: x == 1)
        for j in range(len(runStart_lst)):
            runStart.append(runStart_lst[j]  + sleepStart )
        #print("runStart 2",runStart)
        runLength = []
        for i in range(len(runStart)-1):
            runLength.append(runStart[i+1] - runStart[i])   # Assumes next break point is immediately after the last row
        
        last = len(wake)-(runStart[-1])
        runLength.append(last)
        #print("runLength 2",runLength)

        WASO.sleepStart = sleepStart
        WASO.num = sum(wake[runStart]==2)

        dur_ind = find(wake[runStart],lambda x: x == 2)
        dur =[]
        for i in range(len(dur_ind)):
            dur.append( runLength[dur_ind[i]])
        WASO.dur = sum(dur) /(fs*60)
        WASO.avgdur = mean(dur)/(fs*60)

        #print("WASO sleepStart",WASO.sleepStart)
        #print("WASO num ",WASO.num)
        #print("WASO dur",WASO.dur)
        #print("WASO avgdur",WASO.avgdur)
    return WASO
