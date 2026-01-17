'''
Created on Jul 17, 2024

@author: avo
'''
import sys
import os
# Get the directory where the current script is located
script_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(script_dir)
# Add custom module folders relative to the script location
sys.path.insert(0, os.path.join(parent_dir, 'Mylogging'))
sys.path.insert(0, os.path.join(parent_dir, 'FeatureSelection'))
sys.path.insert(0, os.path.join(parent_dir, 'StatisticalValidation'))

#Logging module
import mylogging

##Libraries for data manipulation
import pandas as pd

# Module for important features selection
import features_selection

# %%%%%%%%%%%%%
name = "Main"
# %%%%%%%%%%%%%

##Data prep

# Get SLURM environment variables
job_id = os.environ.get("SLURM_JOB_ID", "default")
task_id = os.environ.get("SLURM_ARRAY_TASK_ID")

# Build the log subfolder name
if task_id:
    log_subdir = f"{job_id}_{task_id}"
else:
    log_subdir = job_id

# Define the full log path
log_dir = f"logs/ML/{log_subdir}"

# Setup separate loggers for your different tasks
logger_functions = mylogging.setup_logger("ML.Functions", f"{log_dir}/__Functions__.log")
logger_write = mylogging.setup_logger("ML.WriteToFile", f"{log_dir}/__WriteToFile__.log")
logger_upload = mylogging.setup_logger("ML.UploadFile",f"{log_dir}/__uploadFile__.log")
logger_dfChecks = mylogging.setup_logger("ML.dfChecks",f"{log_dir}/__DataFrameChecks__.log")
logger_stats = mylogging.setup_logger("ML.Statistics",f"{log_dir}/__Stats__.log")

# the train/validation data contains only numerical entries and 1 categorical #entry for the Diagnostic_status
dataframe = pd.DataFrame()

logger_upload.info("Inside the "+name+" module")
try:
    pd.options.display.float_format = '{:.6f}'.format
    csv_file = sys.argv[1]
    if not os.path.exists(csv_file):
        logger_upload.error(f"File does not exist: {csv_file}")
        sys.exit(2)
    # csv_file = "/Users/avo/Eclipse/workspace/cfDNA-Biomarkers/CNA_compositions/2025-05-19_19-35/importantRegions_disease-severe.csv"
    print("CSV path:", csv_file)
    dataframe = pd.read_csv(csv_file,sep=',',header=0,index_col=False)
    # print("Columns:", dataframe.columns)
except Exception as e:
    logger_upload.error("An exception occurred:", exc_info=True)

n_col = len(dataframe.columns)

dataframe.head()

#dropping any column with null values
logger_dfChecks.info("Inside the "+name+" module")
try:
    if sum(dataframe.iloc[:,0:(n_col-1)].isnull().any()) != 0:
        df = (dataframe.iloc[:,0:(n_col-1)]).dropna(axis=1)
        df['Diagnostic_status'] = dataframe['Diagnostic_status']
    elif sum(dataframe.iloc[:,0:(n_col-1)].isnull().any()) == 0 :
        df = dataframe
except Exception as e:
    logger_dfChecks.error("An exception occurred:", exc_info=True)

# Save the original column names
original_columns = df.columns.astype(str)

# Save mapping before renaming
name_map = dict(zip(original_columns.str.replace("-", "_"), original_columns))

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
features_selection.calc_stat_sign_feat(df,sys.argv[2],int(sys.argv[3]),name_map,logger_functions, logger_write,logger_stats)


