/********************************
* Встраиваемая функция (SQLCMD) *
********************************/
:setvar dbname "ComplexBank"
:setvar schema "dbo"
:setvar name "stf_NumberSequence"

USE $(dbname)
GO

IF OBJECT_ID('[$(schema)].[$(name)]', 'IF') IS NULL
  EXEC dbo.sp_executesql @statement = N'CREATE FUNCTION [$(schema)].[$(name)]() RETURNS TABLE AS RETURN SELECT 1 AS COL';
GO

IF OBJECT_ID('[$(schema)].[$(name)]', 'IF') IS NOT NULL
BEGIN
  GRANT SELECT ON OBJECT::[$(schema)].[$(name)] TO [AllDataChanged],[SelectRole];
END;
GO

ALTER FUNCTION [$(schema)].[$(name)]
(
	@Start BIGINT,
  @End   BIGINT
)
RETURNS TABLE AS RETURN
 WITH
  L0   AS(SELECT 1 AS c UNION ALL SELECT 1),
  L1   AS(SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),
  L2   AS(SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),
  L3   AS(SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),
  L4   AS(SELECT 1 AS c FROM L3 AS A CROSS JOIN L3 AS B),
  L5   AS(SELECT 1 AS c FROM L4 AS A CROSS JOIN L4 AS B),
  Nums AS(SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS n FROM L5)
  SELECT n FROM Nums WHERE n BETWEEN @Start AND @End;
GO

:exit

/* Использование */
SELECT * FROM dbo.stf_NumberSequence(3001000000,3001000000);