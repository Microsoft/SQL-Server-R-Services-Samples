## Installation

This file explains how to install SQL Server with python and all the needing libraries to run the lung cancer demo.

#### Python with SQL Server Community Technical Preview

The first step is to download [SQL Server 2017 CTP](https://www.microsoft.com/en-us/evalcenter/evaluate-sql-server-2017-ctp/). One of the most important features of the version is that it has built-in Python and R integration. It comes with Anaconda 4.2.0 (64-bit) with Python 3.5. 

To test that python is working correctly, make sure that the library `revoscalepy` can be loaded. To test it, go to the installation folder and look for `python.exe` inside `PYTHON_SERVICES` folder.

	cd "C:\Program Files\Microsoft SQL Server\YOUR-MSSQL-SERVER-INSTANCE-FOLDER\PYTHON_SERVICES"
	python.exe -c "import revoscalepy"

You have to add this folder (`C:\Program Files\Microsoft SQL Server\YOUR-MSSQL-SERVER-INSTANCE-FOLDER\PYTHON_SERVICES`) to the windows path. 

Make sure that python runs inside SQL Server correctly. For that, open SQL Server and connect to your database engine. You need to enable external scripts. For that, press `New Query` and execute: 

	Exec sp_configure 'external scripts enabled', 1
	Reconfigure with override

Then you need to restart SQL Server. Right click on the server and then restart. After restarting, you have to make sure that in external scripts enables run_value is 1.

Finally, to test that everything works correctly you have to execute the file [sqlpytest.sql](sql/sqlpytest.sql).

You need to change the user and password in SQL Server. For that you have to execute the file `change_auth.sql` (changing the variables user and password).

#### Install the rest of the libraries needed to run the the demo
The next step is to install several libraries that we need to run the demo. First you need to install OpenCV:

	cd "C:\Program Files\Microsoft SQL Server\YOUR-MSSQL-SERVER-INSTANCE-FOLDER\PYTHON_SERVICES\Scripts"
	conda.exe install -c https://conda.binstar.org/conda-forge opencv -y

Finally, you need to install the libraries available in the `requirements.txt`. For that you have execute SQL `pip` inside the directory where you downloaded this repo. So, in a terminal write:

	"C:\Program Files\Microsoft SQL Server\YOUR-MSSQL-SERVER-INSTANCE-FOLDER\PYTHON_SERVICES\Scripts\pip.exe" install -r requirements.txt

#### Install lung cancer detection libraries
The last step is to install the lung cancer libraries. You have to go to the folder where you downloaded the libraries and fill up the file [connection_settings.py](lung_cancer/connection_settings.py.template) with your credentials. Another way to add the credentials is using environmnet variables. In this case we use a file embedded in the library because it's easier with the SQL python system. Once the credentials are changed, execute from there:

	cd PATH-TO-SQL-PYTHON-DEEP-LEARNING-REPO
	"C:\Program Files\Microsoft SQL Server\YOUR-MSSQL-SERVER-INSTANCE-FOLDER\PYTHON_SERVICES\python.exe" setup.py install


#### Test that everything works correctly
Once everything was installed, we have to make sure that all libraries can be loaded from SQL. To test it, execute the file [sql_python_load_libs.sql](sql/sql_python_load_libs.sql). You should see the following:

```bash
*********************************************************************************************
3.5.2 |Anaconda 4.2.0 (64-bit)| (default, Jul  5 2016, 11:41:13) [MSC v.1900 64 bit (AMD64)]
!!!Hello World!!!
C:\PROGRA~1\MICROS~1\MSSQL1~1.MSS\MSSQL\EXTENS~1\MSSQLSERVER01\DD9AFD48-A1BB-49C4-9574-DF93B7A8AFFD
Version pandas: 0.18.1
Version OpenCV: 3.1.0
Version Lung Cancer: 0.1
*********************************************************************************************
```
