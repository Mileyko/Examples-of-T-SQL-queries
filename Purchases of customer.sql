/*
Даны 2 таблицы:

@Table1 – клиенты%
	Id_Client – уникальный идентификатор клиента,
	Value – размер кредита

@Table2 – покупки:
	Id_Client – уникальный идентификатор клиента,
	Amount – сумма покупки,
	DocDate – дата покупки,
	Caption - наименование покупки
	 
Необходимо вывести все покупки клиента (сумма, дата, наименование) в обратном хронологическом порядке, пока его кредит больше нуля.
В последнюю строку необходимо вывести не сумму покупки, а остаток кредита.
 
Результат:
1 2005-10-24 00:00:00 5.00 qh
1 2005-10-22 00:00:00 3.00 ek
1 2005-10-19 00:00:00 9.00 wj
1 2005-10-18 00:00:00 6.00 tz
1 2005-10-04 00:00:00 1.00 rl
2 2005-10-23 00:00:00 11.00 uc
2 2005-10-21 00:00:00 2.00 iv
3 2005-10-30 00:00:00 2.00 pn
4 2005-10-23 00:00:00 5.00 gr
*/

DECLARE @Table1 table (Id_Client int, Value money) 

INSERT INTO @Table1 (Id_Client, Value) 
SELECT 1, 24
UNION SELECT 2, 13
UNION SELECT 3, 2 
UNION SELECT 4, 5

DECLARE @Table2 table (Id_Client int, DocDate datetime, Amount money, Caption varchar(6))

INSERT INTO @Table2 (Id_Client, Amount, DocDate, Caption) 
SELECT 1, 5, '20051024', 'qh'
UNION SELECT 1, 9,  '20051019', 'wj' 
UNION SELECT 1, 3,  '20051022', 'ek' 
UNION SELECT 1, 8,  '20051004', 'rl'
UNION SELECT 1, 6,  '20051018', 'tz'
UNION SELECT 1, 5,  '20050929', 'yx'
UNION SELECT 2, 11, '20051023', 'uc'
UNION SELECT 2, 6,  '20051021', 'iv'
UNION SELECT 2, 45, '20051018', 'ob'
UNION SELECT 3, 4,  '20051030', 'pn' 
UNION SELECT 3, 2,  '20051028', 'am' 
UNION SELECT 4, 4,  '20051021', 'sq' 
UNION SELECT 4, 6,  '20051023', 'dw' 
UNION SELECT 4, 8,  '20051023', 'fe' 
UNION SELECT 4, 9,  '20051023', 'gr' 


-- Вариант 1
DECLARE @Table2_Num table
(
	 Id_Num int IDENTITY(1, 1)
	,Id_Client int
	,DocDate datetime
	,Amount money
	,Caption varchar(6)
)
INSERT INTO @Table2_Num
SELECT
	 t1.Id_Client
	,t2.DocDate
	,ISNULL(t2.Amount, t1.Value)
	,t2.Caption
FROM @Table1 t1
LEFT JOIN @Table2 t2 ON t2.Id_Client = t1.Id_Client
ORDER BY Id_Client, DocDate DESC

DECLARE @t1 table
(
	 Id_Num int
	,Id_Client int
	,DocDate datetime
	,Amount money
	,Remain money
	,Caption varchar(6)
)
INSERT INTO @t1
SELECT
	 t21.Id_Num
	,t21.Id_Client
	,t21.DocDate
	,t21.Amount
	,t1.Value - SUM(t22.Amount)
	,t21.Caption
FROM @Table2_Num t21
JOIN @Table2_Num t22
ON		t22.Id_Client = t21.Id_Client
	AND	t22.Id_Num <= t21.Id_Num
JOIN @Table1 t1	ON	t1.Id_Client = t21.Id_Client
GROUP BY
	 t21.Id_Num
	,t21.Id_Client
	,t21.DocDate
	,t21.Amount
	,t21.Caption
	,t1.Value

DECLARE @t2 table (Id_Client int, Id_Num int)
INSERT INTO @t2
SELECT Id_Client, MAX(Id_Num) FROM @t1
WHERE	Remain >= 0
GROUP BY Id_Client

UNION ALL
SELECT Id_Client, MIN(Id_Num) FROM @t1
WHERE	Remain < 0
GROUP BY Id_Client

DECLARE @t3 table (Id_Client int, Id_Num int)
INSERT INTO @t3
SELECT Id_Client, MAX(Id_Num) FROM @t2
GROUP BY Id_Client

DECLARE @Res1 table (Id_Client int, DocDate datetime, Amount money, Caption varchar(6))
INSERT INTO @Res1
SELECT
	 t1.Id_Client
	,t1.DocDate
	,t1.Amount + t1.Remain
	,t1.Caption
FROM @t3 t3
JOIN @t1 t1
ON	t1.Id_Num = t3.Id_Num

UNION ALL
SELECT
	 t1.Id_Client
	,t1.DocDate
	,t1.Amount
	,t1.Caption
FROM @t3 t3
JOIN @t1 t1
ON		t1.Id_Client = t3.Id_Client
	AND t1.Id_Num < t3.Id_Num

SELECT * FROM @Res1 ORDER BY Id_Client, DocDate DESC


-- Вариант 2
DECLARE @r1 table
(
	 Id_Client int
	,DocDate datetime
	,Amount money
	,Caption varchar(6)
	,Num int
	,Cnt int
	,Value money
)
INSERT INTO @r1
SELECT
	 t1.Id_Client
	,t2.DocDate
	,t2.Amount
	,t2.Caption
	,ROW_NUMBER() OVER (PARTITION BY t2.Id_Client ORDER BY t2.DocDate DESC)
	,COUNT(t2.Id_Client) OVER (PARTITION BY t2.Id_Client)
	,t1.Value
FROM @Table1 t1
LEFT JOIN @Table2 t2
ON		t2.Id_Client = t1.Id_Client

DECLARE @r2 table
(
	 Id_Client int
	,DocDate datetime
	,Amount money
	,Caption varchar(6)
	,Num int
	,Cnt int
	,Reserved money
)
INSERT INTO @r2
SELECT
	 r11.Id_Client
	,r11.DocDate
	,r11.Amount
	,r11.Caption
	,r11.Num
	,r11.Cnt
	,r11.Value - SUM(r12.Amount)
FROM @r1 r11
JOIN @r1 r12
ON		r12.Id_Client = r11.Id_Client
	AND	r12.Num <= r11.Num
GROUP BY
	 r11.Id_Client
	,r11.DocDate
	,r11.Amount
	,r11.Caption
	,r11.Num
	,r11.Cnt
	,r11.Value

DECLARE @r3 table (Id_Client int, Num int, DocDate datetime, Remain money, Caption varchar(6))
INSERT INTO @r3
SELECT
	 Id_Client
	,ROW_NUMBER() OVER (PARTITION BY Id_Client ORDER BY DocDate DESC)
	,DocDate
	,Reserved + Amount
	,Caption
FROM @r2
WHERE	Reserved < 0
	AND	Num <= Cnt

DECLARE @Res2 table (Id_Client int, DocDate datetime, Amount money, Caption varchar(6))
INSERT INTO @Res2
SELECT Id_Client, DocDate, Reserved, Caption FROM @r2
WHERE	Cnt = 0

UNION ALL
SELECT Id_Client, DocDate, Amount, Caption FROM @r2
WHERE	Reserved > 0
	AND	Num < Cnt

UNION ALL
SELECT Id_Client, DocDate, Remain, Caption FROM @r3
WHERE	Num = 1

SELECT * FROM @Res2 ORDER BY Id_Client, DocDate DESC


-- Вариант 3
DECLARE @Res3 table (Id_Client int, DocDate datetime, Amount money, Caption varchar(6))
DECLARE @Id_Client int
DECLARE @cnt int
DECLARE @i int
DECLARE @DocDate datetime
DECLARE @Amount money
DECLARE	@Caption varchar(6)
DECLARE @Remain money

DECLARE client_cursor CURSOR FOR
SELECT table1.Id_Client, ISNULL(COUNT(table2.DocDate), 0)
FROM @Table1 table1
LEFT JOIN @Table2 table2
ON	table2.Id_Client = table1.Id_Client
GROUP BY table1.Id_Client

OPEN client_cursor
FETCH NEXT FROM client_cursor INTO @Id_Client, @cnt

WHILE @@FETCH_STATUS = 0
BEGIN
	IF @cnt = 0
	BEGIN
		INSERT INTO @Res3
		SELECT
			 table1.Id_Client
			,NULL
			,table1.Value
			,NULL
		FROM @Table1 table1
		WHERE	table1.Id_Client = @Id_Client
	END
	ELSE
	BEGIN
		SET @i = 1
		SELECT @Remain = table1.Value
		FROM @Table1 table1
		WHERE	table1.Id_Client = @Id_Client
		
		DECLARE trans_cursor CURSOR FOR
		SELECT
			 table2.DocDate
			,table2.Amount
			,table2.Caption
		FROM @Table2 table2
		WHERE	table2.Id_Client = @Id_Client
		ORDER BY table2.DocDate DESC

		OPEN trans_cursor
		FETCH NEXT FROM trans_cursor INTO @DocDate, @Amount, @Caption

		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @Remain - @Amount < 0 BREAK
			IF @Remain - @Amount > 0 AND @i < @cnt
			BEGIN
				INSERT INTO @Res3
				SELECT
					 @Id_Client
					,@DocDate
					,@Amount
					,@Caption
			END
			
			SET @Remain = @Remain - @Amount
			SET @i = @i + 1	
			FETCH NEXT FROM trans_cursor INTO @DocDate, @Amount, @Caption
		END
		
		CLOSE trans_cursor
		DEALLOCATE trans_cursor
		
		INSERT INTO @Res3
		SELECT
			 @Id_Client
			,@DocDate
			,@Remain
			,@Caption
	END
	
	FETCH NEXT FROM client_cursor INTO @Id_Client, @cnt
END

CLOSE client_cursor
DEALLOCATE client_cursor

SELECT * FROM @Res3 ORDER BY Id_Client, DocDate DESC


-- Вариант 4
DECLARE @p1 table
(
	 Id_Client int
	,DocDate datetime
	,Amount money
	,Caption varchar(6)
	,Num int
	,Cnt int
	,Reserved money
)
INSERT INTO @p1
SELECT
	 table1.Id_Client
	,table2.DocDate
	,table2.Amount
	,table2.Caption
	,ROW_NUMBER() OVER (PARTITION BY table2.Id_Client ORDER BY table2.DocDate DESC)
	,COUNT(table2.Id_Client) OVER (PARTITION BY table2.Id_Client)
	,ISNULL(table1.Value - SUM(table2.Amount) OVER (PARTITION BY table2.Id_Client ORDER BY table2.DocDate DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), table1.Value)
FROM @Table1 table1
LEFT JOIN @Table2 table2 ON table2.Id_Client = table1.Id_Client

DECLARE @p2 table (Id_Client int, Num int, DocDate datetime, Remain money, Caption varchar(6))
INSERT INTO @p2
SELECT
	 Id_Client
	,ROW_NUMBER() OVER (PARTITION BY Id_Client ORDER BY DocDate DESC)
	,DocDate
	,Reserved + Amount
	,Caption
FROM @p1
WHERE	Reserved < 0
	AND	Num <= Cnt

DECLARE @Res4 table (Id_Client int, DocDate datetime, Amount money, Caption varchar(6))
INSERT INTO @Res4
SELECT Id_Client, DocDate, Reserved, Caption FROM @p1
WHERE	Cnt = 0

UNION ALL
SELECT Id_Client, DocDate, Amount, Caption FROM @p1
WHERE	Reserved > 0
	AND	Num < Cnt

UNION ALL
SELECT Id_Client, DocDate, Remain, Caption FROM @p2
WHERE	Num = 1

SELECT * FROM @Res4 ORDER BY Id_Client, DocDate DESC


-- Вариант 5
;
WITH CTE AS
(
	SELECT *, ROW_NUMBER() OVER (PARTITION BY Id_Client ORDER BY DocDate, Amount) as rn
	FROM @Table2
)
SELECT
	 t2.Id_Client
	,t2.DocDate	
	,CASE WHEN t1.value - x.rt < 0 THEN t1.value - x.rt + t2.Amount ELSE t2.Amount END as Amount,
	Caption
FROM CTE t2
CROSS APPLY
(
	SELECT SUM(Amount) FROM cte WHERE Id_Client = t2.Id_Client and rn >= t2.rn
) x(rt)
JOIN @Table1 t1
ON		t1.Id_Client = t2.Id_Client
WHERE
	t1.value - x.rt + t2.Amount > 0
ORDER BY t2.Id_Client, t2.DocDate DESC
