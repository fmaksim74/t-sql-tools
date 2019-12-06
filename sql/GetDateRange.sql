/******************************
* Табличная функция (SQLCMD)  *
******************************/
:setvar dbname "database"
:setvar schema "dbo"
:setvar name "GetDateRange"

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
  @Increment CHAR(1),
  @StartDate DATETIME,
  @EndDate DATETIME
)
RETURNS @Range TABLE ([Date] DATETIME)
AS 
BEGIN
      ;WITH cteRange ([Date]) AS (
            SELECT @StartDate
            UNION ALL
            SELECT 
                  CASE
                        WHEN @Increment = 'd' THEN DATEADD(dd, 1, [Date])
                        WHEN @Increment = 'w' THEN DATEADD(ww, 1, [Date])
                        WHEN @Increment = 'm' THEN DATEADD(mm, 1, [Date])
                        WHEN @Increment = 'q' THEN DATEADD(qq, 1, [Date])
                        WHEN @Increment = 'y' THEN DATEADD(yy, 1, [Date])
                  END
            FROM cteRange
            WHERE [Date] < @EndDate)
      INSERT INTO @Range ([Date])
      SELECT [Date]
      FROM cteRange
      WHERE [Date] < @EndDate
/*      UNION 
      SELECT @EndDate AS [Date] */
      OPTION (MAXRECURSION 3660);
      RETURN
END
GO

:exit

/* Использование */
SELECT * FROM stf_getDateRange('m', '20140105', '20141231')
--PRINT DATEDIFF(dd,  '20200101', '20210101')
