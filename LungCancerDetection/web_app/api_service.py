from api import app, BAD_PARAM, STATUS_OK, BAD_REQUEST
from flask import request, jsonify, abort, make_response, render_template
import sys
from lung_cancer.connection_settings_microsoftml import get_connection_string, TABLE_GIF, TABLE_CLASSIFIERS, FASTTREE_MODEL_NAME, DATABASE_NAME, NUMBER_PATIENTS, TABLE_PCA_FEATURES, TABLE_PATIENTS
from lung_cancer.lung_cancer_utils_microsoftml import get_patient_id_from_index, select_entry_where_column_equals_value, retrieve_model
import pyodbc
import cherrypy
from microsoftml import rx_predict as ml_predict
from revoscalepy import RxSqlServerData, rx_import
from paste.translogger import TransLogger


def run_server():
    # Enable WSGI access logging via Paste
    app_logged = TransLogger(app)

    # Mount the WSGI callable object (app) on the root directory
    cherrypy.tree.graft(app_logged, '/')

    # Set the configuration of the web server
    cherrypy.config.update({
        'engine.autoreload_on': True,
        'log.screen': True,
        'log.error_file': "cherrypy.log",
        'server.socket_port': 5000,
        'server.socket_host': '0.0.0.0',
        'server.thread_pool': 50, # 10 is default
    })

    # Start the CherryPy WSGI web server
    cherrypy.engine.start()
    cherrypy.engine.block()

# Connection
connection_string = get_connection_string()


# Model
model = retrieve_model(TABLE_CLASSIFIERS, connection_string, FASTTREE_MODEL_NAME)


# Functions
@app.route("/")
def index():
    cherrypy.log("CHERRYPY LOG: /")
    return render_template('index.html')


@app.route('/gif/<patient_index>')
def patient_gif(patient_index):
    patient_index = int(patient_index)
    if patient_index > NUMBER_PATIENTS:
        abort(BAD_REQUEST)
    cherrypy.log("CHERRYPY LOG: /gif/<patient_index>")
    gif_url = manage_gif(patient_index)
    return make_response(jsonify({'status': STATUS_OK, 'gif_url': gif_url}), STATUS_OK)


@app.route('/predict/<patient_index>')
def predict_patient(patient_index):
    patient_index = int(patient_index)
    if patient_index > NUMBER_PATIENTS:
        abort(BAD_REQUEST)
    cherrypy.log("CHERRYPY LOG: /predict/<patient_index>")
    prob = manage_prediction(patient_index)
    return make_response(jsonify({'status': STATUS_OK, 'prob': prob}), STATUS_OK)


@app.route('/patient_info', methods=['POST'])
def patient_info():
    cherrypy.log("CHERRYPY LOG: /patient_info")
    patient_index = manage_request_patient_index(request.form['patient_index'])
    gif_url = manage_gif(patient_index)
    return render_template('patient.html', patient_index=patient_index, gif_url=gif_url)


@app.route('/patient_prob', methods=['POST'])
def patient_prob():
    cherrypy.log("CHERRYPY LOG: /patient_prob")
    patient_index = manage_request_patient_index(request.form['patient_index'])
    prob = manage_prediction_store_procedure(patient_index)
    gif_url = manage_gif(patient_index)
    return render_template('patient.html', patient_index=patient_index, prob=round(prob, 2), gif_url=gif_url)


def is_integer(s):
    try:
        int(s)
        return True
    except ValueError:
        return False


def manage_request_patient_index(patient_request):
    patient1 = "Anthony Embleton".lower()
    patient2 = "Ana Fernandez".lower()
    if patient_request.lower() in patient1:
        patient_index = 1
    elif patient_request.lower() in patient2:
        patient_index = 175
    else:
        if is_integer(patient_request):
            patient_index = int(patient_request)
            if patient_index > NUMBER_PATIENTS:
                patient_index = NUMBER_PATIENTS - 1
        else:
            patient_index = 7
    return patient_index


def manage_gif(patient_index):
    patient_id = get_patient_id_from_index(TABLE_GIF, connection_string, patient_index)
    resp = select_entry_where_column_equals_value(TABLE_GIF, connection_string, 'patient_id', patient_id)
    gif_url = resp["gif_url"].iloc[0]
    print("gif_url: ", gif_url)
    return gif_url


def manage_prediction(patient_index):
    query = "SELECT TOP(1) * FROM {} AS t1 INNER JOIN {} AS t2 ON t1.patient_id = t2.patient_id WHERE t2.idx = {}".format(
        TABLE_PCA_FEATURES, TABLE_PATIENTS, patient_index)
    patient_sql = RxSqlServerData(sql_query=query, connection_string=connection_string)
    predictions = ml_predict(model, data=patient_sql, extra_vars_to_write=["label", "patient_id"])
    prob = float(predictions["Probability"].iloc[0])*100
    return prob


def manage_prediction_store_procedure(patient_index):
    conn = pyodbc.connect(connection_string)
    cur = conn.cursor()
    query = "SET NOCOUNT ON; DECLARE @PredictionResultSP FLOAT; "
    query += "EXECUTE {}.dbo.PredictLungCancer @PatientIndex = {}, @ModelName = \"{}\", @PredictionResult = @PredictionResultSP;".format(DATABASE_NAME, patient_index, FASTTREE_MODEL_NAME)
    cur.execute(query)
    prob = cur.fetchone()[0] * 100
    conn.close()
    print("Probability: ", prob)
    return prob


if __name__ == "__main__":
    run_server()
