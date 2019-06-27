-- ================================================
-- Create Models View
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
use ModelMgmtDB
go

-- =============================================
-- Create date: 6/26/2019
-- Modified date: 6/26/2019
-- Description:	create model results view
-- =============================================
CREATE VIEW v_ModelResults AS

 SELECT u.id,
		u.CampID,
		u.UsageDate,
		u.Channel,
		u.Season,
		p.ResponseRate,
		p.TotalRevenue
  FROM [dbo].[ModelUsageTbl] u JOIN [dbo].[ModelPerfTbl] p
  ON u.id = p.id AND u.CampID = p.CampID

GO
