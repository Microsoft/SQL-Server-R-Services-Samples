##################################################
#
# Insert model usage info into ModelUsageTbl
# Initially populate table with multiple campaigns
#
# Part of Model Management Demo
#
# Create Date: May 29, 2019
# Last Update: May 29, 2019
#
#################################################

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
channel <- "DirectMail"
season <- "Winter"

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelUsage '",
                   modelID, "','", campID, "' ,'" , channel, "','", season, "'")
sqlQuery(ch, insQuery)

#############################################
## Use Christmas Catalog model
#############################################

## st proc parameters

modelID <- "Christmas Catalog model"
campID <- "Second Christmas Mailing - December"
channel <- "DirectMail"
season <- "Winter"

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelUsage '",
                   modelID, "','", campID, "' ,'" , channel, "','", season, "'")
sqlQuery(ch, insQuery)

#############################################
## Use Easter Sale Catalog model
#############################################

## st proc parameters

modelID <- "Easter Sale Catalog model"
campID <- "Easter Mailing - March"
channel <- "DirectMail"
season <- "Spring"

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelUsage '",
                   modelID, "','", campID, "' ,'" , channel, "','", season, "'")
sqlQuery(ch, insQuery)

#############################################
## Use Fall Email model
#############################################

## st proc parameters

modelID <- "Fall Email model"
campID <- "Fall Email Blast 1 - October"
channel <- "EMail"
season <- "Fall"

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelUsage '",
                   modelID, "','", campID, "' ,'" , channel, "','", season, "'")
sqlQuery(ch, insQuery)

#############################################
## Use Fall Email model
#############################################

## st proc parameters

modelID <- "Fall Email model"
campID <- "Fall Email Blast 2 - November"
channel <- "EMail"
season <- "Fall"

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelUsage '",
                   modelID, "','", campID, "' ,'" , channel, "','", season, "'")
sqlQuery(ch, insQuery)

#############################################
## Use Summer Sale model
#############################################

## st proc parameters

modelID <- "Summer Sale model"
campID <- "First Summer Newspaper Insert - June"
channel <- "Insert"
season <- "Summer"

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelUsage '",
                   modelID, "','", campID, "' ,'" , channel, "','", season, "'")
sqlQuery(ch, insQuery)

#############################################
## Use Summer Sale model
#############################################

## st proc parameters

modelID <- "Summer Sale model"
campID <- "Second Summer Newspaper Insert - July"
channel <- "Insert"
season <- "Summer"

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelUsage '",
                   modelID, "','", campID, "' ,'" , channel, "','", season, "'")
sqlQuery(ch, insQuery)

#############################################
## Use Summer Sale model
#############################################

## st proc parameters

modelID <- "Summer Sale model"
campID <- "Third Summer Newspaper Insert - August"
channel <- "Insert"
season <- "Summer"

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelUsage '",
                   modelID, "','", campID, "' ,'" , channel, "','", season, "'")
sqlQuery(ch, insQuery)

#############################################
## Use Clearance Sale model
#############################################

## st proc parameters

modelID <- "Clearance Sale model"
campID <- "Clearance Sale TV Ad - January"
channel <- "TV"
season <- "Winter"

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelUsage '",
                   modelID, "','", campID, "' ,'" , channel, "','", season, "'")
sqlQuery(ch, insQuery)

#############################################
## Use Back to School model
#############################################

## st proc parameters

modelID <- "Back to School model"
campID <- "Back To School Newspaper Insert - August"
channel <- "Insert"
season <- "Summer"

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelUsage '",
                   modelID, "','", campID, "' ,'" , channel, "','", season, "'")
sqlQuery(ch, insQuery)

#############################################
## Use Cyber Monday model
#############################################

## st proc parameters

modelID <- "Cyber Monday model"
campID <- "Cyber Monday EMail - November"
channel <- "EMail"
season <- "Fall"

# write model details
insQuery <- paste0("EXEC dbo.sp_insertModelUsage '",
                   modelID, "','", campID, "' ,'" , channel, "','", season, "'")
sqlQuery(ch, insQuery)

##################################################
# close DB channel

close(ch)

##################################################
##################################################