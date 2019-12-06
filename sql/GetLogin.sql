/*****************************
* Скалярная функция (SQLCMD) *
*****************************/
:setvar dbname "<database>"
:setvar schema "dbo"
:setvar name "GetLogin"

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

ALTER FUNCTION [$(schema)].[$(name)]()
RETURNS VARCHAR(255)
AS
BEGIN
  RETURN SUBSTRING(SUSER_SNAME(),PATINDEX('%\%',SUSER_SNAME()) + 1,LEN(SUSER_SNAME()))
END
GO

:exit

/* Использование */
SELECT dbo.GetLogin()
