/*
Найти значение числа пи путём бросания короткой иглы. Эта задача известна как задача Бюффона https://ru.wikipedia.org/wiki/%D0%97%D0%B0%D0%B4%D0%B0%D1%87%D0%B0_%D0%91%D1%8E%D1%84%D1%84%D0%BE%D0%BD%D0%B0_%D0%BE_%D0%B1%D1%80%D0%BE%D1%81%D0%B0%D0%BD%D0%B8%D0%B8_%D0%B8%D0%B3%D0%BB%D1%8B
*/

-- Функция вычисляет определитель матрицы 2x2
CREATE FUNCTION dbo.det(@a11 AS float, @a12 AS float, @a21 AS float, @a22 AS float)
RETURNS float
AS
BEGIN
	RETURN @a11 * @a22 - @a21 * @a12
END
GO

DECLARE @n int = 150 -- Количество испытаний
DECLARE @L float = 3 -- Длина иглы
DECLARE @r float = 4 -- Расстояние между параллельными прямыми

-- Координаты концов параллельной линии
DECLARE @X3 float = -@L
DECLARE @Y3 float = @r
DECLARE @X4 float = 1 + @L
DECLARE @Y4 float = @Y3

-- Моделируем случайное распределение координат одного из концов иглы и угла
SELECT TOP (@n)
	x = RAND(CHECKSUM(NEWID())),
	y = @r * RAND(CHECKSUM(NEWID())),
	phi = PI() * RAND(CHECKSUM(NEWID()))
INTO dbo.t
FROM sys.all_objects AS s1 CROSS JOIN sys.all_objects AS s2
OPTION (MAXDOP 1)

;
WITH

-- Дополняем таблицу координатами другого конца иглы
p
AS (
	SELECT x AS x1, y AS y1, x + @L * COS(phi) AS x2, y + @L * SIN(phi) AS y2 FROM dbo.t
),

-- Дополняем таблицу значениями определителя в знаменателе
c AS (
	SELECT
		x1, y1, x2, y2,
		dbo.det(
			dbo.det(x1, 1, x2, 1),		dbo.det(y1, 1, y2, 1),
			dbo.det(@X3, 1, @X4, 1),	dbo.det(@Y3, 1, @Y4, 1)
		) AS d
	FROM p
),

-- Находим координаты точек пересечения
s AS (
	SELECT
		x1, y1, x2, y2,
		dbo.det(
			dbo.det(x1, y1, x2, y2),		dbo.det(x1, 1, x2, 1),
			dbo.det(@X3, @Y3, @X4, @Y4),	dbo.det(@X3, 1, @X4, 1)
		) / c.d AS x,
		dbo.det(
			dbo.det(x1, y1, x2, y2),		dbo.det(y1, 1, y2, 1),
			dbo.det(@X3, @Y3, @X4, @Y4),	dbo.det(@Y3, 1, @Y4, 1)
		) / c.d AS y
	FROM c WHERE c.d <> 0
),

-- Отсекаем испытания, когда игла не пересекла ни одну из прямых
k AS (
	SELECT x1, y1, x2, y2, x, y FROM s
	WHERE	(
				(
					(x1 <= x AND x <= x2) OR (x2 <= x AND x <= x1)
				)
				AND
				(
					(y1 <= y AND y <= y2) OR (y2 <= y AND y <= y1)
				)
			)
		OR	y1 = 0
		OR	y1 = @r
		OR	y2 = @r
)

-- Находим значение числа пи
SELECT 2 * @L / (@r * COUNT(1) / @n) FROM k

/*
-- Визуализируем распределение
-- Игла
SELECT
	geometry::STGeomFromText(
		'LINESTRING (' +
			CAST(x1 AS nvarchar) + ' ' + 
			CAST(y1 AS nvarchar) + ',' + 
			CAST(x2 AS nvarchar) + ' ' + 
			CAST(y2 AS nvarchar) + 
		')', 0)
FROM k

-- Окрестность точки пересечения иглы с прямой
UNION ALL
SELECT
	geometry::STGeomFromText(
		'LINESTRING (' +
			CAST(x - 0.1 AS nvarchar) + ' ' + 
			CAST(y - 0.1 AS nvarchar) + ',' + 
			CAST(x + 0.1 AS nvarchar) + ' ' + 
			CAST(y - 0.1 AS nvarchar) + ',' +
			CAST(x + 0.1 AS nvarchar) + ' ' + 
			CAST(y + 0.1 AS nvarchar) + ',' +
			CAST(x - 0.1 AS nvarchar) + ' ' + 
			CAST(y + 0.1 AS nvarchar) + ',' +
			CAST(x - 0.1 AS nvarchar) + ' ' + 
			CAST(y - 0.1 AS nvarchar) + 
		')', 0)
FROM k

-- Прямая
UNION ALL
SELECT
	geometry::STGeomFromText(
		'LINESTRING (' +
			CAST(ISNULL(@X3, 0) AS nvarchar) + ' ' + 
			CAST(ISNULL(@Y3, 0) AS nvarchar) + ',' + 
			CAST(ISNULL(@X4, 0) AS nvarchar) + ' ' + 
			CAST(ISNULL(@Y4, 0) AS nvarchar) + 
		')', 0)

-- Ордината
UNION ALL
SELECT
	geometry::STGeomFromText(
		'LINESTRING (' +
			CAST(ISNULL(@X3, 0) AS nvarchar) + ' ' + 
			CAST(ISNULL(0, 0) AS nvarchar) + ',' + 
			CAST(ISNULL(@X4, 0) AS nvarchar) + ' ' + 
			CAST(ISNULL(0, 0) AS nvarchar) + 
		')', 0)
*/

-- Удаляем временные объекты
DROP TABLE dbo.t
DROP FUNCTION dbo.det
