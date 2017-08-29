import os
import numpy as np
import pandas as pd
import pkg_resources
import pickle
import pyodbc
import dicom
from pandas import DataFrame
from sklearn.metrics import roc_auc_score, roc_curve
import matplotlib.pyplot as plt
import scipy.misc

from revoscalepy import RxSqlServerData, rx_import, rx_read_object, rx_write_object, RxOdbcData, rx_get_var_names, rx_data_step, rx_summary
from microsoftml import load_image, resize_image, extract_pixels, featurize_image, rx_featurize

######################################################################
# For verifying setup
def print_library_version():
    print(os.getcwd())
    version_pandas = pkg_resources.get_distribution("pandas").version
    print("Version pandas: {}".format(version_pandas))


######################################################################
# For preprocessing
def convert_dicom_to_png(dicom_path, image_path):
    slices = [(dicom.read_file(os.path.join(dicom_path, s)),s) for s in os.listdir(dicom_path)]
    for slice, file_name in slices:
        path = os.path.join(image_path, file_name[:-4]+'.png')
        scipy.misc.imsave(path, slice.pixel_array)


######################################################################
# for feature generation
def get_patients_id(table_name, connection_string):
    query = "SELECT DISTINCT patient_id FROM {}".format(table_name)
    sqldata = RxSqlServerData(sql_query=query, connection_string=connection_string)
    data = rx_import(sqldata)
    return data["patient_id"].tolist()


def save_image(scans):
    print(scans.shape)
    path = "C:/Users/t-tyrome/Documents/Internship/sql_python_deep_learning/images/scan.png"
    scipy.misc.imsave(path, scans[0,:,:,:].squeeze().transpose(1,2,0))


def gather_image_paths(images_folder, connection_string):
    root = os.path.dirname(images_folder)
    query = 'SELECT ([file_stream].GetFileNamespacePath()) as image FROM [MriData] WHERE [is_directory] = 0'
    filetable_sql = RxSqlServerData(sql_query=query, connection_string=connection_string)
    data = rx_import(filetable_sql)
    data["image"] = data["image"].apply(lambda x: os.path.join(root, x[1:]))    # TODO: assert to confirm paths exist
    data["patient_id"] = data["image"].map(lambda x: os.path.basename(os.path.dirname(x)))
    return data


def featurize_transform(dataset, context):
    from microsoftml import load_image, resize_image, extract_pixels, featurize_image, rx_featurize
    from lung_cancer.connection_settings import MICROSOFTML_MODEL_NAME
    data = DataFrame(dataset)
    data = rx_featurize(
        data=data,
        overwrite=True,
        ml_transforms=[
            load_image(cols={"feature": "image"}),
            resize_image(cols="feature", width=224, height=224),
            extract_pixels(cols="feature"),
            featurize_image(cols="feature", dnn_model=MICROSOFTML_MODEL_NAME)
        ]
    )
    data.columns = ["image", "patient_id"] + ["f" + str(i) for i in range(len(data.columns)-2)]
    return data


def compute_features(data, output_table, connection_string):
    results_sql = RxSqlServerData(table=output_table, connection_string=connection_string)
    rx_data_step(input_data=data, output_file=results_sql, overwrite=True, transform_function=featurize_transform, report_progress=2)


def average_pool(slice_table, connection_string):
    # Create formula
    slicefeats_sql = RxSqlServerData(table=slice_table, connection_string=connection_string)
    colnames = rx_get_var_names(slicefeats_sql)
    f = "+".join([x for x in colnames if x not in ["image", "patient_id"]])

    pooled_data = []
    summary = None
    patient_ids = get_patients_id(slice_table, connection_string)
    
    # Summarize slices for each individual patient
    for patient_id in patient_ids:
        query = "SELECT * FROM {} WHERE patient_id='{}'".format(slice_table, patient_id)
        patientfeats_sql = RxSqlServerData(sql_query=query, connection_string=connection_string)
        summary = rx_summary(formula=f, data=patientfeats_sql, by_term=True).summary_data_frame
        patient_data = [patient_id] + summary["Mean"].tolist()
        pooled_data.append(patient_data)
    cols = ["patient_id"] + summary["Name"].tolist()
    pooled_data = pd.DataFrame(pooled_data, columns=cols)
    return pooled_data


#########################################################################
#for scoring and evaluating
def train_test_split(train_id_table, patients_table, p, connection_string):
    pyodbc_cnxn = pyodbc.connect(connection_string)
    pyodbc_cursor = pyodbc_cnxn.cursor()
    pyodbc_cursor.execute("DROP TABLE if exists {};".format(train_id_table))
    pyodbc_cursor.execute("SELECT DISTINCT patient_id INTO {} FROM {} WHERE ABS(CAST(CAST(HashBytes('MD5', patient_id) AS VARBINARY(64)) AS BIGINT) % 100) < {};".format(train_id_table, patients_table, p))
    pyodbc_cursor.close()
    pyodbc_cnxn.commit()
    pyodbc_cnxn.close()


def get_patient_id_from_index(table_name, connection_string, patient_index):
    patients = get_patients_id(table_name, connection_string)  #FIXME: this could be faster with a new table with (idx, id)
    return patients[patient_index]

def create_formula(sql_data):
    features_all = rx_get_var_names(sql_data)
    features_to_remove = ["label", "patient_id"]
    training_features = [x for x in features_all if x not in features_to_remove]
    formula = "label ~ " + " + ".join(training_features)
    return formula

#code from http://scikit-learn.org/stable/auto_examples/model_selection/plot_roc.html#sphx-glr-auto-examples-model-selection-plot-roc-py
def roc(y, y_hat):
    print("ROC AUC: ", roc_auc_score(y, y_hat))
    fpr, tpr, thresholds = roc_curve(y, y_hat)
    plt.figure()
    plt.plot(fpr, tpr, color='darkorange', lw=2, label='ROC curve')
    plt.plot([0, 1], [0, 1], color='navy', lw=2, linestyle='--')
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.05])
    plt.xlabel('False Positive Rate')
    plt.ylabel('True Positive Rate')
    plt.title('ROC Plot')
    plt.legend(loc="lower right")
    plt.show()


def insert_model(table_name, connection_string, classifier, name):
    classifier_odbc = RxOdbcData(connection_string, table=table_name)
    rx_write_object(classifier_odbc, key=name, value=classifier, serialize=True, overwrite=True)


def retrieve_model(table_name, connection_string, name):
    classifier_odbc = RxOdbcData(connection_string, table=table_name)
    classifier = rx_read_object(classifier_odbc, key=name, deserialize=True)
    return classifier


#########################################################################
# for API
#code from https://github.com/miguelgfierro/codebase/blob/master/python/database/sql_server/select_values.py
def select_entry_where_column_equals_value(table_name, connection_string, column_name, value):
    query = "SELECT TOP (1) * FROM {} WHERE {} = '{}'".format(table_name, column_name, value)
    print(query)
    query_sql = RxSqlServerData(sql_query=query, connection_string=connection_string)
    data = rx_import(query_sql)
    return data


def select_top_value_of_column(table_name, connection_string, column_name):
    query = "SELECT TOP(1) " + column_name + " FROM " + table_name
    print(query)
    query_sql = RxSqlServerData(sql_query=query, connection_string=connection_string)
    data = rx_import(query_sql)
    print(data)
    return data.iloc[0, 0]