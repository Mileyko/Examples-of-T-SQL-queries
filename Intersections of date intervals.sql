/*
Посчитайте по таблице FactInternetSales скользящее среднее по продажам (поле SalesAmount) за окно в 3 дня (время в поле OrderDate)
*/

DECLARE @t table (StartDate date, EndDate date)
INSERT INTO @t VALUES ('20050101', '20050110'), ('20050108', '20050115')

DECLARE @FromDate date	= (SELECT MIN(StartDate) FROM @t)
DECLARE @ToDate date	= (SELECT MAX(EndDate) FROM @t)

;
WITH p (DateKey) AS
(
	SELECT DateKey FROM DimDate
	LEFT JOIN @t t ON DimDate.FullDateAlternateKey BETWEEN t.StartDate AND t.EndDate
	WHERE DimDate.FullDateAlternateKey BETWEEN @FromDate AND @ToDate
	GROUP BY DateKey
	HAVING COUNT(DimDate.DateKey) > 1
)

SELECT COUNT(DateKey) AS [Кол-во пересечений] FROM p
