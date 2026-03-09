# Module 6 Homework — Batch Processing with Spark

In this homework we'll put what we learned about Spark in practice.

For this homework we will be using the Yellow 2025-11 data from the official website:

```bash
wget https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2025-11.parquet
```

---

## Question 1: Install Spark and PySpark

- Install Spark
- Run PySpark
- Create a local spark session
- Execute spark.version.

What's the output?

✅ **4.1.1**

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("HW6") \
    .getOrCreate()

print(spark.version)  # 4.1.1
```

---

## Question 2: Yellow November 2025

Read the November 2025 Yellow into a Spark Dataframe.
Repartition the Dataframe to 4 partitions and save it to parquet.

What is the average size of the Parquet (ending with .parquet extension) Files that were created (in MB)?

❌ 6MB
✅ **25MB**
❌ 75MB
❌ 100MB

```python
df = spark.read.parquet("yellow_tripdata_2025-11.parquet")
df.repartition(4).write.parquet("output/yellow_repartitioned/")
# ls -lh output/yellow_repartitioned/*.parquet → 4 fichiers de 24 MB chacun
```

---

## Question 3: Count records

How many taxi trips were there on the 15th of November?
Consider only trips that started on the 15th of November.

❌ 62,610
❌ 102,340
✅ **162,604**
❌ 225,768

```python
from pyspark.sql.functions import col, to_date

nov15 = df.filter(to_date(col("tpep_pickup_datetime")) == "2025-11-15")
print(nov15.count())  # 162604
```

---

## Question 4: Longest trip

What is the length of the longest trip in the dataset in hours?

❌ 22.7
❌ 58.2
✅ **90.6**
❌ 134.5

```python
from pyspark.sql.functions import unix_timestamp

df_duration = df.withColumn(
    "duration_hours",
    (unix_timestamp("tpep_dropoff_datetime") - unix_timestamp("tpep_pickup_datetime")) / 3600
)
df_duration.agg({"duration_hours": "max"}).collect()[0][0]  # 90.64666...
```

---

## Question 5: User Interface

Spark's User Interface which shows the application's dashboard runs on which local port?

❌ 80
❌ 443
✅ **4040**
❌ 8080

---

## Question 6: Least frequent pickup location zone

Load the zone lookup data into a temp view in Spark:

```bash
wget https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv
```

Using the zone lookup data and the Yellow November 2025 data, what is the name of the LEAST frequent pickup location Zone?

✅ **Governor's Island/Ellis Island/Liberty Island**
❌ Arden Heights
❌ Rikers Island
❌ Jamaica Bay

```python
zones = spark.read.option("header", "true").csv("taxi_zone_lookup.csv")
zones.createOrReplaceTempView("zones")
df.createOrReplaceTempView("trips")

spark.sql("""
    SELECT z.Zone, COUNT(*) as cnt
    FROM trips t
    JOIN zones z ON t.PULocationID = z.LocationID
    GROUP BY z.Zone
    ORDER BY cnt ASC
    LIMIT 1
""").show()
# Governor's Island/Ellis Island/Liberty Island → 1 trip
```