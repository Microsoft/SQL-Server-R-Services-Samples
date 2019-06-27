USE [ModelMgmtDB]
GO

/****** Object:  Table [dbo].[CustData]    Script Date: 11/26/2018 4:31:38 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SELECT [cust_ID]
      ,[CARDPROM]
      ,[REC_PROMO_DT]
      ,[NUMPROM]
      ,[CARDPM12]
      ,[NUMPRM12]
	  ,[PURCH_AMT_LIFE]
      ,[NUMPURCH_LIFE]
      ,[CARDPURCH_LIFE]
      ,[MIN_PURCH_AMT]
      ,[MIN_PURCH_DT]
      ,[MAX_PURCH_AMT]
      ,[MAX_PURCH_DT]
      ,[REC_PURCH_AMT]
      ,[AVG_PURCH]
  Into dbo.AccountHist
  FROM ModelMgmtDB.[dbo].[CustSmall]