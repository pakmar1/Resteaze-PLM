import sys
import os
import numpy as np
import datetime
from numpy import mean, sqrt, square
from utilities import Param, Output, nightData, WASO, sleepText, rms, find
from syncRE import syncRE
from getLMiPod import getLMiPod
from candidate_lms import candidate_lms
from scoreSleep import scoreSleep
from calculateArousal import calculateArousal
from periodic_lms import periodic_lms
from calculateWASO_RE import calculateWASO_RE

########################################################################################

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
    
    #################################################

    """calculating root-mean-square of the acclerometer movements for both legs"""
    output.lRMS = rms(leftLeg[:,[1,2,3]])
    output.rRMS = rms(rightLeg[:,[1,2,3]])

    #print("output of rms:")
    #print(output.lRMS.shape)
    #print(output.rRMS.shape)
    #################################################
    
    """ compute LM(leg movement)"""
    rLM = getLMiPod(params,output.rRMS,output.up2Down1)
    lLM = getLMiPod(params,output.rRMS,output.up2Down1)
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
    WASO = calculateWASO_RE(output.wake,params.minSleepTime,params.fs) # NEED TO UPDATE OUTPUT MATRICES AFTER HERE
    
    rLM[:,5] = output.wake[np.array(rLM[:,0],dtype=int)]+1 # still using up2down1 format
    lLM[:,5] = output.wake[np.array(lLM[:,0],dtype=int)]+1 # still using up2down1 format
    bCLM[:,5] = output.wake[np.array(bCLM[:,0],dtype=int)]+1 # still using up2down1 format
    #print("bcLM ",bCLM)
    if len(PLM) != 0:
        PLM[:,5] = output.wake[np.array(PLM[:,0],dtype=int)]+1 # still using up2down1 format
        #print("PLM 5",PLM)
    else:
        PLM = []
    #################################################
    """ Matrices to output """
    output.rLM = rLM
    output.lLM = lLM
    
    output.bCLM = bCLM
    output.PLM = PLM
    output.PLMS = []
    if len(PLM) != 0:
        xx = find(PLM[:,5],lambda x: x==1)
        output.PLMS = PLM[xx,:]
        print("output.PLMS ",output.PLMS)
    
    #################################################
    """ Quantitative measures to output """

    output.TRT = output.up2Down1.shape[0]/(params.fs*60)
    output.TST = output.TRT - WASO.dur
    output.sleepEff = output.TST / output.TRT
    output.WASOnum = WASO.num
    output.WASOdur = WASO.dur
    output.WASOavgdur = WASO.avgdur
    if len(output.PLMS) != 0: #change this to !=0
        output.PI = sum( np.array(output.PLMS[:,8]==0,dtype=int) ) / (output.bCLM.shape[0]-1)

    output.avglogCLMSIMI = mean(np.log(bCLM[bCLM[:,5]==1,3]))
    output.stdlogCLMSIMI = np.std(np.log(bCLM[bCLM[:,5]==1,3]))

    #print("avglogCLMSIMI ",output.avglogCLMSIMI)
    #print("stdlogCLMSIMI ",output.stdlogCLMSIMI)
    
    output.avgCLMSDuration = mean(bCLM[bCLM[:,5]==1,3])
    output.stdCLMSDuration = np.std(bCLM[bCLM[:,5]==1,3])
    #print("avgCLMSDuration ",output.avgCLMSDuration)
    #print("stdCLMSDuration ",output.stdCLMSDuration)
    
    if len(PLM) != 0:
        plm_5 = PLM[:,5] == 1 
        plm_8 = PLM[:,8] == 0
        plm_combi = PLM[plm_5|plm_8,3]

        output.avglogPLMSIMI = mean(np.log(plm_combi))
        output.stdlogPLMSIMI = np.std(np.log(plm_combi))

        output.avgPLMSDuration = mean(PLM[PLM[:,5]==1,2])
        output.stdPLMSDuration = np.std(PLM[PLM[:,5]==1,2])
        

    #print("avglogPLMSIMI ",output.avglogPLMSIMI)
    #print("stdlogPLMSIMI ",output.stdlogPLMSIMI)

    #print("avglogPLMSIMI ",output.avgPLMSDuration)
    #print("stdlogPLMSIMI ",output.stdPLMSDuration)

    output.CLMhr = bCLM.shape[0]/(output.TRT/60)
    output.CLMShr = sum(bCLM[:,5]==1)/(output.TST/60)
    output.CLMWhr = sum(bCLM[:,5]==2)/((output.TRT-output.TST)/60)
    #print("CLMhr ",output.CLMhr)
    #print("CLMShr ",output.CLMShr)
    #print("CLMWhr ",output.CLMWhr)

    if len(PLM) != 0:
        output.PLMhr = len(PLM)/(output.TRT/60)
        output.PLMShr = sum(PLM[:,5]==1)/(output.TST/60)
        output.PLMWhr = sum(PLM[:,5]==2)/((output.TRT-output.TST)/60)
    #print("PLMhr ",output.PLMhr)
    #print("PLMShr ",output.PLMShr)
    #print("PLMWhr ",output.PLMWhr)

    output.CLMnum = bCLM.shape[0]
    output.CLMSnum = sum(bCLM[:,5]==1)
    output.CLMWnum = sum(bCLM[:,5]==2)
    #print("CLMnum ",output.CLMnum)
    #print("CLMSnum ",output.CLMSnum)
    #print("CLMWnum ",output.CLMWnum)
    if len(PLM) != 0: 
        output.PLMnum = len(PLM)
        output.PLMSnum = sum(PLM[:,5]==1)
        output.PLMWnum = sum(PLM[:,6]==2)

        output.PLMSArI = sum(output.PLMS[:,10])/(output.TST/60) # num plms arousals per hr of sleep
    
    output.GLM = bCLM[bCLM[:,4]==0,:]
    #print("PLMSArI ",output.PLMSArI)
    #print("GLM ",output.GLM.shape)

    # some more stuff needed for report %%%%%%%%%%%

    output.intervalSize = 1
    #output.GLM = bCLM[bCLM[:,4]==0,:)
    #output.Arousal = output.Arousal
    output.fs = params.fs
    output.pos = 2 * np.ones(leftLeg.shape[0]) #%%%%%%%%%%%%%%%%%%%%% ALL BACKSIDE RIGHT NOW SINCE NO POS VECTOR YET
    output.ArI = output.Arousal.shape[0]/(output.TST/60)
    output.PLMSI = output.PLMShr
    #print("intervalSize ",output.intervalSize)
    #print("pos ",output.pos)
    #print("ArI ",output.ArI)
    #print("PLMSI ",output.PLMSI)
    #print("Arousal ",output.Arousal)
    leftStart = datetime.datetime.fromtimestamp(leftLeg[0,3] / 1000)
    leftStart = [leftStart.year, leftStart.month, leftStart.day, leftStart.hour, leftStart.minute, leftStart.second]
    output.sleepStart = np.mod(leftStart[3]*60 + leftStart[4]- 12*60 , 24*60)
    print("sleepStart ",output.sleepStart)
    output.sleepEnd = output.sleepStart + output.TRT
    print("sleepEnd ",output.sleepEnd)
    output.date = str(leftStart[1])+ '/' +str(leftStart[2])+ '/'+ str(np.mod(leftStart[0],100))
    print("date ",output.date)

    output.SQ = 0
    output.SQhrs = []

    nightData = output

    fileID = open(output.fileName+'.txt','w')
    fileID.write('PatientID: '+ output.fileName+'\n')
    fileID.write('Record Start: '+ sleepText(nightData.sleepStart)+'\n')
    fileID.write('Record Stop: ' + sleepText(nightData.sleepEnd)+'\n')
    fileID.write('Sleep Efficiency:  '+ '{:.2f}'.format(nightData.sleepEff)+'\n')
    fileID.write('Total Sleep Time:  '+ '{:.2f}'.format(nightData.TST)+'\n')
    fileID.write('PLMS/hr:  '+ '{:.2f}'.format(nightData.PLMShr)+'\n')
    fileID.write('Arousals/hr:  '+ '{:.2f}'.format(nightData.ArI)+'\n')
    fileID.write('Sleep Quality:  ' + '{:.2f}'.format(nightData.SQ)+'\n')
    fileID.write('WASO: '+ '{:.2f}'.format(nightData.WASOdur)+'\n')
    fileID.write('Sleep_quality_per_hr :')
    for i in range(len(nightData.SQhrs)):
        fileID.write(fileID+': '+'{:.2f}'.format(nightData.SQhrs[0,i])+'\n')
    fileID.close()

    print('PatientID: '+output.fileName)
    print('Record Start: '+ sleepText(nightData.sleepStart))
    print('Record Stop: ' + sleepText(nightData.sleepEnd))
    print('Sleep Efficiency:  '+ str(nightData.sleepEff))
    print('Total Sleep Time:  '+ str(nightData.TST))
    print('PLMS/hr:  '+ str(nightData.PLMShr))
    print('Arousals/hr:  '+ str(nightData.ArI))
    print('Sleep Quality:  ' + str(nightData.SQ))
    print('WASO: '+ str(nightData.WASOdur))
    """
    fprintf(fileID,'Sleep_quality_per_hr : ')
    for ii=1:size(nightData(i).SQhrs,2)
        fprintf(fileID, '%.2f ', nightData(i).SQhrs(1,ii));
    end"""
    
########################################################################################

def init_output(subjectid):
    output = Output()
    output.fileName = subjectid
    output.PI = 0

    output.avglogCLMSIMI = None
    output.stdlogCLMSIMI = None
    output.avgCLMSDuration = None
    output.stdCLMSDuration = None

    output.avglogPLMSIMI = None
    output.stdlogPLMSIMI = None
    output.avgPLMSDuration = None 
    output.stdPLMSDuration = None
    
    output.CLMhr = 0
    output.CLMShr = 0
    output.CLMWhr = 0
    output.PLMhr = 0
    output.PLMShr = 0
    output.PLMWhr = 0

    output.CLMnum = 0
    output.CLMSnum = 0
    output.CLMWnum = 0
    output.PLMnum = 0
    output.PLMSnum = 0
    output.PLMWnum = 0

    output.PLMSArI = 0
    return output
########################################################################################

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
########################################################################################


########################################################################################
########################################################################################
""" syncRE """
########################################################################################

########################################################################################
########################################################################################




########################################################################################
########################################################################################
""" getLMiPod calculation """
########################################################################################
"""
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

 #This Function finds the closest next (sequential) run from the current
 #position.  It does include prior runs.  If there is no run it returns a
 #distance of -1, otherwise it returns the distance to the next run.  It
 #will also return the length of that run.  If there is no run it returns a
 #length of -1.
 
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
"""
########################################################################################
########################################################################################




########################################################################################
########################################################################################
""" candidate_lms():"""
##########################################################################################
"""
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

"""
##########################################################################################
##########################################################################################


##########################################################################################
##########################################################################################
""" calculating Arousal """
##########################################################################################

##########################################################################################
##########################################################################################


##########################################################################################
##########################################################################################
""" periodic_lms()::"""
##########################################################################################
"""
%% PLM = periodic_lms(CLM,params)
%  find periodic leg movements from the array of CLM. Can either ignore
%  intervening LMs or add breakpoints. Contains subfunctions for ignoring
%  iLMs, restructuring breakpoint locations to find PLM runs and marking
%  the CLM which occur in periodic series.

% Create CLMt array of all CLM with IMI greater than the minimum allowable
% if intervening lm option is not selected, we remove CLMs whose IMI are
% too short. Really, new standards say that these should always be
% breakpoint, so the first case is only for posterity. """

##########################################################################################
##########################################################################################


##########################################################################################
##########################################################################################

##########################################################################################
##########################################################################################

##########################################################################################
##########################################################################################
""" 
%WASO calculates the number of awakenings and total wake-after-sleep-onset duration.
%
%inputs (default values):
%up2Down1=whether they are in sleep or not
%minSleepTime=5 minutes
%fs=20Hz
%
%outputs:
%WASO.sleepStart=datapoint where sleep begins
%WASO.num=number of times wake after sleep began
%WASO.dur=total duration of wake after sleep began
%WASO.avgdur=average duration of each waking period
"""

##########################################################################################
##########################################################################################



if __name__ == '__main__':
    resteaze_dash(sys.argv[1],sys.argv[2],sys.argv[3])