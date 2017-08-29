# Lung Cancer Detection Algorithm in SQL Server

This document describes how to execute a transfer learning algorithm using deep learning and SQL Server in the context of lung cancer detection. We want to prove with this solution a new paradigm of computation, where the intelligence of the application is brought to the data, instead of bringing the data to the application. 

The data we used are CT scans from the 2017 [Data Science Bowl](https://www.kaggle.com/c/data-science-bowl-2017/data). The scans are horizontal slices of the thorax and the images are black and white and of size `512x512`. The scans are grouped by patient, there are 1595 patients and each of them have a variable number of scans that goes from 100 to 500 images. The dataset is labelled per patient, not per image, this means that for each patient we have a label of having cancer or not.

In the next figure there is an animation showing all the scans for one patient:

<p align="center">
<img src="https://migonzastorage.blob.core.windows.net/projects/data_science_bowl_2017/gif/0015ceb851d7251b8f399e39779d1e7d.gif" alt="animation of lung cancer scans" width="15%"/>
</p>

We use transfer learning with a pre-trained Convolutional Neural Network (CNN) on [ImageNet dataset](http://image-net.org/) as a featurizer to generate features from the Data Science Bowl dataset, this process is computed with microsoftml's featurizer. Once the features are computed, a fast trees model is applied to classify the image.

A similar process is explained in detail in this [blog](https://blogs.technet.microsoft.com/machinelearning/2017/02/17/quick-start-guide-to-the-data-science-bowl-lung-cancer-detection-challenge-using-deep-learning-microsoft-cognitive-toolkit-and-azure-gpu-vms/).


To create the featurizer, we remove the last layer of the pretrained CNN (in this example we used the [ResNet architecture](https://arxiv.org/abs/1512.03385)) and use the output of the penultimate layer as features. Each patient has an arbitrary number of scan images. The images are cropped to `224×244` to match the format of ImageNet. They are fed to the pre-trained network in k batches and then convoluted in each internal layer, until the penultimate one. The output of the network average-pooled for each patient. These avarage-pooled, dimension-reduced features are the features we feed to the fast trees model.

Once the fast trees model is trained, it can be operationalized to classify cancerous scans for other patients using a web app.

In the next sections we will explain how to execute this system inside SQL. All the data, models and resulting features are stored and queried in different tables of a SQL database. There are 3 main processes: featurization, training and scoring.


## Installation

The installation process can be found [here](INSTALL.md).

## Preprocessing

We have to download the data from [kaggle dataset](https://www.kaggle.com/c/data-science-bowl-2017/data). The images are in [DICOM format](https://en.wikipedia.org/wiki/DICOM) and consist of a group of slices of the thorax of each patient as it is shown in the following figure:

<p align="center">
	<img src="https://msdnshared.blob.core.windows.net/media/2017/02/021717_1842_QuickStartG2.png" alt="lung cancer scans" width="30%"/>
	<img src="https://msdnshared.blob.core.windows.net/media/2017/02/021717_1842_QuickStartG3.png" alt="lung cancer scans" width="30%"/>
</p>

We are going to upload the images to SQL. The reason for doing this, instead of reading the images directly from disk, is because we want to simulate an scenario where all the data is already in SQL. For demo purposes we are going to use a small subset of the images, they can be found in [stage1_labels_partial.csv](data/stage1_labels_partial.csv). This subset consists of 200 patients out of 1595. The complete patient info is [stage1_labels.csv](data/stage1_labels.csv).

The first step is to create in SQL Server a database called `LungCancer`. We also require that FileTables are enabled on the database. This is for working with image data in SQL Server. Follow the instructions [here](https://docs.microsoft.com/en-us/sql/relational-databases/blob/enable-the-prerequisites-for-filetable) to set it up. Execute [file_table_creation.sql](sql/file_table_creation.sql) in order to create this database and allow it to support FileTables. This script will also create a FileTable called `MriData`.

In addition, SQLRUsergroup user group should be granted dbreader access on your database. Otherwise, the sp_execute_external_script won't be able to access the image files.

The next step is to upload the images. First you need to put the correct paths in the file [config_preprocessing.py](preprocessing/config_preprocessing.py.template). In case you want to upload the full dataset, just uncomment `STAGE1_LABELS = os.path.join(DATA_PATH, 'stage1_labels.csv')`. In addition, you need to set `IMAGES_FOLDER` to the location of your file table. To import the images to the SQL database using the FileTable you have set up, you have to execute the script [insert_scan_images_in_sql_database.py](preprocessing/insert_scan_images_in_sql_database.py). This will take a while.

In the mean time, execute the script [insert_other_items_in_sql_database.py](preprocessing/insert_other_items_in_sql_database.py). This script creates and fill tables for the labels, the CNN model and a gif representation of the images. 

## Python Workflow
The python workflow is meant to demonstrate how a data scientist might prepare the model prior to operationalizing it in SQL.

There are two ways to walk through this workflow. One is by executing the stepN_*.py files in order. These files will generate features, perform average pooling, train a fast trees model, and score the fast trees model. The other way is to walk through the ipython notebook: [data_scientist_workflow.ipynb](Python/data_scientist_workflow.ipynb).

## SQL Workflow
### Process 1: Featurization of Lung Scans with CNN

The initial process generates features from the scans using a pretrained ResNet. In the SQL stored procedure [sp_00_cnn_feature_generation_create.sql](sql/sp_00_cnn_feature_generation_create.sql), the code can be found. To create the store procedure you just need to execute the SQL file in SQL Server Management Studio. This will create several new stored procedures under `lung_cancer_database/Programmability/Stored Procedures`.

To execute this stored procedure you have to execute the file [sp_00_cnn_feature_generation_execute.sql](sql/sp_00_cnn_feature_generation_execute.sql). This process takes quite a while.

### Process 2: Training of Scan Features with Fast Trees

Once the features are computed and inserted in the SQL table, we use them to train a fast trees model using the microsoftml library. The code that computes this process is [sp_01_training_and_scoring_create.sql](sql/sp_01_training_and_scoring_create.sql) and generates stored procedure called `dbo.TrainModel` and `dbo.ScoreModel`.

This process takes around 1 min.

### Process 3: Operationalize Scoring with the Trained Classifier

The final process is the operationalization routine. The boosted tree can be used to compute the probability of a new patient of having cancer. The script is [sp_02_individual_prediction_create.sql](sql/sp_02_individual_prediction_create.sql) and generates a stored procedure called `PredictLungCancer`. This can be connected to a web app via an API.

The inputs of the SQL stored procedure are `@PatientIndex` and `@ModelName`. The output is the prediction result `@PredictionResult` given a patient index and a model name. Inside the stored procedure, we get the fast trees model (which is serialized and stored as a binary variable) and the features of the patient, which are stored in a sql table.

In this case there is an input and output for the python routine from SQL. The input is `PatientIndex` which is the index of the patient we want to analyze. The output is `PredictionResult`, which is the probability of this patient of having cancer.

To execute this stored procedure you have to makes this query, which takes 1s:

```sql
DECLARE @PredictionResultSP FLOAT;
EXECUTE lung_cancer_database.dbo.PredictLungCancer @PatientIndex = 0, @PredictionResult = @PredictionResultSP;
```
The variable `@PredictionResultSP` is the output of the stored procedure and `@PatientIndex = 0` is the input. If we use the small dataset, the maximum input is 200, in case we use the full dataset, the maximum input is 1594.

## Lung Cancer Detection Web Service

We created a demo web app to show the lung cancer detection in SQL python. To run it, you just need to execute [api_service.py](web_app/api_service.py)

The web page can be accessed at `http://localhost:5000`. 

In case you want to access it from outside you have to open the port 5000 in the Azure portal (Network Interfaces/Network security group/Inbound security rules). You need to do the same in the Firewall inside the virtual machine (Windows Firewall with Advanced Security/Inbound rules). To access the web service from outside just replace `localhost` with the DNS or IP of the VM.

You can try to search a patient called Anthony or another call Ana. You can also search for patients by ID entering a number between 0 and 200 (1594 if you use the full dataset).

## Disclaimer

The idea of the lung cancer demo is to showcase that a deep learning algorithm can be computed using revoscalepy and microsoftml inside SQL in python. 

The accuracy of the actual algorithm is low. It has a very simple pipeline. 

An example of an algorithm with higher accuracy can be found [here](https://eliasvansteenkiste.github.io/machine%20learning/lung-cancer-pred/), the pipeline has a 3D CNN for nodule segmentation, one CNN for false positive reduction, another CNN for identifying if the nodule is malignant or not, then transfer learning and finally ensembling.  

It is important to understand that the focus of the demo is not the algorithm itself but the pipeline which allows to execute deep learning in a SQL database.


## References

The meat of this demo was adapeted from [this demo](https://github.com/Azure/sql_python_deep_learning) that showcases how a deep learning algorithm can be computed using cntk inside SQL in python.

## Contributing

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
