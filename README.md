# sql-data-cleaning-layoffs
SQL-based data cleaning and standardization pipeline executed on a global tech layoffs dataset using MySQL.

# Portfolio Case Study: Global Tech Layoffs Data Cleaning & Standardization

**Author:** Nosakhare Osakue

**Tool Stack:** MySQL Workbench 8.0 CE, Relational Database Management System (RDBMS), SQL Data Manipulation Language (DML) & Data Definition Language (DDL)

**Dataset:** Global Tech Layoffs Dataset (`layoffs.csv`)

**SQL Pipeline Script:** [`layoffs_data_cleaning.sql`](./layoffs_data_cleaning.sql)

---

## 1. Executive Summary

This case study documents an end-to-end data cleaning and standardization pipeline executed in **MySQL Workbench 8.0 CE**  on a global tech layoffs dataset (`layoffs.csv`). Raw industry datasets frequently suffer from duplicate entries, inconsistent string formatting, invalid data types, and incomplete records.

Through a structured four-stage cleaning process (Duplicate Removal, Field Standardization, Missing Value Imputation, and Irrelevant Record Removal), the raw dataset was transformed from **2,361 raw records** into a refined analysis-ready dataset of **1,995 valid records**. A total of **5 duplicate rows** were eliminated, **361 incomplete records** missing primary metrics were dropped, and categorical attributes were standardized across global entities.

---

## 2. Business Problem

Raw global layoff reports compiled from public sources contain structural noise, duplicate reports, and missing key financial metrics. Conducting exploratory data analysis (EDA) or executive reporting on uncleaned data leads to distorted metrics—such as inflated headcount loss, skewed industry distribution figures, and broken chronological queries.

To enable reliable downstream business intelligence and macroeconomic reporting, the raw staging data required comprehensive data hygiene and schema enforcement.

---

## 3. Business Context

Tech industry stakeholders, HR strategists, and venture capital firms monitor workforce reduction trends across company funding stages, locations, and industry sectors. Accurate data on total workforce impact (`total_laid_off`), layoff severity (`percentage_laid_off`), and venture backing (`funds_raised_millions`) provides critical signals for talent acquisition planning, market risk assessment, and economic forecasting.

---

## 4. Objectives

* **Identify and eliminate duplicate records** resulting from multi-source report ingestion.
* **Standardize text attributes and categorical values** (trimming whitespace, aligning industry naming conventions, and standardizing geographic fields).
* **Fix data types**, converting string dates into standard SQL `DATE` values.
* **Impute missing categorical fields** using relational self-joins where applicable.
* **Remove unusable records** that lack key quantifiable quantitative metrics.

---

## 5. Dataset and Data Sources

The raw dataset (`layoffs.csv`) consists of **2,361 rows** and **9 columns**:

| Column Name | Raw Data Type | Target Data Type | Description |
| --- | --- | --- | --- |
| `company` | `text` | `VARCHAR/TEXT` | Company name |
| `location` | `text` | `VARCHAR/TEXT` | Headquarters / office location |
| `industry` | `text` | `VARCHAR/TEXT` | Primary business industry sector |
| `total_laid_off` | `int` | `INT` | Absolute count of employees laid off |
| `percentage_laid_off` | `text` | `DECIMAL/FLOAT` | Proportion of total workforce laid off |
| `date` | `text` | `DATE` | Date of layoff event (`MM/DD/YYYY` text) |
| `stage` | `text` | `VARCHAR/TEXT` | Corporate funding stage (e.g., Series A, Post-IPO) |
| `country` | `text` | `VARCHAR/TEXT` | Country of operation |
| `funds_raised_millions` | `int` | `INT` | Total venture capital raised ($ USD Millions) |

---

## 6. Data Quality and Cleaning

The initial quality assessment revealed several key structural issues:

```
+-------------------------------------------------------------------+
| RAW DATA AUDIT (2,361 rows)                                       |
+-------------------------------------------------------------------+
|  [!] 5 Exact Duplicate Records                                    |
|  [!] Unstandardized Strings ('Crypto', 'Crypto Currency', etc.)   |
|  [!] Trailing Punctuation ('United States.')                      |
|  [!] Text-formatted Dates ('m/d/Y')                               |
|  [!] 4 Missing Industry Values (4 records)                        |
|  [!] 362 Records with BOTH total & percentage laid off as NULL    |
+-------------------------------------------------------------------+

```

---

## 7. Methodology / Analytical Approach

The data cleaning pipeline was structured into a four-stage modular SQL workflow (`layoffs_data_cleaning.sql`):

```
[ Raw Staging Table ] 
         │
         ▼
 ┌─────────────────────────────────────────────────────────┐
 │ STEP 1: Duplicate Identification & Removal              │
 │ • CTE with ROW_NUMBER() PARTITION BY all fields         │
 │ • Staging Table 'layoffs_nosa2' creation                │
 └─────────────────────────────────────────────────────────┘
         │
         ▼
 ┌─────────────────────────────────────────────────────────┐
 │ STEP 2: Field Standardization & Type Casting            │
 │ • TRIM whitespace on text fields                        │
 │ • Categorical alignment (Crypto, United States)         │
 │ • STR_TO_DATE() conversion & ALTER TABLE MODIFY DATE    │
 └─────────────────────────────────────────────────────────┘
         │
         ▼
 ┌─────────────────────────────────────────────────────────┐
 │ STEP 3: Missing Value Imputation                        │
 │ • Empty string '' to NULL conversion                    │
 │ • Relational Self-Join (UPDATE t1 JOIN t2) ON company   │
 └─────────────────────────────────────────────────────────┘
         │
         ▼
 ┌─────────────────────────────────────────────────────────┐
 │ STEP 4: Record Filtering & Schema Cleanup               │
 │ • DELETE records where layoff metrics are mutually NULL │
 │ • DROP helper column (row_num)                          │
 └─────────────────────────────────────────────────────────┘
         │
         ▼
[ Cleaned Staging Table ]

```

### Stage 1: Duplicate Identification & Removal

Because the table lacked a primary key, exact duplicates were identified using a Common Table Expression (CTE) with `ROW_NUMBER()` partitioned across all 9 schema columns:

```sql
WITH duplicateCTE AS (
    SELECT *,
           ROW_NUMBER() OVER(
               PARTITION BY company, location, industry, total_laid_off, 
                            percentage_laid_off, `date`, stage, country, funds_raised_millions
           ) AS row_num
    FROM layoffs_nosa
)
SELECT * FROM duplicateCTE WHERE row_num > 1;

```

To remove these rows safely in MySQL, a persistent staging table (`layoffs_nosa2`) was populated with `row_num`, followed by targeted deletion:

```sql
DELETE FROM layoffs_nosa2 WHERE row_num > 1;

```

### Stage 2: Standardization & Data Type Casting

Text variables were cleaned of leading/trailing whitespace and inconsistent naming conventions:

```sql
-- Whitespace trimming
UPDATE layoffs_nosa2 SET company = TRIM(company);
UPDATE layoffs_nosa2 SET location = TRIM(location);

-- Industry standardization
UPDATE layoffs_nosa2 
SET industry = 'Crypto' 
WHERE industry LIKE 'Crypto%';

-- Country trailing punctuation fix
UPDATE layoffs_nosa2 
SET country = TRIM(TRAILING '.' FROM country) 
WHERE country LIKE 'United States%';

```

Date strings formatted as text (`%m/%d/%Y`) were converted to native SQL `DATE` types to support temporal partitioning and window functions:

```sql
UPDATE layoffs_nosa2 
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_nosa2 
MODIFY COLUMN `date` DATE;

```

### Stage 3: Missing Value Imputation

Blanks were normalized to `NULL`. A self-join was performed to backfill missing `industry` data from existing records matching the same `company`:

```sql
UPDATE layoffs_nosa2 SET industry = NULL WHERE industry = '';

UPDATE layoffs_nosa2 t1
JOIN layoffs_nosa2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;

```

### Stage 4: Filtering Unusable Records & Final Schema Optimization

Records missing both `total_laid_off` and `percentage_laid_off` contained no quantitative layoff signal and were purged. The temporary tracking column was then removed:

```sql
DELETE FROM layoffs_nosa2 
WHERE total_laid_off IS NULL 
  AND percentage_laid_off IS NULL;

ALTER TABLE layoffs_nosa2 
DROP COLUMN row_num;

```

---

## 8. Key Findings

| Metric / Dimension | Raw Dataset | Cleaned Dataset | Variance / Impact |
| --- | --- | --- | --- |
| **Total Row Count** | 2,361 | 1,995 | -366 records (-15.5%) |
| **Duplicate Entries** | 5 | 0 | 5 redundant rows deleted |
| **Non-analyzable Records** | 362 | 0 | 362 double-NULL records purged |
| **Industry Standardizations** | Multiple variants (`Crypto Currency`, `CryptoCurrency`) | Consolidated to `Crypto` | Eliminates category fragmentation |
| **Country Standardizations** | `United States.` present | Standardized to `United States` | Aggregates geographic totals accurately |
| **Imputed Industries** | 4 missing records | 1 remaining missing record (`Bally's Interactive`) | 3 industries successfully backfilled |

---

## 9. Recommendations

* **Implement Foreign Keys and Unique Constraints:**
  * *Observed Finding:* 5 exact duplicate rows were ingested due to a lack of unique constraints.


  * *Action:* Define a composite primary key or surrogate key `(company, location, date, stage)` at schema creation to reject duplicate records at entry.


* **Enforce Strict Ingestion Data Types:**
  * *Observed Finding:* Dates were stored as `text` strings (`%m/%d/%Y`).


  * *Action:* Enforce ISO-8601 (`YYYY-MM-DD`) `DATE` data types at ETL pipeline ingestion to prevent casting overhead during database maintenance.


* **Automate Text Normalization Triggers:**
  * *Observed Finding:* Categorical fields contained trailing dots (`United States.`) and varied label conventions (`Crypto Currency`).


  * *Action:* Implement `BEFORE INSERT` SQL triggers or upstream data validation (e.g., Python Pydantic / SQL constraints) to trim text and enforce enum lists.


* **Establish Required Validation Rules for Quantitative Metrics:**
  * *Observed Finding:* 362 records contained `NULL` values in both `total_laid_off` and `percentage_laid_off`, offering zero analytical value.


  * *Action:* Update ingestion validation so that reports must contain at least one valid metric (`total_laid_off` OR `percentage_laid_off`) before being written to storage.



---

## 10. Limitations

* **Single-Record Unresolved Industry:** `Bally's Interactive` only appears once in the dataset with a `NULL` industry, preventing self-join lookup imputation.
* **Unimputed Layoff Metrics:** Missing values in `total_laid_off` (when `percentage_laid_off` was present) were left as `NULL` to avoid introducing arbitrary statistical noise through synthetic imputation.
* **Text Column Memory Overhead:** Columns were defined as broad `text` types in the intermediate staging table rather than optimized `VARCHAR(n)` length constraints.

---

## 11. Possible Next Steps

* Perform exploratory data analysis (EDA) to evaluate layoff trends across funding stages (`Post-IPO` vs `Series A-E`) and temporal quarters.
* Build an automated dashboard (e.g., Power BI or Tableau) tracking total global layoffs, top impacted industries, and geographic density.

---

## 12. Technical Skills Demonstrated

* **SQL DDL & Schema Control:** `CREATE TABLE LIKE`, `ALTER TABLE MODIFY COLUMN`, `DROP COLUMN`.


* **Advanced SQL Window Functions:** `ROW_NUMBER() OVER (PARTITION BY ...)` for duplicate detection.


* **Complex Data Transformations:** `STR_TO_DATE()`, `TRIM()`, `TRIM(TRAILING ... FROM ...)`, conditional update logic.


* **Relational Joins for Imputation:** Multi-table `UPDATE` queries using relational self-joins (`JOIN ON company`).



---
