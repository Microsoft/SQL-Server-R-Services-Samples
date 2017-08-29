
USE [lung_cancer_database]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('[dbo].[PredictLungCancer]', 'P') IS NOT NULL  
    DROP PROCEDURE [dbo].[PredictLungCancer];  
GO  

CREATE PROCEDURE [dbo].[PredictLungCancer] 
@PatientIndex INT,
@ModelName VARCHAR(50),
@PredictionResult FLOAT OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	DECLARE @predictScript NVARCHAR(MAX);
	SET @predictScript = N'
from lung_cancer.connection_settings import get_connection_string, TABLE_CLASSIFIERS, TABLE_FEATURES, TABLE_PATIENTS
from lung_cancer.lung_cancer_utils import retrieve_model
from revoscalepy import RxInSqlServer, rx_set_compute_context, RxSqlServerData
from microsoftml import rx_predict as ml_predict

# Connect to SQL Server and set compute context
connection_string = get_connection_string()
sql = RxInSqlServer(connection_string = connection_string)
#rx_set_compute_context(sql)

query = "SELECT TOP(1) * FROM {} AS t1 INNER JOIN {} AS t2 ON t1.patient_id = t2.patient_id WHERE t2.idx = {}".format(TABLE_FEATURES, TABLE_PATIENTS, PatientIndex)
patient_sql = RxSqlServerData(sql_query=query, connection_string=connection_string)

# Get classifier
classifier = retrieve_model(TABLE_CLASSIFIERS, connection_string, ModelName)

# Make Prediction on a single patient
predictions = ml_predict(classifier, data=patient_sql, extra_vars_to_write=["label", "patient_id"])
print(predictions.head())

PredictionResult = float(predictions["Probability"].iloc[0])*100
print("The probability of cancer for patient {} is {}%".format(PatientIndex, PredictionResult))
	'
	EXECUTE sp_execute_external_script
	@language = N'python',
	@script = @predictScript,
	@params = N'@ModelName VARCHAR(50), @PatientIndex INT, @PredictionResult FLOAT OUTPUT',
	@ModelName = @ModelName,
	@PatientIndex = @PatientIndex,
	@PredictionResult = @PredictionResult OUTPUT;

	PRINT 'Probability for having cancer (%):'
	SELECT @PredictionResult
END
GO



