-- ================================================
-- Insert Model Usage info into ModelUsageTbl
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
use ModelMgmtDB
go

-- =============================================
-- Create date: 5/29/2019
-- Description:	Insert model usage info into ModelUsageTbl
-- =============================================
CREATE PROCEDURE dbo.sp_insertModelUsage
@id varchar(200) = '',
@campID varchar(200) = '',
@channel nchar(10) = 'Email',
@season nchar(10) = 'Summer'
 

AS
BEGIN

    -- Insert statements for procedure here

	insert into [dbo].[ModelUsageTbl] values
				(@id, @campID, GETDATE(), @channel, @season)

END
GO
