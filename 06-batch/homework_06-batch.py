from pyspark.sql import SparkSession
from pyspark.sql.functions import col, to_date, unix_timestamp

spark = SparkSession.builder.appName("HW6").getOrCreate()

# Q1 — Version Spark
print("Q1 - Spark version:", spark.version)

# Charger le dataset principal
df = spark.read.parquet("yellow_tripdata_2025-11.parquet")

# Q2 — Repartition 4 + écriture Parquet
df.repartition(4).write.parquet("output/yellow_repartitioned/")
# → Après le run : ls -lh output/yellow_repartitioned/*.parquet

# Q3 — Trips du 15 novembre
nov15 = df.filter(to_date(col("tpep_pickup_datetime")) == "2025-11-15")
print("Q3 - Trips Nov 15:", nov15.count())

# Q4 — Trip le plus long en heures
df_duration = df.withColumn(
    "duration_hours",
    (unix_timestamp("tpep_dropoff_datetime") - unix_timestamp("tpep_pickup_datetime")) / 3600
)
print("Q4 - Longest trip (hours):", df_duration.agg({"duration_hours": "max"}).collect()[0][0])

# Q5 — Spark UI → réponse : 4040 (pas de code nécessaire)

# Q6 — Zone la moins fréquente via temp view
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