e#Online Fraud Detection Template implemented on SQL Server R Service
--------------------------
 * **Introduction**
	 * **System Requirements**
	 * **Workflow Automation**
 * **Step 0: Data Preparation**
 * **Step 1: Tagging**
 * **Step 2: Preprocessing**
 * **Step 3: Create Risk Tables**
 * **Step 4: Feature Engineering for Training**
 * **Step 5: Model Training**
 * **Step 6: Prediction**
 * **Step 7: Evaluation**
 * **Step 8: Production Scoring**

### Introduction:
-------------------------

Fraud detection is an important machine learning application. In this template, the online purchase transaction fraud detection scenario (for the online merchants, detecting whether a transaction is made by the original owner of payment instrument) is used as an example. This on-prem implementation with SQL Server R Services is equivalent to the [Azure ML template for Online Fraud Detection](https://gallery.cortanaanalytics.com/Collection/Online-Fraud-Detection-Template-1).

For customers that prefers an on-prem solution, the implementation with SQL Server R Services is a great option, which takes advantage of the power of SQL Server and RevScaleR. In this template, we implemented all steps in SQL stored procedures, where data cleaning, data preprocessing and feature engineering are implemented in pure SQL, while the model training, scoring and evaluation steps are implemented with SQL stored procedures calling R (Microsoft R Server) code. 

All the steps can be executed on SQL Server client environment (such as SQL Server Management Studio), as well as from other applications. We provide a Windows PowerShell script which invokes the SQL scripts and demonstrate the end-to-end modeling process.

### System Requirements
-----------------------

To run the scripts, it requires the following:
 * SQL server 2016 CTP 3 with Microsoft R server installed and configured;
 * The SQL user name and password, and the user is configured properly to execute R scripts in-memory;
 * SQL Database which the user has write permission and execute stored procedures;
 * For more information about SQL server 2016 and R service, please visit: https://msdn.microsoft.com/en-us/library/mt604847.aspx

### Workflow Automation
-------------------

We provide a Windows PowerShell script to demonstrate the end-to-end workflow. To learn how to run the script, open a PowerShell command prompt, navigate to the directory storing the powershell script and type:

                Get-Help .\SQLR-Fraud-Detection.ps1

To invoke the PowerShell script, type:

                .\SQLR-Fraud-Detection.ps1 -ServerName "Server Name" -DBName "Database Name"
                
You can choose whether to execute each step or not.

### Step 0: Data Preparation

The following data are provided in the Data directory:

<table style="width:85%">
  <tr>
    <th>File</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>.\Data\Online Fraud-Fraud Transactions.csv</td>
    <td>Raw fraud transaction data</td>
  </tr>
  <tr>
    <td>.\Data\Online Fraud-Untagged Transactions.csv</td>
    <td>Raw transaction data without fraud tag</td>
  </tr>
</table>

In this step, we'll create two tables named "untaggedData" and "fraud" in SQL Server database OnlineFraudDetection, and the data is uploaded to these tables using bcp command in the powershell script.

Input:

* untagged data: Online Fraud- Untagged Transactions.csv
* fraud data: Online Fraud- Fraud Transactions.csv

Output:

* "untaggedData" table in SQL server
* "fraud" table in SQL server


### Step 1: Tagging
In this step, we tag the untagged data on account level based on the fraud data. The tagging logic is the following. In fraud data, we group it by account ID and sort by time, thus, we have the fraud time period for each fraud account. For each transaction in untagged data, if the account ID is not in fraud data, this transaction is labeled as non fraud (label = 0); if the account ID is in fraud data and the transaction time is within the fraud time period of this account, this transaction is labeled as fraud (label = 1); if the account ID is in fraud data and the transaction time is out of the fraud time period of this account, this transaction is labeled as pre-fraud or unknown (label = 2) which will be removed later. Besides, we will do some re-formatting for some columns. For example, uniform the transactionTime filed to 6 digits. 

Input:
* "untaggedData" table
* "fraud" table

Output:
* "sql_taggedData" table

Related files:
* Step1_Tagging.sql: Create a SQL stored procedure to re-format and tag the data

### Step 2: Preprocessing
In this step, do the following:

* Clean the tagged data (filling missing values and removing transactions with invalid transaction time and amount). 
* Split the tagged data into training set and testing set on account level. This means transactions from one account will be put into either training or testing set. Training/testing ratio is 7/3.

Input:

* "sql_taggedData" table

Output:

* "sql_tagged_training" table
* "sql_tagged_testing" table

Related files:

* FillMissing.sql: Create a stored procedure which will be used in the main procedure of step 2
* Step2_Preprocess.sql: Create a SQL stored procedure to clean and split the data

### Step 3: Create Risk Tables
In this step, we create risk tables for bunch of categorical variables, such as location related variables. This is related to the method called "weight of evidence". The risk table stores risk (log of smoothed odds ratio) for each level of one categorical variable. For example, variable **X** has two levels: **A** and **B**. For each level (e.g., **A**), we compute the following:

* Total number of good transactions, **n_good(A)**, 
* Total number of bad transactions, **n_bad(A)**. 
* The smoothed odds, **odds(A) = (n_bad(A)+10)/(n_bad(A)+n_good(A)+100)**. 
* The the risk of level **A**, **risk(A) = log(odds(A)/(1-odds(A))**. 

Thus, the risk table of variable **X** looks like the following:

<table style="width:85%">
  <tr>
    <th>X</th>
    <th>Risk</th>
  </tr>
  <tr>
    <td>A</td>
    <td>Risk(A)</td>
  </tr>
  <tr>
    <td>B</td>
    <td>Risk(B)</td>
  </tr>
</table>

With the risk table, we can assign the risk value to each level. This is how we transform the categorical variable into numerical variable. One thing need to be mentioned, if a new level of a categorical values occurs in test dataset, we use the average risk to fill this new level. For the example, if in test set, variable X has new level "C", we can't find any risk value in the risk table. Thus, we use (risk(A)+risk(B))/2 as risk(C).

Input:

* "sql_tagged_training" table

Output:

* "sql_risk_var" table: a table stores the name of variables to be converted and the name of risk tables
* "sql_risk_xxx" tables: risk tables for variable xxx.

Related files:

* CreateRiskTable.sql: Create a SQL stored procedure to generate risk tables.
* Step3_CreateRiskTables.sql: Create a SQL stored procedure to generate risk tables for all required variables.

### Step 4: Feature Engineering for Training
This step does feature engineering to training data set. We will generate two groups of new features:

* Binary variables. For example, address mismatch flags.
* Numerical risk variables transformed from categorical variables based on the risk tables created in step 3.

Input:

* "sql_tagged_training" table
* "sql_risk_var" table
* "sql_risk_xxx" tables

Output:

* "sql_tagged_training" table: new created features will be appended to original sql_tagged_training table

Related files:

* AssignRisk.sql: Create a SQL stored procedure to assign risk to variables according to risk tables. This procedure will be used by FeatureEngineer procedure.
* FillNA.sql: Create a SQL stored procedure to fill NA value if NA value appear when assign risk. This procedure will be used by FeatureEngineer procedure.
* FeatureEngineer.sql: Create a SQL stored procedure to do feature engineering.
* Step4_FeatureEngineerForTraining.sql: Create a stored procedure to do feature engineering for training set.

### Step 5: Model Training
In this step, we train a gradient boosted tree model with training data.

Input:

* "sql_tagged_training" table

Output:

* "sql_trained_model" table: stores a serialized model 

Related files:

* Step5_Training.sql: Create a SQL stored procedure to train model by calling RRE

### Step 6: Prediction (Scoring)
This step do the following steps for the test data, or production data:

*  feature engineering 
*  scores test set using the trained model in step 5. 
  
The feature engineering part is the same as that for training. 

Input:

* "sql_trained_model" table
* "sql_tagged_testing" table

Output:

* "sql_predict_score" table: table stores the predicted score in the last column

Related files:

* FeatureEngineer.sql
* Step6_Prediction.sql: Create a SQL procedure to do feature engineering and scoring to the test set.

### Step 7: Evaluation
This step evaluates the performance on both account level and transaction level.

Input:

* "sql_predict_score" table

Output:

* "sql_performance" table: stores metrics on account level.
* "sql_performance_auc" table: stores metrics on transaction level: AUC of ROC curve. 

Related files:

* Step7_Evaluation.sql: Create a SQL stored procedure to evaluate performance on account level. 
* Step7_Evaluation_AUC.sql: Create a SQL stored procedure to evaluate performance on transaction level.

### STEP 8: Production Scoring

In this step, we show how we call the stored procedures to make predictions on new data. A single record is taken from the testing dataset for demo purpose. 

To invoke the production scoring, you need turn on the "Score" switch in the provided powershell script:

	.\SQLR-Fraud-Detection.ps1 -ServerName "Server Name" -DBName "Database Name" -Score
 

Input:

* "sql_trained_model" table
* "sql_scoring" table

Output:

* The result will be displayed in the Powershell console.
