import sys
import os
import numpy as np
import datetime
from numpy import sqrt, square
from utilities import Param, Output, nightData, WASO, sleepText, rms, find
from syncRE import syncRE
from getLMiPod import getLMiPod
from candidate_lms import candidate_lms
from scoreSleep import scoreSleep
from calculateArousal import calculateArousal
from periodic_lms import periodic_lms
from calculateWASO_RE import calculateWASO_RE


def resteaze_dash(left,right,subjectid):

    np.seterr(divide='ignore', invalid='ignore')

    params = init_params()
    output = init_output(subjectid)

    if os.path.exists(left):
        leftPath = os.path.splitext(left)[0]
        #leftFileNames = os.path.splitext(left)[1]
        ext = os.path.splitext(left)[1]

        print("leftpath: "+leftPath)
        #print("leftFileNames: "+leftFileNames)
    else:
        print("lefterror")
    if os.path.exists(right):
        
        rightPath = os.path.splitext(right)[0]
        #rightFileNames = os.path.splitext(right)[1]
        right_ext = os.path.splitext(right)[1]
        print("rightpath: " + rightPath)
        #print("rightFileNames: " + rightFileNames)

    else:
        print("righterror")

    
    #add code to read and process multiple csv's

    """ read data from csv files """
    bandData_left = np.genfromtxt(left,delimiter=',',skip_header=1)
    bandData_right = np.genfromtxt(right,delimiter=',',skip_header=1)

    """synching signals from two legs"""
    leftLeg,rightLeg = syncRE(bandData_left,bandData_right)

    output.up2Down1 = np.ones((leftLeg.shape[0],1)) 
    
    #################################################

    """calculating root-mean-square of the acclerometer movements for both legs"""
    output.lRMS = rms(leftLeg[:,[1,2,3]])
    output.rRMS = rms(rightLeg[:,[1,2,3]])

    #################################################
    
    """ compute LM(leg movements) """
    rLM = getLMiPod(params,output.rRMS,output.up2Down1)
    lLM = getLMiPod(params,output.lRMS,output.up2Down1)
    
    #################################################

    """ Start Patrick's standard scoring stuff """
    bCLM = candidate_lms(rLM,lLM,params)
    Arousal = calculateArousal(bCLM,leftLeg,rightLeg)
    output.Arousal = Arousal[Arousal[:,2]==1,:]
    bCLM[:,10] = Arousal[:,2]
    PLM, bCLM = periodic_lms(bCLM,params)
    #################################################
    PLM = np.asarray(PLM)
    
    """  score sleep/wake """
    output.wake = scoreSleep(params.fs,output.lRMS,PLM,bCLM)
    WASO = calculateWASO_RE(output.wake,params.minSleepTime,params.fs) # NEED TO UPDATE OUTPUT MATRICES AFTER HERE
    
    rLM[:,5] = output.wake[np.array(rLM[:,0],dtype=int)] + 1 # still using up2down1 format
    lLM[:,5] = output.wake[np.array(lLM[:,0],dtype=int)] + 1 # still using up2down1 format
    bCLM[:,5] = output.wake[np.array(bCLM[:,0],dtype=int)] + 1 # still using up2down1 format
    
    if len(PLM) != 0:
        PLM[:,5] = output.wake[np.array(PLM[:,0],dtype=int)] + 1  # still using up2down1 format
    
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
    
    #################################################
    """ Quantitative measures to output """

    output.TRT = (output.up2Down1.shape[0]/params.fs)/60
    output.TST = output.TRT - WASO.dur
    output.sleepEff = output.TST / output.TRT
    output.WASOnum = WASO.num
    output.WASOdur = WASO.dur
    output.WASOavgdur = WASO.avgdur


    if len(output.PLMS) != 0: #change this to !=0
        output.PI = sum( np.array(output.PLMS[:,8]==0,dtype=int) ) / (output.bCLM.shape[0]-1)
        output.PLMSArI = sum(output.PLMS[:,10])/(output.TST/60) # num plms arousals per hr of sleep

    if len(PLM) != 0:
        plm_5 = PLM[:,5] == 1 
        plm_8 = PLM[:,8] == 0
        plm_combi = PLM[plm_5|plm_8,3]

        output.avglogPLMSIMI = np.mean(np.log(plm_combi))
        output.stdlogPLMSIMI = np.std(np.log(plm_combi))

        output.avgPLMSDuration = np.mean(PLM[plm_5,2])
        output.stdPLMSDuration = np.std(PLM[plm_5,2])
    
        output.PLMhr = PLM.shape[0]/(output.TRT/60)
        output.PLMShr = sum(PLM[:,5]==1)/(output.TST/60)
        output.PLMWhr = sum(PLM[:,5]==2)/((output.TRT-output.TST)/60)

        output.PLMnum = len(PLM)
        output.PLMSnum = sum(PLM[:,5]==1)
        output.PLMWnum = sum(PLM[:,6]==2)

    if len(bCLM) != 0:
        output.avglogCLMSIMI = np.mean(np.log(bCLM[bCLM[:,5]==1,3]))
        output.stdlogCLMSIMI = np.std(np.log(bCLM[bCLM[:,5]==1,3]))

        output.avgCLMSDuration = np.mean(bCLM[bCLM[:,5]==1,2])
        output.stdCLMSDuration = np.std(bCLM[bCLM[:,5]==1,2])

        output.CLMhr = bCLM.shape[0]/(output.TRT/60)
        output.CLMShr = sum(bCLM[:,5]==1)/(output.TST/60)
        output.CLMWhr = sum(bCLM[:,5]==2)/((output.TRT-output.TST)/60)

        output.CLMnum = bCLM.shape[0]
        output.CLMSnum = sum(bCLM[:,5]==1)
        output.CLMWnum = sum(bCLM[:,5]==2)

        output.GLM = bCLM[bCLM[:,4]==0,:]

    #print("avglogCLMSIMI ",output.avglogCLMSIMI)
    #print("stdlogCLMSIMI ",output.stdlogCLMSIMI)
    #print("avgCLMSDuration ",output.avgCLMSDuration)
    #print("stdCLMSDuration ",output.stdCLMSDuration)
    
    #print("avglogPLMSIMI ",output.avglogPLMSIMI)
    #print("stdlogPLMSIMI ",output.stdlogPLMSIMI)
    #print("avglogPLMSIMI ",output.avgPLMSDuration)
    #print("stdlogPLMSIMI ",output.stdPLMSDuration)
    
    #print("CLMhr ",output.CLMhr)
    #print("CLMShr ",output.CLMShr)
    #print("CLMWhr ",output.CLMWhr)
    
    #print("PLMhr ",output.PLMhr)
    #print("PLMShr ",output.PLMShr)
    #print("PLMWhr ",output.PLMWhr)
    
    #print("CLMnum ",output.CLMnum)
    #print("CLMSnum ",output.CLMSnum)
    #print("CLMWnum ",output.CLMWnum)        
    
    #print("PLMSArI ",output.PLMSArI)
    #print("GLM ",output.GLM.shape)

    #some more stuff needed for report 
    output.intervalSize = 1
    output.fs = params.fs
    output.pos = 2 * np.ones(leftLeg.shape[0]) # ALL BACKSIDE RIGHT NOW SINCE NO POS VECTOR YET
    output.ArI = output.Arousal.shape[0]/(output.TST/60)
    output.PLMSI = output.PLMShr
    leftStart = datetime.datetime.fromtimestamp(leftLeg[0,3] / 1000)
    leftStart = [leftStart.year, leftStart.month, leftStart.day, leftStart.hour, leftStart.minute, leftStart.second]
    output.sleepStart = np.mod(leftStart[3]*60 + leftStart[4] - 12*60 , 24*60)
    output.sleepEnd = output.sleepStart + output.TRT
    output.date = str(leftStart[1])+ '/' +str(leftStart[2])+ '/'+ str(np.mod(leftStart[0],100))

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

    print('PatientID: '+ output.fileName)
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

def init_params():
    # Initialize default parameters, if we want to allow them to change, modify here.
    params = Param()

    params.iLMbp='on'
    params.morphologyCriteria='on'

    # this is for the RestEaZe data.
    #params.lowThreshold=0.005;
    #params.highThreshold=0.01;
    params.lowThreshold = 0.05
    params.highThreshold = 0.1

    params.minLowDuration = 0.5
    params.minHighDuration = 0.5
    params.minIMIDuration = 10
    params.maxIMIDuration = 90
    params.maxCLMDuration = 10
    
    #sampling rate for the RestEaZe data
    #params.fs=50;
    params.fs = 25
    params.minNumIMI = 3
    params.minSleepTime = 5
    params.maxOverlapLag = 0.5
    params.maxbCLMOverlap = 4
    params.maxbCLMDuration = 15
    params.side = 'both'
    print("params initialized...")

    return params

if __name__ == '__main__':
    resteaze_dash(sys.argv[1],sys.argv[2],sys.argv[3])