-- ================================================
-- Create Model Data View
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
use ModelMgmtDB
go

-- =============================================
-- Create date: 4/26/2019
-- Modified date: 4/26/2019
-- Description:	create model details view
-- =============================================
CREATE VIEW v_ModelData AS

 SELECT a.cust_ID
      ,a.CARDPROM
      ,a.REC_PROMO_DT
      ,a.NUMPROM
      ,a.CARDPM12
      ,a.NUMPRM12
      ,a.PURCH_AMT_LIFE
      ,a.NUMPURCH_LIFE
      ,a.CARDPURCH_LIFE
      ,a.MIN_PURCH_AMT
      ,a.MIN_PURCH_DT
      ,a.MAX_PURCH_AMT
      ,a.MAX_PURCH_DT
      ,a.REC_PURCH_AMT
      ,a.AVG_PURCH
	  ,c.RESPONSE
	  ,c.PURCHASE
  FROM [dbo].[AccountHist] a JOIN [dbo].[CampaignResponse] c
  ON a.cust_ID = c.cust_ID

GO
