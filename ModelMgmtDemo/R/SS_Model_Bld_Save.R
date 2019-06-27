##################################################
#
# Perform model building and saving of models
# and model details inside SQL Server
#
# Part of Model Management Demo
#
# Create Date: April 26, 2019
# Last Update: May 28, 2019
#
#################################################

library(RODBC)

# DB connection to save models using ODBC DSN
ch <- odbcConnect("ModelMgmtDB")

##################################################
#################   set up data source  #########
##################################################

sqlConnString <- "Driver=SQL Server;Server=5167798-0125\\MSSQL2017;Database=ModelMgmtDB;Trusted_Connection=TRUE"
sqlCustTable <- "dbo.v_ModelData"
sqlRowsPerRead = 50000

sqlCustDS <- RxSqlServerData(connectionString = sqlConnString, verbose = 1,
                              table = sqlCustTable, rowsPerRead = sqlRowsPerRead)

custDF <- rxImport(sqlCustDS)

rxGetInfo(data = custDF, getVarInfo = TRUE, numRows = 3)

#################################################
## Create training and testing sets with caret
#################################################

#install.packages("caret")

library(caret)

set.seed(998)

inTraining <- createDataPartition(custDF$RESPONSE, p = .75, list = FALSE)

training <- custDF[ inTraining,]
testing  <- custDF[-inTraining,]

rxGetInfo(data=training, getVarInfo=TRUE,numRows=10)

rxGetInfo(data=testing, getVarInfo=TRUE,numRows=10)

#########################################################################
####### build models
#########################################################################

#############################################
## A linear regression
#############################################

### Build model

system.time(reg1 <- rxLinMod(formula = RESPONSE ~ AVG_PURCH + REC_PURCH_AMT + NUMPURCH_LIFE, data = training))

summary(reg1)

## model parameters

lang <- "R"
modelName <- "Christmas Catalog model"
modelType <- "Linear Regression"
modelVersion <- 1
owner <- "Joe Schmoe"
built <- "Manual"


### Test model performance

rxPredOut <- rxPredict(modelObject = reg1, data = testing, 
                       writeModelVars = TRUE, predVarNames = "RespPrediction")

# Compute the ROC data for the default number of thresholds	
rxRocObject <- rxRoc(actualVarName = "RESPONSE", predVarNames = c("RespPrediction"), 
                     data = rxPredOut)

# Draw the ROC curve
plot(rxRocObject)

auc<-rxAuc(rxRocObject)

## model performance parameter
performance <- auc

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

#############################################
#######  test the model as needed ###########
# Load the model
readReg <- rxReadObject(ds, modelName)

all.equal(reg1, readReg)

#############################################
## A logistic regression
#############################################

### Build model

system.time(log1 <- rxLogit(formula = RESPONSE ~ AVG_PURCH + REC_PURCH_AMT + NUMPURCH_LIFE, data = training))

summary(log1)

## model parameters

lang <- "R"
modelName <- "Easter Sale Catalog model"
modelType <- "Logistic Regression"
modelVersion <- 1
owner <- "Jane Schmoe"
built <- "Manual"

### Test model performance

rxPredOut <- rxPredict(modelObject = log1, data = testing, 
                       writeModelVars = TRUE, predVarNames = "RespPrediction")

# Compute the ROC data for the default number of thresholds	
rxRocObject <- rxRoc(actualVarName = "RESPONSE", predVarNames = c("RespPrediction"), 
                     data = rxPredOut)

# Draw the ROC curve
plot(rxRocObject)

auc<-rxAuc(rxRocObject)

## model performance parameter
performance <- auc

#############################################
## save model to DB
#############################################
# Create the data source
ds <- RxOdbcData(table = "ModelTbl", connectionString = sqlConnString)

### Store the model in the database
# write model
rxWriteObject(ds, modelName, log1)
# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelDetails '",
                   modelName, "','", lang, "' ,'" , modelType, "', ",
                   modelVersion, ", '", owner, "', ", performance, " ,'" ,built,"'")
sqlQuery(ch, insQuery)


#############################################
# Decision Tree
#############################################

system.time(tr1 <- rxDTree(formula = RESPONSE ~ AVG_PURCH + REC_PURCH_AMT + NUMPURCH_LIFE, maxDepth = 3, data = training))

tr1

## model parameters

lang <- "R"
modelName <- "Fall Email model"
modelType <- "Decision Tree"
modelVersion <- 1
owner <- "James Schmoe"
built <- "Manual"

### Test model performance

rxPredOut <- rxPredict(modelObject = tr1, data = testing, 
                       writeModelVars = TRUE, predVarNames = "RespPrediction")

# Compute the ROC data for the default number of thresholds	
rxRocObject <- rxRoc(actualVarName = "RESPONSE", predVarNames = c("RespPrediction"), 
                     data = rxPredOut)

# Draw the ROC curve
plot(rxRocObject)

auc<-rxAuc(rxRocObject)

## model performance parameter
performance <- auc

#############################################
## save model to DB
#############################################
# Create the data source
ds <- RxOdbcData(table = "ModelTbl", connectionString = sqlConnString)

### Store the model in the database
# write model
rxWriteObject(ds, modelName, tr1)
# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelDetails '",
                   modelName, "','", lang, "' ,'" , modelType, "', ",
                   modelVersion, ", '", owner, "', ", performance, " ,'" ,built,"'")
sqlQuery(ch, insQuery)

#############################################
## A glm
#############################################

system.time(glm1 <- rxGlm(formula = RESPONSE ~ AVG_PURCH + REC_PURCH_AMT + NUMPURCH_LIFE, data = training))

summary(glm1)

## model parameters

lang <- "R"
modelName <- "Summer Sale model"
modelType <- "Generalized Linear Model"
modelVersion <- 1
owner <- "Joan Schmoe"
built <- "Manual"

### Test model performance

rxPredOut <- rxPredict(modelObject = glm1, data = testing, 
                       writeModelVars = TRUE, predVarNames = "RespPrediction")

# Compute the ROC data for the default number of thresholds	
rxRocObject <- rxRoc(actualVarName = "RESPONSE", predVarNames = c("RespPrediction"), 
                     data = rxPredOut)

# Draw the ROC curve
plot(rxRocObject)

auc<-rxAuc(rxRocObject)

## model performance parameter
performance <- auc

#############################################
## save model to DB
#############################################
# Create the data source
ds <- RxOdbcData(table = "ModelTbl", connectionString = sqlConnString)

### Store the model in the database
# write model
rxWriteObject(ds, modelName, glm1)
# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelDetails '",
                   modelName, "','", lang, "' ,'" , modelType, "', ",
                   modelVersion, ", '", owner, "', ", performance, " ,'" ,built,"'")
sqlQuery(ch, insQuery)

#############################################
## A gbm
#############################################

system.time(gbm1 <- rxBTrees(formula = RESPONSE ~ AVG_PURCH + REC_PURCH_AMT + NUMPURCH_LIFE, data = training))

summary(gbm1)

## model parameters

lang <- "R"
modelName <- "Clearance Sale model"
modelType <- "Gradient Boosted Trees"
modelVersion <- 1
owner <- "Jerry Schmoe"
built <- "Manual"

### Test model performance

rxPredOut <- rxPredict(modelObject = gbm1, data = testing, 
                       writeModelVars = TRUE, predVarNames = "RespPrediction")

# Compute the ROC data for the default number of thresholds	
rxRocObject <- rxRoc(actualVarName = "RESPONSE", predVarNames = c("RespPrediction"), 
                     data = rxPredOut)

# Draw the ROC curve
plot(rxRocObject)

auc<-rxAuc(rxRocObject)

## model performance parameter
performance <- auc

#############################################
## save model to DB
#############################################
# Create the data source
ds <- RxOdbcData(table = "ModelTbl", connectionString = sqlConnString)

### Store the model in the database
# write model
rxWriteObject(ds, modelName, gbm1)
# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelDetails '",
                   modelName, "','", lang, "' ,'" , modelType, "', ",
                   modelVersion, ", '", owner, "', ", performance, " ,'" ,built,"'")
sqlQuery(ch, insQuery)

#############################################
## A Decision Forest
#############################################

system.time(df1 <- rxDForest(formula = RESPONSE ~ AVG_PURCH + REC_PURCH_AMT + NUMPURCH_LIFE, data = training))

summary(df1)

## model parameters

lang <- "R"
modelName <- "Back to School model"
modelType <- "Decision Forest"
modelVersion <- 1
owner <- "Jenny Schmoe"
built <- "Manual"

### Test model performance

rxPredOut <- rxPredict(modelObject = df1, data = testing, 
                       writeModelVars = TRUE, predVarNames = "RespPrediction")

# Compute the ROC data for the default number of thresholds	
rxRocObject <- rxRoc(actualVarName = "RESPONSE", predVarNames = c("RespPrediction"), 
                     data = rxPredOut)

# Draw the ROC curve
plot(rxRocObject)

auc<-rxAuc(rxRocObject)

## model performance parameter
performance <- auc

#############################################
## save model to DB
#############################################
# Create the data source
ds <- RxOdbcData(table = "ModelTbl", connectionString = sqlConnString)

### Store the model in the database
# write model
rxWriteObject(ds, modelName, df1)
# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelDetails '",
                   modelName, "','", lang, "' ,'" , modelType, "', ",
                   modelVersion, ", '", owner, "', ", performance, " ,'" ,built,"'")
sqlQuery(ch, insQuery)

#############################################
## A neural network
#############################################

system.time(nn1 <- rxNeuralNet(formula = RESPONSE ~ AVG_PURCH + REC_PURCH_AMT + NUMPURCH_LIFE,
                               type = "binary", data = training))

summary(nn1)

## model parameters

lang <- "R"
modelName <- "Cyber Monday model"
modelType <- "Neural Network"
modelVersion <- 1
owner <- "Johnny Schmoe"
built <- "Manual"

### Test model performance
### Neural Network comes from MML package and uses different prediction names

rxPredOut <- rxPredict(modelObject = nn1, data = testing, 
                       writeModelVars = TRUE)

# Compute the ROC data for the default number of thresholds	
rxRocObject <- rxRoc(actualVarName = "RESPONSE", predVarNames = c("Probability.1"), 
                     data = rxPredOut)

# Draw the ROC curve
plot(rxRocObject)

auc<-rxAuc(rxRocObject)

## model performance parameter
performance <- auc

#############################################
## save model to DB
#############################################
# Create the data source
ds <- RxOdbcData(table = "ModelTbl", connectionString = sqlConnString)

### Store the model in the database
# write model
rxWriteObject(ds, modelName, nn1)
# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelDetails '",
                   modelName, "','", lang, "' ,'" , modelType, "', ",
                   modelVersion, ", '", owner, "', ", performance, " ,'" ,built,"'")
sqlQuery(ch, insQuery)

##################################################
# close DB channel

close(ch)

##################################################
##################################################
