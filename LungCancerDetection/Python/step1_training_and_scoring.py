import sys
from revoscalepy import RxSqlServerData, RxInSqlServer, RxLocalSeq, rx_set_compute_context, rx_data_step
from microsoftml import rx_fast_trees
from microsoftml import rx_predict as ml_predict

from lung_cancer.lung_cancer_utils import insert_model, create_formula, roc, train_test_split
from lung_cancer.connection_settings import get_connection_string, TABLE_PATIENTS, TABLE_CLASSIFIERS, TABLE_FEATURES, TABLE_TRAIN_ID, TABLE_PREDICTIONS, FASTTREE_MODEL_NAME

print("Starting routine")

# Set recursion limit to be slightly larger to accommodate larger formulas (which are paresed recursively)
print("Old recursion limit: ", sys.getrecursionlimit())
sys.setrecursionlimit(1500)
print("New recursion limit: ", sys.getrecursionlimit())

# Connect to SQL Server and set compute context
connection_string = get_connection_string()
sql = RxInSqlServer(connection_string = connection_string)
local = RxLocalSeq()
rx_set_compute_context(local)

# Train Test Split
print("Performing Train Test Split")
p = 80
train_test_split(TABLE_TRAIN_ID, TABLE_PATIENTS, p, connection_string=connection_string)

# Point to the SQL table with the training data
column_info = {"label": {"type": "numeric"}}
query = "SELECT * FROM {} WHERE patient_id IN (SELECT patient_id FROM {})".format(TABLE_FEATURES, TABLE_TRAIN_ID)
train_sql = RxSqlServerData(sql_query=query, connection_string=connection_string, column_info=column_info)

# Create formula
formula = create_formula(train_sql)
print("Formula:", formula)

# Fit a classification model
rx_set_compute_context(local)   # TODO: rx_fast_trees not working in sql context. Change to sql later
classifier = rx_fast_trees(formula=formula,
                           data=train_sql,
                           num_trees=1000,
                           method="binary",
                           random_seed=5)
rx_set_compute_context(local)

# Serialize model and insert into table
insert_model(TABLE_CLASSIFIERS, connection_string, classifier, FASTTREE_MODEL_NAME)

# Point to the SQL table with the testing data
query = "SELECT * FROM {} WHERE patient_id NOT IN (SELECT patient_id FROM {})".format(TABLE_FEATURES, TABLE_TRAIN_ID)
test_sql = RxSqlServerData(sql_query=query, connection_string=connection_string, column_info=column_info)

# Make predictions on the test data
predictions = ml_predict(classifier, data=test_sql, extra_vars_to_write=["label", "patient_id"])
predictions_sql = RxSqlServerData(table=TABLE_PREDICTIONS, connection_string=connection_string)
rx_data_step(predictions, predictions_sql, overwrite=True)

# Evaluate model using ROC
roc(predictions["label"], predictions["Probability"])

print("Routine finished")






