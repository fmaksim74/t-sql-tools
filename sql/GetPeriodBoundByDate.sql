/*****************************
* Скалярная функция (SQLCMD) *
*****************************/
:setvar dbname "test"
:setvar schema "dbo"
:setvar name "GetPeriodBoundByDate"

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
  @datepart NVARCHAR(8),
  @date DATE,
  @rside BIT = 0,
  @shift INT = 0)
RETURNS DATE
AS
BEGIN
  IF @datepart IS NULL OR @date IS NULL
    RETURN NULL;

  DECLARE @result DATE;

  SELECT @result =
  CASE
    WHEN @datepart IN ('year','yy','yyyy')
      THEN DATEADD(YEAR, @shift,
                   IIF(@rside = 0,
                       DATEFROMPARTS(DATEPART(YEAR, @date), 1, 1),
                       EOMONTH(DATEFROMPARTS(DATEPART(YEAR, @date), 12, 1))))
    WHEN @datepart IN ('quarter','qq','q')
      THEN DATEADD(QUARTER, @shift,
                   IIF(@rside = 0,
                       DATEFROMPARTS(DATEPART(YEAR, @date), DATEPART(QUARTER, @date) * 3 - 2, 1),
                       EOMONTH(DATEFROMPARTS(DATEPART(YEAR, @date), DATEPART(QUARTER, @date) * 3, 1))))
    WHEN @datepart IN ('month','mm','m')
      THEN IIF(@rside = 0,
               DATEFROMPARTS(DATEPART(YEAR, @date), DATEPART(MONTH, DATEADD(MONTH, @shift, @date)), 1),
               EOMONTH(DATEFROMPARTS(DATEPART(YEAR, DATEADD(MONTH, @shift, @date)),
                                     DATEPART(MONTH, DATEADD(MONTH, @shift, @date)),1)))
    WHEN @datepart IN ('week','wk','ww')
      THEN DATEADD(week, @shift, 
                   IIF(@rside = 0,
                       DATEADD(DAY, (-1) * DATEPART(weekday,@date) + 1, @date),
                       DATEADD(DAY, (-1) * DATEPART(weekday,@date) + 7, @date)))
    ELSE NULL
  END;

  RETURN @result;
END
GO

:exit

/* Использование */
DECLARE @date DATE = '20200210', @shift INT = 0;

SELECT PART='YEAR',
       [SHIFT] = FORMATMESSAGE('CURRENT + ( %d )', @shift),
       YB=dbo.sf_GetPeriodBoundByDate('yy', @date, 0, @shift), -- начало текущего года
       YE=dbo.sf_GetPeriodBoundByDate('yy', @date, 1, @shift)  -- конец текущего года
UNION ALL
SELECT PART='QUARTER',
       [SHIFT] = FORMATMESSAGE('CURRENT + ( %d )', @shift),
       QB=dbo.sf_GetPeriodBoundByDate('qq', @date, 0, @shift), -- начало текущего квартала
       QE=dbo.sf_GetPeriodBoundByDate('qq', @date, 1, @shift)  -- конец текущего квартала
UNION ALL
SELECT PART='WEEK',
       [SHIFT] = FORMATMESSAGE('CURRENT + ( %d )', @shift),
       WB=dbo.sf_GetPeriodBoundByDate('ww', @date, 0, @shift), -- начало текущей недели
       WE=dbo.sf_GetPeriodBoundByDate('ww', @date, 1, @shift)  -- конец текущей недели
UNION ALL
SELECT PART='MONTH',
       [SHIFT] = FORMATMESSAGE('CURRENT + ( %d )', @shift),
       MB=dbo.sf_GetPeriodBoundByDate('mm', @date, 0, @shift), -- начало текущего месяца
       ME=dbo.sf_GetPeriodBoundByDate('mm', @date, 1, @shift)  -- конец текущего месяца