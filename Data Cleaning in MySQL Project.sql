-- Data Cleaning

SELECT*
FROM layoffs;
-- first we want to do is create a staging table. This is the one we will work in and clean the data. We want a table with the raw data incase something happenns

CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

INSERT layoffs_staging
SELECT *
FROM layoffs;
	
-- now when we are cleaning data we usually follow a few steps
-- 1. check for duplicates and remove any 
-- 2. standardize data and fix errors
-- 3. Look at null values 
-- 4. remove any columns and rows that are not neccessary

-- 1. Remove duplicates

#First let's check for duplicates


SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company,industry,total_laid_off,percentage_laid_off) AS row_num
FROM layoffs_staging;


WITH duplicate_cte AS 
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE  row_num > 1;

-- let's just look at Oda to confirm

SELECT*
FROM layoffs_staging
WHERE company ='Oda';

-- the solution to deleting the duplicates is creating a new column and adding those row numbers in. Then delete where row numbers are over 1, then delete that column
-- so let's do it!!

CREATE TABLE `layoffs_staging2` (
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
FROM layoffs_staging2
WHERE row_num > 1;



INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions) AS row_num
FROM layoffs_staging;

-- now that we have this we can delete rows where row_num is greater than 1


DELETE 
FROM layoffs_staging2
WHERE row_num > 1;

SELECT * 
FROM  layoffs_staging2;
---------------------------------------------------------------------------------------------------------------------------------------------

-- 2. Standerdizing Data 

-- let's start by checking industry and updating 
SELECT company,TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);
-- if we look at industry it looks like we have some null and empty rows, let's take a look at these 

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- I noticed the Crypto has multiple different variations . We need to standardize that- let's set all to Crypto

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- now that's taken care of
----------------------------------------------------------------------------------------------------------------

-- we also need to look at country 

SELECT DISTINCT country,TRIM(country)
FROM layoffs_staging2
ORDER BY 1;


-- everything looks fine except apparently we have some " United States" and some "Unted States." with a period at the end . Let's standardize this.

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- now if we run this again it is fixed

SELECT DISTINCT country,TRIM(country)
FROM layoffs_staging2
ORDER BY 1;

-- Let's also fix the date columns

SELECT `date`
FROM layoffs_staging2;
-- we can use str to date to update this field
UPDATE layoffs_staging2
SET `date`= STR_TO_DATE(`date`,'%m/%d/%Y');

-- now we can convert the data type properly

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- 3. Look at Null values

SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- we should set the blanks to nulls since those are typically easier to work with

UPDATE layoffs_staging2
SET  industry = NULL 
WHERE industry = '';



SELECT *
FROM layoffs_staging2
WHERE industry IS NULL 
OR industry = '';


SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- it looks like airbnb is a travel, but this one just isn't populated.
-- I'm sure it's the same for the others. What we can dio is 
-- write a query that if there is another row with the same company name, it will update it to the non-null industry values
-- makes it easy so if there were thousands we wouldn't have to manually check them all


SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
  ON t1.company = t2.company
  AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- now we need to populate those nulls if possible


UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

SELECT *
FROM layoffs_staging2;

-- Let's remove any columns and rows we need to

SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;


DELETE  
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;


SELECT *
FROM layoffs_staging2;



ALTER TABLE layoffs_staging2
DROP  COLUMN row_num;









