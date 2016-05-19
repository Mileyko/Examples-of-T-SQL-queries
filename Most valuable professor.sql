/*
Найдите преподавателей, которые преподают у всех студентов
*/

SET NOCOUNT ON

/*
Создадим необходимые таблицы и заполним их тестовыми данными.
*/

/*
Преподаватели
*/
IF OBJECT_ID('Teachers', 'U') IS NULL
BEGIN

CREATE TABLE Teachers
(
		t_id int NOT NULL PRIMARY KEY
	,	name nvarchar(250) NOT NULL
)

INSERT INTO Teachers
			SELECT 1, 'Вахрущев Николай Викторович'
UNION ALL	SELECT 2, 'Борисова Надежда Афанасьевна'
UNION ALL	SELECT 3, 'Ипатова Людмила Петровна'
UNION ALL	SELECT 4, 'Плотников Дмитрий Павлович'
UNION ALL	SELECT 5, 'Мкртчан Людмила Григорьевна'

END

/*
Студенты
*/
IF OBJECT_ID('Students', 'U') IS NULL
BEGIN

CREATE TABLE Students
(
		s_id int NOT NULL PRIMARY KEY
	,	name nvarchar(250) NOT NULL
)

INSERT INTO Students
			SELECT 1, 'Абасклов Павел'
UNION ALL	SELECT 2, 'Милейко Александр'
UNION ALL	SELECT 3, 'Милейко Борис'
UNION ALL	SELECT 4, 'Борисова Татьяна'
UNION ALL	SELECT 5, 'Литоренко Вика'
UNION ALL	SELECT 6, 'Лаптев Сергей'
UNION ALL	SELECT 7, 'Чупина Валя'

END

/*
Привязка студента к преподавателю
*/
IF OBJECT_ID('L', 'U') IS NULL
BEGIN

CREATE TABLE L
(
		t_id int NOT NULL
	,	s_id int NOT NULL
	,	CONSTRAINT PK_t_id_s_id PRIMARY KEY (t_id, s_id)
)

INSERT INTO L
			SELECT 1, 1
UNION ALL	SELECT 1, 2
UNION ALL	SELECT 1, 3
UNION ALL	SELECT 1, 4
UNION ALL	SELECT 1, 5
UNION ALL	SELECT 1, 6
UNION ALL	SELECT 1, 7

UNION ALL	SELECT 2, 2
UNION ALL	SELECT 2, 4
UNION ALL	SELECT 2, 6

UNION ALL	SELECT 3, 2
UNION ALL	SELECT 3, 4

UNION ALL	SELECT 4, 1
UNION ALL	SELECT 4, 2
UNION ALL	SELECT 4, 3
UNION ALL	SELECT 4, 4
UNION ALL	SELECT 4, 5
UNION ALL	SELECT 4, 6
UNION ALL	SELECT 4, 7

END

/*
Мы  ожидаем получить следующий результат:

Вахрущев Николай Викторович
Плотников Дмитрий Павлович
*/


-- Вариант 0
/*
Выбираем тех учителей, у которых количество студентов равно общему числу студентов.
*/
SELECT t.name
FROM Teachers AS t
LEFT JOIN L AS l ON l.t_id = t.t_id
GROUP BY t.t_id, t.name
HAVING COUNT(l.s_id) = (SELECT COUNT(s.s_id) FROM Students AS s)


-- Вариант 1
/*
В этом запросе мы составляем список студентов, у которых нет преподавателей. Если у студента 
нет преподавателя, то он попадёт в этот список. Обратно, если у студента есть преподаватель, то 
он не попадёт в этот список. Пустой список студентов для данного преподавателя означает, что 
этот преподаватель закреплён за всеми студентами.

Например, для преподавателя с кодом 2 (Борисова Надежда Афанасьевна) для запроса (2) мы 
можем получить такой список:
Абасклов Павел
Милейко Борис
Литоренко Вика
Чупина Валя

Получается, что эти студенты не закреплены за данным преподавателем. Действительно, за 
Борисовой Надеждой Афанасьевной закреплены только:
Милейко Александр
Борисова Татьяна
Лаптев Сергей

В то же время список для преподавателя с кодом 1 (Вахрущев Николай Викторович) будет пустым 
так как он закреплён за всеми студентами. Поэтому в (1) мы проверяем пустой список или нет и 
если он пустой, то выводим преподавателя.
*/

SELECT teachers.name
FROM Teachers AS teachers
WHERE
	-- (1)
	NOT EXISTS
	(
		-- (2)	
		SELECT 1 FROM Students AS students
		WHERE
			NOT EXISTS
			(
				SELECT 1 FROM L AS l
				WHERE l.t_id = teachers.t_id AND l.s_id = students.s_id
			)
	)


-- Вариант 2
/*
Несмотря на то, что в этом варианте есть конструкция NOT EXISTS здесь применён обратный 
метод решения чем в предыдущем варианте.

Составим таблицу соответствия студентов и преподавателя. Например, для преподавателя с 
кодом 2 мы получим:

Студент			1	2	3	4	5	6	7
Преподаватель	N	2	N	2	N	2	N

Здесь N означает NULL.
Мы видим, что преподаватель с кодом 2 закреплён за студентами с кодами 2, 4 и 6.

Если преподаватель закреплён за всеми студентами, то у нас получится:

Студент			1	2	3	4	5	6	7
Преподаватель	1	1	1	1	1	1	1

Поэтому, мы можем решить проблему следующим образом. Будем составлять список из единиц (2) 
если для преподавателя множество, получаемое в (1), содержит  NULL. Если получаемый список 
не пуст, то это означает, что не все студенты закрплены за этим преподавателем. Обратно, 
если список будет пуст, то за этим преподаватем закреплены все студенты. Собственно, в (3) 
проверяется пустой список (2) или нет. 
*/

SELECT teachers.name
FROM Teachers AS teachers
WHERE
	-- (3)
	NOT EXISTS
	(
		-- (2)
		SELECT 1 FROM 
		(
			-- (1)
			SELECT l.s_id FROM Students AS s
			LEFT JOIN L AS l ON l.t_id = teachers.t_id AND l.s_id = s.s_id
		) s
		WHERE	s.s_id IS NULL
	)


-- Вариант 3
/*
Фактически этот вариант показывает другой вид на метод решения в варианте 0, но в более 
компактной реализации.

Составим декартово произведение студентов и преподавателей. Дополним это произведение 
множеством соответсвия между студентом и преподавателем.

Получим:

				1	2	3	4	5	6	7	Студенты
Преподаватели
1				1	1	1	1	1	1	1
2				N	1	N	1	N	1	N	
3				N	1	N	1	N	N	N
4				1	1	1	1	1	1	1
5				N	N	N	N	N	N	N

Как и выше N означает NULL. Посчитаем количество единиц для каждого преподавателя. Если это 
количество будет равно количеству студентов, то это означает, что за данным преподавателем 
закреплены все студенты.
*/

SELECT t.name
FROM Students AS s
CROSS JOIN Teachers AS t
LEFT JOIN L AS l ON l.s_id = s.s_id AND l.t_id = t.t_id
GROUP BY t.name
HAVING COUNT(l.s_id) = COUNT(s.s_id)


/*
-- Удаляем таблицы
DROP TABLE L
DROP TABLE Students
DROP TABLE Teachers
*/
