USE [lung_cancer_database]
GO

DECLARE @PredictionResultSP FLOAT;
EXECUTE PredictLungCancer @PatientIndex = 5, @ModelName = "rx_fast_trees", @PredictionResult = @PredictionResultSP;