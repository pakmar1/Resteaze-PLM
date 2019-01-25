import sys
import os
import csv
import pandas
import numpy as np
from numpy import mean, sqrt, square

class Param:
    pass

class Output:
    pass

class nightData:
    pass

class WASO:
    pass


""" function to convert number to time"""
def sleepText(sleepTime):
    sleepHr = int(np.mod(np.floor(sleepTime/60)+12,24))
    sleepMin = int(np.floor(sleepTime % 60))
    if sleepHr < 10:
        sleepHr = '0'+str(sleepHr)
    else:
        sleepHr = str(sleepHr)

    if sleepMin < 10:
        sleepMin = '0'+str(sleepMin)
    else:
        sleepMin = str(sleepMin)

    output = sleepHr+':'+sleepMin
    return output


def rms(x):
    y = sqrt(mean(square(x),axis=1))
    return y

def find(a, func):
    return [i for (i, val) in enumerate(a) if func(val)]

    
