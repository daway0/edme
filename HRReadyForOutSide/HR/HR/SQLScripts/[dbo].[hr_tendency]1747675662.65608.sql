CREATE TABLE [dbo].[HR_tendency](
	[id] [bigint] NOT NULL,
	[Title] [nvarchar](150) NOT NULL,
	[FieldOfStudy_id] [bigint] NOT NULL,
 CONSTRAINT [PK__HR_tende__3213E83F1302FA7F] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
