-- ================================================
-- Insert Model Performance info into ModelPerfTbl
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
use ModelMgmtDB
go

-- =============================================
-- Create date: 5/29/2019
-- Last Modified date: 6/3/2019
-- Description:	Insert model performance info into ModelPerfTbl
-- Prior to insert, determine if the model performance has decreased since
-- the prior usage, and if so, re-build the model
-- =============================================
CREATE PROCEDURE dbo.sp_insertModelPerf
@id varchar(200) = '',
@campID varchar(200) = '',
@respRate float = 0,
@totRev float = 0
 

AS
BEGIN

DECLARE @rr float = 0;
DECLARE @vers float = 0;

  SELECT @rr = ResponseRate
  FROM [ModelMgmtDB].[dbo].[ModelPerfTbl]
  where id = @id
  AND PerfDate = (Select max(PerfDate) from ModelPerfTbl where id = @id)

  -- Get model version number to increment
  SELECT @vers = Version
  FROM [ModelMgmtDB].[dbo].[ModelDetailsTbl]
  where id = @id
  AND Version = (Select max(Version) from ModelDetailsTbl where id = @id)

  SET @vers = @vers + 1;

  if @rr > @respRate
	EXEC dbo.sp_bld_model @id, @vers
  
   -- Insert statements for procedure here

	insert into [dbo].[ModelPerfTbl] values
				(@id, @campID, GETDATE(), @respRate, @totRev)

END
GO
