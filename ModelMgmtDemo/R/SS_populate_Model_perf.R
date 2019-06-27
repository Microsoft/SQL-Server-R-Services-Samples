############################################################
#
# Insert model performance info into ModelPerfTbl
# Initially populate table with multiple campaign results
## This simulates a feed from a CRM system which uses the models
#
# Part of Model Management Demo
#
# Create Date: May 29, 2019
# Last Update: May 29, 2019
#
############################################################

library(RODBC)

# DB connection to save models using ODBC DSN
ch <- odbcConnect("ModelMgmtDB")

#########################################################################
####### insert 1 row for each time model is used
#########################################################################

#############################################
## Use Christmas Catalog model
#############################################

## st proc parameters

modelID <- "Christmas Catalog model"
campID <- "First Christmas Mailing - November"
respRate <- 5.5
totRev <- 1000000

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelPerf '",
                   modelID, "','", campID, "' ," , respRate, ",", totRev)
sqlQuery(ch, insQuery)

#############################################
## Use Christmas Catalog model
#############################################

## st proc parameters

modelID <- "Christmas Catalog model"
campID <- "Second Christmas Mailing - December"
respRate <- 5.8
totRev <- 1250000

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelPerf '",
                   modelID, "','", campID, "' ," , respRate, ",", totRev)
sqlQuery(ch, insQuery)

#############################################
## Use Easter Sale Catalog model
#############################################

## st proc parameters

modelID <- "Easter Sale Catalog model"
campID <- "Easter Mailing - March"
respRate <- 3.7
totRev <- 240000

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelPerf '",
                   modelID, "','", campID, "' ," , respRate, ",", totRev)
sqlQuery(ch, insQuery)

#############################################
## Use Fall Email model
#############################################

## st proc parameters

modelID <- "Fall Email model"
campID <- "Fall Email Blast 1 - October"
respRate <- 4.1
totRev <- 375000

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelPerf '",
                   modelID, "','", campID, "' ," , respRate, ",", totRev)
sqlQuery(ch, insQuery)

#############################################
## Use Fall Email model
#############################################

## st proc parameters

modelID <- "Fall Email model"
campID <- "Fall Email Blast 2 - November"
respRate <- 4.7
totRev <- 425000

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelPerf '",
                   modelID, "','", campID, "' ," , respRate, ",", totRev)
sqlQuery(ch, insQuery)

#############################################
## Use Summer Sale model
#############################################

## st proc parameters

modelID <- "Summer Sale model"
campID <- "First Summer Newspaper Insert - June"
respRate <- 7.0
totRev <- 600000

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelPerf '",
                   modelID, "','", campID, "' ," , respRate, ",", totRev)
sqlQuery(ch, insQuery)

#############################################
## Use Summer Sale model
#############################################

## st proc parameters

modelID <- "Summer Sale model"
campID <- "Second Summer Newspaper Insert - July"
respRate <- 7.5
totRev <- 650000

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelPerf '",
                   modelID, "','", campID, "' ," , respRate, ",", totRev)
sqlQuery(ch, insQuery)

#############################################
## Use Summer Sale model
#############################################

## st proc parameters

modelID <- "Summer Sale model"
campID <- "Third Summer Newspaper Insert - August"
respRate <- 8.0
totRev <- 700000

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelPerf '",
                   modelID, "','", campID, "' ," , respRate, ",", totRev)
sqlQuery(ch, insQuery)

#############################################
## Use Clearance Sale model
#############################################

## st proc parameters

modelID <- "Clearance Sale model"
campID <- "Clearance Sale TV Ad - January"
respRate <- 5.8
totRev <- 470000

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelPerf '",
                   modelID, "','", campID, "' ," , respRate, ",", totRev)
sqlQuery(ch, insQuery)

#############################################
## Use Back to School model
#############################################

## st proc parameters

modelID <- "Back to School model"
campID <- "Back To School Newspaper Insert - August"
respRate <- 7.1
totRev <- 800000

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelPerf '",
                   modelID, "','", campID, "' ," , respRate, ",", totRev)
sqlQuery(ch, insQuery)

#############################################
## Use Cyber Monday model
#############################################

## st proc parameters

modelID <- "Cyber Monday model"
campID <- "Cyber Monday EMail - November"
respRate <- 9.1
totRev <- 2000000

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelPerf '",
                   modelID, "','", campID, "' ," , respRate, ",", totRev)
sqlQuery(ch, insQuery)

##################################################
# close DB channel

close(ch)

##################################################
##################################################