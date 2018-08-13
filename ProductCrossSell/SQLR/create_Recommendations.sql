use CustomerDB;

EXEC sp_execute_external_script
@language = N'R',
@script = N'
###########################################################
#
# Implement Retail Product Cross Sell inside SQL Server
# Uses reshape package
#
###########################################################

#install.packages("reshape")
library(reshape)

### fetch data ###

sqlConnString <- "Driver=SQL Server;Server=MININT-03A5LFB; 
                  Database=CustomerDB;Trusted_Connection=TRUE"

# remove all but product variables
# product variables are binary, but could qty or $$ values

xs <- xs[2:20]

###########################################################
###
##### build models
###
###########################################################

v <- colnames(xs)
l <- length(v)
algo = "rxLogisticRegression"

library(doRSR)
registerDoRSR()

modelList <- foreach(i = 1:l) %do% {
  cat("\n\nBuilding model for product ", v[i], "\n\n")
  # build formula with all inputs; remove target
  inVars <- paste(v[-i],collapse = " + ")
  myFormula <- paste(v[i]," ~ ",inVars)
  s <- paste(algo, "(formula =", myFormula, ", data = xs)")
  eval(parse(text = s))
}

## clean up
rm(xs)

###########################################################
###
##### score customers with list of product models
###
###########################################################

scdo <- RxSqlServerData(connectionString = sqlConnString, table = "ProductXSL")
sc <- rxImport(scdo)

pred <- data.frame(cust_ID = sc$cust_ID)

### the score field varies by algorithm
### change temp$Probability.1 if using another algorithm

foreach(i = 1:l) %do% {
  # do prediction against test set
  cat("\n\nGenerating scores for model ", v[i] , "\n")
  temp <- rxPredict(modelObject = modelList[[i]], data = sc,
                    extraVarsToWrite = "cust_ID")
  pred[i+1] <- temp$Probability.1
}
names(pred)[2:20] <- v

## clean up
rm(temp)
rm(sc)

###########################################################
###
##### create a ranked order listing of products for each customer
###
###########################################################

md <- melt(pred, id=(c("cust_ID")))

# order by customer and descending scores
rs <- md[with(md, order(cust_ID, -value)), ]

# no longer need score (rows are sorted !!!)
rs2 <- rs[,1:2]

sz <- nrow(rs2)

###########################################################
###
##### build output df - ranked list of product names
##### for each customer
###
###########################################################

rs2$prodnum <- rep(1:l,len=sz)

ndf <- reshape(rs2, idvar = "cust_ID", timevar = "prodnum", direction = "wide")

p <- paste0("Product", c(1:l))
pn <- c("cust_ID",p)
colnames(ndf) <- pn

###########################################################
###
##### insert product df into DB
###
###########################################################

reco <- RxSqlServerData(table = "Recommendations", 
                    connectionString = sqlConnString)

if (rxSqlServerTableExists("Recommendations",  connectionString = sqlConnString))  
  rxSqlServerDropTable("Recommendations",  connectionString = sqlConnString)

rxDataStep(inData = ndf, outFile = reco, overwrite = TRUE )

############################ end ################################
',
@input_data_1 = N'select * from dbo.ProductXSL',
@input_data_1_name = N'xs';

