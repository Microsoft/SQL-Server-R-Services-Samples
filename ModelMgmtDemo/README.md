# Model Management Demo Tutorial with SQL Server Machine Learning (R) Services

In this tutorial, we demonstrate how to implement a model management solution with SQL Server and Machine Learning Services.

This tutorial demonstrates a model management solution in a marketing automation scenario, using customer data:

|File|Description|
|-|-|
|`.\Data\CustSmall.csv`|Customer marketing promotion response data|

This tutorial demonstrates how to implement a model management solution using SQL Server. The data processing, model training, and prediction scoring are done using SQL Server stored procedures and by calling R (Microsoft Machine Learning Server) code, the capability provided by SQL Server Machine Learning Services. These procedures can be run within a SQL environment (such as SQL Server Management Studio) or called by applications. This capability could be automated/scheduled for production deployment.

**This package requires the `caret` and `pROC` packages**.

The following is the directory structure for this tutorial:

* `Data`. This contains the provided sample data.
* `R`. This contains the original R code used to build and debug this example. There are 4 separate R source code files. This code can be run from your favorite IDE to populate the ModelMgmtDB database and to demonstrate how the system works.  
* `SQL`. This contains the SQL Server Stored procedures that set up the database and then perform all the system tasks. The code runs in a SQL Server environment.

Additional files found in the root directory:

* `Model Mgmt Tutorial Detailed Description.pdf`. This document describes the goals of the model management system and includes an architectural diagram that shows the data flows in the system and the processing performed at each step.
* `Model Mgmt Tutorial Start Up Instructions.pdf`. This file contains very detailed information on how to run this example, from building the database to populating tables to demonstrating the system.  
* `MyModelMgmtDashboard.pbix`. This is the Power BI dashboard that shows the results of the model management process.
