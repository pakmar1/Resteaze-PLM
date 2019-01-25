import pythoncode
import matlab.engine as matengine
import os
import subprocess



path = 'input'
os.chdir(path)
files = []
for p,n,f in os.walk(os.getcwd()):
    for a in f:
        a = str(a)
        if a.endswith('.csv'):
            files.append(a)

os.chdir('..')
for i in range(len(files)):
    print()
    print("input file:"+files[i])
    """ running matlab code """
    print("********************************************************************************************************************")
    print("**********************************************************")
    print("Starting MATLAB engine...")
    print()
    eng = matengine.start_matlab()
    eng.cd('matlabcode')
    print("Running MATLAB code...")

    #printing output
    print("MATLAB output...")
    eng.resteaze_dash('../input/'+files[i],'../input/'+files[i],'../output/matlab_'+files[i],nargout = 0)
    print()

    """ running python code on same file """
    print("**********************************************************")
    print("Starting PYTHON engine...")
    print()
    subprocess.call("python pythoncode/resteaze_dash.py  input/"+files[i] + " input/"+files[i] + " output/python_"+ files[i]+"", shell=True)
    print("**********************************************************")
    print("********************************************************************************************************************")
