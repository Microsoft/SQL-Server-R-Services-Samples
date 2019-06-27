############################################################
#
# Comprehensive Demo and test script for model mgmt tutorial
# This script allows you to do the following:
#
# 1. Build and test a model and save it to SQL Server
# 2. Specify that the model was used by simulating a feed from a CRM system
# 3. Specify the model performance by simulating a feed from a CRM system
# 4. Repeat steps 2 and 3 with lower performance to trigger the building of a new model
# 5. Repeat steps 2 and 3 with higher performance with no new model built
# 
#
# Part of Model Management Demo
#
# Create Date: May 29, 2019
# Last Update: June 27, 2019
#
############################################################

# run from RGui as admn as needed for all pkgs
#install.packages('caret', 
#                 lib = "C:\\Program Files\\Microsoft SQL Server\\MSSQL14.MSSQL2017\\R_SERVICES\\library",
#                 dependencies = TRUE)

library(RODBC)
library(caret)
library(pROC)

##################################################
#################   Start Initialize  #########
##################################################

###
### customize the demo with your own Model Name
###
modName <- "Independence Day"
###

## st proc parameters
modelID <- paste0(modName," model")
campID <- paste0(modName," Email - 1")
channel <- "EMail"
season <- "Fall"
respRate <- 5.5
totRev <- 2000000

## model parameters
lang <- "R"
modelName <- modelID
modelType <- "Linear Regression"
modelVersion <- 1
owner <- "Joe Schmoe"
built <- "Manual"

##################################################
#################   End Initialize  #########
##################################################

# DB connection to save models using ODBC DSN
ch <- odbcConnect("ModelMgmtDB")

##################################################
#################   set up data source  #########
##################################################

sqlConnString <- "Driver=SQL Server;Server=5167798-0125\\MSSQL2017; Database=ModelMgmtDB;Trusted_Connection=TRUE"
sqlCustTable <- "dbo.v_ModelData"
sqlRowsPerRead = 50000

sqlCustDS <- RxSqlServerData(connectionString = sqlConnString, verbose = 1,
                             table = sqlCustTable, rowsPerRead = sqlRowsPerRead)

custDF <- rxImport(sqlCustDS)

rxGetInfo(data = custDF, getVarInfo = TRUE, numRows = 3)

#################################################
## Create training and testing sets with caret
#################################################

set.seed(998)

inTraining <- createDataPartition(custDF$RESPONSE, p = .75, list = FALSE)

training <- custDF[ inTraining,]
testing  <- custDF[-inTraining,]

rxGetInfo(data=training, getVarInfo=TRUE,numRows=10)

rxGetInfo(data=testing, getVarInfo=TRUE,numRows=10)

#########################################################################
####### 1. build model
#########################################################################

#############################################
## A linear regression
#############################################

### Build model

reg1 <- lm(formula = RESPONSE ~ AVG_PURCH + REC_PURCH_AMT + NUMPURCH_LIFE, 
           data = training)

### Test model performance

lmPredOut <- predict(reg1, testing, type = "response")

testing$prediction <- lmPredOut

# Compute auc	

auc <- auc(testing$RESPONSE, testing$prediction)

## model performance parameter
performance <- as.numeric(auc)

#############################################
## save model to DB
#############################################
# Create the data source
ds <- RxOdbcData(table = "ModelTbl", connectionString = sqlConnString)

### Store the model in the database
# write model
rxWriteObject(ds, modelName, reg1)
# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelDetails '",
                   modelName, "','", lang, "' ,'" , modelType, "', ",
                   modelVersion, ", '", owner, "', ", performance, " ,'" ,built,"'")
sqlQuery(ch, insQuery)


#########################################################################
####### 2. Simulate the usage of the model
#########################################################################

#############################################
## Use New model
#############################################

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelUsage '",
                   modelID, "','", campID, "' ,'" , channel, "','", season, "'")
sqlQuery(ch, insQuery)


#########################################################################
####### 3. Simulate the model performance
#########################################################################

#############################################
## Use New model
#############################################

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelPerf '",
                   modelID, "','", campID, "' ," , respRate, ",", totRev)
sqlQuery(ch, insQuery)


#########################################################################
####### 4A. Simulate the usage of the model
#########################################################################

#############################################
## Use New model
#############################################

### new campaign
campID <- paste0(modName," Email - 2")

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelUsage '",
                   modelID, "','", campID, "' ,'" , channel, "','", season, "'")
sqlQuery(ch, insQuery)


#########################################################################
####### 4B. Simulate the model performance - lower performance than prior
####### model usage, which will trigger building a new model
#########################################################################

#############################################
## Use New model
#############################################

### lower performance
respRate <- 4.7
totRev <- 1500000

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelPerf '",
                   modelID, "','", campID, "' ," , respRate, ",", totRev)
sqlQuery(ch, insQuery)


#########################################################################
####### 5A. Simulate the usage of the model
#########################################################################

#############################################
## Use New model
#############################################

### new campaign
campID <- paste0(modName," Email - 3")

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelUsage '",
                   modelID, "','", campID, "' ,'" , channel, "','", season, "'")
sqlQuery(ch, insQuery)


#########################################################################
####### 5B. Simulate the model performance - higher performance than prior
####### model usage, which will trigger building a new model
#########################################################################

#############################################
## Use New model
#############################################

### higher performance
respRate <- 7.3
totRev <- 2700000

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelPerf '",
                   modelID, "','", campID, "' ," , respRate, ",", totRev)
sqlQuery(ch, insQuery)

##################################################
# close DB channel

close(ch)

##################################################
##################################################
