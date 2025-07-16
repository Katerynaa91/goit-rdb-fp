-- 1. Завантажте дані:
-- - Створіть схему pandemic у базі даних за допомогою SQL-команди.
-- - Оберіть її як схему за замовчуванням за допомогою SQL-команди.
-- - Імпортуйте дані за допомогою Import wizard так.
-- - Як бачите, атрибути Entity та Code постійно повторюються. Позбудьтеся цього за допомогою нормалізації даних.
-- 2. Нормалізуйте таблицю infectious_cases до 3ї нормальної форми. Збережіть у цій же схемі дві таблиці з нормалізованими даними.
-- Виконайте запит SELECT COUNT(*) FROM infectious_cases , щоб ментор міг зрозуміти, скільки записів ви завантажили у базу даних із файла.

CREATE schema pandemic;

use pandemic;
SELECT COUNT(1) FROM infectious_cases;  -- Output: 10521. Окремо додала скріншот з результатом у pdf файлі.

-- Нормалізація. Розділяємо оригінальну таблицю на 2 таблиці: 
-- - countries, яка міститиме id країни, назву країни та код країни;
-- - infectious_cases_new, яка міститиме всі записи з оригінальної таблиці (атрибути для кількості кожного захворювання, рік), 
-- але замість назви та коду країни додамо id країни, що є зовнішнім ключем відносно id країни у новоствореній таблиці countries. 

CREATE TABLE IF NOT EXISTS countries (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    country VARCHAR(255),
    country_code VARCHAR(10)
);

INSERT INTO countries (country, country_code)
SELECT DISTINCT Entity, Code FROM infectious_cases;

CREATE TABLE IF NOT EXISTS infectious_cases_new AS 
SELECT (SELECT c.id FROM countries c WHERE c.country = ic.Entity) AS country_id,
		ic.Year,
		ic.Number_yaws,
		ic.polio_cases,
		ic.cases_guinea_worm,
		ic.Number_rabies,
		ic.Number_malaria,
		ic.Number_hiv,
		ic.Number_tuberculosis,
		ic.Number_smallpox,
		ic.Number_cholera_cases 
FROM infectious_cases ic;

-- 3. Проаналізуйте дані:
-- - Для кожної унікальної комбінації Entity та Code або їх id порахуйте середнє, мінімальне, максимальне значення та суму для атрибута Number_rabies.
-- - Врахуйте, що атрибут Number_rabies може містити порожні значення ‘’ — вам попередньо необхідно їх відфільтрувати.
-- - Результат відсортуйте за порахованим середнім значенням у порядку спадання.
-- - Оберіть тільки 10 рядків для виведення на екран.

SELECT c.country,
	     ROUND(AVG(inf.Number_rabies), 4) AS average,
       MIN(inf.Number_rabies) AS min_number,
       MAX(inf.Number_rabies) AS max_number,
       ROUND(SUM(inf.Number_rabies), 4) AS total_cases_sum
FROM   infectious_cases_new inf
JOIN   countries c ON inf.country_id = c.id
WHERE  inf.Number_rabies IS NOT NULL
GROUP BY 1
ORDER BY average DESC
LIMIT 10;

-- 4. Побудуйте колонку різниці в роках.
-- Для оригінальної або нормованої таблиці для колонки Year побудуйте з використанням вбудованих SQL-функцій:
-- - атрибут, що створює дату першого січня відповідного року (наприклад, якщо атрибут містить значення ’1996’, то значення нового атрибута має бути ‘1996-01-01’),
-- - атрибут, що дорівнює поточній даті,
-- - атрибут, що дорівнює різниці в роках двох вищезгаданих колонок.
-- Перераховувати всі інші атрибути, такі як Number_malaria, не потрібно.

SELECT 
     Year AS original_year,
     MAKEDATE(year, 1) AS original_year_start,
     CURRENT_DATE AS today,
     TIMESTAMPDIFF(YEAR, MAKEDATE(year, 1), CURRENT_DATE) AS years_since_record_date
FROM infectious_cases_new
;

-- 5. Побудуйте власну функцію. Створіть і використайте функцію, що будує такий же атрибут, як і в попередньому завданні:
-- - функція має приймати на вхід значення року, а повертати різницю в роках між поточною датою та датою, створеною з атрибута року (1996 рік → ‘1996-01-01’).

DROP FUNCTION IF EXISTS GetYearsDifference;
DELIMITER //

CREATE FUNCTION GetYearsDifference(start_year INT)  -- YEAR datatype ranges between 1901 and 2155 so better to have INT to avoid errors
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE start_date DATE;
    SET start_date = MAKEDATE(start_year, 1);
    RETURN TIMESTAMPDIFF(YEAR, start_date, CURRENT_DATE);
END //

DELIMITER ;

-- function testing
SELECT GetYearsDifference(2020); 

SELECT 
     Year AS original_year,
     CURRENT_DATE AS today,
     GetYearsDifference(Year) AS years_since_record_date
FROM infectious_cases_new;
