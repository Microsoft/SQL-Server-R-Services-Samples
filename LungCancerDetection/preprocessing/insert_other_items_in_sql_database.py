import sys,os
import numpy as np
import pandas as pd
import pyodbc
import pickle
from lung_cancer.connection_settings import get_connection_string, TABLE_GIF, TABLE_LABELS, TABLE_PATIENTS, TABLE_SCAN_IMAGES
import wget
import datetime
from config_preprocessing import STAGE1_LABELS, BASE_URL


def create_table_gifs(table_name, cursor, connector, drop_table=False):
    query = ''
    if drop_table:
        query += 'IF OBJECT_ID(\'' + table_name + '\') IS NOT NULL DROP TABLE ' + table_name + ' '
    query += 'CREATE TABLE ' + table_name
    query += ' ( patient_id varchar(50) not null, gif_url varchar(200) not null )'
    cursor.execute(query)
    connector.commit()


def create_table_labels(table_name, cursor, connector, drop_table=False):
    query = ''
    if drop_table:
        query += 'IF OBJECT_ID(\'' + table_name + '\') IS NOT NULL DROP TABLE ' + table_name + ' '
    query += 'CREATE TABLE ' + table_name
    query += ' ( patient_id varchar(50) not null, label integer not null )'
    cursor.execute(query)
    connector.commit()


def create_table_patient_index(table_name, cursor, connector, drop_table=False):
    query = ''
    if drop_table:
        query += 'IF OBJECT_ID(\'' + table_name + '\') IS NOT NULL DROP TABLE ' + table_name + ' '
    query += 'CREATE TABLE ' + table_name
    query += ' ( idx integer not null, patient_id varchar(50) not null)'
    cursor.execute(query)
    connector.commit()


def get_patients_id(df):
    patient_ids = df['id'].tolist()
    return patient_ids


def generate_gif_url(patient_ids):
    gif_urls = [BASE_URL + p + '.gif' for p in patient_ids]
    return gif_urls


def insert_gifs(table_name, cursor, connector, patient_ids, gif_urls):
    query = 'INSERT INTO ' + table_name + '( patient_id, gif_url ) VALUES (?,?)'
    for p,g in zip(patient_ids, gif_urls):
        cursor.execute(query, p, g)
    connector.commit()


def insert_labels(table_name, cursor, connector, df):
    query = 'INSERT INTO ' + table_name + '( patient_id, label ) VALUES (?,?)'
    for idx, row in df.iterrows():
        cur.execute(query, row['id'], row['cancer'])
    conn.commit()


def insert_patient_id(table_name, cursor, connector, patient_ids):
    query = 'INSERT INTO ' + table_name + '( idx, patient_id ) VALUES (?,?)'
    for idx, patient_id in enumerate(patient_ids):
        cur.execute(query, idx, patient_id)
    conn.commit()


if __name__ == "__main__":

    #Create SQL database connection and table
    connection_string = get_connection_string()
    conn = pyodbc.connect(connection_string)
    cur = conn.cursor()
    print("Creating tables {}, {}".format(TABLE_GIF, TABLE_LABELS))
    create_table_gifs(TABLE_GIF, cur, conn, True)
    create_table_labels(TABLE_LABELS, cur, conn, True)
    create_table_patient_index(TABLE_PATIENTS, cur, conn, True)

    #Insert gifs
    df = pd.read_csv(STAGE1_LABELS)
    patient_ids = get_patients_id(df)
    gif_urls = generate_gif_url(patient_ids)
    insert_gifs(TABLE_GIF, cur, conn, patient_ids, gif_urls)

    # Insert patient id
    insert_patient_id(TABLE_PATIENTS, cur, conn, patient_ids)

    # Insert labels
    insert_labels(TABLE_LABELS, cur, conn, df)

    print("Process finished")
    conn.close()

