from revoscalepy import RxInSqlServer, RxLocalSeq, rx_set_compute_context, RxSqlServerData
from microsoftml import rx_predict as ml_predict

from lung_cancer.connection_settings import get_connection_string, TABLE_CLASSIFIERS, TABLE_FEATURES, TABLE_PATIENTS, FASTTREE_MODEL_NAME
from lung_cancer.lung_cancer_utils import retrieve_model

# Connect to SQL Server and set compute context
connection_string = get_connection_string()
sql = RxInSqlServer(connection_string=connection_string)
local = RxLocalSeq()
rx_set_compute_context(local)

# Specify patient to make prediction for
PatientIndex = 20

# Select patient data
query = "SELECT TOP(1) * FROM {} AS t1 INNER JOIN {} AS t2 ON t1.patient_id = t2.patient_id WHERE t2.idx = {}".format(TABLE_FEATURES, TABLE_PATIENTS, PatientIndex)
patient_sql = RxSqlServerData(sql_query=query, connection_string=connection_string)

# Get classifier
classifier = retrieve_model(TABLE_CLASSIFIERS, connection_string, FASTTREE_MODEL_NAME)

# Make Prediction on a single patient
predictions = ml_predict(classifier, data=patient_sql, extra_vars_to_write=["label", "patient_id"])

print("The probability of cancer for patient {} with patient_id {} is {}%".format(PatientIndex, predictions["patient_id"].iloc[0], predictions["Probability"].iloc[0]*100))
if predictions["label"].iloc[0] == 0:
    print("Ground Truth: This patient does not have cancer")
else:
    print("Ground Truth: This patient does have cancer")
