USE [HR]
GO
/****** Object:  UserDefinedFunction [dbo].[Date_MiladiToShamsi]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[Date_MiladiToShamsi] (@inputDate DATE)
RETURNS VARCHAR(10)
AS
BEGIN
    DECLARE @persianYear INT;
    DECLARE @nowruz DATE;
    DECLARE @days INT;
    DECLARE @persianMonth INT;
    DECLARE @persianDay INT;
    DECLARE @needsAdjustment BIT = 0;
 
    -- محاسبه سال شمسی
    IF MONTH(@inputDate) > 3 OR (MONTH(@inputDate) = 3 AND DAY(@inputDate) >= 21)
        SET @persianYear = YEAR(@inputDate) - 621;
    ELSE
        SET @persianYear = YEAR(@inputDate) - 622;
 
    -- جدول سال‌های کبیسه شمسی
    DECLARE @LeapYears TABLE (persianYear INT);
    INSERT INTO @LeapYears VALUES
        (1301), (1305), (1309), (1313), (1317), (1321), (1325), (1329), (1333), (1337),
        (1341), (1346), (1350), (1354), (1358), (1362), (1366), (1370), (1375), (1379),
        (1383), (1387), (1391), (1395), (1399), (1403), (1407), (1411), (1415), (1419),
        (1423), (1428), (1432), (1436), (1440), (1444);
 
    -- تعیین تاریخ نوروز شمسی
    SET @nowruz = DATEFROMPARTS(
        CASE WHEN MONTH(@inputDate) < 3 OR (MONTH(@inputDate) = 3 AND DAY(@inputDate) < 21)
             THEN YEAR(@inputDate) - 1
             ELSE YEAR(@inputDate)
        END,
        3,
        21
    );
 
    -- بررسی کبیسه بودن سال شمسی
    IF EXISTS (SELECT 1 FROM @LeapYears WHERE persianYear = @persianYear)
    BEGIN
        SET @nowruz = DATEADD(DAY, -1, @nowruz);
        -- Check if this is one of the problematic leap years
        IF @persianYear IN (1358, 1362, 1366, 1370)
            SET @needsAdjustment = 1;
    END
 
    -- محاسبه تعداد روزهای سپری‌شده از نوروز
    SET @days = DATEDIFF(DAY, @nowruz, @inputDate);
 
    -- محاسبه ماه و روز شمسی
    IF @days < 186
    BEGIN
        SET @persianMonth = @days / 31 + 1;
        SET @persianDay = @days % 31 + 1;
    END
    ELSE
    BEGIN
        SET @days = @days - 186;
        SET @persianMonth = @days / 30 + 7;
        SET @persianDay = @days % 30 + 1;
    END;
 
    -- Apply correction for specific problematic dates
    IF @needsAdjustment = 1 AND NOT (
        -- Exclude dates where the calculation is already correct
        -- Add conditions based on patterns in your data
        (@persianMonth = 1 AND @persianDay = 1) OR
        (@persianMonth = 12 AND @persianDay > 28)
    )
    BEGIN
        SET @persianDay = @persianDay - 1;
        
        -- Handle month rollover if day becomes 0
        IF @persianDay = 0
        BEGIN
            SET @persianMonth = @persianMonth - 1;
            IF @persianMonth = 0
            BEGIN
                SET @persianMonth = 12;
                SET @persianYear = @persianYear - 1;
            END
            
            IF @persianMonth <= 6
                SET @persianDay = 31;
            ELSE
                SET @persianDay = 30;
        END
    END
 
    -- خروجی با فرمت yyyy/MM/dd
    RETURN
        CAST(@persianYear AS VARCHAR) + '/' +
        RIGHT('0' + CAST(@persianMonth AS VARCHAR(2)), 2) + '/' +
        RIGHT('0' + CAST(@persianDay AS VARCHAR(2)), 2);
END;
GO
/****** Object:  UserDefinedFunction [dbo].[Date_ReversDate]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================

Create FUNCTION [dbo].[Date_ReversDate] (@DateStr varchar(10))
RETURNS varchar(10)

AS

BEGIN
DECLARE @TempStr varchar(10)
DECLARE @StartIndex int
DECLARE @SubStrLen int
DECLARE @i int

SET @TempStr = ''
SET @StartIndex = LEN(@DateStr) + 2
SET @i = LEN(@DateStr)
WHILE @i > 0
BEGIN
IF SUBSTRING(@DateStr,@i,1) IN ('/', '-')
BEGIN
SET @SubStrLen = @StartIndex - (@i + 2)
SET @StartIndex = @i + 1
SET @TempStr = @TempStr + SUBSTRING(@DateStr,@StartIndex,@SubStrLen) + SUBSTRING(@DateStr,@i,1)
END
SET @i = @i - 1
END
IF @TempStr <> ''
BEGIN
SET @SubStrLen = @StartIndex - 2
SET @TempStr = @TempStr + SUBSTRING(@DateStr,1,@SubStrLen)
END
ELSE
SET @TempStr = @DateStr
RETURN @TempStr
END





GO
/****** Object:  UserDefinedFunction [dbo].[Date_ShamsiDateAdd]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mohammad Sepahkar
-- Create date: 1402/05/30
-- Description:	این تابع یک تاریخ شمسی را گرفته و به تعداد مشخصی به آن روز اضافه و یا کم می کند
-- =============================================
Create FUNCTION [dbo].[Date_ShamsiDateAdd] 
(
	-- Add the parameters for the function here
	@ShamsiDate varchar(10),
	@DayCount smallint
)
RETURNS varchar(10)
AS
BEGIN
	If ISNULL(@DayCount,0) = 0
		Return @ShamsiDate


	--ابتدا تاریخ معادل میلادی را به دست می آوریم
	Declare @MiladiDate Date 
	Set @MiladiDate = dbo.Date_ShamsiToMiladi(@ShamsiDate)

	--حالا اختلاف روز را حساب می کنیم
	Set @MiladiDate = DATEADD(day, @DayCount, @MiladiDate)

	-- Return the result of the function
	Set @ShamsiDate = dbo.Date_MiladiToShamsi(@MiladiDate)

	Return @ShamsiDate

END
GO
/****** Object:  UserDefinedFunction [dbo].[Date_ShamsiDateDiff]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[Date_ShamsiDateDiff] 
(
	-- Add the parameters for the function here
	@StartDate varchar(10),
	@EndDate varchar(10)
)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	DECLARE @DiffDays int

	
	--در صورت وقوع هر یک از شرایط زیر مقدار صفر بازگشت داده می شود
	If ISNULL(@StartDate,'') = '' Or ISNULL(@EndDate,'') = '' --اگر پارامترهای ورودی خالی باشند
	Or LEN(@StartDate) < 10  Or LEN(@EndDate) < 10
	--Or LEFT(@StartDate,2) <> '13' 
	Or ISNUMERIC(LEFT(@StartDate,4)) = 0 -- در صورتی که شماره سال در تاریخ شروع نامعتبر باشد
	--Or LEFT(@EndDate,2) <> '13' 
	Or ISNUMERIC(LEFT(@EndDate,4)) = 0 -- در صورتی که شماره سال در تاریخ پایان نامعتبر باشد
	Or ISNUMERIC(SUBSTRING(@StartDate,6,2)) = 0 Or SUBSTRING(@StartDate,6,2) > '12'--در صورتی که شماره ماه در تاریخ نامعتبر باشد
	Or ISNUMERIC(SUBSTRING(@EndDate,6,2)) = 0 Or SUBSTRING(@EndDate,6,2) > '12'--در صورتی که شماره ماه در تاریخ نامعتبر باشد
	Or ISNUMERIC(RIGHT(@StartDate,2)) = 0 Or RIGHT(@StartDate,2) > '31' --در صورتی که شماره ی روز در تاریخ نامعتبر باشد
	Or ISNUMERIC(RIGHT(@EndDate,2)) = 0 Or RIGHT(@EndDate,2) > '31' --در صورتی که شماره ی روز در تاریخ نامعتبر باشد
		Return 0

	--Declare @StartDay int, @StartMonth int, @StartYear int
	--Declare @EndDay int, @EndMonth int, @EndYear int

	----فیلدهای روز و ماه و سال را به ازای هر تاریخ به دست می آوریم
	--Select @StartDay = RIGHT(@StartDate,2),@StartMonth=SUBSTRING(@StartDate,6,2), @StartYear = LEFT(@StartDate,4),	
	--@EndDay = RIGHT(@EndDate,2),@EndMonth=SUBSTRING(@EndDate,6,2), @EndYear = LEFT(@EndDate,4)


	--Set @DiffDays = (@EndYear - @StartYear) * 365 + (@EndMonth - @StartMonth) * 30 + (@EndDay - @StartDay)
	
	Set @DiffDays =  DATEDIFF(Day, dbo.EVA_Date_ShamsiToMiladi(@StartDate), dbo.EVA_Date_ShamsiToMiladi(@EndDate))
	
	-- Return the result of the function
	RETURN @DiffDays

END
GO
/****** Object:  UserDefinedFunction [dbo].[Date_ShamsiToMiladi]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Mohammad Sepahkar
-- Create date: 98-04-26
-- Description:	این تابع یک تاریخ شمسی را گرفته و تاریخ میلادی بازگشت می دهد
-- =============================================
Create FUNCTION [dbo].[Date_ShamsiToMiladi](@DateStr varchar(10))
RETURNS DATETIME
AS 
BEGIN 
declare @YYear int
declare @MMonth int
declare @DDay int
declare @epbase int
declare @epyear int
declare @mdays int
declare @persian_jdn int
declare @i int
declare @j int
declare @l int
declare @n int
declare @TMPRESULT varchar(10)
declare @IsValideDate int
declare @TempStr varchar(20)
DECLARE @TmpDateStr varchar(10)

SET @i=charindex('/',@DateStr)

IF LEN(@DateStr) - CHARINDEX('/', @DateStr,CHARINDEX('/', @DateStr,1)+1) = 4
BEGIN
SET @TmpDateStr = dbo.Date_ReversDate(@DateStr)
IF ( ISDATE(@TmpDateStr) =1 ) 
RETURN @TmpDateStr
ELSE
RETURN NULL
END
ELSE
SET @TmpDateStr = @DateStr

IF ((@i<>0) and
(dbo.Date_SubStrCount('/', @TmpDateStr)=2) and
(ISNUMERIC(REPLACE(@TmpDateStr,'/',''))=1) and 
(charindex('.',@TmpDateStr)=0)
)
BEGIN
SET @YYear=CAST(SUBSTRING(@TmpDateStr,1,@i-1) AS INT)
IF ( @YYear< 1300 )
SET @YYear =@YYear + 1300
IF @YYear > 9999
RETURN NULL

SET @TempStr= SUBSTRING(@TmpDateStr,@i+1,Len(@TmpDateStr))

SET @i=charindex('/',@TempStr)
SET @MMonth=CAST(SUBSTRING(@TempStr,1,@i-1) AS INT)
SET @MMonth=@MMonth-- -1

SET @TempStr= SUBSTRING(@TempStr,@i+1,Len(@TempStr)) 

SET @DDay=CAST(@TempStr AS INT)
SET @DDay=@DDay-- - 1

IF ( @YYear >= 0 )
SET @epbase = @YYear - 474
Else
SET @epbase = @YYear - 473
SET @epyear = 474 + (@epbase % 2820)

IF (@MMonth <= 7 )
SET @mdays = ((@MMonth) - 1) * 31
Else
SET @mdays = ((@MMonth) - 1) * 30 + 6

SET @persian_jdn =(@DDay) + @mdays + CAST((((@epyear * 682) - 110) / 2816) as int) + (@epyear - 1) * 365 + CAST((@epbase / 2820) as int ) * 1029983 + (1948321 - 1)



IF (@persian_jdn > 2299160) 
BEGIN
SET @l = @persian_jdn + 68569
SET @n = CAST(((4 * @l) / 146097) as int)
SET @l = @l - CAST(((146097 * @n + 3) / 4) as int)
SET @i = CAST(((4000 * (@l + 1)) / 1461001) as int)
SET @l = @l - CAST( ((1461 * @i) / 4) as int) + 31
SET @j = CAST(((80 * @l) / 2447) as int)
SET @DDay = @l - CAST( ((2447 * @j) / 80) as int)
SET @l = CAST((@j / 11) as int)
SET @MMonth = @j + 2 - 12 * @l
SET @YYear = 100 * (@n - 49) + @i + @l
END

SET @TMPRESULT=Cast(@MMonth as varchar(2))+'/'+CAST(@DDay as Varchar(2))+'/'+CAST(@YYear as varchar(4)) 
RETURN Cast(@TMPRESULT as Datetime)

END
RETURN NULL 

END
GO
/****** Object:  UserDefinedFunction [dbo].[Date_SubStrCount]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================


Create FUNCTION [dbo].[Date_SubStrCount](@SubStr varchar(8000), @MainText Text) 
RETURNS int 
AS 
BEGIN 
DECLARE @StrCount int
DECLARE @StrPos int

SET @StrCount = 0
SET @StrPos = 0
SET @StrPos = CHARINDEX( @SubStr, @MainText, @StrPos)

WHILE @StrPos > 0
BEGIN
SET @StrCount = @StrCount + 1
SET @StrPos = CHARINDEX( @SubStr, @MainText, @StrPos+1)
END

RETURN @StrCount 
END




GO
/****** Object:  UserDefinedFunction [dbo].[Date_WorkHistory]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Mohammad Sepahkar>
-- Create date: <Create Date, ,1401-11-11>
-- Description:	<Description, ,این تابع طول مدت همکاری فرد را بر حسب ماه و سال نشان می دهد>
-- =============================================
CREATE FUNCTION [dbo].[Date_WorkHistory]
(
 @StartDate varchar(10),
 @EndDate varchar(10)
)
RETURNS nvarchar(100)
AS
BEGIN
	Declare @MonthCount int, @YearCount int
	Declare @ReturnString nvarchar(100) = ''
	Set @MonthCount = DATEDIFF(MONTH,dbo.Date_ShamsiToMiladi(@StartDate), 
	ISNULL(dbo.Date_ShamsiToMiladi(@EndDate),GETDATE()))

	if @MonthCount = 0 
		Set @ReturnString = N'کمتر از یک ماه'
	else
	begin
		Set @YearCount = @MonthCount / 12
		Set @MonthCount = @MonthCount % 12
		if @YearCount > 0
			Set @ReturnString = CAST(@YearCount As varchar(2)) + N' سال '
	
		if @MonthCount > 0 and @YearCount > 0
			Set @ReturnString = @ReturnString + N' و '

		if @MonthCount > 0 
			Set @ReturnString = @ReturnString + CAST(@MonthCount As varchar(2)) + N' ماه'
	end

	return @ReturnString

END
GO
/****** Object:  UserDefinedFunction [dbo].[EVA_Date_ReversDate]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================

Create FUNCTION [dbo].[EVA_Date_ReversDate] (@DateStr varchar(10))
RETURNS varchar(10)

AS

BEGIN
DECLARE @TempStr varchar(10)
DECLARE @StartIndex int
DECLARE @SubStrLen int
DECLARE @i int

SET @TempStr = ''
SET @StartIndex = LEN(@DateStr) + 2
SET @i = LEN(@DateStr)
WHILE @i > 0
BEGIN
IF SUBSTRING(@DateStr,@i,1) IN ('/', '-')
BEGIN
SET @SubStrLen = @StartIndex - (@i + 2)
SET @StartIndex = @i + 1
SET @TempStr = @TempStr + SUBSTRING(@DateStr,@StartIndex,@SubStrLen) + SUBSTRING(@DateStr,@i,1)
END
SET @i = @i - 1
END
IF @TempStr <> ''
BEGIN
SET @SubStrLen = @StartIndex - 2
SET @TempStr = @TempStr + SUBSTRING(@DateStr,1,@SubStrLen)
END
ELSE
SET @TempStr = @DateStr
RETURN @TempStr
END





GO
/****** Object:  UserDefinedFunction [dbo].[EVA_Date_ShamsiToMiladi]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Mohammad Sepahkar
-- Create date: 98-04-26
-- Description:	این تابع یک تاریخ شمسی را گرفته و تاریخ میلادی بازگشت می دهد
-- =============================================
Create FUNCTION [dbo].[EVA_Date_ShamsiToMiladi](@DateStr varchar(10))
RETURNS DATETIME
AS 
BEGIN 
declare @YYear int
declare @MMonth int
declare @DDay int
declare @epbase int
declare @epyear int
declare @mdays int
declare @persian_jdn int
declare @i int
declare @j int
declare @l int
declare @n int
declare @TMPRESULT varchar(10)
declare @IsValideDate int
declare @TempStr varchar(20)
DECLARE @TmpDateStr varchar(10)

SET @i=charindex('/',@DateStr)

IF LEN(@DateStr) - CHARINDEX('/', @DateStr,CHARINDEX('/', @DateStr,1)+1) = 4
BEGIN
SET @TmpDateStr = dbo.EVA_Date_ReversDate(@DateStr)
IF ( ISDATE(@TmpDateStr) =1 ) 
RETURN @TmpDateStr
ELSE
RETURN NULL
END
ELSE
SET @TmpDateStr = @DateStr

IF ((@i<>0) and
(dbo.EVA_Date_SubStrCount('/', @TmpDateStr)=2) and
(ISNUMERIC(REPLACE(@TmpDateStr,'/',''))=1) and 
(charindex('.',@TmpDateStr)=0)
)
BEGIN
SET @YYear=CAST(SUBSTRING(@TmpDateStr,1,@i-1) AS INT)
IF ( @YYear< 1300 )
SET @YYear =@YYear + 1300
IF @YYear > 9999
RETURN NULL

SET @TempStr= SUBSTRING(@TmpDateStr,@i+1,Len(@TmpDateStr))

SET @i=charindex('/',@TempStr)
SET @MMonth=CAST(SUBSTRING(@TempStr,1,@i-1) AS INT)
SET @MMonth=@MMonth-- -1

SET @TempStr= SUBSTRING(@TempStr,@i+1,Len(@TempStr)) 

SET @DDay=CAST(@TempStr AS INT)
SET @DDay=@DDay-- - 1

IF ( @YYear >= 0 )
SET @epbase = @YYear - 474
Else
SET @epbase = @YYear - 473
SET @epyear = 474 + (@epbase % 2820)

IF (@MMonth <= 7 )
SET @mdays = ((@MMonth) - 1) * 31
Else
SET @mdays = ((@MMonth) - 1) * 30 + 6

SET @persian_jdn =(@DDay) + @mdays + CAST((((@epyear * 682) - 110) / 2816) as int) + (@epyear - 1) * 365 + CAST((@epbase / 2820) as int ) * 1029983 + (1948321 - 1)



IF (@persian_jdn > 2299160) 
BEGIN
SET @l = @persian_jdn + 68569
SET @n = CAST(((4 * @l) / 146097) as int)
SET @l = @l - CAST(((146097 * @n + 3) / 4) as int)
SET @i = CAST(((4000 * (@l + 1)) / 1461001) as int)
SET @l = @l - CAST( ((1461 * @i) / 4) as int) + 31
SET @j = CAST(((80 * @l) / 2447) as int)
SET @DDay = @l - CAST( ((2447 * @j) / 80) as int)
SET @l = CAST((@j / 11) as int)
SET @MMonth = @j + 2 - 12 * @l
SET @YYear = 100 * (@n - 49) + @i + @l
END

SET @TMPRESULT=Cast(@MMonth as varchar(2))+'/'+CAST(@DDay as Varchar(2))+'/'+CAST(@YYear as varchar(4)) 
RETURN Cast(@TMPRESULT as Datetime)

END
RETURN NULL 

END
GO
/****** Object:  UserDefinedFunction [dbo].[EVA_Date_SubStrCount]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================


Create FUNCTION [dbo].[EVA_Date_SubStrCount](@SubStr varchar(8000), @MainText Text) 
RETURNS int 
AS 
BEGIN 
DECLARE @StrCount int
DECLARE @StrPos int

SET @StrCount = 0
SET @StrPos = 0
SET @StrPos = CHARINDEX( @SubStr, @MainText, @StrPos)

WHILE @StrPos > 0
BEGIN
SET @StrCount = @StrCount + 1
SET @StrPos = CHARINDEX( @SubStr, @MainText, @StrPos+1)
END

RETURN @StrCount 
END




GO
/****** Object:  UserDefinedFunction [dbo].[GetAllUserTeamRole]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mohammad Sepahkar
-- Create date: 1403-10-10
-- Description:	این تابع لیست تمامی سمت های فرد با تاریخ شروع و پایان را بازگشت می دهد
-- =============================================
CREATE FUNCTION [dbo].[GetAllUserTeamRole] 
(
	-- Add the parameters for the function here
	@Username varchar(100)
)
RETURNS nvarchar(1000)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @AllUserTeamRole nvarchar(1000) = ''
	Declare @UserTeamRole nvarchar(100)

	Declare CurAllTeamRole Cursor LOCAL FORWARD_ONLY FAST_FORWARD READ_ONLY
	For Select RoleName + N' تیم ' + TeamName + N' از ' + StartDate + N' تا ' + 
	CASE  WHEN EndDate IS NULL THEN N'کنون' ELSE EndDate END As UserTeamRole 
	From UserTeamRoleAll 
	Where Username = @Username
	Order By StartDate

	Open CurAllTeamRole

	FETCH Next From CurAllTeamRole into @UserTeamRole
	--به ازای هر سمت این کار را می کنیم
	WHILE @@FETCH_STATUS = 0
	BEGIN
		--در صورتی که اولین سمت نباشد کاما اضافه می کنیم
		if @AllUserTeamRole = '' 
			Set @AllUserTeamRole = @AllUserTeamRole + ', '
		--سمت را به لیست سمت های فرد اضافه می کنیم
		Set @AllUserTeamRole = @AllUserTeamRole + @UserTeamRole
		--رکورد بعدی را واکشی می کنیم
		FETCH Next From CurAllTeamRole into @UserTeamRole
	END
	--کرسر را بسته و حافظه را آزاد می کنیم
	Close CurAllTeamRole
	Deallocate CurAllTeamRole
	-- Return the result of the function
	RETURN @AllUserTeamRole

END
GO
/****** Object:  UserDefinedFunction [dbo].[HR_ConvertTimeToMinutes]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Nadya Helmi
-- Create date: 98-03-22
-- Description:	این تابع برای تبدیل زمان متنی به دقیقه استفاده می شود
-- =============================================
CREATE FUNCTION [dbo].[HR_ConvertTimeToMinutes] 
(
	-- Add the parameters for the function here
	@TimeText varchar(10)
)
RETURNS int
AS
BEGIN
	Declare @TotalTimeMin int = 0

	--مکان کارکتر : را به دست می آوریم
	Declare @CharPosition tinyint = 0
	Set @CharPosition = CHARINDEX(':',@TimeText) 

	Declare @SplitTime varchar(5)

	--اگر دو نقطه وجود داشته باشد
	If @CharPosition > 1
	Begin
		Set @SplitTime = LEFT(@TimeText,@CharPosition-1)
		--کارکترهای سمت چپ، ساعت را نشان می دهند، آن را در 60 ضرب می کنیم
		If ISNUMERIC(@SplitTime)=1
			Set @TotalTimeMin = @SplitTime * 60
	End
	--اگر سمت راست : عددی وجود داشته باشد
	If LEN(@TimeText)-@CharPosition > 0
	Begin
		Set @SplitTime = RIGHT(@TimeText,LEN(@TimeText)-@CharPosition)

		--به دست آوردن دقیقه
		If ISNUMERIC(@SplitTime)=1
			Set @TotalTimeMin += @SplitTime
	End

	Return @TotalTimeMin
END
GO
/****** Object:  UserDefinedFunction [dbo].[HR_GetTeamMemberCount]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mohammad Sepahkar
-- Create date: 1403-02-23
-- Description:	این تابع تعداد افراد یک تیم را بازگشت می دهد
-- =============================================
CREATE FUNCTION [dbo].[HR_GetTeamMemberCount] 
(
	-- Add the parameters for the function here
	@TeamCode char(3)
)
RETURNS tinyint
AS
BEGIN
	
	Return (Select Count(*) From Team Where TeamCode = @TeamCode)

END
GO
/****** Object:  UserDefinedFunction [dbo].[HR_Name_GetTeamManager]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--ModifyDate : 1402-07-26 Mohammad Sepahkar
--این تابع بسته به پارامتر ورودی تایپ، می تواند نام کاربری و نام و نام خانوادگی مدیری
--که سمت مربوطه و تیم به تابع داده شده است را بر گرداند
--مثلا نام مدیر برنامه نویسان تیم خودرو را می خواهیم

--Modify Date : 1402-07-29 Mohammad Sepahkar
--برای حالتی که سمت متناظر در تیم وجود نداشته باشد 
--مدیر عمومی تیم بازگشت داده می شود

CREATE FUNCTION [dbo].[HR_Name_GetTeamManager]
(
	@RoleId int,
	@TeamCode Char(3)
	,@ReturnType Char(1)
	---U UserNme
	---N Name
)
RETURNS Varchar(150)
AS
BEGIN
	DECLARE @TeamManager varchar(150)
	--If @Type = 'U'
	--	Begin
	--		;With CTE_TeamManager As (
	--		Select  HM.UserName UserName
	--		From HR_organizationchartteamrole TR
	--		Inner JOIN HR_OrganizationChartRole R
	--		On R.Id=TR.OrganizationChartRole_id
	--		Inner JOin Role Ro
	--		On Ro.RoleId=R.RoleId_id
	--		Inner Join UserTeamRole HM
	--		On TR.ManagerUserName_id=HM.UserName
	--		Inner JOin Users U
	--		On HM.UserName=U.UserName
	--		INner JOIn Team T
	--		On T.TeamCode=TR.TeamCode_id
	--		Where R.RoleId_id=@RoleId
	--		And (TR.TeamCode_id=@TeamCode)
	--		Union 
	--		Select  HM.UserName UserName
	--		From UserTeamRole H
	--		INner JOIn Team T
	--		On T.TeamCode=H.TeamCode
	--		Inner Join UserTeamRole HM
	--		On H.ManagerUserName_id=HM.UserName
	--		Inner JOin Users U
	--		On HM.UserName=U.UserName
	--		Where H.RoleId=@RoleId
	--		And (H.TeamCode=@TeamCode )
	--		)
	--		Select @TeamManager= UserName From CTE_TeamManager
	--	End
	--	If @Type= 'N'
	--		Begin
	--			;With CTE_TeamManager As (
	--			Select  U.FirstName +' ' + U.LastName FullName
	--			From HR_organizationchartteamrole TR
	--			Inner JOIN HR_OrganizationChartRole R
	--			On R.Id=TR.OrganizationChartRole_id
	--			Inner JOin Role Ro
	--			On Ro.RoleId=R.RoleId_id
	--			Inner Join UserTeamRole HM
	--			On TR.ManagerUserName_id=HM.UserName
	--			Inner JOin Users U
	--			On HM.UserName=U.UserName
	--			INner JOIn Team T
	--			On T.TeamCode=TR.TeamCode_id
	--			Where R.RoleId_id=@RoleId
	--			And (TR.TeamCode_id=@TeamCode)
	--			Union 
	--			Select U.FirstName +' ' + U.LastName FullName
	--			From UserTeamRole H
	--			INner JOIn Team T
	--			On T.TeamCode=H.TeamCode
	--			Inner Join UserTeamRole HM
	--			On H.ManagerUserName_id=HM.UserName
	--			Inner JOin Users U
	--			On HM.UserName=U.UserName
	--			Where H.RoleId=@RoleId
	--			And (H.TeamCode=@TeamCode )
	--			)
	--			Select @TeamManager= FullName From CTE_TeamManager
	--	End

	If @ReturnType = 'U'
	Begin
		Select TOP(1) @TeamManager = ManagerUserName_id From UserTeamRole
		Where RoleId = @RoleId And TeamCode = @TeamCode

		--اگر سمت مورد نظر در تیم وجود نداشته باشد، مدیر تیم را بازگشت می دهد
		If @TeamManager Is null
			Select TOP(1) @TeamManager = GeneralManager_id From Team
			Where  TeamCode = @TeamCode
	End
	Else
	Begin
		Select TOP(1) @TeamManager = FirstName + ' ' + LastName
		From UserTeamRole UTR
		Inner Join Users U
		On ManagerUserName_id = U.UserName
		Where RoleId = @RoleId And TeamCode = @TeamCode		

		--اگر سمت مورد نظر در تیم وجود نداشته باشد، مدیر تیم را بازگشت می دهد
		If @TeamManager Is null
			Select TOP(1) @TeamManager = FirstName + ' ' + LastName From Team
			Inner Join Users U
			On GeneralManager_id = U.UserName
			Where  TeamCode = @TeamCode

	End

		RETURN @TeamManager
END
GO


CREATE VIEW [dbo].[Users]
ADD Username2 AS (left([Username],charindex('@',[UserName])-(1)))
GO

CREATE VIEW [dbo].[Team]
ADD [UserCount]  AS ([dbo].[HR_GetTeamMemberCount]([TeamCode]))
GO

/****** Object:  Table [dbo].[HR_city]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
/****** Object:  Table [dbo].[Users]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Users](
	[UserName] [varchar](100) NOT NULL,
	[Username2]  AS (left([Username],charindex('@',[UserName])-(1))),
	[FirstName] [nvarchar](200) NOT NULL,
	[LastName] [nvarchar](200) NOT NULL,
	[FatherName] [nvarchar](200) NULL,
	[FirstNameEnglish] [nvarchar](80) NULL,
	[LastNameEnglish] [nvarchar](100) NULL,
	[ContractDate] [nvarchar](10) NULL,
	[ContractEndDate] [nvarchar](10) NULL,
	[ContractType_id] [bigint] NULL,
	[About] [nvarchar](1000) NULL,
	[CVFile] [nvarchar](100) NULL,
	[Gender] [bit] NOT NULL,
	[NationalCode] [nvarchar](10) NULL,
	[NumberOfChildren] [smallint] NULL,
	[DegreeType_id] [bigint] NULL,
	[MilitaryStatus_id] [bigint] NULL,
	[Religion_id] [bigint] NULL,
	[LivingAddress_id] [bigint] NULL,
	[BirthDate] [nvarchar](10) NULL,
	[BirthCity_id] [int] NULL,
	[IdentityNumber] [nvarchar](10) NULL,
	[IdentitySerialNumber] [nvarchar](20) NULL,
	[IdentityCity_id] [int] NULL,
	[IdentityRegisterDate] [date] NULL,
	[InsuranceNumber] [nvarchar](20) NULL,
	[IsActive] [bit] NOT NULL,
	[UserStatus_id] [bigint] NULL,
	[MarriageStatus_id] [bigint] NULL,
	[LastBuilding_id] [bigint] NULL,
	[LastFloor_id] [bigint] NULL,
	[BirthDateMiladi] [date] NULL,
	[ContractDateMiladi] [date] NULL,
	[ContractEndDateMiladi] [date] NULL,
 CONSTRAINT [PK__Users__C9F284573283E976] PRIMARY KEY CLUSTERED 
(
	[UserName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HR_constvalue]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_constvalue](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[Caption] [nvarchar](50) NOT NULL,
	[Code] [nvarchar](100) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[OrderNumber] [smallint] NULL,
	[ConstValue] [int] NULL,
	[Parent_id] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[UserFullInformation_View]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE View [dbo].[UserFullInformation_View] As
Select Username, FirstName, LastName, FatherName,ContractDate,
ContractEndDate, CT.Caption ContractType,
CASE Gender WHEN 1 THEN N'مرد' WHEN 0 THEN N'زن' ELSE N'نامشخص' END Gender, NationalCode, 
NumberOfChildren, CD.Caption DegreeType,  CM.Caption MilitaryStatus, CR.Caption Religion,
BirthDate, C.CityTitle BirthCity, IdentityNumber, U.IsActive,
CS.Caption UserStatus,CMA.Caption MarriageStatus, dbo.GetAllUserTeamRole(Username) UserTeamRoles
From Users U
Left Join HR_constvalue CT
On U.ContractType_id = CT.Id
Left Join HR_constvalue CD
On U.DegreeType_id = CD.id
Left Join HR_constvalue CM
On U.MilitaryStatus_id = CM.id
Left Join HR_constvalue CR
On U.Religion_id = CR.id
Left Join HR_city C
On U.BirthCity_id = C.id
Left Join HR_constvalue CMA
On U.MarriageStatus_id = CMA.id
Left Join HR_constvalue CS
On U.UserStatus_id = CS.id
GO
/****** Object:  Table [dbo].[UserTeamRole]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserTeamRole](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[StartDate] [varchar](10) NOT NULL,
	[EndDate] [varchar](10) NULL,
	[RoleId] [int] NOT NULL,
	[TeamCode] [char](3) NOT NULL,
	[UserName] [varchar](100) NOT NULL,
	[LevelId_id] [bigint] NULL,
	[Superior] [bit] NOT NULL,
	[ManagerUserName_id] [varchar](100) NULL,
	[Comment] [nvarchar](1000) NULL,
	[ManagerNationalCode] [nvarchar](10) NULL,
	[NationalCode] [nvarchar](10) NULL,
 CONSTRAINT [PK__UserTeam__3213E83F6DF7641E] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Role]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Role](
	[RoleId] [int] NOT NULL,
	[RoleName] [nvarchar](100) NOT NULL,
	[HasLevel] [bit] NOT NULL,
	[HasSuperior] [bit] NOT NULL,
	[Comment] [nvarchar](200) NULL,
	[NewRoleRequest_id] [bigint] NULL,
	[RoleTypeCode] [char](1) NULL,
	[ManagerType_id] [bigint] NULL,
	[ManagerType] [nvarchar](100) NULL,
	[RoleType] [nvarchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[RoleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PreviousUserTeamRole]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PreviousUserTeamRole](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[StartDate] [varchar](10) NOT NULL,
	[EndDate] [varchar](10) NULL,
	[RoleId] [int] NOT NULL,
	[TeamCode] [char](3) NOT NULL,
	[UserName] [varchar](100) NOT NULL,
	[LevelId_id] [bigint] NULL,
	[Superior] [bit] NOT NULL,
	[ManagerUserName_id] [varchar](100) NULL,
	[Comment] [nvarchar](1000) NULL,
	[ManagerNationalCode] [nvarchar](10) NULL,
	[NationalCode] [nvarchar](10) NULL,
 CONSTRAINT [PK__Previous__3213E83F1A2FBE5E] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Team]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Team](
	[TeamCode] [char](3) NOT NULL,
	[TeamName] [nvarchar](100) NOT NULL,
	[ActiveInService] [bit] NOT NULL,
	[ActiveInEvaluation] [bit] NOT NULL,
	[GeneralManager_id] [varchar](100) NULL,
	[SupportManager_id] [varchar](100) NULL,
	[TestManager_id] [varchar](100) NULL,
	[IsActive] [bit] NOT NULL,
	[GeneralManagerNationalCode] [nvarchar](10) NULL,
	[SupportManagerNationalCode] [nvarchar](10) NULL,
	[TestManagerNationalCode] [nvarchar](10) NULL,
	[TeamDescription] [nvarchar](max) NULL,
	[ShortDescription] [nvarchar](1000) NULL,
	[UserCount]  AS ([dbo].[HR_GetTeamMemberCount]([TeamCode])),
 CONSTRAINT [PK__Team__550135094BD77BFA] PRIMARY KEY CLUSTERED 
(
	[TeamCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  View [dbo].[V_AllUserList]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_AllUserList]
AS
SELECT     U.Username, FirstName, LastName, U.NationalCode, ContractDate, T .TeamCode, TeamName, UTR.RoleId, RoleName, U.IsActive UserActive, 1 RoleActive
FROM        UserTeamRole UTR INNER JOIN
                  Users U ON UTR.UserName = U.UserName INNER JOIN
                  Team T ON T .TeamCode = UTR.TeamCode INNER JOIN
                  Role R ON R.RoleId = UTR.RoleId
UNION
SELECT     U.Username, FirstName, LastName, U.NationalCode, ContractDate, T .TeamCode, TeamName, UTR.RoleId, RoleName, U.IsActive UserActive, 0 ActiveRole
FROM        PreviousUserTeamRole UTR INNER JOIN
                  Users U ON UTR.UserName = U.UserName INNER JOIN
                  Team T ON T .TeamCode = UTR.TeamCode INNER JOIN
                  Role R ON R.RoleId = UTR.RoleId
UNION
SELECT     Username, FirstName, LastName, NationalCode,  ContractDate, NULL, NULL, NULL, NULL, IsActive, 0
FROM        Users
WHERE     Username NOT IN
                      (SELECT     Username
                       FROM        UserTeamRole
                       UNION
                       SELECT     Username
                       FROM        PreviousUserTeamRole)
GO
/****** Object:  View [dbo].[HR_RoleManager]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE View [dbo].[HR_RoleManager] As
With CTE_RoleTeam As 
(Select * From Role R, Team T)
,CTE_RoleManager As
(Select RoleId,RoleName, HasLevel, RoleTypeCode, TeamCode, TeamName,
SupportManager_id ManagerId, SupportManagerNationalCode ManagerNationalCode
From CTE_RoleTeam
Where RoleTypeCode = 'S' 
UNION
Select RoleId,RoleName, HasLevel, RoleTypeCode, TeamCode, TeamName, 
TestManager_id ManagerId, TestManagerNationalCode ManagerNationalCode
From CTE_RoleTeam
Where RoleTypeCode = 'T' 
UNION
Select RoleId,RoleName, HasLevel, RoleTypeCode, TeamCode, TeamName, 
GeneralManager_id ManagerId, GeneralManagerNationalCode ManagerNationalCode
From CTE_RoleTeam
Where RoleTypeCode Not In ('T','S','M')
UNION
Select RT.RoleId,RT.RoleName, RT.HasLevel, RT.RoleTypeCode, RT.TeamCode, RT.TeamName, 
UTR.ManagerUserName_id ManagerId, UTR.ManagerNationalCode ManagerNationalCode
From CTE_RoleTeam RT
Inner Join UserTeamRole UTR
On UTR.TeamCode = RT.TeamCode And UTR.RoleId = RT.RoleId
Where RoleTypeCode = 'M' )
Select ROW_NUMBER() Over (Order By RoleId, TeamCode) Id ,* From CTE_RoleManager




GO
/****** Object:  Table [dbo].[HR_Payment]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_Payment](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[YearNumber] [int] NOT NULL,
	[Payment] [bigint] NULL,
	[InsuranceAmount] [bigint] NULL,
	[OtherPayment] [bigint] NULL,
	[PaymentCost] [bigint] NULL,
	[MonthNumber] [int] NOT NULL,
	[PersonnelCode] [nvarchar](10) NOT NULL,
	[BasePayment] [bigint] NULL,
	[Username] [nvarchar](100) NULL,
	[OverTime] [int] NULL,
	[OverTimePayment] [bigint] NULL,
	[Reward] [bigint] NULL,
	[TotalPayment] [bigint] NULL,
	[DataType] [smallint] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[V_Payment_Average]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/****** Script for SelectTopNRows command from SSMS  ******/
CREATE view [dbo].[V_Payment_Average] As
SELECT 
ROW_NUMBER() Over(order by YearNumber, MonthNumber) As id,
YearNumber, MonthNumber,AVG(Payment) Payment, AVG(OtherPayment) OtherPayment, AVG(PaymentCost) PaymentCost, 
AVG(BasePayment) BasePayment, AVG(OverTimePayment) OverTimePayment, AVG(OverTime) OverTime,
AVG(Reward) Reward, AVG(TotalPayment) TotalPayment
  FROM [HR].[dbo].[HR_Payment]
  Group By YearNumber,MonthNumber
GO
/****** Object:  Table [dbo].[WorkTime]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WorkTime](
	[PersonnelCode] [varchar](10) NOT NULL,
	[YearNo] [smallint] NOT NULL,
	[MonthNo] [tinyint] NOT NULL,
	[WorkHours] [varchar](10) NULL,
	[RemoteHours] [varchar](10) NULL,
	[RemoteDays] [tinyint] NULL,
	[OverTime] [varchar](10) NULL,
	[DeductionTime] [varchar](10) NULL,
	[OffTimeHourly] [varchar](10) NULL,
	[OffTimeDaily] [int] NULL,
	[UserName] [varchar](100) NULL,
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_EVA_WorkTime] PRIMARY KEY CLUSTERED 
(
	[PersonnelCode] ASC,
	[YearNo] ASC,
	[MonthNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[V_WorkTime]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE View [dbo].[V_WorkTime] As
SELECT  [YearNo]

      ,Sum(dbo.HR_ConvertTimeToMinutes([WorkHours]))/60 WorkHours
	  
       ,Sum(dbo.HR_ConvertTimeToMinutes([RemoteHours]))/60.0 RemoteHours
      ,Sum([RemoteDays])RemoteDays
     , Sum(dbo.HR_ConvertTimeToMinutes([OverTime]))/60.0 OverTime
     , Sum(dbo.HR_ConvertTimeToMinutes([DeductionTime]))/60.0 DeductionTime
      ,Sum(dbo.HR_ConvertTimeToMinutes([OffTimeHourly]))/60.0 OffTimeHourly
      ,Sum([OffTimeDaily])OffTimeDaily
      ,[UserName]
	  ,ROW_NUMBER() Over (order by YearNo) Id
  FROM [HR].[dbo].[WorkTime]
  Group By UserName,YearNo
GO
/****** Object:  Table [dbo].[RoleLevel]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RoleLevel](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[LevelName] [nvarchar](20) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[UserTeamRoleAll]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[UserTeamRoleAll]
AS
SELECT        UTR.ID, StartDate, EndDate, UTR.RoleId, R.RoleName, T .TeamCode, TeamName, UTR.UserName, FirstName, LastName, U.NationalCode, LevelId_id, LevelName, Superior, ManagerUserName_id
FROM            UserTeamRole UTR INNER JOIN
                         Users U ON UTR.Username = U.Username INNER JOIN
                         Role R ON UTR.RoleId = R.RoleId LEFT JOIN
                         RoleLevel RL ON LevelId_id = RL.id LEFT JOIN
                         Team T ON UTR.TeamCode = T .TeamCode
UNION
/* دو تا سلکتور ور با هم یکی میکند*/ SELECT UTR.ID, StartDate, EndDate, UTR.RoleId, R.RoleName, T .TeamCode, TeamName, UTR.UserName, FirstName, LastName, U.NationalCode, LevelId_id, LevelName, Superior, ManagerUserName_id
FROM            PreviousUserTeamRole UTR INNER JOIN
                         Users U ON UTR.Username = U.Username INNER JOIN
                         Role R ON UTR.RoleId = R.RoleId LEFT JOIN
                         RoleLevel RL ON LevelId_id = RL.id LEFT JOIN
                         Team T ON UTR.TeamCode = T .TeamCode
GO
/****** Object:  View [dbo].[ChangeUserTeamRole]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[ChangeUserTeamRole]
AS
SELECT     UTR.StartDate, UTR.EndDate, R.RoleName, RL.LevelName, T.TeamName, UTR.UserName
FROM        dbo.UserTeamRoleAll AS UTR INNER JOIN
                  dbo.Role AS R ON UTR.RoleId = R.RoleId INNER JOIN
                  dbo.Team AS T ON UTR.TeamCode = T.TeamCode LEFT OUTER JOIN
                  dbo.RoleLevel AS RL ON UTR.LevelId_id = RL.id
GO
/****** Object:  View [dbo].[UserWithoutTeamRole]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE View [dbo].[UserWithoutTeamRole] As
Select UserName, FirstName, LastName, NationalCode, 
ContractDateMiladi as ContractDate,  dbo.Date_MiladiToShamsi(ContractDateMiladi) ContractDateShamsi,
ContractEndDateMiladi as ContractEndDate,  dbo.Date_MiladiToShamsi(ContractEndDateMiladi) ContractEndDateShamsi
From Users
Where UserName Not In
(Select UserName From PreviousUserTeamRole
UNION 
Select UserName From UserTeamRole)
GO
/****** Object:  View [dbo].[ChangeTeamRoleJSON]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE View [dbo].[ChangeTeamRoleJSON] As
Select '{"team_code":"'+ UTR.TeamCode  +'", "team_name":"'+ T.TeamName  +'",
"role_id":"'+ CAST(UTR.RoleId as varchar(5))  +'","role_name":"'+ R.RoleName  +'",
"level_id":"'+ CAST(ISNULL(UTR.LevelId_id,'') As varchar(1))  +'","level_name":"'+ ISNULL(RL.LevelName,'')  +'",
"superior":"'+ CAST( UTR.Superior As varchar(1)) +'","start_date":"'+ UTR.StartDate  +'",
"manager_nationalcode":"'+ ISNULL(Manager.NationalCode,'')  +'","manager_fullname":"'+ ISNULL(Manager.FirstName + ' ' + Manager.LastName, '')  +'",
}' ChangeTeamRoleJSON From UserTeamRole UTR
Inner Join Role R
On UTR.RoleId = R.RoleId
Inner Join Team T
On UTR.TeamCode = T.TeamCode
LEFT Join RoleLevel RL
On UTR.LevelId_id = RL.id
Inner Join Users Manager
On UTR.ManagerNationalCode = Manager.NationalCode
Where UTR.NationalCode = '1280419180'
GO
/****** Object:  View [dbo].[UserTeamRoleJSON]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE View [dbo].[UserTeamRoleJSON] As
Select U.NationalCode, U.FirstName, U.LastName, U.Username2 Username, U.Gender,U.IsActive,'C' As Current_Previous, '{"team_code":"'+ UTR.TeamCode  +'", "team_name":"'+ T.TeamName  +'",
"role_id":"'+ CAST(UTR.RoleId as varchar(5))  +'","role_name":"'+ R.RoleName  +'",
"level_id":"'+ CAST(ISNULL(UTR.LevelId_id,'') As varchar(1))  +'","level_name":"'+ 
ISNULL(RL.LevelName,'')  +'",
"superior":"'+ CAST( UTR.Superior As varchar(1)) 
+'","start_date":"'+ UTR.StartDate  +'", 
"active_in_evaluation":'+ 
CASE T.ActiveInEvaluation  WHEN 1 THEN 'true' ELSE 'false' END +',
"active_in_service":'+ 
CASE T.ActiveInService  WHEN 1 THEN 'true' ELSE 'false' END+',
"manager_nationalcode":"'+ ISNULL(Manager.NationalCode,'')  +'",
"manager_username":"'+ ISNULL(Manager.Username2,'')  +'",
"manager_fullname":"'+ ISNULL(Manager.FirstName + ' ' + Manager.LastName, '')  +'"}' 
UserTeamRole 
From Users U Inner Join
UserTeamRole UTR
On U.NationalCode = UTR.NationalCode
Inner Join Role R
On UTR.RoleId = R.RoleId
Inner Join Team T
On UTR.TeamCode = T.TeamCode
LEFT Join RoleLevel RL
On UTR.LevelId_id = RL.id
Inner Join Users Manager
On UTR.ManagerNationalCode = Manager.NationalCode
UNION
Select U.NationalCode, U.FirstName, U.LastName, U.Username2 Username, U.Gender,U.IsActive,'P' As Current_Previous, '{"team_code":"'+ UTR.TeamCode  +'", "team_name":"'+ T.TeamName  +'",
"role_id":"'+ CAST(UTR.RoleId as varchar(5))  +'","role_name":"'+ R.RoleName  +'",
"level_id":"'+ CAST(ISNULL(UTR.LevelId_id,'') As varchar(1))  +'","team_code":"'+ ISNULL(RL.LevelName,'')  +'",
"superior":"'+ CAST( UTR.Superior As varchar(1)) +'",
"start_date":"'+ UTR.StartDate  +'","end_date":"'+ UTR.EndDate  +'",
"active_in_evaluation":'+ 
CASE T.ActiveInEvaluation  WHEN 1 THEN 'true' ELSE 'false' END +',
"active_in_service":'+ 
CASE T.ActiveInService  WHEN 1 THEN 'true' ELSE 'false' END +',
"manager_nationalcode":"'+ ISNULL(Manager.NationalCode,'')  +'","manager_fullname":"'+ ISNULL(Manager.FirstName + ' ' + Manager.LastName, '')  +'"}' 
UserTeamRole 
From Users U Inner Join
PreviousUserTeamRole UTR
On U.NationalCode = UTR.NationalCode
Inner Join Role R
On UTR.RoleId = R.RoleId
Inner Join Team T
On UTR.TeamCode = T.TeamCode
LEFT Join RoleLevel RL
On UTR.LevelId_id = RL.id
Inner Join Users Manager
On UTR.ManagerNationalCode = Manager.NationalCode

GO
/****** Object:  Table [dbo].[auth_group]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[auth_group](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](150) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [auth_group_name_a6ea08ec_uniq] UNIQUE NONCLUSTERED 
(
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[auth2_user]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[auth2_user](
	[password] [nvarchar](128) NOT NULL,
	[last_login] [datetimeoffset](7) NULL,
	[is_superuser] [bit] NOT NULL,
	[username] [nvarchar](150) NOT NULL,
	[first_name] [nvarchar](150) NOT NULL,
	[last_name] [nvarchar](150) NOT NULL,
	[email] [nvarchar](254) NOT NULL,
	[is_staff] [bit] NOT NULL,
	[is_active] [bit] NOT NULL,
	[date_joined] [datetimeoffset](7) NOT NULL,
	[national_code] [nvarchar](10) NOT NULL,
	[team_roles] [nvarchar](max) NULL,
	[gender] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[national_code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[username] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[auth2_user_groups]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[auth2_user_groups](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[user_id] [nvarchar](10) NOT NULL,
	[group_id] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HR_pagepermission]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_pagepermission](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[GroupId] [int] NOT NULL,
	[Editable] [bit] NOT NULL,
	[Page_id] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HR_pageinformation]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_pageinformation](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[PageName] [nvarchar](30) NOT NULL,
	[ColorSet] [nvarchar](30) NOT NULL,
	[EnglishName] [nvarchar](30) NOT NULL,
	[IconName] [nvarchar](30) NOT NULL,
	[ShowDetail] [bit] NOT NULL,
	[OrderNumber] [smallint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[V_PagePermission]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO












CREATE VIEW [dbo].[V_PagePermission]
AS
SELECT        u.username AS username_id,
mu.NationalCode,
P.id, P.GroupId, P.Editable, P.Page_id,i.OrderNumber
FROM            dbo.auth_group AS g INNER JOIN
                         dbo.auth2_user_groups AS ug ON ug.group_id = g.id INNER JOIN
                         dbo.auth2_user AS u ON u.national_code = ug.user_id INNER JOIN
                         dbo.HR_pagepermission AS P ON P.GroupId = g.id
						 Inner Join HR_pageinformation i on i.id=p.Page_id
						inner join Users mU on mu.NationalCode = u.national_code 
GO
/****** Object:  View [dbo].[TeamInformation]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[TeamInformation]
AS
WITH CTE_teamcount AS (SELECT        TeamCode, COUNT(*) AS TeamCount
                                                         FROM            dbo.UserTeamRole AS utr
                                                         GROUP BY TeamCode)
    SELECT        Row_number() OVER (ORDER BY tc.TeamCount) AS Id, t.TeamCode, t.TeamName, ISNULL(std.TeamDescription, '') AS TeamDesc, ISNULL(std.ShortDescription, '') AS ShortDesc, tc.TeamCount, t.IsActive IsTeamActive
     FROM            ServiceBook.dbo.ServiceBook_teamdescription AS std RIGHT OUTER JOIN
                              dbo.Team AS t ON t.TeamCode = std.TeamCode AND std.YearNumber = 1402 INNER JOIN
                              CTE_teamcount AS tc ON tc.TeamCode = t.TeamCode
GO
/****** Object:  View [dbo].[Auth_UserTeamRole]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE View [dbo].[Auth_UserTeamRole] As
SELECT 
    NationalCode, 
    Username, 
    FirstName, 
    LastName, 
    Gender, 
    IsActive,
   
    JSON_QUERY(
        '{' +
        '"current": [' + ISNULL(STRING_AGG(CASE WHEN Current_Previous = 'C' THEN CAST(UserTeamRole AS NVARCHAR(MAX)) END, ','), '') + '],' +
        '"previous": [' + ISNULL(STRING_AGG(CASE WHEN Current_Previous = 'P' THEN CAST(UserTeamRole AS NVARCHAR(MAX)) END, ','), '') + ']' +
        '}'
    ) AS UserTeamRoles

FROM 
    UserTeamRoleJSON
GROUP BY 
    NationalCode, 
    Username, 
    FirstName, 
    LastName, 
    Gender, 
    IsActive

GO
/****** Object:  Table [dbo].[HR_rolegroup]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_rolegroup](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[RoleGroup] [nvarchar](50) NOT NULL,
	[RoleGroupName] [nvarchar](100) NULL,
	[RoleID_id] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[KeyMembers]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[KeyMembers]
AS
SELECT DISTINCT 0 AS Id, u.UserName, REPLACE(u.UserName, '@eit', '') AS UserAlone, u.FirstName, u.LastName, t.TeamName, t.TeamCode, r.RoleName, r.RoleId, utr.Superior
FROM            dbo.HR_rolegroup AS rg INNER JOIN
                         dbo.UserTeamRole AS utr ON utr.RoleId = rg.RoleID_id INNER JOIN
                         dbo.Users AS u ON u.UserName = utr.UserName INNER JOIN
                         dbo.Team AS t ON t.TeamCode = utr.TeamCode INNER JOIN
                         dbo.Role AS r ON r.RoleId = utr.RoleId
WHERE        (rg.RoleGroup = 'Manager') OR
                         (utr.Superior = 1)
GO
/****** Object:  View [dbo].[V_Payment_Role_Average]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/****** Script for SelectTopNRows command from SSMS  ******/
CREATE view [dbo].[V_Payment_Role_Average] As
SELECT ROW_NUMBER() Over(order by YearNumber, MonthNumber,UTR.RoleId, UTR.LevelId_id) As id,
YearNumber,MonthNumber, UTR.RoleId, UTR.LevelId_id,
AVG(Payment) Payment, AVG(OtherPayment) OtherPayment, AVG(PaymentCost) PaymentCost, 
AVG(BasePayment) BasePayment, AVG(OverTimePayment) OverTimePayment,  AVG(OverTime) OverTime,
AVG(Reward) Reward, AVG(TotalPayment) TotalPayment
  FROM [HR].[dbo].[HR_Payment] P
  Inner Join UserTeamRoleAll UTR
  On P.Username = UTR.UserName
  Group By YearNumber,MonthNumber, UTR.RoleId, UTR.LevelId_id
GO
/****** Object:  View [dbo].[V_Payment_Yearly]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE view [dbo].[V_Payment_Yearly] as
Select ROW_NUMBER() Over(order by YearNumber,Username) Id,
YearNumber, PersonnelCode, Username,
AVG(Payment) Payment, AVG(OtherPayment) OtherPayment, AVG(PaymentCost) PaymentCost, 
AVG(OverTime) OverTime, AVG(OverTimePayment) OverTimePayment, AVG(Reward) Reward, 
AVG(TotalPayment) TotalPayment , AVG(BasePayment) BasePayment
From HR_Payment
Group By YearNumber, PersonnelCode, Username
GO
/****** Object:  Table [dbo].[HR_changerole]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_changerole](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[Superior] [bit] NOT NULL,
	[SuperiorTarget] [bit] NOT NULL,
	[Education] [bit] NOT NULL,
	[Educator] [nvarchar](100) NULL,
	[Evaluation] [bit] NOT NULL,
	[Assessor] [nvarchar](100) NULL,
	[RequestGap] [int] NULL,
	[Assessor2] [nvarchar](100) NULL,
	[ReEvaluation] [bit] NOT NULL,
	[PmChange] [bit] NOT NULL,
	[ITChange] [bit] NOT NULL,
	[LevelId_id] [bigint] NULL,
	[LevelIdTarget_id] [bigint] NULL,
	[RoleID_id] [int] NOT NULL,
	[RoleIdTarget_id] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[V_HR_RoleTarget]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--USE [HR]
--GO

--/****** Object:  View [dbo].[V_HR_RoleTarget]    Script Date: 1/21/2025 11:28:13 PM ******/
--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO

CREATE View [dbo].[V_HR_RoleTarget] As 
----سطح رو به دست میاریم برای همه سمت ها
With CTE_RoleLevel As (
Select R.RoleId,R.RoleName
,RL.LevelName,RL.id LevelId,R.HasLevel,R.HasSuperior
From Role R
Cross Join RoleLevel RL
Where R.HasLevel=1 And RoleId<>127
Union 
Select R.RoleId,R.RoleName
,'','' LevelId,R.HasLevel,R.HasSuperior From Role R
Where R.HasLevel=0 And RoleId<>127
)
---برای سمت های عملیاتی به غیر عملیاتی
,CTE_NoneTechnicalRoleTarget as (
Select ChR.RoleID_id RoleID,RG.RoleID_id RoleTargetID
,CHR.LevelId_id LevelID,L.LevelId LevelIdTargetID
,CHR.Superior,CHR.SuperiorTarget
,Education,Evaluation,ReEvaluation,Assessor,PmChange,ITChange

From HR_changerole CHR
Inner Join HR_rolegroup RG
-----سمت های غیر عملیاتی رو به دست میاریم
On RG.RoleGroup='NoneTechnicalRole'
Inner Join CTE_RoleLevel L
on L.RoleId=RG.RoleID_id

Where  CHR.RoleIdTarget_id=127
And  RG.RoleID_id<>127
And CHR.RoleID_id<>CHR.RoleIdTarget_id
),CTE_NoneTechnicalRole As (

---برای سمت های غیر عملیاتی به عملیاتی
Select RG.RoleID_id RoleID,CHR.RoleIdTarget_id RoleTargetID
,L.LevelId LevelID,CHR.LevelIdTarget_id LevelIdTargetID
,CHR.Superior,CHR.SuperiorTarget
,Education,Evaluation,ReEvaluation,Assessor,PmChange,ITChange

From HR_changerole CHR
Inner Join HR_rolegroup RG
-----سمت های غیر عملیاتی رو به دست میاریم
On RG.RoleGroup='NoneTechnicalRole'
Inner Join CTE_RoleLevel L
on L.RoleId=RG.RoleID_id
Where  CHR.RoleId_id=127
And  RG.RoleID_id<>127
And RG.RoleID_id<>CHR.RoleIdTarget_id)
,CTE_RoleBase As (
--برای سمت پرسنل آزمایشی
Select 117 RoleID
,RL.RoleId RoleTargetID
,'' LevelID,RL.LevelId LevelIdTargetID
,Convert(bit,0) Superior,Convert(bit,0) SuperiorTarget
,Convert(bit,1) Education,Convert(bit,1) Evaluation,Convert(bit,1) ReEvaluation
,'' Assessor,Convert(bit,1) PmChange,Convert(bit,1) ITChange

From CTE_RoleLevel RL
Where RL.RoleId Not IN (Select RoleID_id From HR_rolegroup Where RoleGroup='Manager')
And RL.RoleId<>117
)
,CTE_RoleBaseSuprier As (
--برای ارشد سمت پرسنل آزمایشی
Select 117 RoleID
,RL.RoleId RoleTargetID
,0 LevelID,RL.LevelId LevelIdTargetID
,Convert(bit,0) Superior,Convert(bit,1) SuperiorTarget
,Convert(bit,1) Education,Convert(bit,1) Evaluation,Convert(bit,0) ReEvaluation
,'' Assessor,Convert(bit,1) PmChange,Convert(bit,1) ITChange

From CTE_RoleLevel RL
Where RL.RoleId Not IN (Select RoleID_id From HR_rolegroup Where RoleGroup='Manager')
And RL.HasSuperior=1 
And LevelId<=5
And RL.RoleId<>117)
,CTE_TechnicalRole As(
---برای سمت های  عملیاتی به عملیاتی
Select CHR.RoleID_id RoleID,CHR.RoleIdTarget_id RoleTargetID
,CHR.LevelId_id LevelID,CHR.LevelIdTarget_id LevelIdTargetID
,CHR.Superior,CHR.SuperiorTarget
,Education,Evaluation,ReEvaluation,Assessor,PmChange,ITChange

From HR_changerole CHR
Where  CHR.RoleId_id<>127
And  CHR.RoleIdTarget_id<>127
)
,CTE_NoneTechnicalRoleSelf As(
---برای سمت های غیر عملیاتی به غیر عملیاتی
Select 
R.RoleId RoleID,R2.RoleId RoleTargetID
,R.LevelId LevelID,R2.LevelId LevelIdTargetID
,Convert(bit,0)  Superior,Convert(bit,0) SuperiorTarget
,Convert(bit,1) Education, Convert(bit,1) Evaluation,
Convert(bit,1) ReEvaluation
,'' Assessor
,Convert(bit,0) PmChange,Convert(bit,1) ITChange

From CTE_RoleLevel R
Cross Join CTE_RoleLevel R2
Where R.RoleId in (Select RoleID_id From HR_rolegroup Where RoleGroup='NoneTechnicalRole')
And  R2.RoleId in (Select RoleID_id From HR_rolegroup Where RoleGroup='NoneTechnicalRole')
),
----برای تبدیل مدیران به همه سمت ها
CTE_Manager As (
Select  RL.RoleID
,RL2.RoleId RoleTargetID
,RL.LevelId LevelID,RL2.LevelId LevelIdTargetID
,Convert(bit,0) Superior,Convert(bit,0) SuperiorTarget
,Convert(bit,1) Education,Convert(bit,1) Evaluation,Convert(bit,1) ReEvaluation
,'' Assessor,Convert(bit,1) PmChange,Convert(bit,1) ITChange
From CTE_RoleLevel RL
Cross Join CTE_RoleLevel RL2
Where RL.RoleId  IN (Select RoleID_id From HR_rolegroup Where RoleGroup='Manager')
And RL.RoleId<>RL2.RoleId
),
----برای تبدیل مدیران به ارشد همه سمت ها
CTE_ManagerSuprier As (
Select  RL.RoleID
,RL2.RoleId RoleTargetID
,RL.LevelId LevelID,RL2.LevelId LevelIdTargetID
,Convert(bit,0) Superior,Convert(bit,1) SuperiorTarget
,Convert(bit,1) Education,Convert(bit,1) Evaluation,Convert(bit,0) ReEvaluation
,'' Assessor,Convert(bit,1) PmChange,Convert(bit,1) ITChange
From CTE_RoleLevel RL
Cross Join CTE_RoleLevel RL2
Where RL.RoleId  IN (Select RoleID_id From HR_rolegroup Where RoleGroup='Manager')
And RL.RoleId<>RL2.RoleId
And RL2.HasSuperior=1
And RL2.LevelId <= 5
),
--برای پشتیبان جونیور به ارشد
CTE_JuniorSupporterSuprier As (
Select  RL.RoleId --پشتیبان
,RL2.RoleId RoleTargetID
,RL.LevelId LevelID,RL2.LevelId LevelIdTargetID
,Convert(bit,0) Superior,Convert(bit,1) SuperiorTarget
,Convert(bit,1) Education,Convert(bit,1) Evaluation,Convert(bit,0) ReEvaluation
,'' Assessor,Convert(bit,1) PmChange,Convert(bit,1) ITChange
From CTE_RoleLevel RL
Cross Join CTE_RoleLevel RL2
Where RL.RoleId  =69 --پشتیبان
And RL2.RoleId = 69
And RL2.HasSuperior=1
And RL2.LevelId <= RL.LevelId
And RL2.LevelId <= 5)

---تغییرات برای تغییر سمت 
,CTE_RoleChaneg As (
Select * From CTE_NoneTechnicalRole
Union
Select *  From CTE_NoneTechnicalRoleTarget
Union 
Select * From CTE_RoleBase
Union 
Select * From CTE_RoleBaseSuprier
union 
Select * From CTE_TechnicalRole
union 
Select * From CTE_Manager
union
Select * From CTE_ManagerSuprier
union
select * From CTE_JuniorSupporterSuprier
union
Select * From CTE_NoneTechnicalRoleSelf),CTE_RequestType As (
----برای تایپ 4 یعنی تعریف جدیدسمت میتواند از گروه خود انتخاب کند
Select RC.*,'4' RequestType From CTE_RoleChaneg RC
Inner Join HR_rolegroup  Rg
On RC.RoleID=RG.RoleID_id
Inner Join HR_rolegroup  Rg2
On RC.RoleTargetID=RG2.RoleID_id
Where RG.RoleGroup=RG2.RoleGroup
And RoleID<>RoleTargetID
Union 
----برای حالتی که میخواد استثنا انتخاب کند
Select  RL.RoleID
,RL2.RoleId RoleTargetID
,RL.LevelId LevelID,RL2.LevelId LevelIdTargetID
,Convert(bit,0) Superior,Convert(bit,0) SuperiorTarget
,Convert(bit,1) Education,Convert(bit,1) Evaluation,Convert(bit,1) ReEvaluation
,'' Assessor,Convert(bit,1) PmChange,Convert(bit,1) ITChange
,'4' RequestType
From CTE_RoleLevel RL
Cross Join CTE_RoleLevel RL2
Where RL.RoleID in(63,57,58,55,56)
And RL2.RoleId In (72,69)
Union 
----برای حالتی که میخواد استثنا ارشد باشه انتخاب کند
Select  RL.RoleID
,RL2.RoleId RoleTargetID
,RL.LevelId LevelID,RL2.LevelId LevelIdTargetID
,Convert(bit,1) Superior,Convert(bit,0) SuperiorTarget
,Convert(bit,1) Education,Convert(bit,1) Evaluation,Convert(bit,1) ReEvaluation
,'' Assessor,Convert(bit,1) PmChange,Convert(bit,1) ITChange
,'4' RequestType
From CTE_RoleLevel RL
Cross Join CTE_RoleLevel RL2
Where RL.RoleID in(63,57,58,55,56)
And RL2.RoleId In (72,69)
And RL.LevelId <= 5
Union 
----برای حالتی که میخواد استثنا ارشد باشه ارشد  انتخاب کند
Select  RL.RoleID
,RL2.RoleId RoleTargetID
,RL.LevelId LevelID,RL2.LevelId LevelIdTargetID
,Convert(bit,1) Superior,Convert(bit,1) SuperiorTarget
,Convert(bit,1) Education,Convert(bit,1) Evaluation,Convert(bit,1) ReEvaluation
,'' Assessor,Convert(bit,1) PmChange,Convert(bit,1) ITChange
,'4' RequestType
From CTE_RoleLevel RL
Cross Join CTE_RoleLevel RL2
Where RL.RoleID in(63,57,58,55,56)
And RL2.RoleId In (72,69)
And RL.LevelId <= 5
And RL2.LevelId <= 5
Union 
----برای حالتی که میخواد استثنا  باشه ارشد  انتخاب کند
Select  RL.RoleID
,RL2.RoleId RoleTargetID
,RL.LevelId LevelID,RL2.LevelId LevelIdTargetID
,Convert(bit,0) Superior,Convert(bit,1) SuperiorTarget
,Convert(bit,1) Education,Convert(bit,1) Evaluation,Convert(bit,1) ReEvaluation
,'' Assessor,Convert(bit,1) PmChange,Convert(bit,1) ITChange
,'4' RequestType
From CTE_RoleLevel RL
Cross Join CTE_RoleLevel RL2
Where RL.RoleID in(63,57,58,55,56)
And RL2.RoleId In (72,69)
And RL2.LevelId <= 5
Union 
--برای تایپ سمت و تیم جدید
Select RC.*,'6' RequestType From CTE_RoleChaneg RC
Inner Join HR_rolegroup  Rg
On RC.RoleID=RG.RoleID_id
Inner Join HR_rolegroup  Rg2
On RC.RoleTargetID=RG2.RoleID_id
Where RG.RoleGroup=RG2.RoleGroup
And RoleID<>RoleTargetID
Union
----برای حالتی که میخواد استثنا انتخاب کند
Select  RL.RoleID
,RL2.RoleId RoleTargetID
,RL.LevelId LevelID,RL2.LevelId LevelIdTargetID
,Convert(bit,0) Superior,Convert(bit,0) SuperiorTarget
,Convert(bit,1) Education,Convert(bit,1) Evaluation,Convert(bit,1) ReEvaluation
,'' Assessor,Convert(bit,1) PmChange,Convert(bit,1) ITChange
,'6' RequestType
From CTE_RoleLevel RL
Cross Join CTE_RoleLevel RL2
Where RL.RoleID in(63,57,58,55,56)
And RL2.RoleId In (72,69)
Union 
----برای حالتی که میخواد استثنا ارشد باشه انتخاب کند
Select  RL.RoleID
,RL2.RoleId RoleTargetID
,RL.LevelId LevelID,RL2.LevelId LevelIdTargetID
,Convert(bit,1) Superior,Convert(bit,0) SuperiorTarget
,Convert(bit,1) Education,Convert(bit,1) Evaluation,Convert(bit,1) ReEvaluation
,'' Assessor,Convert(bit,1) PmChange,Convert(bit,1) ITChange
,'6' RequestType
From CTE_RoleLevel RL
Cross Join CTE_RoleLevel RL2
Where RL.RoleID in(63,57,58,55,56)
And RL2.RoleId In (72,69)
And RL.LevelId <= 5
Union 
----برای حالتی که میخواد استثنا ارشد باشه ارشد  انتخاب کند
Select  RL.RoleID
,RL2.RoleId RoleTargetID
,RL.LevelId LevelID,RL2.LevelId LevelIdTargetID
,Convert(bit,1) Superior,Convert(bit,1) SuperiorTarget
,Convert(bit,1) Education,Convert(bit,1) Evaluation,Convert(bit,1) ReEvaluation
,'' Assessor,Convert(bit,1) PmChange,Convert(bit,1) ITChange
,'6' RequestType
From CTE_RoleLevel RL
Cross Join CTE_RoleLevel RL2
Where RL.RoleID in(63,57,58,55,56)
And RL2.RoleId In (72,69)
And RL.LevelId <= 5
And RL2.LevelId <= 5
Union 
----برای حالتی که میخواد استثنا  باشه ارشد  انتخاب کند
Select  RL.RoleID
,RL2.RoleId RoleTargetID
,RL.LevelId LevelID,RL2.LevelId LevelIdTargetID
,Convert(bit,0) Superior,Convert(bit,1) SuperiorTarget
,Convert(bit,1) Education,Convert(bit,1) Evaluation,Convert(bit,1) ReEvaluation
,'' Assessor,Convert(bit,1) PmChange,Convert(bit,1) ITChange
,'6' RequestType
From CTE_RoleLevel RL
Cross Join CTE_RoleLevel RL2
Where RL.RoleID in(63,57,58,55,56)
And RL2.RoleId In (72,69)
And RL2.LevelId <= 5
Union 
--برای تایپ جابه جایی سمت 
Select RC.*,'1' RequestType From CTE_RoleChaneg RC
Where RoleID<>RoleTargetID
Union 
--برای تایپ جابهجایی سمت و تیم 
Select RC.*,'3' RequestType From CTE_RoleChaneg RC
Where RoleID<>RoleTargetID
union 
---برای تایپ تغییر سطح
Select RC.*,'8' RequestType From CTE_RoleChaneg RC
Where RoleID=RoleTargetID 
And ((Isnull(LevelIdTargetID,0)+1=Isnull(LevelID,0)) Or 
(RC.Superior<>RC.SuperiorTarget And Isnull(LevelIdTargetID,0)=Isnull(LevelID,0)))
)
Select R.RoleID,R.RoleTargetID
,RO.RoleName RoleTargetName
,R.Education,R.Evaluation
,R.ITChange,isnull(R.LevelID,0)LevelID
,isnull(R.LevelIdTargetID,0) LevelIdTargetID,R.PmChange,R.ReEvaluation,R.Superior,R.SuperiorTarget
,R.RequestType
,(Case When R.Assessor in('106','108','111','115','88') Then 
(Select UserName From UserTeamRole Where RoleId=Assessor) Else '' End) Assessor
,ROW_NUMBER()Over(order by R.RoleID) Id
From CTE_RequestType R
Inner Join Role Ro
On Ro.RoleId=R.RoleTargetID


GO
/****** Object:  View [dbo].[V_Payment_Average_Yearly]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Payment_Average_Yearly] as
Select ROW_NUMBER() Over(order by YearNumber) Id,
YearNumber,
AVG(Payment) Payment, AVG(OtherPayment) OtherPayment, AVG(PaymentCost) PaymentCost, 
AVG(OverTime) OverTime, AVG(OverTimePayment) OverTimePayment, AVG(Reward) Reward, 
AVG(TotalPayment) TotalPayment, AVG(BasePayment) BasePayment 
From V_Payment_Average
Group By YearNumber
GO
/****** Object:  Table [dbo].[HR_organizationchartrole]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_organizationchartrole](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[LevelId_id] [bigint] NULL,
	[RoleId_id] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HR_organizationchartteamrole]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_organizationchartteamrole](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[RoleCount] [int] NULL,
	[ManagerUserName_id] [varchar](100) NULL,
	[OrganizationChartRole_id] [bigint] NOT NULL,
	[TeamCode_id] [char](3) NOT NULL,
	[ManagerNationalCode] [nvarchar](10) NULL,
 CONSTRAINT [PK__HR_organ__3213E83F074C4FF4] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[V_RoleTeam]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE View [dbo].[V_RoleTeam] As 
With CTE_User As (
Select Distinct RoleId_id RoleId,TeamCode_id TeamCode,OC.ManagerUserName_id ManagerUserName, OC.ManagerNationalCode ManagerNationalCode
From  HR_organizationchartrole o
Inner Join HR_organizationchartteamrole OC
On oC.OrganizationChartRole_id=O.id
union
Select Distinct RoleId,TeamCode,ManagerUserName_id, ManagerNationalCode From UserTeamRole WHERE ManagerNationalCode IS NULL)
Select * 
,ROW_NUMBER() Over(order By teamCode) Id
From CTE_User
GO
/****** Object:  View [dbo].[V_Payment_Role_Average_Yearly]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE view [dbo].[V_Payment_Role_Average_Yearly] as
Select ROW_NUMBER() Over(order by YearNumber,RoleId,LevelId_id) Id,
YearNumber,RoleId,LevelId_id,
AVG(Payment) Payment, AVG(OtherPayment) OtherPayment, AVG(PaymentCost) PaymentCost, 
AVG(OverTime) OverTime, AVG(OverTimePayment) OverTimePayment, AVG(Reward) Reward, 
AVG(TotalPayment) TotalPayment , AVG(BasePayment) BasePayment
From V_Payment_Role_Average
Group By YearNumber,RoleId,LevelId_id
GO
/****** Object:  Table [dbo].[HR_UserSlip]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_UserSlip](
	[id] [bigint] NULL,
	[PersonnelCode] [nvarchar](10) NOT NULL,
	[YearNumber] [smallint] NOT NULL,
	[MonthNumber] [smallint] NOT NULL,
	[ItemValue] [bigint] NOT NULL,
	[Code] [nvarchar](60) NULL,
	[UserName] [varchar](100) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[V_UserSlip_Average]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




	CREATE View [dbo].[V_UserSlip_Average] as
  Select    ROW_NUMBER() Over(order by YearNumber, MonthNumber) As id,
  YearNumber, MonthNumber, AVG(ItemValue) ItemValue, Code 
  From HR_UserSlip
Group By  YearNumber, MonthNumber,  Code
GO
/****** Object:  Table [dbo].[AccessControl_app]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AccessControl_app](
	[Code] [nvarchar](6) NOT NULL,
	[Title] [nvarchar](100) NOT NULL,
	[SystemCode_id] [nvarchar](3) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[AccessControl_apppermissiontype]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AccessControl_apppermissiontype](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[PermissionType] [nvarchar](100) NOT NULL,
	[AppCode] [nvarchar](6) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[AccessControl_appurl]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AccessControl_appurl](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[URL] [nvarchar](500) NOT NULL,
	[AppCode] [nvarchar](6) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[AccessControl_groupuser]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AccessControl_groupuser](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[Group_id] [bigint] NOT NULL,
	[User_id] [nvarchar](100) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[AccessControl_permission]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AccessControl_permission](
	[Code] [nvarchar](10) NOT NULL,
	[Title] [nvarchar](100) NOT NULL,
	[PermissionType] [nvarchar](1) NOT NULL,
	[AppCode_id] [nvarchar](6) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[AccessControl_permissiongroup]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AccessControl_permissiongroup](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[Title] [nvarchar](100) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[AccessControl_permissionvariable]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AccessControl_permissionvariable](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[Code] [nvarchar](5) NOT NULL,
	[Title] [nvarchar](100) NOT NULL,
	[VariableDescription] [nvarchar](200) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[AccessControl_system]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AccessControl_system](
	[Code] [nvarchar](3) NOT NULL,
	[Title] [nvarchar](100) NOT NULL,
	[PortNumber] [int] NOT NULL,
	[Logo] [nvarchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[AccessControl_userrolegrouppermission]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AccessControl_userrolegrouppermission](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[OwnerPermissionGroup] [bigint] NULL,
	[OwnerPermissionRole] [int] NULL,
	[OwnerPermissionUser] [nvarchar](100) NULL,
	[PermissionCode] [nvarchar](10) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[auth_group_permissions]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[auth_group_permissions](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[group_id] [int] NOT NULL,
	[permission_id] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[auth_permission]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[auth_permission](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](255) NOT NULL,
	[content_type_id] [int] NOT NULL,
	[codename] [nvarchar](100) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[auth2_user_user_permissions]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[auth2_user_user_permissions](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[user_id] [nvarchar](10) NOT NULL,
	[permission_id] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Cartable_documenrflow]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Cartable_documenrflow](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReciveDate] [date] NULL,
	[IsRead] [bit] NOT NULL,
	[SendDate] [date] NULL,
	[DueDate] [date] NULL,
	[PersonalDueDate] [date] NULL,
	[DocumentId_id] [bigint] NULL,
	[InboxOwner_id] [nvarchar](100) NOT NULL,
	[PreviousFlow_id] [bigint] NULL,
	[SenderUser_id] [nvarchar](100) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Cartable_document]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Cartable_document](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[AppDocId] [int] NOT NULL,
	[Priority] [nvarchar](100) NOT NULL,
	[DocState] [nvarchar](100) NOT NULL,
	[AppURLId_id] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[django_admin_log]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[django_admin_log](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[action_time] [datetimeoffset](7) NOT NULL,
	[object_id] [nvarchar](max) NULL,
	[object_repr] [nvarchar](200) NOT NULL,
	[action_flag] [smallint] NOT NULL,
	[change_message] [nvarchar](max) NOT NULL,
	[content_type_id] [int] NULL,
	[user_id] [nvarchar](10) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[django_content_type]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[django_content_type](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[app_label] [nvarchar](100) NOT NULL,
	[model] [nvarchar](100) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [django_content_type_app_label_model_76bd3d3b_uniq] UNIQUE NONCLUSTERED 
(
	[app_label] ASC,
	[model] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[django_migrations]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[django_migrations](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[app] [nvarchar](255) NOT NULL,
	[name] [nvarchar](255) NOT NULL,
	[applied] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[django_session]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[django_session](
	[session_key] [nvarchar](40) NOT NULL,
	[session_data] [nvarchar](max) NOT NULL,
	[expire_date] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[session_key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Duties_request]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Duties_request](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Duties_requeststep]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Duties_requeststep](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Duties_rolecategory]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Duties_rolecategory](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[CategoryName] [nvarchar](100) NOT NULL,
	[DescriptionType] [nvarchar](1) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Duties_roledescription]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Duties_roledescription](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreateDate] [datetime2](7) NULL,
	[ModifyDate] [datetime2](7) NULL,
	[Superior] [bit] NOT NULL,
	[Title] [nvarchar](4000) NOT NULL,
	[IsConfirm] [bit] NOT NULL,
	[Category_id] [bigint] NOT NULL,
	[CreatorUserName_id] [nvarchar](100) NULL,
	[LevelId] [bigint] NULL,
	[ModifierUserName_id] [nvarchar](100) NULL,
	[RoleId] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Duties_rolepermission]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Duties_rolepermission](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreateDate] [datetime2](7) NULL,
	[ModifyDate] [datetime2](7) NULL,
	[CreatorUserName_id] [nvarchar](100) NULL,
	[ModifierUserName_id] [nvarchar](100) NULL,
	[Permission_id] [nvarchar](10) NOT NULL,
	[Role_id] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Duties_step]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Duties_step](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[EVA_Users]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EVA_Users](
	[UserName] [varchar](100) NOT NULL,
	[PersonnelCode] [varchar](10) NULL,
	[LastName] [nvarchar](200) NULL,
	[FirstName] [nvarchar](200) NULL,
	[FatherName] [nvarchar](100) NULL,
	[Gender] [bit] NULL,
	[IsActive] [bit] NOT NULL,
	[MobileNo] [varchar](12) NULL,
	[TelNo] [varchar](12) NULL,
	[Address] [nvarchar](2000) NULL,
	[BirthDate] [varchar](10) NULL,
	[MilitaryStatus] [tinyint] NULL,
	[ContractDate] [varchar](10) NULL,
	[MaridageStatus] [bit] NULL,
	[Comment] [nvarchar](max) NULL,
	[DegreeType] [tinyint] NULL,
	[FieldOfStudy] [nvarchar](255) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HR_accesspersonnel]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_accesspersonnel](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[UserName_id] [varchar](100) NOT NULL,
	[NationalCode] [nvarchar](10) NULL,
 CONSTRAINT [PK__HR_acces__3213E83F3FE62382] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HR_citydistrict]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_citydistrict](
	[id] [bigint] NOT NULL,
	[DistrictTitle] [nvarchar](50) NOT NULL,
	[City_id] [int] NOT NULL,
 CONSTRAINT [PK__HR_cityd__3213E83FD27FBCDE] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HR_educationhistory]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_educationhistory](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[StartDate] [date] NULL,
	[EndDate] [date] NULL,
	[StartYear] [smallint] NULL,
	[EndYear] [smallint] NULL,
	[IsStudent] [bit] NOT NULL,
	[GPA] [numeric](4, 2) NULL,
	[EducationTendency_id] [bigint] NULL,
	[Person_id] [varchar](100) NOT NULL,
	[University_id] [bigint] NULL,
	[Degree_Type_id] [bigint] NOT NULL,
	[PersonNationalCode] [nvarchar](10) NULL,
 CONSTRAINT [PK__HR_educa__3213E83F4D02780D] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HR_emailaddress]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_emailaddress](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[Email] [nvarchar](254) NOT NULL,
	[Title] [nvarchar](100) NULL,
	[Person_id] [varchar](100) NULL,
	[IsDefault] [bit] NOT NULL,
	[PersonNationalCode] [nvarchar](10) NULL,
 CONSTRAINT [PK__HR_email__3213E83F37A5CB59] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HR_fieldofstudy]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_fieldofstudy](
	[id] [bigint] NOT NULL,
	[Title] [nvarchar](150) NOT NULL,
 CONSTRAINT [PK__HR_field__3213E83FA016913F] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HR_newrolerequest]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_newrolerequest](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[RoleTitle] [nvarchar](100) NOT NULL,
	[HasLevel] [bit] NOT NULL,
	[HasSuperior] [bit] NOT NULL,
	[AllowedTeams] [nvarchar](1000) NOT NULL,
	[RequestorId] [nvarchar](10) NOT NULL,
	[RequestDate] [date] NOT NULL,
	[ManagerId] [nvarchar](10) NOT NULL,
	[ManagerOpinion] [bit] NOT NULL,
	[ManagerDate] [date] NULL,
	[CTOId] [nvarchar](10) NULL,
	[CTOOpinion] [bit] NULL,
	[CTODate] [date] NULL,
	[ConditionsText] [nvarchar](1000) NULL,
	[DutiesText] [nvarchar](1000) NULL,
	[StatusCode] [nvarchar](6) NULL,
	[DocId] [int] NULL,
	[ManagerType_id] [bigint] NULL,
	[NewRoleTypeTitle] [nvarchar](100) NULL,
	[RoleType_id] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HR_organizationchartteamrole14010725]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_organizationchartteamrole14010725](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[RoleCount] [int] NULL,
	[ManagerUserName_id] [nvarchar](100) NULL,
	[OrganizationChartRole_id] [bigint] NOT NULL,
	[TeamCode_id] [nvarchar](3) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HR_phonenumber]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_phonenumber](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[TelNumber] [bigint] NOT NULL,
	[Title] [nvarchar](50) NULL,
	[Person_id] [varchar](100) NULL,
	[TelType_id] [bigint] NOT NULL,
	[Province_id] [bigint] NULL,
	[IsDefault] [bit] NOT NULL,
	[PersonNationalCode] [nvarchar](10) NULL,
 CONSTRAINT [PK__HR_phone__3213E83F7168D750] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HR_postaladdress]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_postaladdress](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[Title] [nvarchar](100) NULL,
	[AddressText] [nvarchar](500) NULL,
	[No] [nvarchar](20) NULL,
	[UnitNo] [smallint] NULL,
	[PostalCode] [bigint] NULL,
	[CityDistrict_id] [bigint] NULL,
	[Person_id] [varchar](100) NULL,
	[City_id] [int] NOT NULL,
	[IsDefault] [bit] NOT NULL,
	[PersonNationalCode] [nvarchar](10) NULL,
 CONSTRAINT [PK__HR_posta__3213E83F97BFA363] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HR_province]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_province](
	[id] [bigint] NOT NULL,
	[ProvinceTitle] [nvarchar](50) NOT NULL,
	[AbbreviationCode] [nvarchar](2) NULL,
	[PhoneCode] [int] NULL,
 CONSTRAINT [PK__HR_provi__3213E83F09A289BF] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ__HR_provi__C1314ED00D4273A9] UNIQUE NONCLUSTERED 
(
	[ProvinceTitle] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HR_rolegrouptargetexception]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_rolegrouptargetexception](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[RoleGroup] [nvarchar](100) NOT NULL,
	[RoleGroupTarget] [nvarchar](100) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HR_roleinformation]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
/****** Object:  Table [dbo].[HR_RoleType]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_RoleType](
	[TypeCode] [nvarchar](1) NOT NULL,
	[TypeTitle] [nvarchar](200) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[TypeCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HR_setteamallowedrolerequest]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_setteamallowedrolerequest](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[TeamAllowedRoles] [nvarchar](2000) NOT NULL,
	[RequestorId] [nvarchar](10) NOT NULL,
	[RequestDate] [date] NOT NULL,
	[ManagerId] [nvarchar](10) NOT NULL,
	[ManagerOpinion] [bit] NULL,
	[ManagerDate] [date] NULL,
	[CTOId] [nvarchar](10) NOT NULL,
	[CTOOpinion] [bit] NULL,
	[CTODate] [date] NULL,
	[DocId] [int] NULL,
	[StatusCode] [nvarchar](6) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HR_teamallowedroles]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_teamallowedroles](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[AllowedRoleCount] [smallint] NULL,
	[Comment] [nvarchar](500) NOT NULL,
	[RoleId] [int] NOT NULL,
	[SetTeamAllowedRoleRequest_id] [bigint] NULL,
	[TeamCode] [char](3) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HR_tendency]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_tendency](
	[id] [bigint] NOT NULL,
	[Title] [nvarchar](150) NOT NULL,
	[FieldOfStudy_id] [bigint] NOT NULL,
 CONSTRAINT [PK__HR_tende__3213E83F1302FA7F] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HR_university]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_university](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[Title] [nvarchar](150) NOT NULL,
	[UniversityCity_id] [int] NULL,
	[University_Type_id] [bigint] NULL,
 CONSTRAINT [PK__HR_unive__3213E83FD4E575A2] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HR_university14010321]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_university14010321](
	[id] [bigint] NOT NULL,
	[Title] [nvarchar](150) NOT NULL,
	[UniversityType] [smallint] NULL,
	[UniversityCity_id] [bigint] NULL,
	[University_Type_id] [bigint] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[HR_userhistory]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HR_userhistory](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[UserName] [nvarchar](300) NOT NULL,
	[AuthLoginKey] [nvarchar](300) NULL,
	[RequestDate] [datetime2](7) NOT NULL,
	[EnterDate] [datetime2](7) NULL,
	[RequestUrl] [nvarchar](300) NULL,
	[EnterUrl] [nvarchar](300) NULL,
	[IP] [nvarchar](39) NULL,
	[UserAgent] [nvarchar](300) NULL,
	[ChangedUserInfo] [bit] NULL,
	[AppName] [nvarchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Import_ActiveInActive]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Import_ActiveInActive](
	[ردیف] [float] NULL,
	[کد ملی] [nvarchar](255) NULL,
	[نام] [nvarchar](255) NULL,
	[نام خانوادگی] [nvarchar](255) NULL,
	[فعال یا غیر فعال] [float] NULL,
	[وضعیت پرسنلی در چارگون] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Import_BirthCity]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Import_BirthCity](
	[ردیف] [float] NULL,
	[کد ملی] [nvarchar](255) NULL,
	[نام] [nvarchar](255) NULL,
	[نام خانوادگی] [nvarchar](255) NULL,
	[شهر تولد] [nvarchar](255) NULL,
	[شهر تولد در چارگون] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Import_BirthDate]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Import_BirthDate](
	[ردیف] [float] NULL,
	[کد ملی] [nvarchar](255) NULL,
	[نام] [nvarchar](255) NULL,
	[نام خانوادگی] [nvarchar](255) NULL,
	[تاریخ تولد در BPMS] [nvarchar](255) NULL,
	[تاریخ تولد در چارگون] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Import_ChildrenCount]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Import_ChildrenCount](
	[ردیف] [float] NULL,
	[کد ملی] [nvarchar](255) NULL,
	[نام] [nvarchar](255) NULL,
	[نام خانوادگی] [nvarchar](255) NULL,
	[تعداد فرزند در BPMS] [nvarchar](255) NULL,
	[تعداد فرزند در چارگون] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Import_Education]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Import_Education](
	[ردیف] [float] NULL,
	[کد ملی] [nvarchar](255) NULL,
	[نام] [nvarchar](255) NULL,
	[نام خانوادگی] [nvarchar](255) NULL,
	[تحصیلات در BPMS] [nvarchar](255) NULL,
	[تحصیلات در چارگون] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Import_EmployeedWorker]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Import_EmployeedWorker](
	[ردیف] [float] NULL,
	[نام کاربری] [nvarchar](255) NULL,
	[کد ملی] [nvarchar](255) NULL,
	[نام] [nvarchar](255) NULL,
	[نام خانوادگی] [nvarchar](255) NULL,
	[تاریخ ترک کار  در BPMS] [nvarchar](255) NULL,
	[تاریخ ترک کار در چارگون] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Import_EmploymentType]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Import_EmploymentType](
	[ردیف] [float] NULL,
	[کد ملی] [nvarchar](255) NULL,
	[نام] [nvarchar](255) NULL,
	[نام خانوادگی] [nvarchar](255) NULL,
	[نوع استخدام  در BPMS] [nvarchar](255) NULL,
	[نوع استخدام  در چارگون] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Import_FatherName]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Import_FatherName](
	[ردیف] [float] NULL,
	[نام کاربری] [nvarchar](255) NULL,
	[کد ملی] [nvarchar](255) NULL,
	[نام] [nvarchar](255) NULL,
	[نام خانوادگی] [nvarchar](255) NULL,
	[نام پدر در BPMS] [nvarchar](255) NULL,
	[نام پدر در چارگون] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Import_IdentificationNumber]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Import_IdentificationNumber](
	[ردیف] [float] NULL,
	[کد ملی] [nvarchar](255) NULL,
	[نام] [nvarchar](255) NULL,
	[نام خانوادگی] [nvarchar](255) NULL,
	[شماره شناسنامه] [nvarchar](255) NULL,
	[شماره شناسنامه در چارگون] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Import_LeaveWork]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Import_LeaveWork](
	[ردیف] [float] NULL,
	[نام کاربری] [nvarchar](255) NULL,
	[کد ملی] [nvarchar](255) NULL,
	[نام] [nvarchar](255) NULL,
	[نام خانوادگی] [nvarchar](255) NULL,
	[تاریخ ترک کار  در BPMS] [nvarchar](255) NULL,
	[تاریخ ترک کار در چارگون] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Import_Marriage]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Import_Marriage](
	[ردیف] [float] NULL,
	[کد ملی] [nvarchar](255) NULL,
	[نام] [nvarchar](255) NULL,
	[نام خانوادگی] [nvarchar](255) NULL,
	[تاهل] [nvarchar](255) NULL,
	[تاهل در چارگون] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Import_Military]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Import_Military](
	[ردیف] [float] NULL,
	[کد ملی] [nvarchar](255) NULL,
	[نام] [nvarchar](255) NULL,
	[نام خانوادگی] [nvarchar](255) NULL,
	[نظام وظیفه در BPMS] [nvarchar](255) NULL,
	[نظام وظیفه در چارگون] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Import_Religion]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Import_Religion](
	[ردیف] [float] NULL,
	[کد ملی] [nvarchar](255) NULL,
	[نام] [nvarchar](255) NULL,
	[نام خانوادگی] [nvarchar](255) NULL,
	[دین در BPMS] [nvarchar](255) NULL,
	[دین در چارگون] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Import_Sex]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Import_Sex](
	[ردیف] [float] NULL,
	[کد ملی] [nvarchar](255) NULL,
	[نام] [nvarchar](255) NULL,
	[نام خانوادگی] [nvarchar](255) NULL,
	[تاریخ استخدام] [nvarchar](255) NULL,
	[جنسیت در BPMS] [nvarchar](255) NULL,
	[جنسیت در چارگون] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ImportUserTel]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ImportUserTel](
	[FirstName] [nvarchar](100) NULL,
	[LastName] [nvarchar](100) NULL,
	[Number] [nvarchar](50) NULL,
	[UserName] [nvarchar](50) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Sheet1$]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Sheet1$](
	[ردیف] [float] NULL,
	[شماره پرسنلي] [nvarchar](255) NULL,
	[نام] [nvarchar](255) NULL,
	[نام‌خانوادگي] [nvarchar](255) NULL,
	[نام کاربری] [nvarchar](255) NULL,
	[نام پدر] [nvarchar](255) NULL,
	[شماره شناسنامه] [nvarchar](255) NULL,
	[سريال شناسنامه] [nvarchar](255) NULL,
	[محل صدور شناسنامه] [nvarchar](255) NULL,
	[تاريخ صدور شناسنامه] [nvarchar](255) NULL,
	[تاريخ تولد] [nvarchar](255) NULL,
	[محل تولد] [nvarchar](255) NULL,
	[شماره ملي] [nvarchar](255) NULL,
	[تعداد اولاد] [nvarchar](255) NULL,
	[آدرس] [nvarchar](255) NULL,
	[تلفن منزل] [nvarchar](255) NULL,
	[تلفن ضروري] [nvarchar](255) NULL,
	[تلفن همراه] [nvarchar](255) NULL,
	[کد پستي] [nvarchar](255) NULL,
	[ايميل] [nvarchar](255) NULL,
	[تاريخ استخدام] [nvarchar](255) NULL,
	[تاريخ ورود به خدمت] [nvarchar](255) NULL,
	[تاريخ ترك خدمت] [nvarchar](255) NULL,
	[محل اخذ مدرك] [nvarchar](255) NULL,
	[نوع دانشگاه] [nvarchar](255) NULL,
	[معدل] [nvarchar](255) NULL,
	[شماره بيمه] [nvarchar](255) NULL,
	[جنسيت] [nvarchar](255) NULL,
	[وضعيت اشتغال] [nvarchar](255) NULL,
	[محل خدمت] [nvarchar](255) NULL,
	[مليت] [nvarchar](255) NULL,
	[مقطع تحصيلي] [nvarchar](255) NULL,
	[وضعيت نظام‌وظيفه] [nvarchar](255) NULL,
	[وضعيت تاهل] [nvarchar](255) NULL,
	[نوع استخدام] [nvarchar](255) NULL,
	[دين] [nvarchar](255) NULL,
	[استان صدور شناسنامه] [nvarchar](255) NULL,
	[شهر محل صدور شناسنامه] [nvarchar](255) NULL,
	[رشته تحصيلي] [nvarchar](255) NULL,
	[قسمت كاري] [nvarchar](255) NULL,
	[پست رسمي] [nvarchar](255) NULL,
	[دپارتمان رسمي] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Systems_systemcategory]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Systems_systemcategory](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[Title] [nvarchar](500) NOT NULL,
	[Icon] [nvarchar](100) NULL,
	[OrderNumber] [int] NULL,
	[Parent_id] [bigint] NULL,
	[UserName_id] [nvarchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Systems_systemcategoryurl]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Systems_systemcategoryurl](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[AppURL_id] [bigint] NULL,
	[SystemCategory_id] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Temp_ActivePerson]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Temp_ActivePerson](
	[RowNumber] [float] NOT NULL,
	[NationalCode] [nvarchar](255) NULL,
	[Username] [nvarchar](255) NULL,
	[FullName] [nvarchar](255) NULL,
	[PersonStatus] [float] NULL,
	[PersonStatusChargon] [nvarchar](255) NULL,
	[Field7] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_ADR_City]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_ADR_City](
	[Id] [nvarchar](255) NULL,
	[CityName] [nvarchar](255) NULL,
	[RegionId] [nvarchar](255) NULL,
	[StateId] [nvarchar](255) NULL,
	[ProvinceId] [nvarchar](255) NULL,
	[IsCapital] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_ADR_City$]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_ADR_City$](
	[Id] [nvarchar](255) NULL,
	[CityName] [nvarchar](255) NULL,
	[RegionId] [nvarchar](255) NULL,
	[StateId] [nvarchar](255) NULL,
	[ProvinceId] [nvarchar](255) NULL,
	[IsCapital] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_ADR_City_Distance]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_ADR_City_Distance](
	[Id] [nvarchar](255) NULL,
	[CityId1] [nvarchar](255) NULL,
	[CityId2] [nvarchar](255) NULL,
	[Distance] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_ADR_City_Distance$]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_ADR_City_Distance$](
	[Id] [nvarchar](255) NULL,
	[CityId1] [nvarchar](255) NULL,
	[CityId2] [nvarchar](255) NULL,
	[Distance] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_ADR_Country]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_ADR_Country](
	[Id] [nvarchar](255) NULL,
	[CountryName] [nvarchar](255) NULL,
	[CountryEnglishName] [nvarchar](255) NULL,
	[Nationality] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_ADR_Country$]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_ADR_Country$](
	[Id] [nvarchar](255) NULL,
	[CountryName] [nvarchar](255) NULL,
	[CountryEnglishName] [nvarchar](255) NULL,
	[Nationality] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_ADR_Province]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_ADR_Province](
	[Id] [nvarchar](255) NULL,
	[ProvinceName] [nvarchar](255) NULL,
	[CountryId] [nvarchar](255) NULL,
	[AbrivationCode] [nvarchar](255) NULL,
	[IsActive] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_ADR_Province$]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_ADR_Province$](
	[Id] [nvarchar](255) NULL,
	[ProvinceName] [nvarchar](255) NULL,
	[CountryId] [nvarchar](255) NULL,
	[AbrivationCode] [nvarchar](255) NULL,
	[IsActive] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_ADR_Region]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_ADR_Region](
	[Id] [nvarchar](255) NULL,
	[RegionName] [nvarchar](255) NULL,
	[StateId] [nvarchar](255) NULL,
	[ProvinceId] [nvarchar](255) NULL,
	[RegionCode] [nvarchar](255) NULL,
	[IsActive] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_ADR_Region$]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_ADR_Region$](
	[Id] [nvarchar](255) NULL,
	[RegionName] [nvarchar](255) NULL,
	[StateId] [nvarchar](255) NULL,
	[ProvinceId] [nvarchar](255) NULL,
	[RegionCode] [nvarchar](255) NULL,
	[IsActive] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_ADR_Rustic]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_ADR_Rustic](
	[Id] [nvarchar](255) NULL,
	[RusticName] [nvarchar](255) NULL,
	[RegionId] [nvarchar](255) NULL,
	[IsActive] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_ADR_Rustic$]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_ADR_Rustic$](
	[Id] [nvarchar](255) NULL,
	[RusticName] [nvarchar](255) NULL,
	[RegionId] [nvarchar](255) NULL,
	[IsActive] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_ADR_Section]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_ADR_Section](
	[id] [nvarchar](255) NULL,
	[SectionName] [nvarchar](255) NULL,
	[CityId] [nvarchar](255) NULL,
	[SectionNumber] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_ADR_Section$]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_ADR_Section$](
	[id] [nvarchar](255) NULL,
	[SectionName] [nvarchar](255) NULL,
	[CityId] [nvarchar](255) NULL,
	[SectionNumber] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_ADR_State]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_ADR_State](
	[Id] [nvarchar](255) NULL,
	[StateName] [nvarchar](255) NULL,
	[ProvinceId] [nvarchar](255) NULL,
	[IsCapital] [nvarchar](255) NULL,
	[StateCode] [nvarchar](255) NULL,
	[IsActive] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_ADR_State$]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_ADR_State$](
	[Id] [nvarchar](255) NULL,
	[StateName] [nvarchar](255) NULL,
	[ProvinceId] [nvarchar](255) NULL,
	[IsCapital] [nvarchar](255) NULL,
	[StateCode] [nvarchar](255) NULL,
	[IsActive] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_ADR_Village]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_ADR_Village](
	[Id] [nvarchar](255) NULL,
	[VillageName] [nvarchar](255) NULL,
	[RusticId] [nvarchar](255) NULL,
	[RegionId] [nvarchar](255) NULL,
	[VillageCode] [nvarchar](255) NULL,
	[IsActive] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_ADR_Village$]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_ADR_Village$](
	[Id] [nvarchar](255) NULL,
	[VillageName] [nvarchar](255) NULL,
	[RusticId] [nvarchar](255) NULL,
	[RegionId] [nvarchar](255) NULL,
	[VillageCode] [nvarchar](255) NULL,
	[IsActive] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_CMP_Company]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_CMP_Company](
	[Id] [nvarchar](255) NULL,
	[CompanyName] [nvarchar](255) NULL,
	[IsForeign] [nvarchar](255) NULL,
	[CompanyTypeId] [nvarchar](255) NULL,
	[RegisterNumber] [nvarchar](255) NULL,
	[RegisterDate] [nvarchar](255) NULL,
	[RegisterCityId] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_CMP_Company$]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_CMP_Company$](
	[Id] [nvarchar](255) NULL,
	[CompanyName] [nvarchar](255) NULL,
	[IsForeign] [nvarchar](255) NULL,
	[CompanyTypeId] [nvarchar](255) NULL,
	[RegisterNumber] [nvarchar](255) NULL,
	[RegisterDate] [nvarchar](255) NULL,
	[RegisterCityId] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_EDU_FieldOfStudy]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_EDU_FieldOfStudy](
	[Id] [nvarchar](255) NULL,
	[FieldName] [nvarchar](255) NULL,
	[UnCertainty] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_EDU_FieldOfStudy$]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_EDU_FieldOfStudy$](
	[Id] [nvarchar](255) NULL,
	[FieldName] [nvarchar](255) NULL,
	[UnCertainty] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_EDU_Tendency]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_EDU_Tendency](
	[Id] [nvarchar](255) NULL,
	[FieldOfStudyId] [nvarchar](255) NULL,
	[Tendency] [nvarchar](255) NULL,
	[UnCertainty] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_EDU_Tendency$]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_EDU_Tendency$](
	[Id] [nvarchar](255) NULL,
	[FieldOfStudyId] [nvarchar](255) NULL,
	[Tendency] [nvarchar](255) NULL,
	[UnCertainty] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_EDU_University]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_EDU_University](
	[Id] [bigint] NULL,
	[UniversityName] [nvarchar](255) NULL,
	[CountryId] [nvarchar](255) NULL,
	[UniversityTypeId] [bigint] NULL,
	[CityId] [bigint] NULL,
	[StateId] [bigint] NULL,
	[ProvinceId] [bigint] NULL,
	[UnCertainty] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_EDU_University$]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_EDU_University$](
	[Id] [nvarchar](255) NULL,
	[UniversityName] [nvarchar](255) NULL,
	[CountryId] [nvarchar](255) NULL,
	[UniversityTypeId] [nvarchar](255) NULL,
	[CityId] [nvarchar](255) NULL,
	[StateId] [nvarchar](255) NULL,
	[ProvinceId] [nvarchar](255) NULL,
	[UnCertainty] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Temp_Employment]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Temp_Employment](
	[RowNumber] [float] NOT NULL,
	[NationalCode] [nvarchar](255) NULL,
	[Username] [nvarchar](255) NULL,
	[FullName] [nvarchar](255) NULL,
	[EmploymentDate] [nvarchar](255) NULL,
	[EmploymentDateChargon] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Temp_EmploymentStatus]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Temp_EmploymentStatus](
	[RowNumber] [float] NOT NULL,
	[NationalCode] [nvarchar](255) NULL,
	[Username] [nvarchar](255) NULL,
	[FullName] [nvarchar](255) NULL,
	[UserStatus] [nvarchar](255) NULL,
	[UserStatusChargon] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_GEN_StaticValue]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_GEN_StaticValue](
	[Id] [nvarchar](255) NULL,
	[Title] [nvarchar](255) NULL,
	[Code] [nvarchar](255) NULL,
	[ParentId] [nvarchar](255) NULL,
	[ProjectCode] [nvarchar](255) NULL,
	[IsActive] [nvarchar](255) NULL,
	[codenew] [bigint] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_GEN_StaticValue$]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_GEN_StaticValue$](
	[Id] [nvarchar](255) NULL,
	[Title] [nvarchar](255) NULL,
	[Code] [nvarchar](255) NULL,
	[ParentId] [nvarchar](255) NULL,
	[ProjectCode] [nvarchar](255) NULL,
	[IsActive] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Temp_LeaveWork]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Temp_LeaveWork](
	[ID] [int] NOT NULL,
	[RowNumber] [float] NULL,
	[NationalCode] [nvarchar](255) NULL,
	[FullName] [nvarchar](255) NULL,
	[LeavingDate] [nvarchar](255) NULL,
	[LeavingDateChargon] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Temp_New_Personnel]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Temp_New_Personnel](
	[NationalCode] [nvarchar](255) NULL,
	[FirstName] [nvarchar](255) NULL,
	[LastName] [nvarchar](255) NULL,
	[UserName] [nvarchar](255) NULL,
	[FatherName] [nvarchar](255) NULL,
	[IdentificationNo] [nvarchar](255) NULL,
	[IdentificationSerial] [nvarchar](255) NULL,
	[BirthDate] [nvarchar](255) NULL,
	[BirthCity] [nvarchar](255) NULL,
	[BirthCityId] [int] NULL,
	[ChildrenNumber] [nvarchar](255) NULL,
	[PostalAddress] [nvarchar](255) NULL,
	[PostalAddressCity] [nvarchar](100) NULL,
	[PostalAddressCityId] [int] NULL,
	[HomePhone] [nvarchar](255) NULL,
	[EmergencyPhone] [nvarchar](255) NULL,
	[Mobile] [nvarchar](255) NULL,
	[EmployeeDate] [nvarchar](255) NULL,
	[ExitDate] [nvarchar](255) NULL,
	[University] [nvarchar](255) NULL,
	[UniversityType] [nvarchar](255) NULL,
	[UniversityId] [int] NULL,
	[Point] [nvarchar](255) NULL,
	[InsuranceNo] [nvarchar](255) NULL,
	[Gender] [nvarchar](255) NULL,
	[Degree] [nvarchar](255) NULL,
	[DegreeId] [int] NULL,
	[MilitaryService] [float] NULL,
	[MilitaryServiceId] [int] NULL,
	[MarridageStatus] [nvarchar](255) NULL,
	[MarridageStatusId] [int] NULL,
	[نام کاربری1] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Temp_NewPersonnel_NaharTime_14020314]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Temp_NewPersonnel_NaharTime_14020314](
	[Fullname] [nvarchar](255) NULL,
	[PersonnelCode] [varchar](10) NULL,
	[FirstName] [nvarchar](255) NULL,
	[LastName] [nvarchar](255) NULL,
	[Gender] [bit] NOT NULL,
	[Username] [varchar](100) NULL,
	[StartDate] [varchar](10) NULL,
	[EndDate] [varchar](10) NULL,
	[StartDateMiladi] [date] NULL,
	[EndDateMiladi] [date] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_ORG_Organization]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_ORG_Organization](
	[ID] [nvarchar](255) NULL,
	[OrganizationName] [nvarchar](255) NULL,
	[OrganizationCode] [nvarchar](255) NULL,
	[ParentOrganizationCode] [nvarchar](255) NULL,
	[OrganizationTypeId] [nvarchar](255) NULL,
	[Cityid] [nvarchar](255) NULL,
	[OrganizationLevel] [nvarchar](255) NULL,
	[OrganizationClass] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_ORG_Organization$]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_ORG_Organization$](
	[ID] [nvarchar](255) NULL,
	[OrganizationName] [nvarchar](255) NULL,
	[OrganizationCode] [nvarchar](255) NULL,
	[ParentOrganizationCode] [nvarchar](255) NULL,
	[OrganizationTypeId] [nvarchar](255) NULL,
	[Cityid] [nvarchar](255) NULL,
	[OrganizationLevel] [nvarchar](255) NULL,
	[OrganizationClass] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Temp_Personel_14011013]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Temp_Personel_14011013](
	[ID] [float] NULL,
	[PersonnelNumber] [nvarchar](255) NULL,
	[FirstName] [nvarchar](255) NULL,
	[LastName] [nvarchar](255) NULL,
	[FirstNameEnglish] [nvarchar](50) NULL,
	[LastNameEnglish] [nvarchar](50) NULL,
	[Username] [nvarchar](255) NULL,
	[FatherName] [nvarchar](255) NULL,
	[IdentityNo] [nvarchar](255) NULL,
	[IdentitySerialNo] [nvarchar](255) NULL,
	[IdentityPlace] [nvarchar](255) NULL,
	[IdentityRegisterDate] [date] NULL,
	[IdentitiRegisterDateShamsi] [nvarchar](255) NULL,
	[IdentityProvince] [nvarchar](255) NULL,
	[IdentityProvinceId] [int] NULL,
	[IdentityCity] [nvarchar](255) NULL,
	[IdentityCityId] [int] NULL,
	[BirthDateShamsi] [nvarchar](255) NULL,
	[BirthDate] [date] NULL,
	[BirthCity] [nvarchar](255) NULL,
	[BirthCityId] [nchar](10) NULL,
	[NationalCode] [nvarchar](255) NULL,
	[ChildrenCount] [nvarchar](255) NULL,
	[PostalAddress] [nvarchar](255) NULL,
	[PostalAddressCity] [nvarchar](50) NULL,
	[PostalAddressCityId] [int] NULL,
	[PostalCode] [nvarchar](255) NULL,
	[PhoneTel] [nvarchar](255) NULL,
	[PhoneCityCode] [int] NULL,
	[PhoneCityId] [int] NULL,
	[EmergencyTel] [nvarchar](255) NULL,
	[EmergencyCityCode] [int] NULL,
	[EmergencyCityId] [int] NULL,
	[Mobile] [nvarchar](255) NULL,
	[EmailAddress] [nvarchar](255) NULL,
	[ContractDateShamsi] [nvarchar](255) NULL,
	[ContractDate] [date] NULL,
	[ContractEndDateShamsi] [nvarchar](255) NULL,
	[ContractEndDate] [date] NULL,
	[University] [nvarchar](255) NULL,
	[UniversityId] [int] NULL,
	[UniversityType] [nvarchar](255) NULL,
	[UniversityTypeId] [int] NULL,
	[EducationDegree] [nvarchar](255) NULL,
	[EducationDegreeId] [int] NULL,
	[EducationTendency] [nvarchar](255) NULL,
	[EducationTendencyId] [int] NULL,
	[AveragePoint] [nvarchar](255) NULL,
	[PersonnelStatus] [nvarchar](255) NULL,
	[IsActive] [bit] NULL,
	[InsuranceNumber] [nvarchar](255) NULL,
	[GenderText] [nvarchar](255) NULL,
	[Gender] [bit] NULL,
	[Nationality] [nvarchar](255) NULL,
	[MilitaryStatus] [nvarchar](255) NULL,
	[MilitaryStatusId] [int] NULL,
	[MariageStatus] [nvarchar](255) NULL,
	[MarriageStatusId] [int] NULL,
	[EmploymentType] [nvarchar](255) NULL,
	[ContractType] [int] NULL,
	[Religon] [nvarchar](255) NULL,
	[ReligionId] [int] NULL,
	[EmploymentStatus] [nvarchar](255) NULL,
	[UserStatus_id] [int] NULL,
	[EmploymentLocation] [nvarchar](255) NULL,
	[Unit] [nvarchar](50) NULL,
	[Role] [nvarchar](50) NULL,
	[Department] [nvarchar](50) NULL,
	[RoleId] [int] NULL,
	[TeamCode] [char](3) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Temp_Personel_14011013_3]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Temp_Personel_14011013_3](
	[ردیف] [float] NULL,
	[شماره پرسنلي] [nvarchar](255) NULL,
	[نام] [nvarchar](255) NULL,
	[نام‌خانوادگي] [nvarchar](255) NULL,
	[نام کاربری] [nvarchar](255) NULL,
	[نام پدر] [nvarchar](255) NULL,
	[شماره شناسنامه] [nvarchar](255) NULL,
	[سريال شناسنامه] [nvarchar](255) NULL,
	[محل صدور شناسنامه] [nvarchar](255) NULL,
	[تاريخ صدور شناسنامه] [nvarchar](255) NULL,
	[تاريخ تولد] [nvarchar](255) NULL,
	[محل تولد] [nvarchar](255) NULL,
	[شماره ملي] [nvarchar](255) NULL,
	[تعداد اولاد] [nvarchar](255) NULL,
	[آدرس] [nvarchar](255) NULL,
	[تلفن منزل] [nvarchar](255) NULL,
	[تلفن ضروري] [nvarchar](255) NULL,
	[تلفن همراه] [nvarchar](255) NULL,
	[کد پستي] [nvarchar](255) NULL,
	[ايميل] [nvarchar](255) NULL,
	[تاريخ استخدام] [nvarchar](255) NULL,
	[تاريخ ترك خدمت] [nvarchar](255) NULL,
	[محل اخذ مدرك] [nvarchar](255) NULL,
	[نوع دانشگاه] [nvarchar](255) NULL,
	[معدل] [nvarchar](255) NULL,
	[وضعيت پرسنلي] [nvarchar](255) NULL,
	[شماره بيمه] [nvarchar](255) NULL,
	[جنسيت] [nvarchar](255) NULL,
	[وضعيت اشتغال] [nvarchar](255) NULL,
	[محل خدمت] [nvarchar](255) NULL,
	[مليت] [nvarchar](255) NULL,
	[مقطع تحصيلي] [nvarchar](255) NULL,
	[وضعيت نظام‌وظيفه] [nvarchar](255) NULL,
	[وضعيت تاهل] [nvarchar](255) NULL,
	[نوع استخدام] [nvarchar](255) NULL,
	[دين] [nvarchar](255) NULL,
	[استان صدور شناسنامه] [nvarchar](255) NULL,
	[شهر محل صدور شناسنامه] [nvarchar](255) NULL,
	[رشته تحصيلي] [nvarchar](255) NULL,
	[Unit] [nvarchar](255) NULL,
	[Role] [nvarchar](255) NULL,
	[Departmant] [nvarchar](255) NULL,
	[قسمت كاري] [float] NULL,
	[پست رسمي] [float] NULL,
	[دپارتمان رسمي] [float] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Temp_PersonelActive_140110]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Temp_PersonelActive_140110](
	[Id] [float] NULL,
	[PersonnelCode] [nvarchar](255) NULL,
	[Firstname] [nvarchar](255) NULL,
	[LastName] [nvarchar](255) NULL,
	[UserName] [nvarchar](255) NULL,
	[FatherName] [nvarchar](255) NULL,
	[IdentificationId] [nvarchar](255) NULL,
	[IdentificationSerialNo] [nvarchar](255) NULL,
	[IdentificationPlace] [nvarchar](255) NULL,
	[IdentificationDate] [nvarchar](255) NULL,
	[BirthDate] [nvarchar](255) NULL,
	[BirthCity] [nvarchar](255) NULL,
	[NationalCode] [nvarchar](255) NULL,
	[ChildrenCount] [nvarchar](255) NULL,
	[Address] [nvarchar](255) NULL,
	[PhoneHome] [nvarchar](255) NULL,
	[PhoneEmergency] [nvarchar](255) NULL,
	[MobilePhone] [nvarchar](255) NULL,
	[PostalCode] [nvarchar](255) NULL,
	[Email] [nvarchar](255) NULL,
	[ContractDate] [nvarchar](255) NULL,
	[StartServiceDate] [nvarchar](255) NULL,
	[EndServiceDate] [nvarchar](255) NULL,
	[University] [nvarchar](255) NULL,
	[UniversityType] [nvarchar](255) NULL,
	[AveragePoint] [nvarchar](255) NULL,
	[InsuranceNumber] [nvarchar](255) NULL,
	[Gender] [nvarchar](255) NULL,
	[EmployeeStatus] [nvarchar](255) NULL,
	[EmploymentUnit] [nvarchar](255) NULL,
	[Naionality] [nvarchar](255) NULL,
	[Degree] [nvarchar](255) NULL,
	[militaryService] [nvarchar](255) NULL,
	[MarriageStatus] [nvarchar](255) NULL,
	[EmploymentType] [nvarchar](255) NULL,
	[Religion] [nvarchar](255) NULL,
	[IdentificationProvince] [nvarchar](255) NULL,
	[IdentificationCity] [nvarchar](255) NULL,
	[Tendency] [nvarchar](255) NULL,
	[Department] [nvarchar](255) NULL,
	[OrganizationRole] [nvarchar](255) NULL,
	[OrganizationDepartment] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_Sheet1$]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_Sheet1$](
	[F1] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_Users]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_Users](
	[UserName] [varchar](100) NOT NULL,
	[Username2]  AS (left([Username],charindex('@',[UserName])-(1))),
	[FirstName] [nvarchar](200) NOT NULL,
	[LastName] [nvarchar](200) NOT NULL,
	[FatherName] [nvarchar](200) NULL,
	[FirstNameEnglish] [nvarchar](80) NULL,
	[LastNameEnglish] [nvarchar](100) NULL,
	[ContractDate] [date] NULL,
	[ContractEndDate] [date] NULL,
	[ContractType_id] [bigint] NULL,
	[About] [nvarchar](1000) NULL,
	[CVFile] [nvarchar](100) NULL,
	[Gender] [bit] NOT NULL,
	[NationalCode] [nvarchar](10) NULL,
	[NumberOfChildren] [smallint] NULL,
	[DegreeType_id] [bigint] NULL,
	[MilitaryStatus_id] [bigint] NULL,
	[Religion_id] [bigint] NULL,
	[LivingAddress_id] [bigint] NULL,
	[BirthDate] [date] NULL,
	[BirthCity_id] [bigint] NULL,
	[IdentityNumber] [nvarchar](10) NULL,
	[IdentitySerialNumber] [nvarchar](20) NULL,
	[IdentityCity_id] [bigint] NULL,
	[IdentityRegisterDate] [date] NULL,
	[InsuranceNumber] [nvarchar](20) NULL,
	[IsActive] [bit] NOT NULL,
	[UserStatus_id] [bigint] NULL,
	[MarriageStatus_id] [bigint] NULL,
	[LastBuilding_id] [bigint] NULL,
	[LastFloor_id] [bigint] NULL,
 CONSTRAINT [PK__Users__C9F284573283E9761] PRIMARY KEY CLUSTERED 
(
	[UserName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[unk]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[unk](
	[Display Name] [nvarchar](255) NULL,
	[User Extension] [float] NULL,
	[F3] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Users14001018]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Users14001018](
	[UserName] [nvarchar](100) NOT NULL,
	[FirstName] [nvarchar](200) NOT NULL,
	[LastName] [nvarchar](200) NOT NULL,
	[BirthDate] [date] NULL,
	[ContractDate] [date] NULL,
	[DegreeType] [int] NULL,
	[FieldOfStudy] [nvarchar](300) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[users14001112]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[users14001112](
	[UserName] [nvarchar](100) NOT NULL,
	[Gender] [bit] NOT NULL,
	[NationalCode] [nvarchar](10) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[V_Payment]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[V_Payment](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[YearNumber] [int] NOT NULL,
	[Payment] [bigint] NULL,
	[InsuranceAmount] [bigint] NULL,
	[OtherPayment] [bigint] NULL,
	[PaymentCost] [bigint] NULL,
	[MonthNumber] [int] NOT NULL,
	[PersonnelCode] [nvarchar](10) NOT NULL,
	[BasePayment] [bigint] NULL,
	[Username] [nvarchar](100) NULL,
	[OverTime] [int] NULL,
	[OverTimePayment] [bigint] NULL,
	[Reward] [bigint] NULL,
	[TotalPayment] [bigint] NULL,
	[DataType] [smallint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Users] ADD  CONSTRAINT [DF_Users_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[UserTeamRole] ADD  CONSTRAINT [DF_UserTeamRole_Superior]  DEFAULT ((0)) FOR [Superior]
GO
ALTER TABLE [dbo].[AccessControl_app]  WITH CHECK ADD  CONSTRAINT [AccessControl_app_SystemCode_id_25228652_fk_AccessControl_system_Code] FOREIGN KEY([SystemCode_id])
REFERENCES [dbo].[AccessControl_system] ([Code])
GO
ALTER TABLE [dbo].[AccessControl_app] CHECK CONSTRAINT [AccessControl_app_SystemCode_id_25228652_fk_AccessControl_system_Code]
GO
ALTER TABLE [dbo].[AccessControl_apppermissiontype]  WITH CHECK ADD  CONSTRAINT [AccessControl_apppermissiontype_AppCode_3e7a087d_fk_AccessControl_app_Code] FOREIGN KEY([AppCode])
REFERENCES [dbo].[AccessControl_app] ([Code])
GO
ALTER TABLE [dbo].[AccessControl_apppermissiontype] CHECK CONSTRAINT [AccessControl_apppermissiontype_AppCode_3e7a087d_fk_AccessControl_app_Code]
GO
ALTER TABLE [dbo].[AccessControl_appurl]  WITH CHECK ADD  CONSTRAINT [AccessControl_appurl_AppCode_a2d5aed8_fk_AccessControl_app_Code] FOREIGN KEY([AppCode])
REFERENCES [dbo].[AccessControl_app] ([Code])
GO
ALTER TABLE [dbo].[AccessControl_appurl] CHECK CONSTRAINT [AccessControl_appurl_AppCode_a2d5aed8_fk_AccessControl_app_Code]
GO
ALTER TABLE [dbo].[AccessControl_groupuser]  WITH CHECK ADD  CONSTRAINT [AccessControl_groupuser_Group_id_0182a559_fk_AccessControl_permissiongroup_id] FOREIGN KEY([Group_id])
REFERENCES [dbo].[AccessControl_permissiongroup] ([id])
GO
ALTER TABLE [dbo].[AccessControl_groupuser] CHECK CONSTRAINT [AccessControl_groupuser_Group_id_0182a559_fk_AccessControl_permissiongroup_id]
GO
ALTER TABLE [dbo].[AccessControl_permission]  WITH CHECK ADD  CONSTRAINT [AccessControl_permission_AppCode_id_f74436a6_fk_AccessControl_app_Code] FOREIGN KEY([AppCode_id])
REFERENCES [dbo].[AccessControl_app] ([Code])
GO
ALTER TABLE [dbo].[AccessControl_permission] CHECK CONSTRAINT [AccessControl_permission_AppCode_id_f74436a6_fk_AccessControl_app_Code]
GO
ALTER TABLE [dbo].[AccessControl_userrolegrouppermission]  WITH CHECK ADD  CONSTRAINT [AccessControl_userrolegrouppermission_OwnerPermissionGroup_bf11751a_fk_AccessControl_permissiongroup_id] FOREIGN KEY([OwnerPermissionGroup])
REFERENCES [dbo].[AccessControl_permissiongroup] ([id])
GO
ALTER TABLE [dbo].[AccessControl_userrolegrouppermission] CHECK CONSTRAINT [AccessControl_userrolegrouppermission_OwnerPermissionGroup_bf11751a_fk_AccessControl_permissiongroup_id]
GO
ALTER TABLE [dbo].[AccessControl_userrolegrouppermission]  WITH CHECK ADD  CONSTRAINT [AccessControl_userrolegrouppermission_PermissionCode_f942b504_fk_AccessControl_permission_Code] FOREIGN KEY([PermissionCode])
REFERENCES [dbo].[AccessControl_permission] ([Code])
GO
ALTER TABLE [dbo].[AccessControl_userrolegrouppermission] CHECK CONSTRAINT [AccessControl_userrolegrouppermission_PermissionCode_f942b504_fk_AccessControl_permission_Code]
GO
ALTER TABLE [dbo].[auth_group_permissions]  WITH CHECK ADD  CONSTRAINT [auth_group_permissions_group_id_b120cbf9_fk_auth_group_id] FOREIGN KEY([group_id])
REFERENCES [dbo].[auth_group] ([id])
GO
ALTER TABLE [dbo].[auth_group_permissions] CHECK CONSTRAINT [auth_group_permissions_group_id_b120cbf9_fk_auth_group_id]
GO
ALTER TABLE [dbo].[auth_group_permissions]  WITH CHECK ADD  CONSTRAINT [auth_group_permissions_permission_id_84c5c92e_fk_auth_permission_id] FOREIGN KEY([permission_id])
REFERENCES [dbo].[auth_permission] ([id])
GO
ALTER TABLE [dbo].[auth_group_permissions] CHECK CONSTRAINT [auth_group_permissions_permission_id_84c5c92e_fk_auth_permission_id]
GO
ALTER TABLE [dbo].[auth_permission]  WITH CHECK ADD  CONSTRAINT [auth_permission_content_type_id_2f476e4b_fk_django_content_type_id] FOREIGN KEY([content_type_id])
REFERENCES [dbo].[django_content_type] ([id])
GO
ALTER TABLE [dbo].[auth_permission] CHECK CONSTRAINT [auth_permission_content_type_id_2f476e4b_fk_django_content_type_id]
GO
ALTER TABLE [dbo].[auth2_user_groups]  WITH CHECK ADD  CONSTRAINT [auth2_user_groups_group_id_a43621b8_fk_auth_group_id] FOREIGN KEY([group_id])
REFERENCES [dbo].[auth_group] ([id])
GO
ALTER TABLE [dbo].[auth2_user_groups] CHECK CONSTRAINT [auth2_user_groups_group_id_a43621b8_fk_auth_group_id]
GO
ALTER TABLE [dbo].[auth2_user_groups]  WITH CHECK ADD  CONSTRAINT [auth2_user_groups_user_id_8fa5d9cf_fk_auth2_user_national_code] FOREIGN KEY([user_id])
REFERENCES [dbo].[auth2_user] ([national_code])
GO
ALTER TABLE [dbo].[auth2_user_groups] CHECK CONSTRAINT [auth2_user_groups_user_id_8fa5d9cf_fk_auth2_user_national_code]
GO
ALTER TABLE [dbo].[auth2_user_user_permissions]  WITH CHECK ADD  CONSTRAINT [auth2_user_user_permissions_permission_id_2b84c211_fk_auth_permission_id] FOREIGN KEY([permission_id])
REFERENCES [dbo].[auth_permission] ([id])
GO
ALTER TABLE [dbo].[auth2_user_user_permissions] CHECK CONSTRAINT [auth2_user_user_permissions_permission_id_2b84c211_fk_auth_permission_id]
GO
ALTER TABLE [dbo].[auth2_user_user_permissions]  WITH CHECK ADD  CONSTRAINT [auth2_user_user_permissions_user_id_7f8829ab_fk_auth2_user_national_code] FOREIGN KEY([user_id])
REFERENCES [dbo].[auth2_user] ([national_code])
GO
ALTER TABLE [dbo].[auth2_user_user_permissions] CHECK CONSTRAINT [auth2_user_user_permissions_user_id_7f8829ab_fk_auth2_user_national_code]
GO
ALTER TABLE [dbo].[Cartable_documenrflow]  WITH CHECK ADD  CONSTRAINT [Cartable_documenrflow_DocumentId_id_a5e8795b_fk_Cartable_document_id] FOREIGN KEY([DocumentId_id])
REFERENCES [dbo].[Cartable_document] ([id])
GO
ALTER TABLE [dbo].[Cartable_documenrflow] CHECK CONSTRAINT [Cartable_documenrflow_DocumentId_id_a5e8795b_fk_Cartable_document_id]
GO
ALTER TABLE [dbo].[Cartable_documenrflow]  WITH CHECK ADD  CONSTRAINT [Cartable_documenrflow_PreviousFlow_id_971a006d_fk_Cartable_documenrflow_id] FOREIGN KEY([PreviousFlow_id])
REFERENCES [dbo].[Cartable_documenrflow] ([id])
GO
ALTER TABLE [dbo].[Cartable_documenrflow] CHECK CONSTRAINT [Cartable_documenrflow_PreviousFlow_id_971a006d_fk_Cartable_documenrflow_id]
GO
ALTER TABLE [dbo].[django_admin_log]  WITH CHECK ADD  CONSTRAINT [django_admin_log_content_type_id_c4bce8eb_fk_django_content_type_id] FOREIGN KEY([content_type_id])
REFERENCES [dbo].[django_content_type] ([id])
GO
ALTER TABLE [dbo].[django_admin_log] CHECK CONSTRAINT [django_admin_log_content_type_id_c4bce8eb_fk_django_content_type_id]
GO
ALTER TABLE [dbo].[django_admin_log]  WITH CHECK ADD  CONSTRAINT [django_admin_log_user_id_c564eba6_fk_auth2_user_national_code] FOREIGN KEY([user_id])
REFERENCES [dbo].[auth2_user] ([national_code])
GO
ALTER TABLE [dbo].[django_admin_log] CHECK CONSTRAINT [django_admin_log_user_id_c564eba6_fk_auth2_user_national_code]
GO
ALTER TABLE [dbo].[Duties_roledescription]  WITH CHECK ADD  CONSTRAINT [Duties_roledescription_Category_id_7e1d41eb_fk_Duties_rolecategory_id] FOREIGN KEY([Category_id])
REFERENCES [dbo].[Duties_rolecategory] ([id])
GO
ALTER TABLE [dbo].[Duties_roledescription] CHECK CONSTRAINT [Duties_roledescription_Category_id_7e1d41eb_fk_Duties_rolecategory_id]
GO
ALTER TABLE [dbo].[Duties_roledescription]  WITH CHECK ADD  CONSTRAINT [Duties_roledescription_LevelId_73b06b9f_fk_RoleLevel_id] FOREIGN KEY([LevelId])
REFERENCES [dbo].[RoleLevel] ([id])
GO
ALTER TABLE [dbo].[Duties_roledescription] CHECK CONSTRAINT [Duties_roledescription_LevelId_73b06b9f_fk_RoleLevel_id]
GO
ALTER TABLE [dbo].[Duties_roledescription]  WITH CHECK ADD  CONSTRAINT [Duties_roledescription_RoleId_2df2b41c_fk_Role_RoleId] FOREIGN KEY([RoleId])
REFERENCES [dbo].[Role] ([RoleId])
GO
ALTER TABLE [dbo].[Duties_roledescription] CHECK CONSTRAINT [Duties_roledescription_RoleId_2df2b41c_fk_Role_RoleId]
GO
ALTER TABLE [dbo].[HR_accesspersonnel]  WITH CHECK ADD  CONSTRAINT [HR_accesspersonnel_UserName_id_1bff9828_fk_Users_UserName] FOREIGN KEY([UserName_id])
REFERENCES [dbo].[Users] ([UserName])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[HR_accesspersonnel] CHECK CONSTRAINT [HR_accesspersonnel_UserName_id_1bff9828_fk_Users_UserName]
GO
ALTER TABLE [dbo].[HR_changerole]  WITH CHECK ADD  CONSTRAINT [HR_changerole_LevelId_id_7db76733_fk_RoleLevel_id] FOREIGN KEY([LevelId_id])
REFERENCES [dbo].[RoleLevel] ([id])
GO
ALTER TABLE [dbo].[HR_changerole] CHECK CONSTRAINT [HR_changerole_LevelId_id_7db76733_fk_RoleLevel_id]
GO
ALTER TABLE [dbo].[HR_changerole]  WITH CHECK ADD  CONSTRAINT [HR_changerole_LevelIdTarget_id_54617ebe_fk_RoleLevel_id] FOREIGN KEY([LevelIdTarget_id])
REFERENCES [dbo].[RoleLevel] ([id])
GO
ALTER TABLE [dbo].[HR_changerole] CHECK CONSTRAINT [HR_changerole_LevelIdTarget_id_54617ebe_fk_RoleLevel_id]
GO
ALTER TABLE [dbo].[HR_changerole]  WITH CHECK ADD  CONSTRAINT [HR_changerole_RoleID_id_0d6a28fd_fk_Role_RoleId] FOREIGN KEY([RoleID_id])
REFERENCES [dbo].[Role] ([RoleId])
GO
ALTER TABLE [dbo].[HR_changerole] CHECK CONSTRAINT [HR_changerole_RoleID_id_0d6a28fd_fk_Role_RoleId]
GO
ALTER TABLE [dbo].[HR_changerole]  WITH CHECK ADD  CONSTRAINT [HR_changerole_RoleIdTarget_id_3812bf86_fk_Role_RoleId] FOREIGN KEY([RoleIdTarget_id])
REFERENCES [dbo].[Role] ([RoleId])
GO
ALTER TABLE [dbo].[HR_changerole] CHECK CONSTRAINT [HR_changerole_RoleIdTarget_id_3812bf86_fk_Role_RoleId]
GO
ALTER TABLE [dbo].[HR_city]  WITH CHECK ADD  CONSTRAINT [HR_city_Province_id_8ecdb560_fk_HR_province_id] FOREIGN KEY([Province_id])
REFERENCES [dbo].[HR_province] ([id])
GO
ALTER TABLE [dbo].[HR_city] CHECK CONSTRAINT [HR_city_Province_id_8ecdb560_fk_HR_province_id]
GO
ALTER TABLE [dbo].[HR_citydistrict]  WITH CHECK ADD  CONSTRAINT [HR_citydistrict_City_id_d63ab1b9_fk_HR_city_id] FOREIGN KEY([City_id])
REFERENCES [dbo].[HR_city] ([id])
GO
ALTER TABLE [dbo].[HR_citydistrict] CHECK CONSTRAINT [HR_citydistrict_City_id_d63ab1b9_fk_HR_city_id]
GO
ALTER TABLE [dbo].[HR_constvalue]  WITH CHECK ADD  CONSTRAINT [HR_constvalue_Parent_id_3481734d_fk_HR_constvalue_id] FOREIGN KEY([Parent_id])
REFERENCES [dbo].[HR_constvalue] ([id])
GO
ALTER TABLE [dbo].[HR_constvalue] CHECK CONSTRAINT [HR_constvalue_Parent_id_3481734d_fk_HR_constvalue_id]
GO
ALTER TABLE [dbo].[HR_educationhistory]  WITH CHECK ADD  CONSTRAINT [HR_educationhistory_Degree_Type_id_c0ba23a6_fk_HR_constvalue_id] FOREIGN KEY([Degree_Type_id])
REFERENCES [dbo].[HR_constvalue] ([id])
GO
ALTER TABLE [dbo].[HR_educationhistory] CHECK CONSTRAINT [HR_educationhistory_Degree_Type_id_c0ba23a6_fk_HR_constvalue_id]
GO
ALTER TABLE [dbo].[HR_educationhistory]  WITH CHECK ADD  CONSTRAINT [HR_educationhistory_EducationTendency_id_00542002_fk_HR_tendency_id] FOREIGN KEY([EducationTendency_id])
REFERENCES [dbo].[HR_tendency] ([id])
GO
ALTER TABLE [dbo].[HR_educationhistory] CHECK CONSTRAINT [HR_educationhistory_EducationTendency_id_00542002_fk_HR_tendency_id]
GO
ALTER TABLE [dbo].[HR_educationhistory]  WITH CHECK ADD  CONSTRAINT [HR_educationhistory_Person_id_a3dce35d_fk_Users_UserName] FOREIGN KEY([Person_id])
REFERENCES [dbo].[Users] ([UserName])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[HR_educationhistory] CHECK CONSTRAINT [HR_educationhistory_Person_id_a3dce35d_fk_Users_UserName]
GO
ALTER TABLE [dbo].[HR_educationhistory]  WITH CHECK ADD  CONSTRAINT [HR_educationhistory_University_id_193d2294_fk_HR_university_id] FOREIGN KEY([University_id])
REFERENCES [dbo].[HR_university] ([id])
GO
ALTER TABLE [dbo].[HR_educationhistory] CHECK CONSTRAINT [HR_educationhistory_University_id_193d2294_fk_HR_university_id]
GO
ALTER TABLE [dbo].[HR_emailaddress]  WITH CHECK ADD  CONSTRAINT [HR_emailaddress_Person_id_2484204f_fk_Users_UserName] FOREIGN KEY([Person_id])
REFERENCES [dbo].[Users] ([UserName])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[HR_emailaddress] CHECK CONSTRAINT [HR_emailaddress_Person_id_2484204f_fk_Users_UserName]
GO
ALTER TABLE [dbo].[HR_newrolerequest]  WITH CHECK ADD  CONSTRAINT [HR_newrolerequest_ManagerType_id_23d95480_fk_HR_constvalue_id] FOREIGN KEY([ManagerType_id])
REFERENCES [dbo].[HR_constvalue] ([id])
GO
ALTER TABLE [dbo].[HR_newrolerequest] CHECK CONSTRAINT [HR_newrolerequest_ManagerType_id_23d95480_fk_HR_constvalue_id]
GO
ALTER TABLE [dbo].[HR_newrolerequest]  WITH CHECK ADD  CONSTRAINT [HR_newrolerequest_RoleType_id_b6e37fa4_fk_HR_constvalue_id] FOREIGN KEY([RoleType_id])
REFERENCES [dbo].[HR_constvalue] ([id])
GO
ALTER TABLE [dbo].[HR_newrolerequest] CHECK CONSTRAINT [HR_newrolerequest_RoleType_id_b6e37fa4_fk_HR_constvalue_id]
GO
ALTER TABLE [dbo].[HR_organizationchartrole]  WITH CHECK ADD  CONSTRAINT [HR_organizationchartrole_LevelId_id_5dbbd3fd_fk_RoleLevel_id] FOREIGN KEY([LevelId_id])
REFERENCES [dbo].[RoleLevel] ([id])
GO
ALTER TABLE [dbo].[HR_organizationchartrole] CHECK CONSTRAINT [HR_organizationchartrole_LevelId_id_5dbbd3fd_fk_RoleLevel_id]
GO
ALTER TABLE [dbo].[HR_organizationchartrole]  WITH CHECK ADD  CONSTRAINT [HR_organizationchartrole_RoleId_id_425aec8a_fk_Role_RoleId] FOREIGN KEY([RoleId_id])
REFERENCES [dbo].[Role] ([RoleId])
GO
ALTER TABLE [dbo].[HR_organizationchartrole] CHECK CONSTRAINT [HR_organizationchartrole_RoleId_id_425aec8a_fk_Role_RoleId]
GO
ALTER TABLE [dbo].[HR_organizationchartteamrole]  WITH CHECK ADD  CONSTRAINT [HR_organizationchartteamrole_ManagerUserName_id_252a397c_fk_Users_UserName] FOREIGN KEY([ManagerUserName_id])
REFERENCES [dbo].[Users] ([UserName])
GO
ALTER TABLE [dbo].[HR_organizationchartteamrole] CHECK CONSTRAINT [HR_organizationchartteamrole_ManagerUserName_id_252a397c_fk_Users_UserName]
GO
ALTER TABLE [dbo].[HR_organizationchartteamrole]  WITH CHECK ADD  CONSTRAINT [HR_organizationchartteamrole_OrganizationChartRole_id_8861ce23_fk_HR_organizationchartrole_id] FOREIGN KEY([OrganizationChartRole_id])
REFERENCES [dbo].[HR_organizationchartrole] ([id])
GO
ALTER TABLE [dbo].[HR_organizationchartteamrole] CHECK CONSTRAINT [HR_organizationchartteamrole_OrganizationChartRole_id_8861ce23_fk_HR_organizationchartrole_id]
GO
ALTER TABLE [dbo].[HR_organizationchartteamrole]  WITH CHECK ADD  CONSTRAINT [HR_organizationchartteamrole_TeamCode_id_39e6f907_fk_Team_TeamCode] FOREIGN KEY([TeamCode_id])
REFERENCES [dbo].[Team] ([TeamCode])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[HR_organizationchartteamrole] CHECK CONSTRAINT [HR_organizationchartteamrole_TeamCode_id_39e6f907_fk_Team_TeamCode]
GO
ALTER TABLE [dbo].[HR_pagepermission]  WITH CHECK ADD  CONSTRAINT [HR_pagepermission_Page_id_cedb02f6_fk_HR_pageinformation_id] FOREIGN KEY([Page_id])
REFERENCES [dbo].[HR_pageinformation] ([id])
GO
ALTER TABLE [dbo].[HR_pagepermission] CHECK CONSTRAINT [HR_pagepermission_Page_id_cedb02f6_fk_HR_pageinformation_id]
GO
ALTER TABLE [dbo].[HR_phonenumber]  WITH CHECK ADD  CONSTRAINT [HR_phonenumber_Person_id_a3a9b36b_fk_Users_UserName] FOREIGN KEY([Person_id])
REFERENCES [dbo].[Users] ([UserName])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[HR_phonenumber] CHECK CONSTRAINT [HR_phonenumber_Person_id_a3a9b36b_fk_Users_UserName]
GO
ALTER TABLE [dbo].[HR_phonenumber]  WITH CHECK ADD  CONSTRAINT [HR_phonenumber_Province_id_2688f9ef_fk_HR_province_id] FOREIGN KEY([Province_id])
REFERENCES [dbo].[HR_province] ([id])
GO
ALTER TABLE [dbo].[HR_phonenumber] CHECK CONSTRAINT [HR_phonenumber_Province_id_2688f9ef_fk_HR_province_id]
GO
ALTER TABLE [dbo].[HR_phonenumber]  WITH CHECK ADD  CONSTRAINT [HR_phonenumber_TelType_id_0ac81254_fk_HR_constvalue_id] FOREIGN KEY([TelType_id])
REFERENCES [dbo].[HR_constvalue] ([id])
GO
ALTER TABLE [dbo].[HR_phonenumber] CHECK CONSTRAINT [HR_phonenumber_TelType_id_0ac81254_fk_HR_constvalue_id]
GO
ALTER TABLE [dbo].[HR_postaladdress]  WITH CHECK ADD  CONSTRAINT [HR_postaladdress_City_id_0ea67edb_fk_HR_city_id] FOREIGN KEY([City_id])
REFERENCES [dbo].[HR_city] ([id])
GO
ALTER TABLE [dbo].[HR_postaladdress] CHECK CONSTRAINT [HR_postaladdress_City_id_0ea67edb_fk_HR_city_id]
GO
ALTER TABLE [dbo].[HR_postaladdress]  WITH CHECK ADD  CONSTRAINT [HR_postaladdress_CityDistrict_id_82d5f6d8_fk_HR_citydistrict_id] FOREIGN KEY([CityDistrict_id])
REFERENCES [dbo].[HR_citydistrict] ([id])
GO
ALTER TABLE [dbo].[HR_postaladdress] CHECK CONSTRAINT [HR_postaladdress_CityDistrict_id_82d5f6d8_fk_HR_citydistrict_id]
GO
ALTER TABLE [dbo].[HR_postaladdress]  WITH CHECK ADD  CONSTRAINT [HR_postaladdress_Person_id_4ecd4347_fk_Users_UserName] FOREIGN KEY([Person_id])
REFERENCES [dbo].[Users] ([UserName])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[HR_postaladdress] CHECK CONSTRAINT [HR_postaladdress_Person_id_4ecd4347_fk_Users_UserName]
GO
ALTER TABLE [dbo].[HR_rolegroup]  WITH CHECK ADD  CONSTRAINT [HR_rolegroup_RoleID_id_2fe4a202_fk_Role_RoleId] FOREIGN KEY([RoleID_id])
REFERENCES [dbo].[Role] ([RoleId])
GO
ALTER TABLE [dbo].[HR_rolegroup] CHECK CONSTRAINT [HR_rolegroup_RoleID_id_2fe4a202_fk_Role_RoleId]
GO
ALTER TABLE [dbo].[HR_roleinformation]  WITH CHECK ADD  CONSTRAINT [HR_roleinformation_RoleID_88d1f63d_fk_Role_RoleId] FOREIGN KEY([RoleID])
REFERENCES [dbo].[Role] ([RoleId])
GO
ALTER TABLE [dbo].[HR_roleinformation] CHECK CONSTRAINT [HR_roleinformation_RoleID_88d1f63d_fk_Role_RoleId]
GO
ALTER TABLE [dbo].[HR_teamallowedroles]  WITH CHECK ADD  CONSTRAINT [HR_teamallowedroles_RoleId_e7bad001_fk_Role_RoleId] FOREIGN KEY([RoleId])
REFERENCES [dbo].[Role] ([RoleId])
GO
ALTER TABLE [dbo].[HR_teamallowedroles] CHECK CONSTRAINT [HR_teamallowedroles_RoleId_e7bad001_fk_Role_RoleId]
GO
ALTER TABLE [dbo].[HR_teamallowedroles]  WITH CHECK ADD  CONSTRAINT [HR_teamallowedroles_SetTeamAllowedRoleRequest_id_a1dffdbc_fk_HR_setteamallowedrolerequest_id] FOREIGN KEY([SetTeamAllowedRoleRequest_id])
REFERENCES [dbo].[HR_setteamallowedrolerequest] ([id])
GO
ALTER TABLE [dbo].[HR_teamallowedroles] CHECK CONSTRAINT [HR_teamallowedroles_SetTeamAllowedRoleRequest_id_a1dffdbc_fk_HR_setteamallowedrolerequest_id]
GO
ALTER TABLE [dbo].[HR_teamallowedroles]  WITH CHECK ADD  CONSTRAINT [HR_teamallowedroles_TeamCode_2802f188_fk_Team_TeamCode] FOREIGN KEY([TeamCode])
REFERENCES [dbo].[Team] ([TeamCode])
GO
ALTER TABLE [dbo].[HR_teamallowedroles] CHECK CONSTRAINT [HR_teamallowedroles_TeamCode_2802f188_fk_Team_TeamCode]
GO
ALTER TABLE [dbo].[HR_tendency]  WITH CHECK ADD  CONSTRAINT [HR_tendency_FieldOfStudy_id_d21ce95c_fk_HR_fieldofstudy_id] FOREIGN KEY([FieldOfStudy_id])
REFERENCES [dbo].[HR_fieldofstudy] ([id])
GO
ALTER TABLE [dbo].[HR_tendency] CHECK CONSTRAINT [HR_tendency_FieldOfStudy_id_d21ce95c_fk_HR_fieldofstudy_id]
GO
ALTER TABLE [dbo].[HR_university]  WITH CHECK ADD  CONSTRAINT [HR_university_University_Type_id_27f4cae0_fk_HR_constvalue_id] FOREIGN KEY([University_Type_id])
REFERENCES [dbo].[HR_constvalue] ([id])
GO
ALTER TABLE [dbo].[HR_university] CHECK CONSTRAINT [HR_university_University_Type_id_27f4cae0_fk_HR_constvalue_id]
GO
ALTER TABLE [dbo].[HR_university]  WITH CHECK ADD  CONSTRAINT [HR_university_UniversityCity_id_318243fa_fk_HR_city_id] FOREIGN KEY([UniversityCity_id])
REFERENCES [dbo].[HR_city] ([id])
GO
ALTER TABLE [dbo].[HR_university] CHECK CONSTRAINT [HR_university_UniversityCity_id_318243fa_fk_HR_city_id]
GO
ALTER TABLE [dbo].[PreviousUserTeamRole]  WITH CHECK ADD  CONSTRAINT [FK_PreviousUserTeamRole_Role] FOREIGN KEY([RoleId])
REFERENCES [dbo].[Role] ([RoleId])
GO
ALTER TABLE [dbo].[PreviousUserTeamRole] CHECK CONSTRAINT [FK_PreviousUserTeamRole_Role]
GO
ALTER TABLE [dbo].[PreviousUserTeamRole]  WITH CHECK ADD  CONSTRAINT [PreviousUserTeamRole_LevelId_id_4a0d9944_fk_RoleLevel_id] FOREIGN KEY([LevelId_id])
REFERENCES [dbo].[RoleLevel] ([id])
GO
ALTER TABLE [dbo].[PreviousUserTeamRole] CHECK CONSTRAINT [PreviousUserTeamRole_LevelId_id_4a0d9944_fk_RoleLevel_id]
GO
ALTER TABLE [dbo].[PreviousUserTeamRole]  WITH CHECK ADD  CONSTRAINT [PreviousUserTeamRole_ManagerUserName_id_f74aa6b7_fk_Users_UserName] FOREIGN KEY([ManagerUserName_id])
REFERENCES [dbo].[Users] ([UserName])
GO
ALTER TABLE [dbo].[PreviousUserTeamRole] CHECK CONSTRAINT [PreviousUserTeamRole_ManagerUserName_id_f74aa6b7_fk_Users_UserName]
GO
ALTER TABLE [dbo].[PreviousUserTeamRole]  WITH CHECK ADD  CONSTRAINT [PreviousUserTeamRole_TeamCode_50cd94b3_fk_Team_TeamCode] FOREIGN KEY([TeamCode])
REFERENCES [dbo].[Team] ([TeamCode])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[PreviousUserTeamRole] CHECK CONSTRAINT [PreviousUserTeamRole_TeamCode_50cd94b3_fk_Team_TeamCode]
GO
ALTER TABLE [dbo].[PreviousUserTeamRole]  WITH CHECK ADD  CONSTRAINT [PreviousUserTeamRole_UserName_87cf10a9_fk_Users_UserName] FOREIGN KEY([UserName])
REFERENCES [dbo].[Users] ([UserName])
GO
ALTER TABLE [dbo].[PreviousUserTeamRole] CHECK CONSTRAINT [PreviousUserTeamRole_UserName_87cf10a9_fk_Users_UserName]
GO
ALTER TABLE [dbo].[Role]  WITH CHECK ADD  CONSTRAINT [Role_ManagerType_id_c2cc60e2_fk_HR_constvalue_id] FOREIGN KEY([ManagerType_id])
REFERENCES [dbo].[HR_constvalue] ([id])
GO
ALTER TABLE [dbo].[Role] CHECK CONSTRAINT [Role_ManagerType_id_c2cc60e2_fk_HR_constvalue_id]
GO
ALTER TABLE [dbo].[Role]  WITH CHECK ADD  CONSTRAINT [Role_NewRoleRequest_id_8e8452d3_fk_HR_newrolerequest_id] FOREIGN KEY([NewRoleRequest_id])
REFERENCES [dbo].[HR_newrolerequest] ([id])
GO
ALTER TABLE [dbo].[Role] CHECK CONSTRAINT [Role_NewRoleRequest_id_8e8452d3_fk_HR_newrolerequest_id]
GO
ALTER TABLE [dbo].[Systems_systemcategory]  WITH CHECK ADD  CONSTRAINT [Systems_systemcategory_Parent_id_f9a683a2_fk_Systems_systemcategory_id] FOREIGN KEY([Parent_id])
REFERENCES [dbo].[Systems_systemcategory] ([id])
GO
ALTER TABLE [dbo].[Systems_systemcategory] CHECK CONSTRAINT [Systems_systemcategory_Parent_id_f9a683a2_fk_Systems_systemcategory_id]
GO
ALTER TABLE [dbo].[Team]  WITH CHECK ADD  CONSTRAINT [Team_GeneralManager_id_99b4cdca_fk_Users_UserName] FOREIGN KEY([GeneralManager_id])
REFERENCES [dbo].[Users] ([UserName])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Team] CHECK CONSTRAINT [Team_GeneralManager_id_99b4cdca_fk_Users_UserName]
GO
ALTER TABLE [dbo].[Team]  WITH CHECK ADD  CONSTRAINT [Team_SupportManager_id_8957c157_fk_Users_UserName] FOREIGN KEY([SupportManager_id])
REFERENCES [dbo].[Users] ([UserName])
GO
ALTER TABLE [dbo].[Team] CHECK CONSTRAINT [Team_SupportManager_id_8957c157_fk_Users_UserName]
GO
ALTER TABLE [dbo].[Team]  WITH CHECK ADD  CONSTRAINT [Team_TestManager_id_e9f49118_fk_Users_UserName] FOREIGN KEY([TestManager_id])
REFERENCES [dbo].[Users] ([UserName])
GO
ALTER TABLE [dbo].[Team] CHECK CONSTRAINT [Team_TestManager_id_e9f49118_fk_Users_UserName]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [Users_BirthCity_id_26c210fd_fk_HR_city_id] FOREIGN KEY([BirthCity_id])
REFERENCES [dbo].[HR_city] ([id])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [Users_BirthCity_id_26c210fd_fk_HR_city_id]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [Users_ContractType_id_34f40397_fk_HR_constvalue_id] FOREIGN KEY([ContractType_id])
REFERENCES [dbo].[HR_constvalue] ([id])
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [Users_ContractType_id_34f40397_fk_HR_constvalue_id]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [Users_DegreeType_id_0c43d927_fk_HR_constvalue_id] FOREIGN KEY([DegreeType_id])
REFERENCES [dbo].[HR_constvalue] ([id])
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [Users_DegreeType_id_0c43d927_fk_HR_constvalue_id]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [Users_IdentityCity_id_22dc2421_fk_HR_city_id] FOREIGN KEY([IdentityCity_id])
REFERENCES [dbo].[HR_city] ([id])
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [Users_IdentityCity_id_22dc2421_fk_HR_city_id]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [Users_LastBuilding_id_a48e99c7_fk_HR_constvalue_id] FOREIGN KEY([LastBuilding_id])
REFERENCES [dbo].[HR_constvalue] ([id])
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [Users_LastBuilding_id_a48e99c7_fk_HR_constvalue_id]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [Users_LastFloor_id_5d2e0314_fk_HR_constvalue_id] FOREIGN KEY([LastFloor_id])
REFERENCES [dbo].[HR_constvalue] ([id])
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [Users_LastFloor_id_5d2e0314_fk_HR_constvalue_id]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [Users_LivingAddress_id_dba9e903_fk_HR_postaladdress_id] FOREIGN KEY([LivingAddress_id])
REFERENCES [dbo].[HR_postaladdress] ([id])
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [Users_LivingAddress_id_dba9e903_fk_HR_postaladdress_id]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [Users_MarriageStatus_id_c3d74f41_fk_HR_constvalue_id] FOREIGN KEY([MarriageStatus_id])
REFERENCES [dbo].[HR_constvalue] ([id])
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [Users_MarriageStatus_id_c3d74f41_fk_HR_constvalue_id]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [Users_MilitaryStatus_id_ad865930_fk_HR_constvalue_id] FOREIGN KEY([MilitaryStatus_id])
REFERENCES [dbo].[HR_constvalue] ([id])
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [Users_MilitaryStatus_id_ad865930_fk_HR_constvalue_id]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [Users_Religion_id_c7da50c5_fk_HR_constvalue_id] FOREIGN KEY([Religion_id])
REFERENCES [dbo].[HR_constvalue] ([id])
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [Users_Religion_id_c7da50c5_fk_HR_constvalue_id]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [Users_UserStatus_id_5de8dbba_fk_HR_constvalue_id] FOREIGN KEY([UserStatus_id])
REFERENCES [dbo].[HR_constvalue] ([id])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [Users_UserStatus_id_5de8dbba_fk_HR_constvalue_id]
GO
ALTER TABLE [dbo].[UserTeamRole]  WITH CHECK ADD  CONSTRAINT [FK_UserTeamRole_Role] FOREIGN KEY([RoleId])
REFERENCES [dbo].[Role] ([RoleId])
GO
ALTER TABLE [dbo].[UserTeamRole] CHECK CONSTRAINT [FK_UserTeamRole_Role]
GO
ALTER TABLE [dbo].[UserTeamRole]  WITH CHECK ADD  CONSTRAINT [FK_UserTeamRole_RoleLevel] FOREIGN KEY([LevelId_id])
REFERENCES [dbo].[RoleLevel] ([id])
GO
ALTER TABLE [dbo].[UserTeamRole] CHECK CONSTRAINT [FK_UserTeamRole_RoleLevel]
GO
ALTER TABLE [dbo].[UserTeamRole]  WITH CHECK ADD  CONSTRAINT [FK_UserTeamRole_Team] FOREIGN KEY([TeamCode])
REFERENCES [dbo].[Team] ([TeamCode])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[UserTeamRole] CHECK CONSTRAINT [FK_UserTeamRole_Team]
GO
ALTER TABLE [dbo].[auth2_user]  WITH CHECK ADD  CONSTRAINT [auth2_user_team_roles_5eed2639_check] CHECK  ((isjson([team_roles])=(1)))
GO
ALTER TABLE [dbo].[auth2_user] CHECK CONSTRAINT [auth2_user_team_roles_5eed2639_check]
GO
ALTER TABLE [dbo].[django_admin_log]  WITH CHECK ADD  CONSTRAINT [django_admin_log_action_flag_a8637d59_check] CHECK  (([action_flag]>=(0)))
GO
ALTER TABLE [dbo].[django_admin_log] CHECK CONSTRAINT [django_admin_log_action_flag_a8637d59_check]
GO
ALTER TABLE [dbo].[HR_constvalue]  WITH CHECK ADD  CONSTRAINT [HR_constvalue_OrderNumber_6bab28cf_check] CHECK  (([OrderNumber]>=(0)))
GO
ALTER TABLE [dbo].[HR_constvalue] CHECK CONSTRAINT [HR_constvalue_OrderNumber_6bab28cf_check]
GO
ALTER TABLE [dbo].[HR_educationhistory]  WITH CHECK ADD  CONSTRAINT [HR_educationhistory_EndYear_f54c9d2f_check] CHECK  (([EndYear]>=(0)))
GO
ALTER TABLE [dbo].[HR_educationhistory] CHECK CONSTRAINT [HR_educationhistory_EndYear_f54c9d2f_check]
GO
ALTER TABLE [dbo].[HR_educationhistory]  WITH CHECK ADD  CONSTRAINT [HR_educationhistory_StartYear_8eaf057d_check] CHECK  (([StartYear]>=(0)))
GO
ALTER TABLE [dbo].[HR_educationhistory] CHECK CONSTRAINT [HR_educationhistory_StartYear_8eaf057d_check]
GO
ALTER TABLE [dbo].[HR_pageinformation]  WITH CHECK ADD CHECK  (([OrderNumber]>=(0)))
GO
ALTER TABLE [dbo].[HR_pagepermission]  WITH CHECK ADD  CONSTRAINT [HR_pagepermission_GroupId_55295149_check] CHECK  (([GroupId]>=(0)))
GO
ALTER TABLE [dbo].[HR_pagepermission] CHECK CONSTRAINT [HR_pagepermission_GroupId_55295149_check]
GO
ALTER TABLE [dbo].[HR_postaladdress]  WITH CHECK ADD  CONSTRAINT [HR_postaladdress_UnitNo_90b5227d_check] CHECK  (([UnitNo]>=(0)))
GO
ALTER TABLE [dbo].[HR_postaladdress] CHECK CONSTRAINT [HR_postaladdress_UnitNo_90b5227d_check]
GO
ALTER TABLE [dbo].[HR_teamallowedroles]  WITH CHECK ADD  CONSTRAINT [HR_teamallowedroles_AllowedRoleCount_868ad119_check] CHECK  (([AllowedRoleCount]>=(0)))
GO
ALTER TABLE [dbo].[HR_teamallowedroles] CHECK CONSTRAINT [HR_teamallowedroles_AllowedRoleCount_868ad119_check]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [CK__Users__NumberOfC__6166761E] CHECK  (([NumberOfChildren]>=(0)))
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [CK__Users__NumberOfC__6166761E]
GO
/****** Object:  StoredProcedure [dbo].[auth2_CrossDBSynchromization]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[auth2_CrossDBSynchromization]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	

	-- INSERT NEW ACTIVE USERS THAT NOT IN AUTH2_USERS
    INSERT INTO SalesManagement.dbo.auth2_user (
	   [password]
      ,[last_login]
      ,[is_superuser]
      ,[username]
      ,[first_name]
      ,[last_name]
      ,[email]
      ,[is_staff]
      ,[is_active]
      ,[date_joined]
      ,[national_code]
      ,[team_roles]
      ,[gender])
	 SELECT 0
      ,NULL
      ,0
      ,[username2]
      ,FirstName
      ,LastName
      ,LOWER(CONCAT(Username2, '@iraneit.com'))
      ,0
      ,1
      ,GETDATE()
      ,NationalCode
	  ,NULL
      ,Gender
	  FROM hr.dbo.Users
	WHERE NationalCode NOT IN (SELECT national_code FROM SalesManagement.dbo.auth2_user) 
	AND NationalCode IS NOT NULL 
	AND IsActive = 1


	-- UPDATE INACTIVE USERS
	UPDATE SalesManagement.dbo.auth2_user
	SET is_active = 0 
	WHERE national_code IN (SELECT NATIONALCODE FROM HR.DBO.Users WHERE IsActive = 0)


	-- UPDATE USER TEAM ROLES 
	UPDATE SalesManagement.dbo.auth2_user
	SET team_roles = UTR.UserTeamRoles
	FROM  SalesManagement.dbo.auth2_user  A2U
	INNER JOIN HR.DBO.Auth_UserTeamRole UTR ON UTR.NationalCode = A2U.national_code
	
END
GO
/****** Object:  StoredProcedure [dbo].[ChangeTeamRole]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mohammad Sepahkar
-- Create date: 1402-05-30
-- Description:	این تابع برای اعمال تغییرات فرآیند تغییر تیم و سمت در سیستم پرسنلی طراحی شده است
--1402-06-07 mohammad sepahkar
--برای کاربرانی که سطح نداشتند جابجایی درست انجام نمی شد چون فیلد نال بود که اصلاح شد
--1402-11-22 Mohammad Sepahkar
--باگی وجود داشت که اگر یک فرد دوباره وارد از یک  تیم خارج می شد، رکورد خروج دوم در سوابق درج نمی گردید
--1403-12-15 Mohammad Sepahkar
-- اضافه کردن کد ملی کاربر و مدیر
--1404-02-16 Mohmamad Sepahkar
-- اصلاح تاریخ شمسی در زمان غیرفعال سازی به دلیل اصلاح تاریخ پایان در جدول کاربران به شمسی
-- این قابلیت اضافه شد که توضیحات غیرفعال شدن سمت، به توضیحات قبلی اضافه شود
-- =============================================
CREATE PROCEDURE [dbo].[ChangeTeamRole] 
	-- Add the parameters for the stored procedure here
	@RequestId int = 61689
AS
BEGIN


	Declare @RequestType tinyint
	Declare @RequestTypeTitle nvarchar(30)
	Declare @Username varchar(50) 
	Declare @EffectiveDate varchar(10)
	Declare @EffectiveDay tinyint--روز تاریخ موثر
	Declare @EffectiveMonth tinyint--ماه تاریخ موثر
	Declare @DayDiff smallint = 0--اختلاف تاریخ موثر با ابتدای ماه
	Declare @EffectiveDate1 varchar(10)--تاریخ خاتمه سمت قبلی
	Declare @ManagerEffectiveDate varchar(10)
	Declare @SourceRoleId int
	Declare @SourceTeamCode char(3)
	Declare @SourceLevelId tinyint
	Declare @SourceSuperior bit
	Declare @TargetRoleId int
	Declare @TargetTeamCode char(3)
	Declare @TargetLevelId tinyint
	Declare @TargetSuperior bit

	Declare @UserTeamRoleId int
	Declare @ManagerUserName varchar(200)
	Declare @ManagerNationalCode varchar(10)
	Declare @UserNationalCode varchar(10)
	Declare @ContractEndDate Date
	--ابتدا اطلاعات درخواست را دریافت می کنیم
	select @RequestTypeTitle=RequestTypeTitle,
	@Username= UserName,@EffectiveDate=FormEffectiveDate, @ManagerEffectiveDate=ManagerEffectiveDate,@RequestType=RequestTypeId,
	@SourceTeamCode=SourceTeamCode, @SourceRoleId=SourceRoleId, @SourceLevelId=SourceLevelId, @SourceSuperior=SourceSuperior,
	@TargetTeamCode=TargetTeamCode, @TargetRoleId=TargetRoleId, @TargetLevelId=TargetLevelId, @TargetSuperior=TargetSuperior
	from ProcessManagement.dbo.ChangeTeamRole_History
	Where Id = @RequestId

	-- کد ملی کاربر را به دست می آوریم
	Select @UserNationalCode = NationalCode From Users
	Where Username = @Username

	--اگر درخواست غیرفعال سازی باشد، تاریخ موثر همان تاریخ تعیین شده توسط مدیریت است
	If @RequestType = 7
		Set @EffectiveDate = @ManagerEffectiveDate


	--اگر درخواست مربوط به روزهای پایانی ماه باشد، آن را برابر با ابتدا ماه جدید قرار می دهیم
	--مثلا اگر 29 ماه باشد، فرض می کنیم سمت جدید از 1 ماه بعد شروع شده است
	-- البته این موضوع برای غیرفعال سازی که سمت جدیدی وجود ندارد، معنی نخواهد داشت
	If @RequestType <> 7
	Begin
		Set @EffectiveDay = CAST( RIGHT(@EffectiveDate, 2) As tinyint)
		Set @EffectiveMonth = CAST(LEFT(RIGHT(@EffectiveDate, 5),2) As tinyint)
		If @EffectiveDay >= 27 
		Begin
			--در این حالت تاریخ شروع می شود تاریخ روز نخست ماه بعد
			Set @DayDiff = 30 - @EffectiveDay + 1
			--اگر ماه 31 روزه باشد اختلاف یک روز بیشتر است
			If @EffectiveMonth Between 1 And 6
				Set @DayDiff = @DayDiff + 1
		End
		--اگر تاریخ شروع هم سه روز اول ماه باشد، همان روز اول ماه در نظر می گیریم
		If @EffectiveDay <= 3
		Begin
			--در این حالت تاریخ شروع می شود تاریخ روز نخست ماه بعد
			Set @DayDiff = 1 - @EffectiveDay 
		End

		--تاریخ موثر را به روز می کنیم
		Set @EffectiveDate = dbo.Date_ShamsiDateAdd(@EffectiveDate, @DayDiff)
	End

	--تاریخ خاتمه سمت قبلی یک روز قبل از تاریخ شروع این سمت است
	Set @EffectiveDate1 = dbo.Date_ShamsiDateAdd(@EffectiveDate, -1)

	--مدیر تیم مقصد را به دست می آوریم
	--اگر پشتیبان باشد
	If @TargetRoleId = 69
		Select @ManagerUserName = SupportManager_id, 
		@ManagerNationalCode = SupportManagerNationalCode From Team
		Where TeamCode = @TargetTeamCode
	--اگر تستر باشد
	Else If @TargetRoleId in( 72,55 )
		Select @ManagerUserName = TestManager_id, 
		@ManagerNationalCode=TestManagerNationalCode From Team
		Where TeamCode = @TargetTeamCode
	--در غیر این صورت یعنی برنامه نویس یا سمت های دیگر است
	Else
		Select @ManagerUserName = GeneralManager_id, 
		@ManagerNationalCode=GeneralManagerNationalCode From Team
		Where TeamCode = @TargetTeamCode

	Select @UserTeamRoleId = Id From UserTeamRole
	Where UserName = @Username And RoleId = @SourceRoleId And TeamCode = @SourceTeamCode 
	And ISNULL(LevelId_id,0) = ISNULL(@SourceLevelId,0) And Superior = @SourceSuperior


	--اگر رکورد سمت قبلی وجود داشته باشد
	--و تغییر تیم و سمت و یا غیر فعال سازی باشد
	If @UserTeamRoleId Is not null And @RequestType In (1,2,3,7,8)
	Begin
		--در صورتی که این سمت قبلا برای این کاربر درج نشده باشد
		If Not Exists (Select 1 From PreviousUserTeamRole 
						Where UserName = @Username And RoleId = @SourceRoleId And TeamCode = @SourceTeamCode 
						And ISNULL(LevelId_id,0) = ISNULL(@SourceLevelId,0) And Superior = @SourceSuperior And EndDate=@EffectiveDate1)

			--سمت قبلی را در جدول سمت های قبلی کاربران درج می کنیم
			Insert into PreviousUserTeamRole (StartDate, EndDate, RoleId, TeamCode, NationalCode, ManagerNationalCode,
											UserName, LevelId_id, Superior, ManagerUserName_id, Comment)
			Select StartDate, @EffectiveDate1, RoleId, TeamCode, NationalCode, ManagerNationalCode,
			UserName, LevelId_id, Superior, ManagerUserName_id ,Comment + ' ' + 
			N'بنا به درخواست ' + @RequestTypeTitle + N' شماره ' + CAST(@RequestId  as varchar(10)) + N' این سمت غیرفعال شد'
			From UserTeamRole
			Where UserName = @Username And RoleId = @SourceRoleId And TeamCode = @SourceTeamCode 
			And ISNULL(LevelId_id,0) = ISNULL(@SourceLevelId,0) And Superior = @SourceSuperior





		--حالا اطلاعات سمت جدید را در سمت قبلی به روز می کنیم
		Update UserTeamRole
		Set RoleId = @TargetRoleId, LevelId_id = @TargetLevelId , TeamCode = @TargetTeamCode, 
		Superior = @TargetSuperior, ManagerUserName_id = @ManagerUserName, StartDate = @EffectiveDate,
		ManagerNationalCode = @ManagerNationalCode,
		Comment = N'بنا به درخواست ' + @RequestTypeTitle + N' شماره ' + CAST(@RequestId  as varchar(10)) + N' به سیستم اضافه شد'
		Where Id = @UserTeamRoleId
	End

	--اگر تعریف تیم یا سمت جدید باشد، بایستی فقط سمت و تیم جدید را اضافه کنیم
	Else If @RequestType In (4,5,6)
	Begin
		--سمت جدید را در جدول سمت های  کاربران درج می کنیم
		If Not Exists (Select 1 From UserTeamRole Where
						UserName = @Username And RoleId = @TargetRoleId And TeamCode = @TargetTeamCode 
						And ISNULL(LevelId_id,0) = ISNULL(@TargetLevelId,0) And Superior = @TargetSuperior)
			Insert into UserTeamRole (StartDate,  RoleId, TeamCode, ManagerNationalCode, NationalCode,
											UserName, LevelId_id, Superior, ManagerUserName_id, Comment)
			Select @EffectiveDate, @TargetRoleId, @TargetTeamCode, @ManagerNationalCode,@UserNationalCode,
			@UserName, @TargetLevelId, @TargetSuperior, @ManagerUserName , 
			N'بنا به درخواست ' + @RequestTypeTitle + N' شماره ' + CAST(@RequestId  as varchar(10)) + N' به سیستم اضافه شد'
	
	End

	--اگر درخواست غیرفعال سازی باشد باید کارهای زیر را انجام دهیم
	If @RequestType = 7
	Begin
		--رکورد سمت فعلی را حذف کنیم
		Delete UserTeamRole Where Id = @UserTeamRoleId

		--اگر این کاربر هیچ سمت فعال دیگری ندارد، باید آن را غیر فعال کنیم
		If Not Exists (Select 1 From UserTeamRole Where UserName = @Username)
		Begin
			--Set @ContractEndDate = @EffectiveDate

			Select @EffectiveDate ContractEndDate
			--کاربر را غیرفعال کرده و تاریخ خاتمه همکاری را بزنیم
			Update Users
			Set IsActive = 0, ContractEndDate = @EffectiveDate
			Where Username = @Username
		End
	End

	Select * From ProcessManagement.dbo.ChangeTeamRole_History
	Where Id = @RequestId

	Select 'CurrentRole->' CurrentRole, FirstName, LastName, UTR.UserName,
	UTR.NationalCode, UTR.ManagerNationalCode ,StartDate, EndDate 
	,UTR.RoleId, RoleName, UTR.TeamCode, TeamName, LevelId_id, LevelName,Superior, UTR.Comment,
	ManagerUserName_id, U.IsActive
	From Users U
	Left Join UserTeamRole UTR
	On UTR.UserName = U.UserName
	Inner Join Role R
	On UTR.RoleId = R.RoleId
	Inner Join Team T
	On UTR.TeamCode = T.TeamCode
	Left Join RoleLevel RL
	On UTR.LevelId_id = RL.id
	Where UTR.Username = @Username


	Select 'PreviousRole->' CurrentRole, FirstName, LastName, UTR.UserName,
	UTR.NationalCode, UTR.ManagerNationalCode , StartDate, EndDate 
	,UTR.RoleId, RoleName, UTR.TeamCode, TeamName, LevelId_id, LevelName,Superior ,UTR.Comment, 
	ManagerUserName_id,  U.IsActive,  ContractEndDate
	From Users U
	Left Join PreviousUserTeamRole UTR
	On UTR.UserName = U.UserName
	Inner Join Role R
	On UTR.RoleId = R.RoleId
	Inner Join Team T
	On UTR.TeamCode = T.TeamCode
	Left Join RoleLevel RL
	On UTR.LevelId_id = RL.id
	Where UTR.Username = @Username

END
GO
/****** Object:  StoredProcedure [dbo].[CorectInputData]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Nadya Helmi
-- Create date: 1401-05-22
-- Description:	اين تابع حرف ي را جايگزين مي کند 
-- =============================================
CREATE PROCEDURE [dbo].[CorectInputData] 
AS
BEGIN

	SET NOCOUNT ON;

	--جدول پرسنلي
	--جايگزيني حرف ي
	Update Users
	Set FirstName =  REPLACE (FirstName,N'ي',N'ی')
	, LastName =  REPLACE (LastName,N'ي',N'ی')
	, FatherName =  REPLACE (FatherName,N'ي',N'ی')


	--جدول سمت
	--جايگزيني حرف ي
	Update Role 
	Set RoleName =  REPLACE (RoleName,N'ي',N'ی')


	--جدول تيم
	--جايگزيني حرف ي	Update Team
	Update Team
	Set TeamName= REPLACE (TeamName,N'ي',N'ی')


END
GO
/****** Object:  StoredProcedure [dbo].[HR_ExportData]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mohammad Sepahkar
-- Create date: 1401-08-21
-- Description:	این تابع داده های مربوط به اطلاعات اشخاص و ... را به جداول مربوطه در سایر بانک های اطلاعاتی منتقل می کند
-- 1402/05/28 Mohammad Sepahkar
-- حالتی که نام کاربری عوض می شود اضافه شد
--1403/04/08 : Mohammad Sepahkar
--کد انتقال داده به سرویس بوک
--1403/09/18 : Mohammad Sepahkar
-- کد انتقال داده به پروژه صورت حساب

-- =============================================
CREATE PROCEDURE [dbo].[HR_ExportData] 

AS
BEGIN

	-----------------------Cost Price Start------------------------
	----اگر مواردی داریم که کد ملی یکسان است ولی نام کاربری تغییر کرده است باید اصلاح شود
	--اگر مواردی داریم که کد ملی یکسان است ولی نام کاربری تغییر کرده است باید اصلاح شود
	--چون نام کاربری در بسیاری از جداول ذخیره شده است باید در تمامی آنها به روزرسانی انجام شود
	Declare @ChangeUserName Table(OldUsername varchar(50), NewUsername varchar(50))
	insert into @ChangeUserName (NewUsername,OldUsername)
	select U.Username, CU.Username from Users U
	Inner Join CostPrice.dbo.CostPrice_users CU
	on U.NationalCode = CU.PersonnelCode And U.UserName <> CU.Username
	--این خیلی کار خفنیه!
	--نمی توانیم به روزرسانی را انجام دهیم چون یک عالمه کلید خارجی دارد
	--از طرف دیگه نمی توانیم اول کلید خارجی ها را به روزرسانی کنیم، چون نام کاربری جدید وجود ندارد
	--بنابراین اول یک رکورد با نام کاربری جدید درج می کنیم
	--ولی چون کد ملی باید منحصر به فرد باشد، این درج را با کد ملی تغییر یافته انجام می دهیم
	--برای این کار به آخر کدملی *** اضافه می کنیم
	insert into CostPrice.dbo.CostPrice_users(Username, FirstName, LastName, PersonnelCode, ContractDate)
	select NewUser.NewUsername, FirstName, LastName, PersonnelCode+'***', ContractDate 
	from CostPrice.dbo.CostPrice_users U
	Inner Join @ChangeUserName NewUser
	On U.Username = OldUsername
	Where NewUsername Not In
	(Select Username From CostPrice.dbo.CostPrice_users)

	--حالا نام کاربری جدید را داریم، می توانیم کلیدهای خارجی را به روزرسانی کنیم
	--ابتدا در هر یک از جدولهایی که  نام کاربری کلید خارجی است باید به روزرسانی انجام شود
	--CostPrice_importdata_tasklist
	Update TL 
	Set FromUsername = NewUsername
	From CostPrice.dbo.CostPrice_importdata_tasklist TL
	inner join @ChangeUserName U
	On TL.FromUsername = U.OldUsername

	Update TL 
	Set ToUsername = NewUsername
	From CostPrice.dbo.CostPrice_importdata_tasklist TL
	inner join @ChangeUserName U
	On TL.ToUsername = U.OldUsername

	--CostPrice_importdata_taskworktime
	Update TW 
	Set Username = NewUsername
	From CostPrice.dbo.CostPrice_importdata_taskworktime TW
	inner join @ChangeUserName U
	On TW.Username = U.OldUsername

	--CostPrice_payment
	Update Pay 
	Set Username = NewUsername
	From CostPrice.dbo.CostPrice_payment Pay
	inner join @ChangeUserName U
	On Pay.Username = U.OldUsername

	--CostPrice_productservicecostdetail
	Update PSCD 
	Set Username = NewUsername
	From CostPrice.dbo.CostPrice_productservicecostdetail PSCD
	inner join @ChangeUserName U
	On PSCD.Username = U.OldUsername

	--CostPrice_productservicetaskdeletelog
	Update PSTD 
	Set CreatorUser_id = NewUsername
	From CostPrice.dbo.CostPrice_productservicetaskdeletelog PSTD
	inner join @ChangeUserName U
	On PSTD.CreatorUser_id = U.OldUsername

	--CostPrice_producttask
	Update PT 
	Set CreatorUser_id = NewUsername
	From CostPrice.dbo.CostPrice_producttask PT
	inner join @ChangeUserName U
	On PT.CreatorUser_id = U.OldUsername

	--CostPrice_servicetask
	Update ST 
	Set CreatorUser_id = NewUsername
	From CostPrice.dbo.CostPrice_servicetask ST
	inner join @ChangeUserName U
	On ST.CreatorUser_id = U.OldUsername

	--CostPrice_userteamrole
	Update UTR 
	Set Username = NewUsername
	From CostPrice.dbo.CostPrice_userteamrole UTR
	inner join @ChangeUserName U
	On UTR.Username = U.OldUsername

	--CostPrice_userteamrolecount_
	Update UTRC 
	Set Username = NewUsername
	From CostPrice.dbo.CostPrice_userteamrolecount_ UTRC
	inner join @ChangeUserName U
	On UTRC.Username = U.OldUsername

	--CostPrice_userteamrolepermonth
	Update UTRM 
	Set Username = NewUsername
	From CostPrice.dbo.CostPrice_userteamrolepermonth UTRM
	inner join @ChangeUserName U
	On UTRM.Username = U.OldUsername

	--CostPrice_userwithoutteam
	Update UWT 
	Set Username = NewUsername
	From CostPrice.dbo.CostPrice_userwithoutteam UWT
	inner join @ChangeUserName U
	On UWT.Username = U.OldUsername

	--به روزرسانی کلیدهای خارجی تمام شد
	--حالا رکوردهای قدیمی را حذف می کنیم
	Delete CostPrice.dbo.CostPrice_users
	Where Username In (Select OldUsername From @ChangeUserName)

	--حالا کد ملی را به روز می کنیم
	Update CostPrice.dbo.CostPrice_users
	Set PersonnelCode = REPLACE(PersonnelCode,'***','')
	Where Username In (Select NewUsername From @ChangeUserName)



	--user table
	Insert into CostPrice.dbo.CostPrice_users ( Username, FirstName, LastName,PersonnelCode )
	Select Username, FirstName, LastName,NationalCode From Users
	Where NationalCode Is not null and UserName not In (Select Username From CostPrice.dbo.CostPrice_users)

	Select CAST(@@ROWCOUNT As varchar(10)) + ' new users added'

	--ممکن است فیلدهای موجود نام، نام خانوادگی، کد ملی و ... تغییر کرده باشند
	Update CostPrice.dbo.CostPrice_users
	Set FirstName = U.FirstName, LastName = U.LastName
	From CostPrice.dbo.CostPrice_users CU
	Inner Join Users U
	On CU.Username = U.UserName

	--برای کد ملی دو موضوع وجود دارد که قبل از به روزرسانی باید کنترل شود
	--کد ملی تکراری نباشد
	--کد ملی نال نباشد
	Update CostPrice.dbo.CostPrice_users
	Set FirstName = U.FirstName, LastName = U.LastName, 
	ContractDate = U.ContractDate
	From CostPrice.dbo.CostPrice_users CU
	Inner Join Users U
	On CU.Username = U.UserName
	Where NationalCode is not null and NationalCode not in
	(Select PersonnelCode From CostPrice.dbo.CostPrice_users)

	--role table
	--add new role as 'other' group
	Insert into CostPrice.dbo.CostPrice_roles (RoleId, RoleName, RoleGroupCode)
	Select RoleId, RoleName,'O' From Role
	Where RoleId not In (Select RoleId From CostPrice.dbo.CostPrice_roles)

	Select CAST(@@ROWCOUNT As varchar(10)) + ' new role added'

	--role level table
	Insert into CostPrice.dbo.CostPrice_rolelevel (LevelName)
	Select LevelName From RoleLevel
	Where LevelName not In (Select LevelName From CostPrice.dbo.CostPrice_rolelevel)

	Select CAST(@@ROWCOUNT As varchar(10)) + ' new role level added'


	--team table
	--add new team with operation 0 (means not operational team)
	Insert into CostPrice.dbo.CostPrice_team(TeamCode,TeamName, OperationType)
	Select TeamCode, TeamName,0 From Team
	Where TeamCode not In (Select TeamCode From CostPrice.dbo.CostPrice_team)

	Select CAST(@@ROWCOUNT As varchar(10)) + ' new team added'



	--user team role table

	--ابتدا رکوردهای قبلی را پاک می کنیم
	Delete CostPrice.dbo.CostPrice_UserTeamRole

	;With CTE_UserTeamRole As
	(SELECT StartDate, EndDate, ManagerUserName_id
	,[RoleId],[TeamCode],[UserName]
	FROM [HR].[dbo].[PreviousUserTeamRole]
	Union 
	SELECT [StartDate],[EndDate], ManagerUserName_id
	,[RoleId],[TeamCode],[UserName]
	FROM [HR].[dbo].[UserTeamRole])


	Insert into CostPrice.dbo.CostPrice_UserTeamRole
	(StartDateJalali, EndDateJalali, RoleId, TeamCode, Username, ManagerUsername)
	--برای کسانی که در همان سمت و تیم تغییر سطح داشته اند
	--نیازی نیست دو رکورد منتقل شود
	--تاریخ شروع را به عنوان زودترین تاریخ شروع می گیریم
	--تاریخ خاتمه را یک تاریخ بزرگ می گیریم، بعدا نال می کنیم
	Select MIN([StartDate]) StartDate,MAX(ISNULL([EndDate],'1440/01/01' )) EndDate, 
	[RoleId],[TeamCode],UTR.[UserName], ManagerUserName_id
	From CTE_UserTeamRole UTR
	Inner Join Users U
	On UTR.UserName = U.UserName
	Where U.NationalCode Is Not Null
	Group By [RoleId],[TeamCode],UTR.[UserName], ManagerUserName_id

	Select CAST(@@ROWCOUNT As varchar(10)) + ' user team role added'

	--اکنون تاریخی که به عنوان تاریخ بزرگ آینده گرفته بودیم را نال می کنیم
	Update CostPrice.dbo.CostPrice_UserTeamRole
	Set EndDateJalali = null
	Where EndDateJalali = '1440/01/01'

	--حالا تاریخ میلادی را به روزرسانی می کنیم
	Update CostPrice.dbo.CostPrice_UserTeamRole
	Set StartDate = CostPrice.dbo.CostPrice_Date_ShamsiToMiladi(StartDateJalali),
	EndDate = CostPrice.dbo.CostPrice_Date_ShamsiToMiladi(EndDateJalali)

	--در سیستم بهای تمام شده آخرین وضعیت ارشد بودن و آخرین سطح مهم است
	--بنابراین باید آخرین رکورد معادل هر کاربر را به دست بیاوریم
	;with CTE_LastUserTeamRole As
	(Select UserName,TeamCode,RoleId, LevelId_id, Superior,
	ROW_NUMBER() Over(Partition By Username, TeamCode, RoleId Order By StartDate DESC) RecordNumber 
	From UserTeamRoleAll)

	Update CostPrice.dbo.CostPrice_UserTeamRole
	Set LastLevel_id= LUTR.LevelId_id, IsSuperior=LUTR.Superior
	From CostPrice.dbo.CostPrice_UserTeamRole UTR
	Inner Join CTE_LastUserTeamRole LUTR
	on LUTR.Username = UTR.Username and LUTR.TeamCode = UTR.TeamCode And LUTR.RoleId = UTR.RoleId
	Where RecordNumber = 1

	-----------------------Cost Price End------------------------

	-------------------------Service Book Start--------------------

	--کاربرانی که وجود ندارند را اضافه می کنیم
	Insert into ServiceBook.dbo.Users (UserName, FirstName,LastName)
	Select Username, FirstName, LastName From Users Where UserName Not In
	(Select UserName From ServiceBook.dbo.Users)

	--با توجه به کارهای خارق العاده ای که واحد فناوری اطلاعات انجام می دهد، ممکن است نام کاربری یک نفر 
	--را به یک نفر دیگر داده باشد، بنابراین باید نام و نام خانوادگی ها را هم به روز کنیم
	--هر چند اینطوری کل داده ها به هم می ریزد
	Update ServiceBook.dbo.Users
	Set FirstName = HU.FirstName, LastName = HU.LastName
	From ServiceBook.dbo.Users SU
	Inner Join Users HU
	On SU.UserName = HU.UserName

	--حالا لیست سمت ها را به روز می کنیم
	Insert into ServiceBook.dbo.Role(RoleId, RoleName)
	Select RoleId,RoleName From Role
	Where RoleId Not In
	(Select RoleId From ServiceBook.dbo.Role)

	--جهت اطمینان بیشتر همان عملیات به روزرسانی را اینجا هم انجام می دهیم
	--این ربطی به شیرین کاری های فناوری اطلاعات ندارد. 
	--ربط به تجربه من داره که اینجا چیزهای خیلی غیرمنتظره دیده ام
	Update ServiceBook.dbo.Role
	Set RoleName = HR.RoleName
	From ServiceBook.dbo.Role SR
	Inner Join Role HR
	On SR.RoleId = HR.RoleId

	--حالا برویم سراغ تیم ها
	insert into ServiceBook.dbo.Team(TeamCode, TeamName, ActiveInService, ActiveInEvaluation)
	Select TeamCode, TeamName, ActiveInService, ActiveInEvaluation From Team
	Where TeamCode Not In
	(Select TeamCode From ServiceBook.dbo.Team)

	--باز هم به روزرسانی اطلاعات
	--کار از محکم کاری عیب نمی کنه!
	Update ServiceBook.dbo.Team
	Set TeamName = HT.TeamName, ActiveInService = HT.ActiveInService, ActiveInEvaluation = HT.ActiveInEvaluation
	From ServiceBook.dbo.Team ST
	Inner Join Team HT
	On ST.TeamCode = HT.TeamCode

	--یک نکته جالب داشتم فکر می کردم، اگه یک کاربر یا یک تیم یا یک سمت حذف بشود چی؟
	--راجع به کاربر و سمت کاری نمی توانیم بکنیم
	--نمی توانیم حذف کنیم چون ممکن است در جدول مقصد کلید خارجی باشند و همه چیز منفجر می شود
	--اما راجع به تیم می توانیم یک حرکتی بزنیم
	--یعنی می توانیم در این دیتابیس فعال بودن آن در سرویس را غیرفعال کنیم
	Update ServiceBook.dbo.Team
	Set  ActiveInService = 0
	Where TeamCode Not In
	(Select TeamCode From Team)

	--حالا به سراغ جدول سمت و تیم کاربران می رویم
	--با تشکر از خودم، این جدول کلید خارجی ندارد و راحت می توانیم رکوردها را پاک کنیم
	--فقط یک سئوال مهم مطرح می شود
	--آیا اینجا فقط سمت های فعال باید آورده شود یا همه سمت ها؟
	--الان یادم نیست که منطق برنامه چیه، باید چک کنیم و در صورت لزوم اصلاح نماییم
	Delete ServiceBook.dbo.UserTeamRole

	Insert into ServiceBook.dbo.UserTeamRole
	Select StartDate,EndDate,RoleId,TeamCode,UserName From UserTeamRole

	-----------------------Service Book End----------------------

	-----------------------PersonnelService Start--------------------
	-- In personnel service (pors app) we are using the PersonnelService.dbo.Users for 
	-- generating reports. so as we need to the Personnel NationalCode in reports we have to 
	-- keep update the PersonnelService.dbo.Users as well.
	-- we do not have Role, Team and UserTeamRole tables by this time. so we skip updating them
	--(windowsam taze avaz shode va hal nadashtam ke keyboard ro farsi konam)

	--کاربرانی که وجود ندارند را اضافه می کنیم
	Insert into PersonnelService.dbo.Users (UserName, FirstName,LastName, NationalCode)
	Select Username, FirstName, LastName, NationalCode From Users Where UserName Not In
	(Select UserName From PersonnelService.dbo.Users)

	--با توجه به کارهای خارق العاده ای که واحد فناوری اطلاعات انجام می دهد، ممکن است نام کاربری یک نفر 
	--را به یک نفر دیگر داده باشد، بنابراین باید نام و نام خانوادگی ها را هم به روز کنیم
	--هر چند اینطوری کل داده ها به هم می ریزد
	Update PersonnelService.dbo.Users
	Set FirstName = HU.FirstName, LastName = HU.LastName
	From PersonnelService.dbo.Users SU
	Inner Join Users HU
	On SU.UserName = HU.UserName
	-----------------------PersonnelService End----------------------


	-----------------------CorpIssue Start----------------------
	--ابتدا تیم های جدید را درج می کنیم
	insert into SalesManagement.dbo.CorpIssue_team (team_code,team_name, manager)
	Select TeamCode,TeamName,U.NationalCode From HR.dbo.Team T
	Inner Join Users U
	On T.GeneralManager_id = U.Username
	Where T.IsActive = 1 And
	TeamCode not in 
	(Select team_code From SalesManagement.dbo.CorpIssue_team)

	--حالا اگر مدیر تیم عوض شده باشد آن را اصلاح می کنیم
	update c
	set manager = NationalCode
	From HR.dbo.Team T
	Inner Join Users U
	On T.GeneralManager_id = U.Username
	inner join SalesManagement.dbo.CorpIssue_team c
	on t.TeamCode = c.team_code
	Where NationalCode <> manager
	-----------------------CorpIssue End----------------------


END


GO
/****** Object:  StoredProcedure [dbo].[HR_GetAssessorsAndEducators]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[HR_GetAssessorsAndEducators]   

  @TeamCode CHar(3)----اگر تیم جدید داشت جدید اگر نه قبلی  
  ,@InfoID Int  
 , @RoleIdTarget int----اگر سمت جدید داشت جدید اگر نه قبلی  
 , @LevelIdTarget int----اگر سطح جدید داشت جدید اگر نه قبلی  
 , @SuperiorTarget Bit----اگر ارشدیت جدید داشت جدید اگر نه قبلی  
 , @Temporary Bit=0 -----اگر 1 باشد موقت اگر 0 باشد دائمی است
 ,	@Type bit =0--اگر تایپ 0 بود یعنی تغییر اگر 1 بود یعنی جدید
  
AS  
BEGIN  
-----سمت و تیم و سطح قبلی و به دست میاریم  
  Declare @RoleId int  
  Declare @LevelId int  
  Declare @Superior Bit  
  Declare @TeamCodeOld CHar(3) 
  Declare @Test Tinyint
  Select  @RoleId=RoleId,@LevelId=LevelId_id,@Superior=Superior  
  ,@TeamCodeOld=TeamCode  
  From UserTeamRole  
  WHere Id=@InfoID  

-----برای پرسنل آموزشی 
if @RoleId=117 And @TeamCodeOld='EDU'
	Begin
		Select Convert(bit,1) As Education,(Select dbo.HR_Name_GetTeamManager(@RoleIdTarget,@TeamCode,'U')) Educator
		,Convert(bit,1) As Evaluation
		,Convert(bit,1) As PmChange ,Convert(bit,1) As ITChange ,''RequestGap
		,Convert(bit,1) As ReEvaluation
		,(Select dbo.HR_Name_GetTeamManager(@RoleIdTarget,@TeamCode,'U')) Assessor2
		,(Select dbo.HR_Name_GetTeamManager(@RoleIdTarget,@TeamCode,'N')) EducatorName,(Select dbo.HR_Name_GetTeamManager(@RoleIdTarget,@TeamCode,'N'))  AssessorName ,(Select dbo.HR_Name_GetTeamManager(@RoleIdTarget,@TeamCode,'N')) Assessor2Name,
		(Select dbo.HR_Name_GetTeamManager(@RoleIdTarget,@TeamCode,'U')) Assessor,Convert(bit,1) As Confirm
	
			
	
	
	End
	Else 
Begin 

-------اگر مدیر محصول باشد حتما ارشد است
If @RoleIdTarget = 58 
	Begin
	Set @SuperiorTarget = 1
	Set @LevelIdTarget = NULL
	End
-----چک میشود که با هیچ سمت و تیم و سطح در حال حاضر یکی نباشد.
	;With CTE_UserReq 
	As (Select @TeamCode TeamCode,@RoleIdTarget RoleIdTarget
	,ISNull(@LevelIdTarget,0) LevelIdTarget,@SuperiorTarget SuperiorTarget)
	 ,CTE_UserOld As (
	 Select *,COUNT(*) Over ()  As CountRow
	From UserTeamRole U
	Where username in (Select UserName From UserTeamRole WHere Id=@InfoID  )
	)
 	Select Distinct @Test=CountRow-COUNT(*)Over () From CTE_UserOld U
	 Cross JOin CTE_UserReq R
	 Where (U.TeamCode<>R.TeamCode Or RoleId<>RoleIdTarget OR Isnull(LevelId_id,0)<>isnull(LevelIdTarget,0)
	 OR Superior<>SuperiorTarget)
if 
	((@RoleId Not In (63,55,56,57,68,69,72,58) And @RoleIdTarget In (63,55,56,57) And @LevelIdTarget<>6
	And @Temporary = 0))

	Or 
	(@Type=1 And @RoleId=@RoleIdTarget And Isnull(@LevelId,1)<>Isnull(@LevelIdTarget,0) And @Superior=@SuperiorTarget)
	Begin
		Select '' Education,'' Educator,'' Evaluation,'' PmChange ,'' ITChange ,''RequestGap
		,'' ReEvaluation ,'' Assessor2,'' EducatorName,''  AssessorName ,'' Assessor2Name,'' Assessor, Convert(bit,0) As Confirm
	
	
	End Else 

	Begin
If
	@Test=0 
Begin

----اگر جدید باشدو سمت تغییر کند
	if ((@Type = 1 And ( (@RoleId<>@RoleIdTarget  
---اگر سمت های بالاتر تولید باشد سطح آن نیمتواند بالا باشد
	And @RoleId Not In (63,55,56,57) And @RoleIdTarget In (63,55,56,57) And @LevelIdTarget=6)
	Or (@RoleId<>@RoleIdTarget  
	And @RoleId In (63,55,56,57) And @RoleIdTarget  In (63,55,56,57) )
	Or (@RoleId<>@RoleIdTarget  
	And @RoleId Not In (63,55,56,57) And @RoleIdTarget Not In (63,55,56,57) )
	Or (@RoleId<>@RoleIdTarget  
	And @RoleId  In (63,55,56,57) And @RoleIdTarget Not In (63,55,56,57) )
-----اگر سمت یکی است و سطح فرق میکند در حالتی که جدید است نمیتواند سطح از یکی بالاتر برود
	Or (@RoleId=@RoleIdTarget And @TeamCode NOt IN (Select TeamCode
	From UserTeamRole U
	Where username in (Select UserName From UserTeamRole WHere Id=@InfoID ))
	 And Isnull(@LevelId,1)-Isnull(@LevelIdTarget,0) BetWeen 0 And 1 )
	)) 
	Or @Type = 0 
		)
	And ( (SELECT [dbo].[HR_Name_GetTeamManager](@RoleIdTarget,@TeamCode,'U')) is NOt NUll)
	
	Or @Temporary = 1

	Begin
-----اگر سمت شخص در تیم های عملیاتی نباشد یا از تیم عملیاتی به غیر عملیاتی و برعکس انجام شود
		If 		('TechnicalRole' Not in (Select RoleGroup From HR_RoleGroup
				Where RoleID_id=@RoleIdTarget)
				OR 
				'TechnicalRole' Not in
				(Select RoleGroup From HR_RoleGroup
				Where RoleID_id=@RoleId))
				Or(@RoleId=@RoleIdTarget And Isnull(@LevelId,0)=Isnull(@LevelIdTarget,0)
				And @Superior=@SuperiorTarget And @TeamCode<>@TeamCodeOld)
				Or @Type=1
				Or @Temporary = 1
				--Or (@TeamCode<>@TeamCodeOld And (@RoleId=@RoleIdTarget And
				--  Isnull(@LevelId,0)-Isnull(@LevelIdTarget,0)=0 
				----Isnull(@LevelId,0)=isnull(@LevelIdTarget,0)
				--	 And @Superior=@SuperiorTarget))
			Begin
				 ;With CTE_User AS (  
				Select Distinct 
				Case When --(  @TeamCode=@TeamCodeOld ) Or
				 ( @RoleId=@RoleIdTarget) 
				Or (@Temporary = 1)
				Then '' 
				When @RoleIdTarget IN(69,72,63,57,56,58,68,55)
				And @RoleId Not IN (69,72,63,57,56,58,68,55)
				Then 'زهرا معيني امجد'
				When( (@RoleIdTarget=52 And  @RoleId IN (69,72,63,57,56,58,68,55)
				OR @RoleId=52 And @RoleIdTarget IN(69,72,63,57,56,58,68,55))
				And @RoleId<>@RoleIdTarget)
				Then  'زهرا معيني امجد' 
				Else
				(Select dbo.HR_Name_GetTeamManager(@RoleIdTarget,@TeamCode,'N'))
				--'زهرا معيني امجد'
				End EducatorName   
				,Case When
				--(  @TeamCode=@TeamCodeOld ) Or 
				( @RoleId=@RoleIdTarget) 
				Or (@Temporary = 1)
				Then '' 
				When @RoleIdTarget IN(69,72,63,57,56,58,68,55)
				And @RoleId Not IN (69,72,63,57,56,58,68,55)
				Then 'z.moeini@eit' 
				When( (@RoleIdTarget=52 And  @RoleId IN (69,72,63,57,56,58,68,55)
				OR @RoleId=52 And @RoleIdTarget IN(69,72,63,57,56,58,68,55))
				And @RoleId<>@RoleIdTarget)
				Then 'z.moeini@eit' 
				Else
				(Select dbo.HR_Name_GetTeamManager(@RoleIdTarget,@TeamCode,'U'))
				--'z.moeini@eit' 
				End Educator  
				,Case When  (@Temporary=1 )
				Or (@RoleId=@RoleIdTarget And @RoleIdTarget IN (69,72))
				Then 
				Convert(Bit,0)
				ELse
				Convert(Bit,1) End  Evaluation  
				,Convert(Bit,1) PmChange  
				,Convert(Bit,1) ITChange  
				,'' RequestGap  
				,Case When  
				---یا موقت باشد
				(@Temporary=1)
				---یا ارشد بشود
				OR (@SuperiorTarget=1 And @Superior=0) 
				---یا پشتیبان و تستر ارتقا سطح داشته باشند
				Or (@RoleId=@RoleIdTarget And @RoleIdTarget IN (69,72))
				Then CONVERT(bit,0) 
				Else CONVERT(bit,1)  End
				ReEvaluation
				,Case When 
				--(  @TeamCode=@TeamCodeOld ) Or
				( @RoleId=@RoleIdTarget) 
				Or (@Temporary = 1)
				Then Convert(bit,0) Else
				Convert(bit,1) End
				Education  
				
				,Case When  
				(@Temporary=1 OR (@SuperiorTarget=1 And @Superior=0)) Then ''
				When @RoleIdTarget  IN (57,58) And @Type=1 Then
				 (Select FirstName + ' ' + LastName From UserTeamRole UT
				 Inner JOIn Users U3
				 On UT.UserName=U3.UserName
				 Where RoleId=111)
				  When @RoleId=@RoleIdTarget And @RoleIdTarget IN (69,72)
				 Then ''
				 When   @RoleIdTarget  IN (63,55,56,68)And @Type=1 Then
				 (Select FirstName + ' ' + LastName From UserTeamRole UT
				 Inner JOIn Users U2
				 On UT.UserName=U2.UserName
				 Where RoleId=108)
				Else (Select dbo.HR_Name_GetTeamManager(@RoleIdTarget,@TeamCode,'N')) End
				Assessor2Name  
				,Case When  (@Temporary=1 OR (@SuperiorTarget=1 And @Superior=0))  Then ''  
				When @RoleIdTarget  IN (57,58)And @Type=1 Then
				 (Select UT.UserName From UserTeamRole UT
				 Where RoleId=111)
				 When @RoleId=@RoleIdTarget And @RoleIdTarget IN (69,72)
				 Then ''
				 When   @RoleIdTarget  IN (63,55,56,68)And @Type=1 Then
				 (Select UT.UserName From UserTeamRole UT
				  Where RoleId=108)
					Else (Select dbo.HR_Name_GetTeamManager(@RoleIdTarget,@TeamCode,'U')) End
					Assessor2 
				,Case When  @Temporary=1 Then ''   
				When @RoleIdTarget  IN (57,58)And @Type=1 Then
				 (Select FirstName + ' ' + LastName From UserTeamRole UT
				 Inner JOIn Users U3
				 On UT.UserName=U3.UserName
				 Where RoleId=111)
				  When @RoleId=@RoleIdTarget And @RoleIdTarget IN (69,72)
				 Then ''
				 When   @RoleIdTarget  IN (63,55,56,68)And @Type=1 Then
				 (Select FirstName + ' ' + LastName From UserTeamRole UT
				 Inner JOIn Users U2
				 On UT.UserName=U2.UserName
				 Where RoleId=108)
				Else 	(Select dbo.HR_Name_GetTeamManager(@RoleIdTarget,@TeamCode,'N')) End
				AssessorName
				,Case When  @Temporary=1 Then ''  
				When @RoleIdTarget  IN (57,58) And @Type=1 Then
				 (Select UT.UserName From UserTeamRole UT
				 Where RoleId=111)
				 When @RoleId=@RoleIdTarget And @RoleIdTarget IN (69,72)
				 Then ''
				 When   @RoleIdTarget  IN (63,55,56,68)And @Type=1 Then
				(Select UT.UserName From UserTeamRole UT
				Where RoleId=108)
				Else (Select dbo.HR_Name_GetTeamManager(@RoleIdTarget,@TeamCode,'U')) End
				Assessor 
				From UserTeamRole TR  
				Where TR.TeamCode=@TeamCode )

				Select *  ,(Case When COUNT(*) over()=0 Then  Convert(bit,0) Else Convert(bit,1) End ) As Confirm
				From CTE_User

			End
			ELse	
			Begin
				-----اگر فرد در تیم های عملیاتی جا به جا شود  
				 ;With CTE_User AS (  
				 Select  
				 ----اگر شخص تغییر تیم یا سطح داشته باشد به آموزش احتیاجی ندارد
				 Case When @RoleId=@RoleIdTarget And @Superior=@SuperiorTarget
				 Then CONVERT(Bit,0) ELse 
				 Education  End Education
				 ----اگر ارشد اموزش دهنده باشد و در تیم سمت ارشد وجود داشته باشد
				,Case When Educator='Superior' 
				 And (Select Count(*)
				 From UserTeamRole Where RoleId=@RoleIdTarget And Superior=1 And TeamCode=@TeamCode)>0
				 Then   
				 (Select Top (1)UserName From UserTeamRole Where RoleId=@RoleIdTarget And Superior=1 And TeamCode=@TeamCode)
				 When  Educator='Superior'  And ----ارشد در آن تیم وجود نداشته باشد
				 (Select Count(*)
				 From UserTeamRole Where RoleId=@RoleIdTarget And Superior=1 And TeamCode=@TeamCode)=0
				 Then 
				 (Select dbo.HR_Name_GetTeamManager(@RoleIdTarget,@TeamCode,'U'))
				 ----اگر مسئول آموزش مدیر مسئول باشد و وجود داشته باشد
				 When Educator=58 And
				 (Select Count(*) From UserTeamRole Where RoleId=58 And Superior=1 And TeamCode=@TeamCode) >0
				 Then   
				 (Select Top (1)UserName From UserTeamRole Where RoleId=58 And Superior=1 And TeamCode=@TeamCode) 
				 ----اگر مسئول آموزش مدیر محصول باشد و وجود نداشته باشد
				 When Educator=58 And
				 (Select Count(*) From UserTeamRole Where RoleId=58 And Superior=1 And TeamCode=@TeamCode)=0
				 Then   
				  (Select dbo.HR_Name_GetTeamManager(@RoleIdTarget,@TeamCode,'U'))
				 ELse (Select UserName From UserTeamRole Where RoleId=Educator) End As Educator 
				 ,CR.Evaluation  
				 ,Case When Assessor='Superior'  And 
				 (Select Count(*)
				 From UserTeamRole Where RoleId=RoleIdTarget_id And Superior=1 And TeamCode=@TeamCode)>0
					Then 
				 (Select Top(1) UserName
				 From UserTeamRole Where RoleId=RoleIdTarget_id And Superior=1 And TeamCode=@TeamCode) 
				  When Assessor='Superior'  And 
				  ----ارشد در آن تیم وجود نداشته باشد
				 (Select Count(*)
				 From UserTeamRole Where RoleId=RoleIdTarget_id And Superior=1 And TeamCode=@TeamCode)=0
				 Then 
				 (Select dbo.HR_Name_GetTeamManager(@RoleIdTarget,@TeamCode,'U'))
				 When Assessor=58 Then   
				 (Select Top (1)UserName From UserTeamRole Where RoleId=58 And Superior=1 And TeamCode=@TeamCode) 
				 When Assessor=63 Then
				  (Select Top (1)UserName From UserTeamRole Where RoleId=63 And Superior=1 And TeamCode=@TeamCode)  
				 ELse (Select UserName From UserTeamRole Where RoleId=Assessor) End As Assessor 
				 ,Case When @TeamCode<>@TeamCodeOld Then Convert(bit,1) Else   CR.PmChange  End PmChange
				,Case When @TeamCode<>@TeamCodeOld Then Convert(bit,1) Else  CR.ITChange  End ITChange
				 ,CR.RequestGap  
				 ,CR.ReEvaluation  
				 ,Case When Assessor='Superior'  And 
				 (Select Count(*)
				 From UserTeamRole Where RoleId=RoleIdTarget_id And Superior=1 And TeamCode=@TeamCode)>0
					Then 
				 (Select Top(1) UserName
				 From UserTeamRole Where RoleId=RoleIdTarget_id And Superior=1 And TeamCode=@TeamCode) 
				  When Assessor='Superior'  And 
				  ----ارشد در آن تیم وجود نداشته باشد
				 (Select Count(*)
				 From UserTeamRole Where RoleId=RoleIdTarget_id And Superior=1 And TeamCode=@TeamCode)=0
				 Then 
				 (Select dbo.HR_Name_GetTeamManager(@RoleIdTarget,@TeamCode,'U'))
				 When Assessor=58 Then   
				 (Select Top (1)UserName From UserTeamRole Where RoleId=58 And Superior=1 And TeamCode=@TeamCode) 
				 When Assessor=63 Then
				  (Select Top (1)UserName From UserTeamRole Where RoleId=63 And Superior=1 And TeamCode=@TeamCode)  
				 ELse (Select UserName From UserTeamRole Where RoleId=Assessor) End As Assessor2  
				 From HR_ChangeRole CR  
				 Where RoleID_id=@RoleId  
				 And RoleIdTarget_id=@RoleIdTarget  
				 And Isnull(LevelId_id,0)=Isnull(@LevelId,0)  
				 And Isnull(LevelIdTarget_id,0)=Isnull(@LevelIdTarget,0)  
				 And Superior=@Superior  
				 And SuperiorTarget=@SuperiorTarget)  
				Select Education,Educator,Evaluation,PmChange,ITChange,RequestGap
				,ReEvaluation,Case When ReEvaluation = 1 Then IsNull(Assessor2,Assessor) Else Assessor2 End Assessor2
				 ,(select FirstName+ ' ' +LastName From Users u where u.UserName=Educator) EducatorName  
				 ,(select FirstName+ ' ' +LastName From Users u where u.UserName=Assessor) AssessorName  
				 ,Case When ReEvaluation = 1 Then 
				 (Select FirstName+ ' ' +LastName From Users u where u.UserName= IsNull(Assessor2,Assessor))
				Else NULL End Assessor2Name, Assessor
				 ,(Case When (Select COUNT(*) From CTE_User)=0 Then  Convert(bit,0) Else Convert(bit,1) End ) As Confirm
				From CTE_User  
				Union 
				Select '' Education,'' Educator,'' Evaluation,'' PmChange ,'' ITChange ,''RequestGap
				,'' ReEvaluation ,'' Assessor2,'' EducatorName,''  AssessorName ,'' Assessor2Name ,'' Assessor, Convert(bit,0) As Confirm
				Where (Select COUNT(*) From CTE_User)=0
			End
		End Else 
		Begin
			Select '' Education,'' Educator,'' Evaluation,'' PmChange ,'' ITChange ,''RequestGap
			,'' ReEvaluation ,'' Assessor2,'' EducatorName,''  AssessorName ,'' Assessor2Name,'' Assessor , Convert(bit,0) As Confirm
		End  
	End Else 
	Begin
		Select '' Education,'' Educator,'' Evaluation,'' PmChange ,'' ITChange ,''RequestGap
		,'' ReEvaluation ,'' Assessor2,'' EducatorName,''  AssessorName ,'' Assessor2Name,'' Assessor, Convert(bit,0) As Confirm
	End  
 End 
End
End
  
  
  
GO
/****** Object:  StoredProcedure [dbo].[HR_GetChoiceAssessorsAndEducators]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE [dbo].[HR_GetChoiceAssessorsAndEducators]   

  @TeamCode CHar(3)----اگر تیم جدید داشت جدید اگر نه قبلی  
  ,@InfoID Int  
 , @RoleIdTarget int----اگر سمت جدید داشت جدید اگر نه قبلی  
 , @LevelIdTarget int----اگر سطح جدید داشت جدید اگر نه قبلی  
 , @SuperiorTarget Bit----اگر ارشدیت جدید داشت جدید اگر نه قبلی  
 , @Temporary Bit=0 -----اگر 1 باشد موقت اگر 0 باشد دائمی است
 ,	@Type bit =0--اگر تایپ 0 بود یعنی تغییر اگر 1 بود یعنی جدید
AS  
BEGIN  
 
	Select 'z.moeini@eit' UserName , 'زهرا معيني امجد' FullName
	Union 
	Select H.UserName,U.FirstName+ ' ' + U.LastName FullName
	From UserTeamRole H
	Inner Join Users U 
	On U.UserName=H.UserName
	Where H.TeamCode = @TeamCode
	And H.UserName <>(Select HR.UserName
	From UserTeamRole HR
	Where HR.ID=@InfoID)
End
GO
/****** Object:  StoredProcedure [dbo].[HR_GetTargetRole]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[HR_GetTargetRole] 

	@ID int,
	@Type bit =0


AS
BEGIN


	if @Type = 0
		Begin
			Select Distinct  RoleId,RoleName,HasLevel,HasSuperior 
			From Role
			Where RoleId Not in (
			Select RG2.RoleID_id
			From  HR_RoleGroupTargetException RTE
			Inner JOin HR_RoleGroup RG
			On RTE.RoleGroup=RG.RoleGroup
			Inner JOin HR_RoleGroup RG2
			On RTE.RoleGroupTarget=RG2.RoleGroup
			Inner JOin UserTeamRole UTR
			On UTR.RoleId=RG.RoleID_id
			Where UTR.ID=@id And RoleId<>127)
		End
		Else 
		Begin
			--Select Distinct RoleId,RoleName,HasLevel,HasSuperior 
			--From Role R
			--Inner Join HR_RoleGroup HG
			--On HG.RoleID_id=R.RoleId
			--Where RoleId<>127 And
			--HG.RoleGroup IN(
			--Select RoleGroup From Role R
			--Inner Join HR_RoleGroup HG
			--On HG.RoleID_id=R.RoleId
			--Where RoleId in (
			--Select  RoleId From UserTeamRole
			--Where UserName In
			--(Select UserName From UserTeamRole
			--WHere ID=@id)))
			Select Distinct  RoleId,RoleName,HasLevel,HasSuperior 
			From Role
			Where RoleId Not in (
			Select RG2.RoleID_id
			From  HR_RoleGroupTargetException RTE
			Inner JOin HR_RoleGroup RG
			On RTE.RoleGroup=RG.RoleGroup
			Inner JOin HR_RoleGroup RG2
			On RTE.RoleGroupTarget=RG2.RoleGroup
			Inner JOin UserTeamRole UTR
			On UTR.RoleId=RG.RoleID_id
			Where UTR.ID=@id And RoleId<>127)

		End

End


GO
/****** Object:  StoredProcedure [dbo].[HR_GetTeamManager]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Nadya Helmi
-- Create date: 1400/11/06
-- Description:	کدتیم و سمت را می گیرد و تیم و مدیر تیم را برمیگرداند


-- Update: 1402-06-28 عرفان رضایی 
-- Description: از جدول تیم اطلاعات استخراج شد

--Update 1402-07-01 محمد سپه کار
-- مقادیر پیش فرض اضافه شد. لیست همه تیم ها را هم در صورت نیاز برمی گرداند
-- =============================================
CREATE PROCEDURE [dbo].[HR_GetTeamManager] 

	@RoleId int=117,
	@TeamCode Char(3) ='ALL'
	---ALL
	---اگر کلی بخوایم

AS
BEGIN
			--;With CTE_TeamManager As (
			--Select  HM.UserName,U.FirstName,U.LastName,
			--TR.TeamCode_id,T.TeamName
			--From HR_organizationchartteamrole TR
			--Inner JOIN HR_organizationchartrole R
			--On R.Id=TR.OrganizationChartRole_id
			--Inner JOin Role Ro
			--On Ro.RoleId=R.RoleId_id
			--Inner Join UserTeamRole HM
			--On TR.ManagerUserName_id=HM.UserName
			--Inner JOin Users U
			--On HM.UserName=U.UserName
			--INner JOIn Team T
			--On T.TeamCode=TR.TeamCode_id
			--Where R.RoleId_id=@RoleId
			--And (TR.TeamCode_id=@TeamCode Or @TeamCode='ALL')
			--Union 
			--Select  HM.UserName,U.FirstName,U.LastName,
			--H.TeamCode,T.TeamName
			--From UserTeamRole H
			--INner JOIn Team T
			--On T.TeamCode=H.TeamCode
			--Inner Join UserTeamRole HM
			--On H.ManagerUserName_id=HM.UserName
			--Inner JOin Users U
			--On HM.UserName=U.UserName
			--Where H.RoleId=@RoleId
			--And (H.TeamCode=@TeamCode Or @TeamCode='ALL')
			--)
			--Select * From CTE_TeamManager


			
			-- اگر تستر باشد
			IF @RoleId in (72 ,55)
			begin 
				
				select UserName, FirstName, LastName, TeamCode TeamCode_id, TeamName
				from Team T
				inner join Users U on T.TestManager_id = U.UserName
				where (T.TeamCode = @TeamCode Or @TeamCode = 'ALL') And T.IsActive = 1

				
			end
			-- اگر پشتیان باشد

			ELSE IF @RoleId = 69  
			begin 
				select UserName, FirstName, LastName, TeamCode TeamCode_id, TeamName
				from Team T
				inner join Users U on T.SupportManager_id = U.UserName
				where (T.TeamCode = @TeamCode Or @TeamCode = 'ALL') And T.IsActive = 1


				
			end

			-- اگر برنامه نویس یا هر سمت دیگری باشد
			
			ELSE 
			begin 
				select UserName, FirstName, LastName, TeamCode TeamCode_id, TeamName
				from Team T
				inner join Users U on T.GeneralManager_id = U.UserName
				where (T.TeamCode = @TeamCode Or @TeamCode = 'ALL') And T.IsActive = 1


				
			end
		

End

GO
/****** Object:  StoredProcedure [dbo].[HR_ImportData]    Script Date: 5/17/2025 4:43:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mohammad Sepahkar
-- Create date: 1401-12-06
-- Description:	این تابع اطلاعات مربوط به کارکرد افراد را از سیستم ارزیابی می گیرد که آن سیستم نیز از سیستم چارگون می گیرد
-- =============================================
CREATE PROCEDURE [dbo].[HR_ImportData] 
	@YearNumber int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	Declare @CurrentDate varchar(10)
	--اگر شماره سال ارسال نشده باشد، سال جاری را به دست می آوریم
	if @YearNumber = 0
	Begin
		Set @CurrentDate = dbo.Date_MiladiToShamsi(GETDATE())
		--اکنون شماره سال را به دست می آوریم
		if LEN(@CurrentDate) = 10
			Set @YearNumber = CAST(LEFT(@CurrentDate, 4)  as int)
	End



	Declare @WorkTime Table ([PersonnelCode] [varchar](10) NOT NULL,
	[YearNo] [smallint] NOT NULL,
	[MonthNo] [tinyint] NOT NULL,
	[WorkHours] [varchar](10) NULL,
	[RemoteHours] [varchar](10) NULL,
	[RemoteDays] [tinyint] NULL,
	[OverTime] [varchar](10) NULL,
	[DeductionTime] [varchar](10) NULL,
	[OffTimeHourly] [varchar](10) NULL,
	[OffTimeDaily] [int] NULL,
	[UserName] [varchar](100) NULL)

	Insert into @WorkTime
	([PersonnelCode],[YearNo],[MonthNo],[WorkHours]
	,[RemoteHours],[RemoteDays],[OverTime]
	,[DeductionTime],[OffTimeHourly],[OffTimeDaily])
	SELECT [PersonnelCode]
		,[YearNo]
		,[MonthNo]
		,[WorkHours]
		,[RemoteHours]
		,[RemoteDays]
		,[OverTime]
		,[DeductionTime]
		,[OffTimeHourly]
		,[OffTimeDaily]
	FROM [Evaluation].[dbo].[EVA_WorkTime] 
	Where [YearNo] = @YearNumber

	Update @WorkTime
	Set username = U.Username2
	From @WorkTime W
	Inner Join Users U
	On NationalCode = W.PersonnelCode
	
	--اکنون داده های مربوط به آن سال را پاک می کنیم
	Delete WorkTime
	Where YearNo = @YearNumber
	
	Insert into WorkTime ([PersonnelCode],[YearNo],[MonthNo],[WorkHours]
	,[RemoteHours],[RemoteDays],[OverTime]
	,[DeductionTime],[OffTimeHourly],[OffTimeDaily],UserName)
	Select [PersonnelCode],[YearNo],[MonthNo],[WorkHours]
	,[RemoteHours],[RemoteDays],[OverTime]
	,[DeductionTime],[OffTimeHourly],[OffTimeDaily],UserName
	From @WorkTime



END
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = -240
         Left = 0
      End
      Begin Tables = 
         Begin Table = "UTR"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 257
               Right = 290
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "R"
            Begin Extent = 
               Top = 19
               Left = 509
               Bottom = 182
               Right = 703
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "T"
            Begin Extent = 
               Top = 343
               Left = 48
               Bottom = 506
               Right = 274
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "RL"
            Begin Extent = 
               Top = 511
               Left = 48
               Bottom = 630
               Right = 242
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ChangeUserTeamRole'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ChangeUserTeamRole'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "rg"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 215
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "utr"
            Begin Extent = 
               Top = 6
               Left = 253
               Bottom = 136
               Right = 459
            End
            DisplayFlags = 280
            TopColumn = 6
         End
         Begin Table = "u"
            Begin Extent = 
               Top = 138
               Left = 38
               Bottom = 268
               Right = 239
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t"
            Begin Extent = 
               Top = 270
               Left = 38
               Bottom = 400
               Right = 231
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "r"
            Begin Extent = 
               Top = 138
               Left = 277
               Bottom = 268
               Right = 447
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'KeyMembers'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'KeyMembers'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "std"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 248
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t"
            Begin Extent = 
               Top = 138
               Left = 38
               Bottom = 268
               Right = 231
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "tc"
            Begin Extent = 
               Top = 6
               Left = 286
               Bottom = 102
               Right = 456
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'TeamInformation'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'TeamInformation'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = -120
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'UserTeamRoleAll'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'UserTeamRoleAll'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_AllUserList'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_AllUserList'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "g"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 102
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ug"
            Begin Extent = 
               Top = 6
               Left = 246
               Bottom = 119
               Right = 416
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "u"
            Begin Extent = 
               Top = 102
               Left = 38
               Bottom = 232
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "P"
            Begin Extent = 
               Top = 130
               Left = 666
               Bottom = 260
               Right = 836
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 3855
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_PagePermission'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_PagePermission'
GO
