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
-- Create date: 3/23/2018
-- Modified date: 4/26/2019
-- Description:	create model details view
-- =============================================
CREATE VIEW v_Models AS

 SELECT 	d.id,
		d.Language,
		d.Type,
		d.Version,
		d.Owner,
		d.Performance,
		d.BuildType,
		m.DateCreated
  FROM [dbo].[ModelDetailsTbl] d JOIN [dbo].[ModelTbl] m
  ON d.id = m.id

GO
