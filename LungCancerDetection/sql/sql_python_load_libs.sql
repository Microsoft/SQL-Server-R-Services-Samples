
execute sp_execute_external_script 
@language = N'python',
@script = N'
import sys,os


import numpy as np
import dicom
import glob
from sklearn import cross_validation
from matplotlib import pyplot as plt
import pandas as pd
import time
import pkg_resources
import cv2
import lung_cancer

#print("PYTHONPATH={}".format(os.environ["PYTHONPATH"]))
print("PATH={}".format(os.environ["PATH"]))


print("*********************************************************************************************")
print(sys.version)
print("!!!Hello World!!!")
print(os.getcwd())
version_pandas = pkg_resources.get_distribution("pandas").version
print("Version pandas: {}".format(version_pandas))
print("Version OpenCV: {}".format(cv2.__version__))
print("Version Lung Cancer: {}".format(lung_cancer.VERSION))

print("*********************************************************************************************")



'

