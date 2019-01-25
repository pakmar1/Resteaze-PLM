import sys
import os
import numpy as np
from numpy import mean, sqrt, square
from utilities.utilities import  rms, find


def scoreSleep(fs,RMS,LM,GLM):

    #Calculate numLMper10epochs - the number of GLM+LM per 10 epochs
    dataPtsPerWindow = 30 * 10 * fs
    numWindows = np.ceil(RMS.shape[0]/dataPtsPerWindow)
    LM = np.array(LM)
    GLM = np.array(GLM)

    if LM.size != 0:
        b = np.concatenate((LM[0:LM.shape[0],0], GLM[0:GLM.shape[0],0]), axis=0)
    else:
        b = GLM[0:GLM.shape[0],0]

    xy = np.arange(0,numWindows*dataPtsPerWindow+1,dataPtsPerWindow)
    numLMper10epochs = np.histogram(b,xy)[0]

    # wakeLM is a logical vector indicating whether there is at least 1 GLM,LM in
    # the 10 epochwindow that the current dataPt is in (0=there is LM, 1= no LM) 1 corresponds to wake.
    wakeLM = np.zeros(RMS.shape[0])
    
    for i in range(0,int(numWindows)-1):
        start = (i)*dataPtsPerWindow+1
        end = (i+1)*dataPtsPerWindow
        wakeLM[start-1:end] = numLMper10epochs[i] * np.ones(dataPtsPerWindow)
    start = end+1
    end = RMS.shape[0]
    
    wakeLM[start-1:end] = numLMper10epochs[int(numWindows)-1] * np.ones(np.mod(RMS.shape[0],dataPtsPerWindow))
    

    wakeLM = wakeLM == 0

    # Acceleration stuff
    AccelRMS10epochmax = np.zeros(RMS.shape[0])
    for i in range(0,int(numWindows)-1):
        start = (i)*dataPtsPerWindow+1
        end = (i+1)*dataPtsPerWindow
        AccelRMS10epochmax[start-1:end] = np.max(RMS[start-1:end]) * np.ones(dataPtsPerWindow)
    start = end + 1
    end = RMS.shape[0]
    AccelRMS10epochmax[start-1:end] = np.max(RMS[(int(numWindows)-1)*dataPtsPerWindow+1:int(numWindows)*dataPtsPerWindow]) * np.ones(np.mod(RMS.shape[0],dataPtsPerWindow))
    
    AccelRMS10epochmax = AccelRMS10epochmax > 0.15
    # if the max in that 10 epoch window is <.15 then there is no activity and
    # we record sleep, vice versa for wake

    # if the max in the 2 epoch window is >.5 then we record wake, even if prior
    # LM criteria recorded sleep.
    dataPtsPerWindow = 30 * 2 * fs
    numWindows = np.ceil(RMS.shape[0]/dataPtsPerWindow)
    AccelRMS2epochmax = np.zeros(RMS.shape[0])
    for i in range(0,int(numWindows)-1):        
        start = (i)*dataPtsPerWindow+1
        end = (i+1)*dataPtsPerWindow
        AccelRMS2epochmax[start-1:end] = np.max(RMS[start-1:end]) * np.ones(dataPtsPerWindow)
    start = end + 1
    end = RMS.shape[0]
    AccelRMS2epochmax[start-1:end] = np.max(RMS[(int(numWindows)-1)*dataPtsPerWindow+1:int(numWindows)*dataPtsPerWindow]) * np.ones(np.mod(RMS.shape[0],dataPtsPerWindow))
    AccelRMS2epochmax = AccelRMS2epochmax > 0.5

    # Only if <80% of epochs have LM, include accelerometer criteria
    percentLM = 1 - (sum(wakeLM)/wakeLM.shape[0])

    if percentLM < 0.8:
        wake = (wakeLM&AccelRMS10epochmax)| AccelRMS2epochmax
    else:
        wake = wakeLM

    return wake

