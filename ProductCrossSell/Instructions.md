#Retail Customer Cross-sell Template with SQL Server Machine Learning (R) Services

In this template, we demonstrate how to develop and deploy end-to-end customer cross-sell prediction models with SQL Server Machine Learning Services.

This template demonstrates customer cross-sell modeling in a retail scenario, using customer purchase history data:

File	Description
.\Data\xsl.csv	User purchase history data

This template demonstrates how to use SQL to do model development and operationalization. The data processing, model training, and prediction scoring are done using SQL calling R (Microsoft Machine Learning Server) code, the capability provided by SQL Server Machine Learning Services. These procedures can be run within a SQL environment (such as SQL Server Management Studio) or called by applications to make predictions. This capability could easily be automated/scheduled for production deployment.

The following is the directory structure for this template:

•	Data This contains the provided sample data.
•	R This contains the original R code used to build and debug this example. This code can be run from your favorite IDE to follow the code and check on the intermediate results produced.  
•	SQLR This contains the Stored SQL procedure from data processing to model deployment. It runs in a SQL Server environment. This code differs slightly from the R code as the built-in stored procedure sp_execute_external_script allows a table to be passed into the embedded R code via a parameter.
