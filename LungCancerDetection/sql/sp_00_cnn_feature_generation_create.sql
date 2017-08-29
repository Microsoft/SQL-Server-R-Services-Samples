USE [lung_cancer_database]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


IF OBJECT_ID('[dbo].[GenerateFeatures]', 'P') IS NOT NULL  
    DROP PROCEDURE [dbo].GenerateFeatures;  
GO  

CREATE PROCEDURE [dbo].GenerateFeatures 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @root nvarchar(1000) = FileTableRootPath(); 

	DECLARE @batchPatientImages nvarchar(max)
	SET @batchPatientImages = 
		N'SELECT (''' + @root + ''' + [file_stream].GetFileNamespacePath()) as image
			FROM [MriData] WHERE [is_directory] = 0';

    -- Insert statements for procedure here
	EXECUTE sp_execute_external_script
      @language = N'Python'
    , @script = N'
from revoscalepy import RxInSqlServer, RxLocalSeq, rx_set_compute_context, RxSqlServerData, rx_data_step
from lung_cancer.lung_cancer_utils import compute_features, average_pool
from lung_cancer.connection_settings import MICROSOFTML_MODEL_NAME, TABLE_SLICE_FEATURES, get_connection_string

connection_string = get_connection_string()

data = InputDataSet
data["patient_id"] = data["image"].map(lambda x: os.path.basename(os.path.dirname(x)))

rx_set_compute_context(sql)
compute_features(data, output_table=TABLE_SLICE_FEATURES, connection_string=connection_string)
rx_set_compute_context(local)

pooled_data = average_pool(TABLE_SLICE_FEATURES, connection_string=connection_string)

features_sql = RxSqlServerData(table="dbo.tempfeats", connection_string=connection_string)
rx_data_step(pooled_data, features_sql, overwrite=True)	
'
	, @input_data_1 = @batchPatientImages;

	DROP TABLE IF EXISTS features;
	SELECT dbo.tempfeats.*, dbo.labels.label INTO dbo.features FROM dbo.tempfeats INNER JOIN dbo.labels ON dbo.tempfeats.patient_id = dbo.labels.patient_id;
	DROP TABLE IF EXISTS tempfeats;
	
END
GO


