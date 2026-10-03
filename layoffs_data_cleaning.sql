-- Data Cleaning BY NOSA


-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null Values or blank Values
-- 4. Remove Any Columns or Rows

-- 1. STEP 1: REMOVING DUPLICATES
SELECT *
FROM layoffs;

CREATE TABLE layoffs_nosa
LIKE layoffs;

SELECT *
FROM layoffs_nosa;

-- inserting the reference table to my new table that was created
INSERT layoffs_nosa
SELECT * FROM layoffs;

-- locating the duplicate rows, you have to use CTEs
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, 
				percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
FROM layoffs_nosa;

WITH duplicateCTE AS
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, 
				percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
FROM layoffs_nosa
)
SELECT * 
FROM duplicateCTE
WHERE row_num > 1;

-- since CTEs can't delete, you have to edit the whole table to add the column --
CREATE TABLE `layoffs_nosa2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * 
FROM layoffs_nosa2;

-- then insert your details from your CTE tabel to this new one--
INSERT INTO layoffs_nosa2
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, 
				percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
FROM layoffs_nosa;

-- due to the fact that you have created the table, now you can delete the row that has a row number more than 1
SELECT * 
FROM layoffs_nosa2
WHERE row_num > 1;

-- GOOD!!!!!!! DUPLICATES HAS BEEN DELEATED!!!


-- STEP 2: STANDARDIZE THE DATASET

SELECT * 
FROM layoffs_nosa2;

-- starting with the company, by trimming it
SELECT company, TRIM(company)
FROM layoffs_nosa2;

-- then, update the company column--
UPDATE layoffs_nosa2
SET company = TRIM(company);

-- Moving to the location column --
SELECT location, TRIM(location)
FROM layoffs_nosa2;

-- then, update the location column--
UPDATE layoffs_nosa2
SET location = TRIM(location);

-- afterwards, moving to the industry column --
SELECT DISTINCT industry
FROM layoffs_nosa2;

-- we can see that 'crypto' has an issue, hence we have to solve that
SELECT industry
FROM layoffs_nosa2
WHERE industry like 'Crypto%';

UPDATE layoffs_nosa2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- working on the country column now --
SELECT DISTINCT country 
FROM layoffs_nosa2;

-- we see that United States needs fixing here, we have to solve that --
SELECT DISTINCT country 
FROM layoffs_nosa2;

SELECT DISTINCT country 
FROM layoffs_nosa2
WHERE country LIKE 'United States%';

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country) -- trailing is just to show that it is following
FROM layoffs_nosa2
WHERE country LIKE 'United States%';

-- then update the table
UPDATE layoffs_nosa2
SET country = TRIM(TRAILING '.' FROM country) 
WHERE country LIKE 'United States%';

-- Now, moving to the date column to solve that --

SELECT *
FROM layoffs_nosa2;

SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y') -- the Y must be in capital letter for accuracy
FROM layoffs_nosa2;

UPDATE layoffs_nosa2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- it still has the data type as text, so we need to solve that by altering the table--
ALTER TABLE layoffs_nosa2
MODIFY COLUMN `date` DATE;

-- GOOD!!!!!!! THE DATESET IS STANDARD!!!


-- STEP 3: REMOVING NULL/BLANKS
-- also start looking at all the columns as well one after the order
SELECT *
FROM layoffs_nosa2;

-- Industry showed that it has blanks--

SELECT *
FROM layoffs_nosa2
WHERE industry IS NULL
OR industry = '';

-- to solve this, we have to first convert the blanks to NULL so everything can work well
UPDATE layoffs_nosa2
SET industry = NULL
where industry = '';

-- we can decide to fill the blank industry when they are in same company with the written industry
-- to do that, we have to join the table together

SELECT t1.industry, t2.industry
FROM layoffs_nosa2 t1
JOIN layoffs_nosa2 t2
	ON t1.company = t2.company
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- then, update the table

UPDATE layoffs_nosa2 t1
JOIN layoffs_nosa2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;
-- GOOD!!!!!!! YOUR BLANKS/NULLS IN THE MAIN DATA HAS BEEN DELETED!!!


-- STEP 4: Delete unwated rows and columns --

-- now, you have to remove the row that is both blank in the total_laid_off and percentage_laid_off, because it is not needed for this data.

select *
FROM layoffs_nosa2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_nosa2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- you now have to delete the row_num that you created before
ALTER TABLE layoffs_nosa2
DROP COLUMN row_num;

select *
FROM layoffs_nosa2;

-- GREAT!!!!!! YOUR DATA IS CLEAN!!




