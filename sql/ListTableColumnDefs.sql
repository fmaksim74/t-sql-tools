SELECT ColumnName = LTRIM(RTRIM(CONVERT(VARCHAR, d.ColumnName))),
       ColumnType = LTRIM(RTRIM(CONVERT(VARCHAR, d.ColumnType))),
       LineEnd = ','
  FROM            sys.tables      AS t
       INNER JOIN sys.all_columns As c ON c.object_id = t.object_id
       OUTER APPLY dbo.stf_getColumnTypeDefinition(t.name, c.name, t.type) d
WHERE t.name = 'tmp_BookOfSale'

