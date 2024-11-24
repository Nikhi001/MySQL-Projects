CREATE DATABASE data_cleaning;
USE data_cleaning; 
SELECT * FROM laptop; 


# 1. Create_Backup

CREATE TABLE laptop_backup LIKE laptop; #Backup_created
SELECT * FROM laptop_backup; #space_created_without_data
INSERT INTO laptop_backup 
SELECT * FROM laptop; #data_copied
SELECT* FROM laptop_backup;#Data_copied_sucessfully

#2. Check number of rows
SELECT * FROM laptop_backup;

#3. Check memory consumtion for reference
SELECT * FROM information_schema.TABLES
WHERE TABLE_SCHEMA='data_cleaning'
AND TABLE_NAME = 'laptop_backup'; #21_Types_of_data_information_given

SELECT DATA_LENGTH/1024 AS 'data_size' FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'data_cleaning'
AND TABLE_NAME = 'laptop_backup'; # It help us to check data_size 

#4.Drop non important cols
ALTER TABLE laptop_backup DROP COLUMN `Unnamed: 0`;
SELECT* FROM laptop_backup;

# Add Sr column to identify null columns

ALTER TABLE laptop_backup ADD COLUMN sr INT; # create new column
SET @row_number =0;
UPDATE laptop_backup
SET sr=(@row_number := @row_number+1)
where price IS NOT NULL;	#Update sr number where price is not null

SELECT * FROM laptop_backup;



#5.Null values
#DELETE FROM laptop_backup
#WHERE index In();
SELECT * FROM laptop_backup
WHERE (company IS NULL OR company='') AND (Typename IS NULL OR Typename='')AND (Inches IS NULL OR Inches='') 
AND (ScreenResolution IS NULL OR ScreenResolution ='') AND (Cpu IS NULL OR Cpu='') 
AND (Ram IS NULL OR Ram ='')AND (Memory IS NULL OR Memory='')AND (OpSys IS NULL OR OpSys='')
AND (Weight IS NULL OR Weight='') AND(Price IS NULL OR Price=''); # there is no null present in database

# 6.Drop Duplicates (There are many ways to drop duplicates windows, distanct, normal )
SELECT Company,Typename,Inches,ScreenResolution,Cpu,Ram,Memory,Gpu,OpSys,Weight,Price,sr, COUNT(*) FROM laptop_backup
GROUP BY Company,Typename,Inches,ScreenResolution,Cpu,Ram,Memory,Gpu,OpSys,Weight,Price,sr
HAVING COUNT(*)>1; # there is no duplicate values

# 7.check datatype
SELECT Inches FROM laptop_backup; 
ALTER TABLE laptop_backup MODIFY COLUMN Inches DECIMAL(10,1);

# using set command you can disable "safe update mode" 
SET sql_safe_updates = 0; # why we used zero and one?

UPDATE laptop_backup
SET Ram= REPLACE(Ram,'GB','');

SET sql_safe_updates=1; # 0-means off(disable the features) and 1-means ON(enable the features)

SELECT* from laptop_backup; 
ALTER TABLE laptop_backup MODIFY COLUMN RAM INTEGER;
# After doing modification on Ram column data size has reduced an show size is 256.000

SET sql_safe_updates=0;

UPDATE laptop_backup
SET Weight= REPLACE(Weight,'kg','');

UPDATE laptop_backup
SET Price = (SELECT ROUND(Price));

SET sql_safe_updates=1;

ALTER TABLE laptop_backup MODIFY COLUMN Price INTEGER;
# can't convert weight column into integer there is missing value present error given 1366

# changes has done in OpSys column
SELECT DISTINCT OpSys FROM laptop_backup;# OpSys column is holding differnt type of info

SELECT OpSys ,
				CASE 
					WHEN OpSys LIKE '%mac%' THEN 'macos'
                    WHEN OpSys LIKE 'windows%' THEN 'windows'
                    WHEN OpSys LIKE '%linux%' THEN 'linux'
                    WHEN OpSys LIKE 'No OS' THEN 'N/A'
                    ELSE 'other'
				END AS 'os_brands'
FROM laptop_backup;

SET sql_safe_updates =0;

UPDATE laptop_backup
SET OpSys = CASE 
					WHEN OpSys LIKE '%mac%' THEN 'macos'
                    WHEN OpSys LIKE 'windows%' THEN 'windows'
                    WHEN OpSys LIKE '%linux%' THEN 'linux'
                    WHEN OpSys LIKE 'No OS' THEN 'N/A'
                    ELSE 'other'
END ;

SET sql_safe_updates=1;

# Gpu column
ALTER TABLE laptop_backup
ADD COLUMN gpu_brand VARCHAR(255)AFTER Gpu,
Add COLUMN gpu_name VARCHAR(255) AFTER gpu_brand;

SET sql_safe_updates=0;

UPDATE laptop_backup
SET gpu_brand = SUBSTRING_INDEX(Gpu,' ',1);# substring_index is split string on the bases of space from gup column and took the first word

UPDATE laptop_backup
SET gpu_name=  REPLACE(Gpu,gpu_brand,'');# Replace the brand_name and set new column with name

SET sql_safe_updates=1;

# Add column behalf of Cpu
ALTER TABLE laptop_backup
ADD COLUMN cpu_brand VARCHAR(255) AFTER Cpu,
ADD COLUMN cpu_name VARCHAR(255) AFTER cpu_brand,
Add COLUMN cpu_speed DECIMAL(10,1) AFTER cpu_name;

SET sql_safe_updates=0;

UPDATE laptop_backup
SET cpu_brand= substring_index(Cpu,' ',1);#cpu_brand column

UPDATE laptop_backup
SET cpu_speed = CAST(REPLACE(substring_index(Cpu,' ',-1),'GHz','')As DECIMAL(10,2));
#substring ?
#CAST ?
# DECIMAL ?
# select cpu,CAST(REPLACE(substring_index(Cpu,' ',-1),'GHz','') AS Decimal(10,2)) from laptop_backup;

UPDATE laptop_backup
SET cpu_name = REPLACE(REPLACE(Cpu,cpu_brand,''),SUBSTRING_INDEX(REPLACE(Cpu,cpu_brand,''),' ',-1),''); 
#Replace cpu and cpu_brand name where have space with with -1 string number (core_i5)  after subtring_ index replace cpu and cpu_brand with space

SET sql_safe_updates=1;

ALTER TABLE laptop_backup DROP COLUMN Cpu;

#Handling ScreenResolution column
SELECT ScreenResolution ,
SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution,' ',-1),'x',1),
SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution,' ',1),'x',-1)
FROM laptop_backup;


ALTER TABLE laptop_backup
ADD COLUMN resolution_width INTEGER AFTER ScreenResolution,
ADD COLUMN resolution_height INTEGER AFTER resolution_width;


SET sql_safe_updates=0;
UPDATE laptop_backup 
SET resolution_width =SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution,' ',-1),'x',1),
	resolution_height= SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution,' ',-1),'x',-1);


ALTER TABLE laptop_backup
ADD COLUMN touchscreen INTEGER AFTER resolution_height;

SELECT ScreenResolution LIKE '%Touch%' FROM laptop_backup;

UPDATE laptop_backup
SET touchscreen = ScreenResolution LIKE '%Touch%';

ALTER TABLE laptop_backup
DROP COLUMN ScreenResolution;

SELECT* from laptop_backup;

# Handle the cpu_name

SELECT cpu_name,
SUBSTRING_INDEX(TRIM(cpu_name),' ',2)FROM laptop_backup;

UPDATE laptop_backup
SET cpu_name=SUBSTRING_INDEX(TRIM(cpu_name),' ',2);

ALTER TABLE laptop_backup
ADD COLUMN memory_type VARCHAR(255) AFTER Memory,
ADD COLUMN primary_memory INTEGER AFTER memory_type,
ADD COLUMN secondary_memory INTEGER AFTER primary_memory ; 

SELECT DISTINCT(Memory) FROM laptop_backup;
SELECT Memory,
CASE 
	WHEN Memory LIKE '%SSD%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    WHEN Memory LIKE '%SSD%' THEN 'SSD'
    WHEN Memory LIKE '%HDD%' THEN 'HDD'
    WHEN Memory LIKE '%Flash Storage%' THEN 'Flash Storage'
    WHEN Memory LIKE '%Flash Storage%' AND Memory LIKE '%SSD%' THEN 'Hybrid'
	WHEN Memory LIKE '%Flash Storage%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    WHEN Memory LIKE '%Hybrid%' THEN 'Hybrid'
    ELSE NULL
END AS 'memory_type'
FROM laptop_backup;

UPDATE laptop_backup
SET memory_type=
CASE 
	WHEN Memory LIKE '%SSD%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    WHEN Memory LIKE '%SSD%' THEN 'SSD'
    WHEN Memory LIKE '%HDD%' THEN 'HDD'
    WHEN Memory LIKE '%Flash Storage%' THEN 'Flash Storage'
    WHEN Memory LIKE '%Flash Storage%' AND Memory LIKE '%SSD%' THEN 'Hybrid'
	WHEN Memory LIKE '%Flash Storage%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    WHEN Memory LIKE '%Hybrid%' THEN 'Hybrid'
    ELSE NULL
END;

# Memomry column mai se primary_memory or secondary_memory ko split karna
SELECT Memory,
REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',1),'[0-9]+'),
CASE  WHEN Memory LIKE '%+%' THEN REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',-1),'[0-9]+') ELSE 0 END
FROM laptop_backup;

UPDATE laptop_backup
SET primary_memory= REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',1),'[0-9]+'),
secondary_memory = CASE  WHEN Memory LIKE '%+%' THEN REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',-1),'[0-9]+') ELSE 0 END;


# update jo column ki values 1 or 2  hai vo multiply 1024
SELECT primary_memory,
CASE WHEN primary_memory <=2 THEN primary_memory*1024 ELSE primary_memory END,
secondary_memory,
CASE WHEN secondary_memory <=2 THEN secondary_memory*1024 ELSE secondary_memory END FROM laptop_backup;

# update karna primary_memory and secondary_memory
UPDATE laptop_backup
SET primary_memory= CASE WHEN primary_memory <=2 THEN primary_memory*1024 ELSE primary_memory END,
secondary_memory= CASE WHEN secondary_memory <=2 THEN secondary_memory*1024 ELSE secondary_memory END;

ALTER TABLE laptop_backup
DROP COLUMN Memory; #Drop the memory table


# yeh column mai to much information hai 
ALTER TABLE laptop_backup
DROP COLUMN gpu_name;


select * from laptop_backup;
SET sql_safe_updates=1;

#CHECK OUT laptop_EDA_process SHEET