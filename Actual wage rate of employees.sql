/*
Найдите последнюю ставку и дату изменения ставки для каждого сотрудника

Например, для сотрудника с кодом BusinessEntityID 16 в таблице HumanResources.EmployeePayHistory есть три разных часовых ставки:
16	2002-01-20 00:00:00.000	24,00
16	2003-08-16 00:00:00.000	28,75
16	2006-06-01 00:00:00.000	37,50

Для этого сотрудника запрос должен вернуть:
16	David Bradley	37,50	2006-06-01 00:00:00.000
*/

-- Вариант 0
SELECT 
		p.BusinessEntityID AS [ID]
	,	p.FirstName + ' ' + p.LastName AS [Имя]
	,	(
			SELECT TOP 1 eph1.Rate
			FROM HumanResources.EmployeePayHistory AS eph1
			WHERE eph1.BusinessEntityID = p.BusinessEntityID
			ORDER BY eph1.RateChangeDate DESC
		) AS [Посл. ставка]
	,	(
			SELECT TOP 1 eph2.RateChangeDate
			FROM HumanResources.EmployeePayHistory AS eph2
			WHERE eph2.BusinessEntityID = p.BusinessEntityID
			ORDER BY eph2.RateChangeDate DESC
		) AS [Дата назн. ставки]
FROM Person.Person AS p
--WHERE		p.BusinessEntityID = 16
ORDER BY [ID]


-- Вариант 1
SELECT
		p.BusinessEntityID AS [ID]
	,	p.FirstName + ' ' + p.LastName AS [Имя]
	,	T.Rate AS [Посл. ставка]
	,	T.RateChangeDate AS [Дата назн. ставки]
FROM Person.Person AS p

LEFT JOIN
(
	SELECT eph.BusinessEntityID, eph.Rate, eph.RateChangeDate
	FROM HumanResources.EmployeePayHistory AS eph

	JOIN
	(
		SELECT
				EmployeePayHistory.BusinessEntityID
			,	MAX(EmployeePayHistory.RateChangeDate) AS RateChangeLastDate
		FROM HumanResources.EmployeePayHistory AS EmployeePayHistory
		GROUP BY EmployeePayHistory.BusinessEntityID
	) AS eph1
	ON		eph1.BusinessEntityID = eph.BusinessEntityID
		AND	eph1.RateChangeLastDate = eph.RateChangeDate
) AS T
ON		T.BusinessEntityID = p.BusinessEntityID

--WHERE		p.BusinessEntityID = 16
ORDER BY [ID]


-- Вариант 2
SELECT
		p.BusinessEntityID AS [ID]
	,	p.FirstName + ' ' + p.LastName AS [Имя]
	,	eph.Rate AS [Посл. ставка]
	,	eph.RateChangeDate AS [Дата назн. ставки]
FROM Person.Person AS p

LEFT JOIN HumanResources.EmployeePayHistory AS eph
ON		p.BusinessEntityID = eph.BusinessEntityID
	AND	(
			SELECT COUNT(EmployeePayHistory.BusinessEntityID)
			FROM HumanResources.EmployeePayHistory AS EmployeePayHistory
			WHERE	EmployeePayHistory.BusinessEntityID = eph.BusinessEntityID
				AND	EmployeePayHistory.RateChangeDate >= eph.RateChangeDate
			GROUP BY EmployeePayHistory.BusinessEntityID
	) = 1

--WHERE		p.BusinessEntityID = 16
ORDER BY [ID]


-- Вариант 3. С помощью аналитической функции
SELECT
		p.BusinessEntityID AS [ID]
	,	p.FirstName + ' ' + p.LastName AS [Имя]
	,	T.Rate AS [Посл. ставка]
	,	T.RateChangeDate AS [Дата назн. ставки]
FROM Person.Person AS p

LEFT JOIN
(
	SELECT
			eph.BusinessEntityID
		,	eph.RateChangeDate
		,	eph.Rate
		,	ROW_NUMBER() OVER (PARTITION BY eph.BusinessEntityID ORDER BY eph.RateChangeDate DESC) AS [Row Number]
	FROM HumanResources.EmployeePayHistory AS eph
) AS T
ON		T.BusinessEntityID = p.BusinessEntityID
	AND	T.[Row Number] = 1

--WHERE		p.BusinessEntityID = 16
ORDER BY [ID]


/*
-- Проверка запроса
SELECT * FROM HumanResources.EmployeePayHistory AS EmployeePayHistory
WHERE BusinessEntityID = 16
*/
