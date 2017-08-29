import sys,os
import numpy as np
import pyodbc
import pandas as pd
import scipy.misc
from lung_cancer.connection_settings import get_connection_string, TABLE_SCAN_IMAGES, IMAGES_FOLDER
from lung_cancer.lung_cancer_utils import convert_dicom_to_png
from config_preprocessing import STAGE1_LABELS, STAGE1_FOLDER

def create_file_table(table_name, cursor, connector, drop_table=False):
    query = ""
    if drop_table:
        query += "IF OBJECT_ID(\'" + table_name + "\') IS NOT NULL DROP TABLE " + table_name + " "
    else:
        query += "IF OBJECT_ID(\'" + table_name + "\') IS NULL "
         
    query += """CREATE TABLE {} AS FileTable  
        WITH (   
            FileTable_Directory = '{}',  
            FileTable_Collate_Filename = database_default  
        ); """.format(table_name, table_name)
    print(query)
    cursor.execute(query)
    connector.commit()


if __name__ == "__main__":

    #Create SQL database connection and table
    connection_string = get_connection_string()
    conn = pyodbc.connect(connection_string) 
    cur = conn.cursor()

    print("Creating file table {}".format(TABLE_SCAN_IMAGES))
    create_file_table(TABLE_SCAN_IMAGES, cur, conn, drop_table=False)

    #Insert all patient images AS FILESTREAMS
    df = pd.read_csv(STAGE1_LABELS)
    print("Converting dicoms to pngs and inserting {} patient images in the file table".format(df.shape[0]))

    for i, patient_id in enumerate(df['id'].tolist()):

        dicom_folder = os.path.join(STAGE1_FOLDER, patient_id)
        image_folder = os.path.join(IMAGES_FOLDER, patient_id)
        if os.path.exists(image_folder):
            continue

        os.makedirs(image_folder)

        print("Converting patient #{} with id: {}".format(i, patient_id))
        batch = convert_dicom_to_png(dicom_folder, image_folder)

    print("Images inserted")
    conn.close()
