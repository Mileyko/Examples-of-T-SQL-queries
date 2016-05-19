/*
Вывести список всех клиентов (DimCustomer) вместе с их тремя наиболее дорогими (FactInternetSales.SalesAmount) заказами
*/

SELECT
	 DimCustomer.FirstName + ISNULL(' ' + DimCustomer.MiddleName + '.', '') + ' ' + DimCustomer.LastName AS [Full Name],
	 [Sales Order Number],
	 [Internet Sales Amount]
FROM DimCustomer DimCustomer
CROSS APPLY
(
	SELECT TOP 3
		FactInternetSales.SalesOrderNumber AS [Sales Order Number],
		SUM(FactInternetSales.SalesAmount) AS [Internet Sales Amount]
	FROM FactInternetSales
	WHERE FactInternetSales.CustomerKey = DimCustomer.CustomerKey
	GROUP BY FactInternetSales.SalesOrderNumber
	ORDER BY [Internet Sales Amount] DESC
) FactInternetSales
ORDER BY [Full Name]
