-- ================================================
-- Insert Model Details into ModelDetailsTbl
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
use ModelMgmtDB
go

-- =============================================
-- Create date: 5/28/2018
-- Description:	Insert model details into ModelDetailsTbl
-- =============================================
CREATE PROCEDURE dbo.sp_insertModelDetails
@id varchar(200) = '',
@lang nchar(10) = N'R',
@type nvarchar(50) = N'Model Type',
@version float = 0,
@owner nvarchar(50) = N'Nobody',
@perf float = 0,
@built nchar(10) = N'Manual'
 

AS
BEGIN

    -- Insert statements for procedure here

	insert into [dbo].[ModelDetailsTbl] values
				(@id, @lang, @type, @version, @owner, @perf, @built)

END
GO
