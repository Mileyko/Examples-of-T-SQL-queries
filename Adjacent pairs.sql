/*
Имеется последовательность чисел 1, 2, 3, 5, 6, 9. Выведите все соседние пары, между которыми есть пробелы. 3-5, 6-9
*/

declare @t table (fld int)
insert @t values (1), (2), (3), (5), (6), (9)  
--insert @t values (1), (2), (3), (4), (5), (6), (9)
--insert @t values (1), (4), (9)
--select * from @t

/*
-- Вариант 1
DECLARE @t_1 table (id int, fld int)
INSERT INTO @t_1 SELECT ROW_NUMBER() OVER (ORDER BY fld), fld FROM @t

DECLARE @t_2 table (id int, fld int)
INSERT INTO @t_2
SELECT 1, (SELECT MIN(fld) FROM @t) UNION ALL SELECT ROW_NUMBER() OVER (ORDER BY fld) + 1, fld FROM @t

SELECT t_2.fld AS [Left], t_1.fld AS [Right] FROM @t_1 t_1
JOIN @t_2 t_2 ON t_2.id = t_1.id
WHERE	t_1.fld - t_2.fld > 1
*/

/*
-- Вариант 2
DECLARE @ids table (id int)
SET NOCOUNT ON
DECLARE @i int = (SELECT MIN(fld) FROM @t)
WHILE @i <= (SELECT MAX(fld) FROM @t)
BEGIN
	INSERT INTO @ids VALUES (@i)
	SET @i = @i + 1
END

;
WITH
a (id, fld) AS
(
	SELECT ids.id, t.fld FROM @ids ids
	LEFT JOIN @t t ON t.fld = ids.id
),

n (id, fld) AS
(
	SELECT a.id, a.fld FROM a WHERE a.fld IS NULL
),

l_n (id, fld) AS
(
	SELECT id, (SELECT TOP 1 a.fld FROM a WHERE a.id < n.id ORDER BY a.id DESC) FROM n
),
l (id, fld) AS
(
	SELECT ROW_NUMBER() OVER (ORDER BY l_n.id), fld FROM l_n WHERE fld IS NOT NULL
),

r_n (id, fld) AS
(
	SELECT id, (SELECT TOP 1 a.fld FROM a WHERE a.id > n.id ORDER BY a.id ASC) FROM n
),
r (id, fld) AS
(
	SELECT ROW_NUMBER() OVER (ORDER BY r_n.id), fld FROM r_n WHERE fld IS NOT NULL
)

SELECT l.fld AS [Left], r.fld AS [Right] FROM l
JOIN r ON r.id = l.id
*/


-- Вариант 3
;
WITH p (fld_curr, fld_next) AS
(SELECT t1.fld, (SELECT MIN(t2.fld) FROM @t t2 WHERE t2.fld > t1.fld) FROM @t t1)

SELECT fld_curr AS [Left], fld_next AS [Right] FROM p WHERE fld_next - fld_curr > 1

-- Для Microsoft SQL Server 2012 и старше
/*
;
WITH p (fld_curr, fld_next) AS
(SELECT fld, LEAD(fld) OVER (ORDER BY fld) FROM @t)

SELECT fld_curr AS [Left], fld_next AS [Right] FROM p WHERE fld_next - fld_curr > 1
*/
