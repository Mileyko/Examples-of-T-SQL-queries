/*
Посчитайте по таблице FactInternetSales скользящее среднее по продажам (поле SalesAmount) за окно в 3 дня (время в поле OrderDate)
*/

DECLARE @FromDate datetime = '20101227'
DECLARE @ToDate datetime = '20101231'

DECLARE @InternetSales table (OrderDate datetime, SalesAmount money)
INSERT INTO @InternetSales
SELECT
	DimDate.FullDateAlternateKey,
	SUM(FactInternetSales.SalesAmount)
FROM DimDate
LEFT JOIN FactInternetSales ON FactInternetSales.OrderDateKey = DimDate.DateKey
WHERE DimDate.FullDateAlternateKey BETWEEN DATEADD(D, -1, @FromDate) AND DATEADD(D, 1, @ToDate)
GROUP BY DimDate.FullDateAlternateKey

;
WITH
t (RowNum, OrderDate, SalesAmount) AS
(
	SELECT ROW_NUMBER() OVER (ORDER BY OrderDate), OrderDate, SalesAmount FROM @InternetSales
),

r (OrderDate, [Sales Amount], [Moving Average]) AS
(
	SELECT
		t.OrderDate,
		t.SalesAmount,
		CASE
			WHEN [Count Lag] + [Count Curr] + [Count Lead] = 0 THEN
				NULL
			ELSE
				([Sales Amount Lag] + [Sales Amount Curr] + [Sales Amount Lead]) / ([Count Lag] + [Count Curr] + [Count Lead])
		END
	FROM t t
	CROSS APPLY
	(
		SELECT
			ISNULL(SUM(SalesAmount), 0) AS [Sales Amount Lag],
			COUNT(SalesAmount) AS [Count Lag]
		FROM t t_lag
		WHERE t_lag.RowNum < t.RowNum AND t_lag.RowNum >= t.RowNum - 1
	) lag
	CROSS APPLY
	(
		SELECT
			ISNULL(SUM(SalesAmount), 0) AS [Sales Amount Curr],
			COUNT(SalesAmount) AS [Count Curr]
		FROM t t_curr
		WHERE t_curr.RowNum = t.RowNum
	) curr
	CROSS APPLY
	(
		SELECT
			ISNULL(SUM(SalesAmount), 0) AS [Sales Amount Lead],
			COUNT(SalesAmount) AS [Count Lead]
		FROM t t_lead
		WHERE t_lead.RowNum > t.RowNum AND t_lead.RowNum <= t.RowNum + 1
	) lead
)

SELECT * FROM r WHERE OrderDate BETWEEN @FromDate AND @ToDate ORDER BY OrderDate


/*
-- Для Microsoft SQL Server 2012 и старше
;
WITH r (OrderDate, [Sales Amount], [Moving Average]) AS
(
	SELECT
		OrderDate,
		SalesAmount,
		AVG(SalesAmount) OVER (ORDER BY OrderDate ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING)
	FROM @InternetSales
)

SELECT * FROM r WHERE OrderDate BETWEEN @FromDate AND @ToDate ORDER BY OrderDate
*/
