CREATE TABLE [dbo].[HR_city](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[CityTitle] [nvarchar](100) NOT NULL,
	[IsCapital] [bit] NOT NULL,
	[CityCode] [nvarchar](4) NULL,
	[Province_id] [bigint] NOT NULL,
 CONSTRAINT [PK__HR_city__3213E83F790024BE] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
