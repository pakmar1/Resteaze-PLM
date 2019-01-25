import sys
import os
import numpy as np
import matplotlib.pyplot as plt

def generateClinicalReport_RE(nightData):
    if len(nightData)>5:
        print("Error! selected more than 5 nights")
        return
    
    for i in range(len(nightData)):
        input = nightData[i]

        input.numIntervals = np.floor(input.TRT/input.intervalSize) # % Minutes
        input.shiftX_RETable = input.numIntervals * 4/3
        input.shiftY_RETable = 1.5 # put the numbers in the middle

        input.shiftX_sleepPeriod = -5/419 * input.numIntervals
        input.shiftY_sleepPeriod = 1.5 # put the lines in the middle
    
        input.shiftX_restless = -5/419 * input.numIntervals
        input.barHeight_restless = 2 # put the numbers in the middle
    
        input.shiftX_PLM = input.numIntervals * 1/3
        input.barHeight_PLM = 1 # put the numbers in the middle
    
        numIntervals = np.floor(input.TRT/input.intervalSize); # Minutes
        intervalSize = input.intervalSize

        plt.subplot(8,1,i)

        