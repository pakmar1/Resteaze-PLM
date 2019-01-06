import sys
import os
import numpy as np
from numpy import mean, sqrt, square
from utilities import  rms, find



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

