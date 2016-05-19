/*
Удалите из таблицы все повторяющиеся строки
*/

declare @t table (fld1 int, fld2 int, fld3 int)  
insert @t select 1 as fld1, 2 as fld2, 3 as fld3 union all select 4, 5, 6 union all select 1, 2, 3  
--select * from @t

/*
-- Вариант 1
DECLARE @p table (fld1 int, fld2 int, fld3 int)
INSERT INTO @p SELECT DISTINCT * FROM @t
DELETE FROM @t
INSERT INTO @t SELECT * FROM @p

SELECT * FROM @t
*/

/*
-- Вариант 2
DECLARE @c table (fld1 int, fld2 int, fld3 int)
 
;
WITH p (num, fld1, fld2, fld3) AS
(
	SELECT
		 ROW_NUMBER() OVER (PARTITION BY fld1, fld2, fld3 ORDER BY fld1, fld2, fld3)
		,fld1, fld2, fld3
	FROM @t
)
INSERT INTO @c SELECT fld1, fld2, fld3 FROM p WHERE num = 1

DELETE FROM @t
INSERT INTO @t SELECT * FROM @c

SELECT * FROM @t
*/

-- Вариант 3
DECLARE @c table (fld1 int, fld2 int, fld3 int)
 
;
WITH p (fld1, fld2, fld3) AS
(
	SELECT MIN(fld1), MIN(fld2), MIN(fld3) FROM @t
	GROUP BY fld1, fld2, fld3
)
INSERT INTO @c SELECT fld1, fld2, fld3 FROM p 

DELETE FROM @t
INSERT INTO @t SELECT * FROM @c

SELECT * FROM @t
