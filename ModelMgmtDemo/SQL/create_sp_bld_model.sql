-- ================================================
-- Build a new model and insert it into ModelTbl
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
use ModelMgmtDB
go

-- =============================================
-- Create date: 6/4/2019
-- Last Modified date: 6/25/2019
-- Description:	Build a new model and save it
-- =============================================

IF (OBJECT_ID('sp_bld_model') IS NOT NULL)
DROP PROCEDURE sp_bld_model
GO

CREATE PROCEDURE sp_bld_model
@id nchar(200),
@vers float

AS
  BEGIN TRY

  declare @lang nchar(10) = N'R',
		@modelType nvarchar(50) = N'Linear Regression',
		@owner nvarchar(50) = N'No Schmoe',
		@built nchar(10) = N'Automatic',
		@performance float = 0

-- exec st proc to create model

EXEC dbo.sp_create_model @id, @performance OUTPUT;

-- insert to model details table

EXEC dbo.sp_insertModelDetails @id, @lang, @modelType, @vers, @owner, @performance, @built

 END TRY
  BEGIN CATCH
    THROW;
  END CATCH;
GO