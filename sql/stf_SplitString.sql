/*******************************
 * Табличная функция (SQLCMD)  *
 *                             *
 *******************************/
:setvar dbname "ComplexBank"
:setvar schema "dbo"
:setvar name "stf_SplitString"

USE $(dbname)
GO

/*
IF OBJECT_ID('[$(schema)].[$(name)]', 'IF') IS NOT NULL
  DROP FUNCTION [$(schema)].[$(name)];
GO
*/

IF OBJECT_ID('[$(schema)].[$(name)]', 'IF') IS NULL
  EXEC dbo.sp_executesql @statement = N'CREATE FUNCTION [$(schema)].[$(name)]() RETURNS TABLE AS RETURN (SELECT 1 AS COL)'
  GRANT SELECT ON OBJECT::[$(schema)].[$(name)] TO [AllDataChanged],[SelectRole];
GO

ALTER FUNCTION [$(schema)].[$(name)]
(
  @String    NVARCHAR(MAX),
  @Delimeter NVARCHAR(1) = N','
)
RETURNS TABLE AS RETURN
WITH plist AS (
SELECT R.N, IIF(P.I - R.N < 0, N, P.I) AS I, IIF(P.I - R.N < 0, 1, P.I - R.N) AS L
  FROM dbo.stf_NumberSequence(1, LEN(@String + @Delimeter + '.') - 1) AS R
       CROSS APPLY(SELECT CHARINDEX(@Delimeter, @String + @Delimeter, R.N) AS I) AS P)
SELECT IIF(LEN(@Delimeter + '.') - 1 = 0, SUBSTRING(@String, MIN(N), MAX(L)), NULLIF(SUBSTRING(@String, MIN(N), MAX(L)), '')) AS Item
  FROM plist GROUP BY I
GO

:exit

/* Использование */
SELECT * FROM stf_SplitString('A,B,C,D,E,F', ',');
SELECT * FROM stf_SplitString('A,BB,C,DD,E,FF',',');
SELECT * FROM stf_SplitString('A B C D E F', ' '); 
SELECT * FROM stf_SplitString('A BB C DD E FF',' ');
SELECT * FROM stf_SplitString('A,,B,C,,D,E,,F', ',');
SELECT * FROM stf_SplitString('A  B C  D E  F', ' ');
SELECT * FROM stf_SplitString(',A,B,C,D,E,F', ',');
SELECT * FROM stf_SplitString('A,B,C,D,E,F,', ',');
SELECT * FROM stf_SplitString(',A,B,C,D,E,F,', ',');
SELECT * FROM stf_SplitString(' A B C D E F', ' ');
SELECT * FROM stf_SplitString('A B C D E F ', ' ');
SELECT * FROM stf_SplitString(' A B C D E F ', ' ');
SELECT * FROM stf_SplitString(',,A,B,C,D,E,F', ',');
SELECT * FROM stf_SplitString('A,B,C,D,E,F,,', ',');
SELECT * FROM stf_SplitString(',,A,B,C,D,E,F,,', ',');
SELECT * FROM stf_SplitString('  A B C D E F', ' '); !
SELECT * FROM stf_SplitString('A B C D E F  ', ' '); !
SELECT * FROM stf_SplitString('  A B C D E F  ', ' '); !
SELECT * FROM stf_SplitString(',,,A,B,,C,D,E,F', ',');
SELECT * FROM stf_SplitString('A,B,,C,D,E,F,,,', ',');
SELECT * FROM stf_SplitString(',,,A,B,,C,D,E,F,,,', ',');
SELECT * FROM stf_SplitString('   A B  C D E F', ' '); !
SELECT * FROM stf_SplitString('A B  C D E F   ', ' '); !
SELECT * FROM stf_SplitString('   A B  C D E F   ', ' '); !
SELECT * FROM stf_SplitString('A,B,C,D,E,F', '');

/* Отладка */
DECLARE @String VARCHAR(MAX)=CONVERT(NVARCHAR(MAX), ',,A,B,CC,D,E,F,,'), @Delimeter NVARCHAR(1) = ','; --L = 15
WITH plist AS (
/*SELECT 1 AS N,
       CHARINDEX(@Delimeter, @String + @Delimeter, 1) AS I, CHARINDEX(@Delimeter, @String + @Delimeter, 2) - CHARINDEX(@Delimeter, @String + @Delimeter, 1) - 1 AS L, CHARINDEX(@Delimeter, @String + @Delimeter, 2) AS I2
UNION ALL*/
SELECT R.N, P1.I1, P2.I2
  FROM dbo.stf_NumberSequence(1, LEN(@String+'.') - 1) AS R
       CROSS APPLY(SELECT CHARINDEX(@Delimeter, @Delimeter + @String + @Delimeter, R.N) AS I1) AS P1
       CROSS APPLY(SELECT CHARINDEX(@Delimeter, @Delimeter + @String + @Delimeter, R.N + 1) AS I2) AS P2
 /*WHERE P1.I1 - R.N <= 0*/)
SELECT N, I1, I2, N-I1 AS L FROM plist;
, r1 AS (
SELECT 
)
/*SELECT MIN(N) AS N, I,
       MAX(L) AS L,
       IIF(LEN(@Delimeter + '.') - 1 = 0, SUBSTRING(@String, MIN(N), MAX(L)), NULLIF(SUBSTRING(@String, MIN(N), MAX(L)), '')) AS Item
  FROM plist GROUP BY I*/
SELECT N, I, L, I2, Item
  FROM plist
 WHERE L = 0;