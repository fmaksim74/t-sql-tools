/*******************************
 * Скалярная функция (SQLCMD)  *
 *                             *
 *******************************/
:setvar dbname "ComplexBank"
:setvar schema "dbo"
:setvar name "IsINN"

USE $(dbname);
GO

IF OBJECT_ID('[$(schema)].[$(name)]', 'FN') IS NULL
  EXEC dbo.sp_executesql @statement = N'CREATE FUNCTION [$(schema)].[$(name)]() RETURNS INT AS BEGIN RETURN NULL END';
GO

IF OBJECT_ID('[$(schema)].[$(name)]', 'FN') IS NOT NULL
BEGIN
  GRANT EXECUTE ON OBJECT::[$(schema)].[$(name)] TO [AllDataChanged];
END;
GO

ALTER FUNCTION [$(schema)].[$(name)]
(
  @value VARCHAR(12)
)
RETURNS VARCHAR(12)
AS
BEGIN
  IF @value IS NULL
    RETURN NULL;

  SET @value = LTRIM(RTRIM(@value));

  IF LEN(@value) NOT IN (10, 12)
    RETURN NULL;
  
  IF PATINDEX('%[^0-9]%', @value) > 0
    RETURN NULL;

  IF LEN(REPLACE(@value, '0','')) = 0
    RETURN NULL;

  IF NOT EXISTS(
                SELECT *
                  FROM (
                        SELECT n10 = (SUM(INN.n * M1.v) % 11) % 10 * IIF(LEN(@value) = 10, 1 , NULL),
                               n11 = (SUM(INN.n * M2.v) % 11) % 10 * IIF(LEN(@value) = 12, 1 , NULL),
                               n12 = (SUM(INN.n * M3.v) % 11) % 10 * IIF(LEN(@value) = 12, 1 , NULL)
                          FROM (VALUES ( 1),( 2),( 3),( 4),( 5),( 6),( 7),( 8),( 9),(10),(11),(12)) AS N(n)
                               OUTER APPLY (SELECT CONVERT(TINYINT, SUBSTRING(@value, N.n, 1))) AS INN(n)
                               LEFT OUTER JOIN (VALUES ( 1, 2),( 2, 4),( 3, 10),( 4,  3),( 5,  5),( 6, 9),( 7, 4),( 8, 6),( 9, 8),(10, 0),(11, 0),(12, 0)) AS M1(n, v) ON M1.n = N.n
                               LEFT OUTER JOIN (VALUES ( 1, 7),( 2, 2),( 3,  4),( 4, 10),( 5,  3),( 6, 5),( 7, 9),( 8, 4),( 9, 6),(10, 8),(11, 0),(12, 0)) AS M2(n, v) ON M2.n = N.n
                               LEFT OUTER JOIN (VALUES ( 1, 3),( 2, 7),( 3,  2),( 4,  4),( 5, 10),( 6, 3),( 7, 5),( 8, 9),( 9, 4),(10, 6),(11, 8),(12, 0)) AS M3(n, v) ON M3.n = N.n
                        ) AS cc
                 WHERE (LEN(@value) = 10 AND CONVERT(VARCHAR, cc.n10) = RIGHT(@value, 1))
                    OR (LEN(@value) = 12 AND CONVERT(VARCHAR, cc.n11) + CONVERT(VARCHAR, cc.n12) = RIGHT(@value, 2))
               )
    RETURN NULL;

  RETURN @value;
END
GO

:exit

/* Тест */
SELECT dbo.IsINN('0000000000');
SELECT dbo.IsINN('7413000161');
SELECT dbo.IsINN('7413000162');

SELECT dbo.IsINN('7412000161');
SELECT dbo.IsINN('7412000161');
SELECT dbo.IsINN('7411003522');
SELECT dbo.IsINN('7451039003');
SELECT dbo.IsINN('744900124385');
SELECT dbo.IsINN('744900850806');
SELECT dbo.IsINN('744800028180');

