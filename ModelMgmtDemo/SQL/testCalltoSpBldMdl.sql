use ModelMgmtDB
go

--
-- code for testing stored procedures and clean up results
--

-- exec st proc to create model and save model and details

declare @id nchar(200) = N'Christmas Catalog model',
		@vers float = 2.0

exec dbo.sp_bld_model @id, @vers
go

exec dbo.sp_bld_model 'Christmas Catalog model', 2
go

---------------------------------------------------------------------------
-- CLEAN UP inserts

delete dbo.ModelTbl
where id = 'Christmas Catalog model'
  AND DateCreated = (Select max(DateCreated) from ModelTbl where id = 'Christmas Catalog model')

delete dbo.ModelDetailsTbl
where id = 'Christmas Catalog model'
  AND Version = 2.0

-- end CLEAN UP
---------------------------------------------------------------------------

  --- test create and save model proc

declare @performance float = 0,
		@id nchar(200) = N'Christmas Catalog model'

EXEC dbo.sp_create_model @id, @performance OUTPUT
go


-- test insert model details

declare @lang nchar(10) = N'R',
		@modelType nvarchar(50) = N'Linear Regression',
		@owner nvarchar(50) = N'Joe Schmoe',
		@built nchar(10) = N'Automatic',
		@performance float = 0,
		@id nchar(200) = N'Christmas Catalog model',
		@vers float = 2.0

--EXEC dbo.sp_insertModelDetails "Christmas Catalog model", "R", "Linear Regression", 2.0, "Joe Schmoe", .75, "Automatic"
EXEC dbo.sp_insertModelDetails @id, @lang, @modelType, @vers, @owner, @performance, @built
go