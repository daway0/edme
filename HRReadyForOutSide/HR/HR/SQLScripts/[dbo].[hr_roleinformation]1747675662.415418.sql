CREATE TABLE [dbo].[HR_roleinformation](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[DescriptionType] [nvarchar](1) NOT NULL,
	[RoleID] [int] NOT NULL,
	[Title] [nvarchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
