/*****************************
* Скалярная функция (SQLCMD) *
*****************************/
:setvar dbname "<database>"
:setvar schema "dbo"
:setvar name "GetPeriodEndByDate"

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
  @Date DATE,
  @Frequency INT,
  @Shift INT = 0
)
RETURNS SMALLDATETIME
AS
BEGIN
  RETURN EOMONTH(DATEADD(MONTH, (12 / @Frequency) - 1 + @Shift * (12 / @Frequency), DATEFROMPARTS(YEAR(@Date), (MONTH(@Date) / (12 / @Frequency)) * (12 / @Frequency) + IIF(MONTH(@Date) % (12 / @Frequency) <> 0, 1, 1 - (12 / @Frequency)), 1)));
END
GO

/* Использование */
SELECT dbo.GetPeriodEndByDate(GETDATE(), 4, 0);
