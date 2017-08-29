USE [lung_cancer_database]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


IF OBJECT_ID('[dbo].[TrainModel]', 'P') IS NOT NULL  
    DROP PROCEDURE [dbo].[TrainModel];  
GO  

CREATE PROCEDURE [dbo].[TrainModel] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	DECLARE @predictScript NVARCHAR(MAX);
	SET @predictScript = N'
import sys
from revoscalepy import RxSqlServerData, RxInSqlServer, RxLocalSeq, rx_set_compute_context
from microsoftml import rx_fast_trees

from lung_cancer.lung_cancer_utils import insert_model, create_formula
from lung_cancer.connection_settings import get_connection_string, TABLE_CLASSIFIERS, TABLE_FEATURES, TABLE_TRAIN_ID, FASTTREE_MODEL_NAME

# Set recursion limit to be slightly larger to accommodate larger formulas (which are paresed recursively)
print("Old recursion limit: ", sys.getrecursionlimit())
sys.setrecursionlimit(1500)
print("New recursion limit: ", sys.getrecursionlimit())

# Connect to SQL Server and set compute context
connection_string = get_connection_string()
sql = RxInSqlServer(connection_string = connection_string)
local = RxLocalSeq()
rx_set_compute_context(local)

# Point to the SQL table with the training data
column_info = {"label": {"type": "numeric"}}
query = "SELECT * FROM {} WHERE patient_id IN (SELECT patient_id FROM {})".format(TABLE_FEATURES, TABLE_TRAIN_ID)
train_sql = RxSqlServerData(sql_query=query, connection_string=connection_string, column_info=column_info)

# Create formula
formula = create_formula(train_sql)
print("Formula:", formula)

# Fit a classification model
classifier = rx_fast_trees(formula=formula,
                           data=train_sql,
                           num_trees=1000,
                           method="binary",
                           random_seed=5,
                           compute_context=local)	# TODO: sql not currently working correctly. Change to sql later.

# Serialize model and insert into table
insert_model(TABLE_CLASSIFIERS, connection_string, classifier, FASTTREE_MODEL_NAME)
print("Model written to {}".format(TABLE_CLASSIFIERS))
	'

	EXECUTE sp_execute_external_script
	@language = N'python',
	@script = @predictScript;

END
GO


IF OBJECT_ID('[dbo].[ScoreModel]', 'P') IS NOT NULL  
    DROP PROCEDURE [dbo].[ScoreModel];  
GO  

CREATE PROCEDURE [dbo].[ScoreModel] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	DROP TABLE IF EXISTS [dbo].[predictions]
	CREATE TABLE [dbo].[predictions](
		[patient_id] nvarchar(255),
		[label] float,
		[PredictedLabel] bit,
		[Score] float,
		[Probability] float
	)

	DECLARE @predictScript NVARCHAR(MAX);
	SET @predictScript = N'
from revoscalepy import RxSqlServerData, RxInSqlServer, RxLocalSeq, rx_set_compute_context
from microsoftml import rx_predict as ml_predict

from lung_cancer.lung_cancer_utils import retrieve_model
from lung_cancer.connection_settings import get_connection_string, TABLE_CLASSIFIERS, TABLE_TRAIN_ID, FASTTREE_MODEL_NAME, TABLE_FEATURES

# Connect to SQL Server and set compute context
connection_string = get_connection_string()
sql = RxInSqlServer(connection_string = connection_string)
local = RxLocalSeq()
rx_set_compute_context(sql)

# Retrieve and unserialize model
classifier = retrieve_model(TABLE_CLASSIFIERS, connection_string, FASTTREE_MODEL_NAME)

# Point to the SQL table with the testing data
column_info = {"label": {"type": "numeric"}}
query = "SELECT * FROM {} WHERE patient_id NOT IN (SELECT patient_id FROM {})".format(TABLE_FEATURES, TABLE_TRAIN_ID)
test_sql = RxSqlServerData(sql_query=query, connection_string=connection_string, column_info=column_info)

# Make predictions on the test data
predictions = ml_predict(classifier, data=test_sql, extra_vars_to_write=["label", "patient_id"])

print("Predictions written to dbo.predictions")
OutputDataSet = predictions

	'
	INSERT INTO [dbo].[predictions] (patient_id, label, PredictedLabel, Score, Probability)
	EXECUTE sp_execute_external_script
	@language = N'python',
	@script = @predictScript;

END
GO

IF OBJECT_ID('[dbo].[TrainTestSplit]', 'P') IS NOT NULL  
    DROP PROCEDURE [dbo].[TrainTestSplit];  
GO  

CREATE PROCEDURE [dbo].[TrainTestSplit] 
AS
BEGIN
	DROP TABLE IF EXISTS train_id;

	-- The advantage of using a hashing function for splitting is to permit repeatability of the experiment. 
	SELECT DISTINCT patient_id INTO train_id FROM [dbo].[patients] WHERE ABS(CAST(CAST(HashBytes('MD5', patient_id) AS VARBINARY(64)) AS BIGINT) % 100) < 80;
END
GO