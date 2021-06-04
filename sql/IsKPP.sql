/*******************************
 * Скалярная функция (SQLCMD)  *
 *                             *
 *******************************/
:setvar dbname "ComplexBank"
:setvar schema "dbo"
:setvar name "IsKPP"

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
  @value VARCHAR(9)
)
RETURNS VARCHAR(9)
AS
BEGIN
  IF @value IS NULL
    RETURN NULL;

  SET @value = LTRIM(RTRIM(@value));

  IF LEN(REPLACE(@value, '0','')) = 0
    RETURN NULL;

  IF @value NOT LIKE '[0-9][0-9][0-9][0-9][0-9A-Z][0-9A-Z][0-9][0-9][0-9]'
    RETURN NULL;

  RETURN @value;
END
GO

:exit

/* Тест */
SELECT dbo.IsKPP('0000000000');
SELECT dbo.IsKPP('7413000161');
SELECT dbo.IsKPP('7413000162');

SELECT dbo.IsKPP('7412000161');
SELECT dbo.IsKPP('7412000161');
SELECT dbo.IsKPP('7411003522');
SELECT dbo.IsKPP('7451039003');
SELECT dbo.IsKPP('744900124385');
SELECT dbo.IsKPP('744900850806');
SELECT dbo.IsKPP('744800028180');

