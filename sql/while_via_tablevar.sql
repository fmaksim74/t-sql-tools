DECLARE @t TABLE (N INT, ID INT);

INSERT INTO @t (N, ID)
  VALUES (1,1),(2,2),(3,3),(4,4),(5,5),(6,6);

/*SELECT ROW_NUMBER() over (order by id) AS I, N, ID
  FROM @t;*/

DECLARE @n INT = 1, @c INT, @v INT;

SELECT @c = COUNT(*) FROM @t;

WHILE @n <= @c
BEGIN
  SELECT @v = ID, @n += 1 FROM @t WHERE N = @n;
  PRINT @v;
END