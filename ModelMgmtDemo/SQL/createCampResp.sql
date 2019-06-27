USE [ModelMgmtDB]
GO

/****** Object:  Table [dbo].[CustData]    Script Date: 11/26/2018 4:31:38 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SELECT [cust_ID]
      ,[RESPONSE]
      ,[PURCHASE]
  Into dbo.CampaignResponse
  FROM [ModelMgmtDB].[dbo].[CustSmall]