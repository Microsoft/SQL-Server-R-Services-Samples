USE ModelMgmtDB
GO

/****** Object:  Table [dbo].[ModelTbl]    Script Date: 3/19/2018 5:27:00 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--  CREATE SIMPLE MODEL TABLE

CREATE TABLE [dbo].[ModelTbl](
	[id] varchar(200) not null,
    [value] varbinary(max),
	[DateCreated] DATETIME NOT NULL DEFAULT(GETDATE()),
	CONSTRAINT PK_mdltbl PRIMARY KEY CLUSTERED (id,DateCreated)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

-- create model details table

CREATE TABLE [dbo].[ModelDetailsTbl](
	[id] varchar(200) not null,
	[Language] [nchar](10) NULL,
	[Type] [nvarchar](50) NULL,
	[Version] [float] NOT NULL,
	[Owner] [nvarchar](50) NULL,
	[Performance] [float] NULL,
	[BuildType] [nchar](10) NULL,
	CONSTRAINT PK_mdldtls PRIMARY KEY CLUSTERED (id,Version)
) ON [PRIMARY] 
GO

-- create model usage table

CREATE TABLE [dbo].[ModelUsageTbl](
	[id] varchar(200) not null,
	[CampID] varchar(200) not null,
	[UsageDate] [datetime] NULL,
	[Channel] [nchar](10) NULL,
	[Season] [nchar](10) NULL
) ON [PRIMARY] 
GO

-- create model performance table

CREATE TABLE [dbo].[ModelPerfTbl](
	[id] varchar(200) not null,
	[CampID] varchar(200) not null,
	[PerfDate] [datetime] NULL,
	[ResponseRate] [float] NULL,
	[TotalRevenue] [float] NULL
) ON [PRIMARY] 
GO


