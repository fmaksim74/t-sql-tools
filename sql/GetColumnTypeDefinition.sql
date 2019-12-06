/*****************************
* Скалярная функция (SQLCMD) *
*****************************/
:setvar dbname "<database>"
:setvar schema "dbo"
:setvar name "GetColumnTypeDefinition"

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
  @ObjectName SYSNAME,
  @ColumnName SYSNAME,
  @ObjectType CHAR(2)= NULL,
  @OnlySysType BIT = 0
)
RETURNS SYSNAME
AS
BEGIN
  DECLARE @Result SYSNAME;
  SELECT TOP 1 
    @Result =  FORMATMESSAGE('%s%s', systy.name,
                             IIF(systy.is_user_defined = 1 , '',
                             CASE
                               WHEN systy.name IN ('bigint','int','smallint','tinyint','bit',
                                                   'money','smallmoney','real','sql_variant',
                                                   'date','datetime','smalldatetime','timestamp',
                                                   'text','ntext','image','sysname',
                                                   'hierarchyid','geometry','rowversion',
                                                   'uniqueidentifier','geography')
                                 THEN ''
                               WHEN systy.name IN ('decimal','numeric')
                                 THEN FORMATMESSAGE('(%d,%d)', sysc.precision, sysc.scale)
                               WHEN systy.name IN ('float')
                                 THEN FORMATMESSAGE('(%d)', sysc.precision)
                               WHEN systy.name IN ('datetime2','datetimeoffset','time')
                                 THEN FORMATMESSAGE('(%d)', sysc.scale)
                               WHEN systy.name IN ('xml')
                                 THEN FORMATMESSAGE('(%s)', IIF(sysc.xml_collection_id > 0,
                                                                sysxsc.name,
                                                                IIF(sysc.is_xml_document = 0,
                                                                    'CONTENT',
                                                                    'DOCUMENT')))
                               ELSE
                                 IIF(sysc.max_length < 0, '(MAX)', FORMATMESSAGE('(%d)', sysc.max_length))
                              END))
    FROM sys.tables AS syst
         INNER JOIN sys.columns AS sysc 
                 ON sysc.object_id = syst.object_id AND sysc.name = @ColumnName
         INNER JOIN sys.types AS systy 
                ON systy.system_type_id = sysc.system_type_id
               AND systy.user_type_id = IIF(@OnlySysType = 1, systy.user_type_id, sysc.user_type_id)
               AND systy.is_user_defined = IIF(@OnlySysType = 1, 0, systy.is_user_defined)
         LEFT OUTER JOIN sys.xml_schema_collections AS sysxsc ON sysxsc.xml_collection_id = sysc.xml_collection_id
   WHERE syst.object_id = IIF(@ObjectType IS NOT NULL, OBJECT_ID(@ObjectName, @ObjectType), OBJECT_ID(@ObjectName));
  RETURN @Result
END
GO

:exit

/* Пример */
SELECT dbo.GetColumnTypeDefinition('dbo.tval_ZayavBuy', 'TransAccount', 'U', 1) AS ColumnType;
