import pandas as pd
from revoscalepy import RxSqlServerData, rx_data_step, RxInSqlServer, RxLocalSeq, rx_set_compute_context

from lung_cancer.connection_settings import get_connection_string, TABLE_LABELS, TABLE_FEATURES, IMAGES_FOLDER, TABLE_SLICE_FEATURES
from lung_cancer.lung_cancer_utils import compute_features, gather_image_paths, average_pool

print("Starting routine")

# Connect to SQL Server
connection_string = get_connection_string()
sql = RxInSqlServer(connection_string=connection_string)
local = RxLocalSeq()
rx_set_compute_context(local)

# Get paths to filetable images
data = gather_image_paths(IMAGES_FOLDER, connection_string=connection_string)
print("Number of images to featurize: {}".format(len(data)))

# Featureize images
print("Featurizing Images")
rx_set_compute_context(local)   # TODO: sql not working correctly. Change to sql later.
compute_features(data, output_table=TABLE_SLICE_FEATURES, connection_string=connection_string)
rx_set_compute_context(local)

# Average Pooling
print("Performing Average Pooling")
pooled_data = average_pool(TABLE_SLICE_FEATURES, connection_string=connection_string)

# Write features to table
tempfeats_sql = RxSqlServerData(table=TABLE_FEATURES, connection_string=connection_string)
rx_data_step(input_data=pooled_data, output_file=tempfeats_sql, overwrite=True)

# Perform join with labels
print("Joining features with labels")
query = """SELECT {}.*, {}.label FROM {} INNER JOIN {} ON {}.patient_id = {}.patient_id;
    """.format(TABLE_FEATURES, TABLE_LABELS, TABLE_FEATURES, TABLE_LABELS, TABLE_FEATURES, TABLE_LABELS)
tempfeats_sql = RxSqlServerData(sql_query=query, connection_string=connection_string)
features_sql = RxSqlServerData(table=TABLE_FEATURES, connection_string=connection_string)
rx_data_step(tempfeats_sql, features_sql, overwrite=True)

print("Routine finished")