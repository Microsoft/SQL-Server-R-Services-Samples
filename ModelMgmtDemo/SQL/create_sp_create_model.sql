-- ================================================
-- Build a new model and insert it into ModelTbl
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
use ModelMgmtDB
go

-- =============================================
-- Create date: 6/25/2019
-- Last Modified date: 6/26/2019
-- Description:	Build a new model and save it
-- =============================================

IF (OBJECT_ID('sp_create_model') IS NOT NULL)
DROP PROCEDURE sp_create_model
GO

CREATE PROCEDURE [dbo].[sp_create_model] 
@modelid varchar(200), 
@performance float OUTPUT

AS
BEGIN

declare @instance_name nvarchar(100) = @@SERVERNAME,
        @database_name nvarchar(128) = db_name()


EXEC sp_execute_external_script
@language = N'R',
@script = N'
## Create model
##################################################
#################   set up data source  #########
##################################################

# DB connection to save models
connStr <- paste("Driver=SQL Server;Server=", instance_name, ";Database=", database_name, ";Trusted_Connection=true;", sep="");

custDF <- InputDataSet

#################################################
## Create training and testing sets with caret
#################################################

library(caret)
library(pROC)

set.seed(998)

inTraining <- createDataPartition(custDF$RESPONSE, p = .75, list = FALSE)

training <- custDF[ inTraining,]
testing  <- custDF[-inTraining,]

#########################################################################
####### 1. build model
#########################################################################

#############################################
## A linear regression
#############################################

### Build model

reg1 <- lm(formula = RESPONSE ~ AVG_PURCH + REC_PURCH_AMT + NUMPURCH_LIFE, data = training)

## model parameters

modelName <- modelid

### Test model performance

lmPredOut <- predict(reg1, testing, type = "response")

testing$prediction <- lmPredOut

# Compute auc	

auc <- auc(testing$RESPONSE, testing$prediction)

#############################################
## save model to DB
#############################################
# Create the data source
ds <- RxOdbcData(table = "ModelTbl", connectionString = connStr)

### Store the model in the database
# write model
rxWriteObject(ds, modelName, reg1)

performance <- as.numeric(auc)
',
@input_data_1 = N'select * from dbo.v_ModelData',
@params = N'@modelid varchar(200),  @performance float OUTPUT, @instance_name nvarchar(100), @database_name nvarchar(128)'
,@modelid = @modelid
, @instance_name = @instance_name
, @database_name = @database_name
, @performance = @performance OUTPUT;

   END
GO