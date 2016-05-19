/*
Посчитайте сумму продаж нарастающим итогом в разрезе по ProductKey
*/

;
WITH InternetSales (ProductKey, SalesAmount) AS
(
	SELECT ProductKey, SUM(SalesAmount) FROM FactInternetSales GROUP BY ProductKey
)

SELECT
	DimProduct.EnglishProductName AS [Product],
	SUM(SalesAmount) OVER (ORDER BY DimProduct.EnglishProductName, DimProduct.ProductKey) AS [Cumulative Sum]
FROM DimProduct
LEFT JOIN InternetSales ON InternetSales.ProductKey = DimProduct.ProductKey
WHERE InternetSales.SalesAmount IS NOT NULL -- Проданные товары
ORDER BY DimProduct.EnglishProductName
