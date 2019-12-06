/*****************************
* Скалярная функция (SQLCMD) *
*****************************/
:setvar dbname "ComplexBank"
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
      THEN DATEADD(MONTH, @shift,
                   IIF(@rside = 0,
                       DATEFROMPARTS(DATEPART(YEAR, @date), DATEPART(MONTH, @date), 1),
                       EOMONTH(DATEFROMPARTS(DATEPART(YEAR, @date), DATEPART(MONTH, @date),1))))
    WHEN @datepart IN ('week','wk','ww')
      THEN 
        DATEADD(week, @shift, 
                   IIF(@rside = 0,
                       DATEFROMPARTS(DATEPART(YEAR, @date), DATEPART(MONTH, @date), DATEPART(DAY,@date) - DATEPART(weekday, @date) + 1),
                       DATEADD(DAY, 7, DATEFROMPARTS(DATEPART(YEAR, @date), DATEPART(MONTH, @date), DATEPART(DAY,@date) - DATEPART(weekday, @date)))))
    ELSE NULL
  END;

  RETURN @result;
END
GO

:exit

/* Использование */
SELECT dbo.GetPeriodBoundByDate('yy', GETDATE(), 0, 0) -- начало текущего года
SELECT dbo.GetPeriodBoundByDate('yy', GETDATE(), 1, 0) -- конец текущего года

SELECT dbo.GetPeriodBoundByDate('qq', GETDATE(), 0, 0) -- начало текущего квартала
SELECT dbo.GetPeriodBoundByDate('qq', GETDATE(), 1, 0) -- конец текущего квартала
