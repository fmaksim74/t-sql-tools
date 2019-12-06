/******************************
* Скалярная функция (SQLCMD)  *
******************************/
:setvar dbname "database"
:setvar schema "dbo"
:setvar name "GetPeriodNameByBounds"

USE $(dbname);
GO

IF OBJECT_ID('[$(schema)].[$(name)]', 'FN') IS NULL
  EXEC dbo.sp_executesql @statement = N'CREATE FUNCTION [$(schema)].[$(name)]() RETURNS INT AS BEGIN RETURN NULL END';
GO

IF OBJECT_ID('[$(schema)].[$(name)]', 'FN') IS NOT NULL
BEGIN
  GRANT EXECUTE ON OBJECT::[$(schema)].[$(name)] TO [public];
END;
GO

ALTER FUNCTION [$(schema)].[$(name)]
(
  @BeginDate DATE,
  @EndDate DATE,
  @MonthName BIT = 0,
  @DayLeadZero BIT = 0
)
RETURNS NVARCHAR(64)
AS
BEGIN
  IF @BeginDate IS NULL OR @EndDate IS NULL OR @BeginDate > @EndDate
    RETURN NULL;

  DECLARE @Result NVARCHAR(64) = NULL,
          @culture NVARCHAR(8) = 'ru-RU';

  WITH begin_bounds AS (
  SELECT dbo.GetPeriodBoundByDate('yy', @BeginDate, 0, DEFAULT) AS LeftBoundYear,
         dbo.GetPeriodBoundByDate('yy', @BeginDate, 1, DEFAULT) AS RightBoundYear,
         dbo.GetPeriodBoundByDate('qq', @BeginDate, 0, DEFAULT) AS LeftBoundQuarter,
         dbo.GetPeriodBoundByDate('qq', @BeginDate, 1, DEFAULT) AS RightBoundQuarter,
         dbo.GetPeriodBoundByDate('mm', @BeginDate, 0, DEFAULT) AS LeftBoundMonth,
         dbo.GetPeriodBoundByDate('mm', @BeginDate, 1, DEFAULT) AS RightBoundMonth)
  , end_bounds AS (
  SELECT dbo.GetPeriodBoundByDate('yy', @EndDate, 0, DEFAULT) AS LeftBoundYear,
         dbo.GetPeriodBoundByDate('yy', @EndDate, 1, DEFAULT) AS RightBoundYear,
         dbo.GetPeriodBoundByDate('qq', @EndDate, 0, DEFAULT) AS LeftBoundQuarter,
         dbo.GetPeriodBoundByDate('qq', @EndDate, 1, DEFAULT) AS RightBoundQuarter,
         dbo.GetPeriodBoundByDate('mm', @EndDate, 0, DEFAULT) AS LeftBoundMonth,
         dbo.GetPeriodBoundByDate('mm', @EndDate, 1, DEFAULT) AS RightBoundMonth)
  , output_text AS (
  SELECT IIF(    @BeginDate = @EndDate,
                 FORMATMESSAGE('%s%s',
                               FORMAT(@BeginDate, IIF(@MonthName > 0, IIF(@DayLeadZero > 0, 'dd MMMM yyyy', 'D'), IIF(@DayLeadZero > 0, 'dd.MM.yyyy', 'd.MM.yyyy')), @culture),
                               IIF(@MonthName > 0 AND @DayLeadZero = 0, '', ' г.')), NULL) AS OneDayText,
         IIF(    bb.LeftBoundMonth = eb.LeftBoundMonth
             AND bb.RightBoundMonth = eb.RightBoundMonth
             AND DATEDIFF(DAY,@BeginDate,@EndDate) < DATEDIFF(DAY,bb.LeftBoundMonth,bb.RightBoundMonth),
                 FORMATMESSAGE('с %s по %s%s',
                               FORMAT(DATEPART(DAY, @BeginDate), IIF(@DayLeadZero > 0, 'd2', 'd'), @culture),
                               FORMAT(@EndDate, IIF(@MonthName > 0, IIF(@DayLeadZero > 0, 'dd MMMM yyyy', 'D'), IIF(@DayLeadZero > 0, 'dd.MM.yyyy', 'd.MM.yyyy')), @culture),
                               IIF(@MonthName > 0 AND @DayLeadZero = 0, '', ' г.')), NULL) AS   LessThanMonthText,
         IIF(    bb.LeftBoundMonth = eb.LeftBoundMonth 
             AND bb.RightBoundMonth = eb.RightBoundMonth
             AND DATEDIFF(DAY,@BeginDate,@EndDate) = DATEDIFF(DAY,bb.LeftBoundMonth,bb.RightBoundMonth),
                 FORMATMESSAGE('%s г.', LOWER(FORMAT(@BeginDate, IIF(@MonthName > 0, 'y', 'MM.yyyy'), @culture))), NULL) AS EqualMonthText,
         IIF(    bb.LeftBoundQuarter = eb.LeftBoundQuarter
             AND bb.RightBoundQuarter = eb.RightBoundQuarter
             AND DATEDIFF(DAY,@BeginDate,@EndDate) < DATEDIFF(DAY,bb.LeftBoundQuarter,bb.RightBoundQuarter),
             FORMATMESSAGE('с %s по %s%s',
                           FORMAT(@BeginDate, IIF(@MonthName > 0, IIF(@DayLeadZero > 0, 'dd MMMM', 'd MMMMM'), IIF(@DayLeadZero > 0, 'dd.MM', 'd.MM')), @culture),
                           FORMAT(@EndDate, IIF(@MonthName > 0, IIF(@DayLeadZero > 0, 'dd MMMM yyyy', 'D'), IIF(@DayLeadZero > 0, 'dd.MM.yyyy', 'd.MM.yyyy')), @culture),
                           IIF(@MonthName > 0 AND @DayLeadZero = 0, '', ' г.')), NULL) AS LessThanQuarterText,
         IIF(    bb.LeftBoundQuarter = eb.LeftBoundQuarter
             AND bb.RightBoundQuarter = eb.RightBoundQuarter
             AND DATEDIFF(DAY,@BeginDate,@EndDate) = DATEDIFF(DAY,bb.LeftBoundQuarter,bb.RightBoundQuarter),
             FORMATMESSAGE('%s квартал %s г.', DATENAME(QUARTER, @BeginDate), FORMAT(@EndDate, 'yyyy', @culture)), NULL) AS EqualQuarterText,
         IIF(    bb.LeftBoundYear = eb.LeftBoundYear
             AND bb.RightBoundYear = eb.RightBoundYear
             AND DATEDIFF(DAY,@BeginDate,@EndDate) < DATEDIFF(DAY,bb.LeftBoundYear,bb.RightBoundYear),
             FORMATMESSAGE('с %s по %s%s',
                           FORMAT(@BeginDate, IIF(@MonthName > 0, IIF(@DayLeadZero > 0, 'dd MMMM', 'd MMMMM'), IIF(@DayLeadZero > 0, 'dd.MM', 'd.MM')), @culture),
                           FORMAT(@EndDate, IIF(@MonthName > 0, IIF(@DayLeadZero > 0, 'dd MMMM yyyy', 'D'), IIF(@DayLeadZero > 0, 'dd.MM.yyyy', 'd.MM.yyyy')), @culture),
                           IIF(@MonthName > 0 AND @DayLeadZero = 0, '', ' г.')), NULL) AS LessThanYearText,
         IIF(    bb.LeftBoundYear = eb.LeftBoundYear
             AND bb.RightBoundYear = eb.RightBoundYear
             AND DATEDIFF(DAY,@BeginDate,@EndDate) = DATEDIFF(DAY,bb.LeftBoundYear,bb.RightBoundYear),
             FORMATMESSAGE('%s г.', FORMAT(@BeginDate, 'yyyy', @culture)), NULL) AS EqualYearText,
         IIF(    bb.LeftBoundYear <> eb.LeftBoundYear
             AND bb.RightBoundYear <> eb.RightBoundYear,
             FORMATMESSAGE('с %s по %s%s',
                           FORMAT(@BeginDate, IIF(@MonthName > 0, IIF(@DayLeadZero > 0, 'dd MMMM yyyy', 'd MMMMM yyyy'), IIF(@DayLeadZero > 0, 'dd.MM.yyyy', 'd.MM.yyyy')), @culture),
                           FORMAT(@EndDate, IIF(@MonthName > 0, IIF(@DayLeadZero > 0, 'dd MMMM yyyy', 'D'), IIF(@DayLeadZero > 0, 'dd.MM.yyyy', 'd.MM.yyyy')), @culture),
                           IIF(@MonthName > 0 AND @DayLeadZero = 0, '', ' г.')), NULL) AS MoreThanYear
    FROM begin_bounds AS bb, end_bounds AS eb)
   SELECT @Result = COALESCE(OneDayText, LessThanMonthText, EqualMonthText, LessThanQuarterText, EqualQuarterText, LessThanYearText, EqualYearText, MoreThanYear, NULL)
     FROM output_text;
  RETURN @Result;
END
GO

:exit

/* Использование */
-- Получение текстового представления диапазона дат
--один день
SELECT dbo.sf_getPeriodNameByBounds('2019-04-05','2019-04-05',0, 0) -- 5.04.2019 г.
SELECT dbo.sf_getPeriodNameByBounds('2019-04-05','2019-04-05',1, 0) -- 5 апреля 2019 г.
SELECT dbo.sf_getPeriodNameByBounds('2019-04-05','2019-04-05',0, 1) -- 05.04.2019 г.
SELECT dbo.sf_getPeriodNameByBounds('2019-04-05','2019-04-05',1, 1) -- 05 апреля 2019 г.

--меньше месяца
SELECT dbo.sf_getPeriodNameByBounds('2019-01-01','2019-01-09',0, 0) -- с 1 по 9.01.2019 г.
SELECT dbo.sf_getPeriodNameByBounds('2019-01-01','2019-01-09',1, 0) -- с 1 по 9 января 2019 г.
SELECT dbo.sf_getPeriodNameByBounds('2019-01-01','2019-01-09',0, 1) -- с 01 по 09.01.2019 г.
SELECT dbo.sf_getPeriodNameByBounds('2019-01-01','2019-01-09',1, 1) -- с 01 по 09 января 2019 г.

--месяц
SELECT dbo.sf_getPeriodNameByBounds('2019-01-01','2019-01-31',0, DEFAULT) -- 01.2019 г.
SELECT dbo.sf_getPeriodNameByBounds('2019-01-01','2019-01-31',1, DEFAULT) -- январь 2019 г.

--меньше квартала
SELECT dbo.sf_getPeriodNameByBounds('2019-01-01','2019-03-05',0, 0) -- с 1.01 по 5.03.2019 г.
SELECT dbo.sf_getPeriodNameByBounds('2019-01-01','2019-03-05',1, 0) -- с 1 января по 5 марта 2019 г.
SELECT dbo.sf_getPeriodNameByBounds('2019-01-01','2019-03-05',0, 1) -- с 01.01 по 05.03.2019 г.
SELECT dbo.sf_getPeriodNameByBounds('2019-01-01','2019-03-05',1, 1) -- с 01 января по 05 марта 2019 г.

--квартал
SELECT dbo.sf_getPeriodNameByBounds('2019-01-01','2019-03-31',DEFAULT, DEFAULT)  -- 1 квартал 2019 г.

--меньше года
SELECT dbo.sf_getPeriodNameByBounds('2019-01-01','2019-06-05',0, 0) -- с 1.01 по 5.06.2019 г.
SELECT dbo.sf_getPeriodNameByBounds('2019-01-01','2019-06-05',1, 0) -- с 1 января по 5 июня 2019 г.
SELECT dbo.sf_getPeriodNameByBounds('2019-01-01','2019-06-05',0, 1) -- с 01.01 по 05.06.2019 г.
SELECT dbo.sf_getPeriodNameByBounds('2019-01-01','2019-06-05',1, 1) -- с 01 января по 05 июня 2019 г.

--год
SELECT dbo.sf_getPeriodNameByBounds('2019-01-01','2019-12-31',DEFAULT, DEFAULT) -- 2019 г.

--больше года
SELECT dbo.sf_getPeriodNameByBounds('2018-04-05','2019-06-05',0, 0) -- с 5.04.2018 по 5.06.2019 г.
SELECT dbo.sf_getPeriodNameByBounds('2018-04-05','2019-06-05',1, 0) -- с 5 апреля 2018 по 5 июня 2019 г.
SELECT dbo.sf_getPeriodNameByBounds('2018-04-05','2019-06-05',0, 1) -- с 05.04.2018 по 05.06.2019 г.
SELECT dbo.sf_getPeriodNameByBounds('2018-04-05','2019-06-05',1, 1) -- с 05 апреля 2018 по 05 июня 2019 г.

