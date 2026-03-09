# Module 3 Homework: Data Warehousing & BigQuery


## BigQuery Setup

Create an external table using the Yellow Taxi Trip Records. 

Create a (regular/materialized) table in BQ using the Yellow Taxi Trip Records (do not partition or cluster this table). 

~~~~sql
CREATE OR REPLACE EXTERNAL TABLE zoomcamp.external_yellow_tripdata
OPTIONS(
  format = 'PARQUET',
  uris = ['gs://cohesive-folio-485508-e4-terra-bucket/yellow_tripdata_2024-0*.parquet']);

CREATE OR REPLACE TABLE zoomcamp.materialized_yellow_tripdata AS
SELECT * FROM `cohesive-folio-485508-e4.zoomcamp.external_yellow_tripdata`;
~~~~


## Question 1. Counting records

What is count of records for the 2024 Yellow Taxi Data?

❌ 65,623

❌ 840,402

✅ 20,332,093

❌ 85,431,289

~~~~sql
SELECT COUNT(*) 
FROM `cohesive-folio-485508-e4.zoomcamp.external_yellow_tripdata`; -- 20332093
~~~~

## Question 2. Data read estimation

Write a query to count the distinct number of PULocationIDs for the entire dataset on both the tables.
 
What is the **estimated amount** of data that will be read when this query is executed on the External Table and the Table?

❌ 18.82 MB for the External Table and 47.60 MB for the Materialized Table

✅ 0 MB for the External Table and 155.12 MB for the Materialized Table

❌ 2.14 GB for the External Table and 0MB for the Materialized Table

❌ 0 MB for the External Table and 0MB for the Materialized Table

~~~~sql
SELECT DISTINCT  PULocationID 
FROM `cohesive-folio-485508-e4.zoomcamp.external_yellow_tripdata`; -- 0 octet

SELECT DISTINCT  PULocationID 
FROM `cohesive-folio-485508-e4.zoomcamp.materialized_yellow_tripdata`; -- 155,12 Mo
~~~~

Attention malgré que 0 Mb sont affiché pour le cout de l'external table il y a un vraie cout reel lorsque l'on regarde les détails du job 155Mb !!

## Question 3. Understanding columnar storage

Write a query to retrieve the PULocationID from the table (not the external table) in BigQuery. Now write a query to retrieve the PULocationID and DOLocationID on the same table.
Why are the estimated number of Bytes different?

✅ BigQuery is a columnar database, and it only scans the specific columns requested in the query. Querying two columns (PULocationID, DOLocationID) requires 
reading more data than querying one column (PULocationID), leading to a higher estimated number of bytes processed.

❌ BigQuery duplicates data across multiple storage partitions, so selecting two columns instead of one requires scanning the table twice, 
doubling the estimated bytes processed.

❌ BigQuery automatically caches the first queried column, so adding a second column increases processing time but does not affect the estimated bytes scanned.

❌ When selecting multiple columns, BigQuery performs an implicit join operation between them, increasing the estimated bytes processed

~~~~sql
SELECT PULocationID 
FROM `cohesive-folio-485508-e4.zoomcamp.materialized_yellow_tripdata`; -- 155,12 Mo

SELECT PULocationID, DOLocationID 
FROM `cohesive-folio-485508-e4.zoomcamp.materialized_yellow_tripdata`; -- 310.24 Mo
~~~~
Comme dit plus haut BigQuery ordone les donnés en colonnes chaque ajouts de colonnes donne plus de donnés à parcourir 

## Question 4. Counting zero fare trips

How many records have a fare_amount of 0?

❌ 128,210

❌ 546,578

❌ 20,188,016

✅ 8,333

~~~~sql
SELECT COUNT(fare_amount )
FROM `cohesive-folio-485508-e4.zoomcamp.materialized_yellow_tripdata`
WHERE fare_amount = 0;
~~~~

## Question 5. Partitioning and clustering

What is the best strategy to make an optimized table in Big Query if your query will always filter based on tpep_dropoff_datetime and order the results by VendorID (Create a new table with this strategy)

✅ Partition by tpep_dropoff_datetime and Cluster on VendorID

❌ Cluster on by tpep_dropoff_datetime and Cluster on VendorID

❌ Cluster on tpep_dropoff_datetime Partition by VendorID

❌ Partition by tpep_dropoff_datetime and Partition by VendorID

~~~~sql
-- partition and cluster table
CREATE OR REPLACE TABLE zoomcamp.partitoned_clustered_yellow_tripdata
PARTITION BY DATE(tpep_dropoff_datetime)
CLUSTER BY VendorID AS
SELECT * FROM `cohesive-folio-485508-e4.zoomcamp.external_yellow_tripdata`;
~~~~

La partition et le cluster doit bien etre bien définie en fonction des requetes courantes faites, sinon sa na aucun intéret il faut bien réfléchire et déterminer les coûts des requetes!

## Question 6. Partition benefits

Write a query to retrieve the distinct VendorIDs between tpep_dropoff_datetime
2024-03-01 and 2024-03-15 (inclusive)


Use the materialized table you created earlier in your from clause and note the estimated bytes. Now change the table in the from clause to the partitioned table you created for question 5 and note the estimated bytes processed. What are these values? 

Choose the answer which most closely matches.
 
❌ 12.47 MB for non-partitioned table and 326.42 MB for the partitioned table

✅ 310.24 MB for non-partitioned table and 26.84 MB for the partitioned table

❌ 5.87 MB for non-partitioned table and 0 MB for the partitioned table

❌ 310.31 MB for non-partitioned table and 285.64 MB for the partitioned table

~~~~sql
SELECT DISTINCT  VendorID 
FROM `cohesive-folio-485508-e4.zoomcamp.materialized_yellow_tripdata` 
WHERE 
  TIMESTAMP_TRUNC(tpep_dropoff_datetime, DAY) > TIMESTAMP("2024-03-01") 
  AND
  TIMESTAMP_TRUNC(tpep_dropoff_datetime, DAY) <= TIMESTAMP("2024-03-15"); -- 310 Mo

  SELECT DISTINCT  VendorID 
FROM `cohesive-folio-485508-e4.zoomcamp.partitoned_clustered_yellow_tripdata` 
WHERE 
  TIMESTAMP_TRUNC(tpep_dropoff_datetime, DAY) > TIMESTAMP("2024-03-01") 
  AND
  TIMESTAMP_TRUNC(tpep_dropoff_datetime, DAY) <= TIMESTAMP("2024-03-15"); -- 25.05 Mo
~~~~

dans cette exemple on vois bien que le coût de la requete materialized_yellow_tripdata est de 310 Mo
alors que celui de partitoned_clustered_yellow_tripdata est de 25.05.
Une partition et un cluster intélligent a fait économisé 11 fois le coût de la requete.

## Question 7. External table storage

Where is the data stored in the External Table you created?

❌ Big Query

❌ Container Registry

✅ GCP Bucket

❌ Big Table

les donnes sont dans le bucket GCP : 'gs://cohesive-folio-485508-e4-terra-bucket/yellow_tripdata_2024-0*.parquet'
c'est pour cela que a la question 2 BigQuery nous montre un coup de 0 octet se n'est pas le coup reel il n'a pas accés a cette donné

## Question 8. Clustering best practices

It is best practice in Big Query to always cluster your data:

❌ True

✅ False

les tables qui font -1Go n'offre pas d'optimisation, voir en rajoute via l'ajout de la lecture de metadata et a sa maintenance

## Question 9. Understanding table scans

No Points: Write a `SELECT count(*)` query FROM the materialized table you created. How many bytes does it estimate will be read? Why?

~~~~sql
SELECT COUNT(*) 
FROM `cohesive-folio-485508-e4.zoomcamp.materialized_yellow_tripdata` ;
~~~~

Bigquery calcule le coup seulement quand les colones sont explicitement només
et cette information est présente dans les metas datas

## Learning in Public

https://x.com/wyllow5/status/2020898413122871517

https://x.com/wyllow5/status/2020898661090168925

https://x.com/wyllow5/status/2020899546876813348

https://x.com/wyllow5/status/2020900028722590118

https://x.com/wyllow5/status/2020900479450931362

https://www.linkedin.com/feed/update/urn:li:activity:7426672062330642432/

https://www.facebook.com/dhyani.chohan/posts/pfbid02HAxJpQvLougPawXDvtjnFMyBxcpUakP5JChPVW4pS3qtAMMb875D5Xj4Urku9uLal