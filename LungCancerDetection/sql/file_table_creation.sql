-- Follow the instruction in readme file to enable FileTable on your database

-- Conigure new database  
CREATE DATABASE lung_cancer_database
WITH FILESTREAM ( NON_TRANSACTED_ACCESS = FULL, DIRECTORY_NAME = N'FileTableData' )

-- Configure existing database
ALTER DATABASE lung_cancer_database
SET FILESTREAM ( NON_TRANSACTED_ACCESS = FULL, DIRECTORY_NAME = N'FileTableData' )

-- Creating a FileTable table
USE lung_cancer_database
GO
CREATE TABLE MriData AS FileTable  
WITH (   
	FileTable_Directory = 'MriData',  
	FileTable_Collate_Filename = database_default  
);  
