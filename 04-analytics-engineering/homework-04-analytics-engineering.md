# Module 4 Homework — Analytics Engineering with dbt

In this homework, we'll use the dbt project in `04-analytics-engineering/taxi_rides_ny/` to transform NYC taxi data.

---

## Question 1: dbt Lineage and Execution

If you run `dbt run --select int_trips_unioned`, what models will be built?

❌ `stg_green_tripdata`, `stg_yellow_tripdata`, and `int_trips_unioned` (upstream dependencies)

❌ Any model with upstream and downstream dependencies to `int_trips_unioned`

✅ **`int_trips_unioned` only**

❌ `int_trips_unioned`, `int_trips`, and `fct_trips` (downstream dependencies)

> Sans préfixe `+`, dbt ne remonte pas les dépendances upstream. Seul le modèle sélectionné est exécuté.

---

## Question 2: dbt Tests

A new value `6` appears in the source data. What happens when you run `dbt test --select fct_trips`?

❌ dbt will skip the test because the model didn't change

✅ **dbt will fail the test, returning a non-zero exit code**

❌ dbt will pass the test with a warning about the new value

❌ dbt will update the configuration to include the new value

> `accepted_values` vérifie strictement la liste définie — `6` n'y est pas, donc le test échoue avec un exit code non-zero.

---

## Question 3: Counting Records in `fct_monthly_zone_revenue`

What is the count of records in the `fct_monthly_zone_revenue` model?

✅ **12,998**

❌ 14,120

❌ 12,184

❌ 15,421

```sql
SELECT COUNT(*) as total
FROM `cohesive-folio-485508-e4.DBT_NY_Taxi.fct_monthly_zone_revenue`;
```

> Clé : le modèle doit grouper par `pickup_location_id` + `service_type` + `revenue_month`. Sans `service_type` dans le `GROUP BY`, on obtenait ~6 805 lignes (moitié du résultat attendu).

---

## Question 4: Best Performing Zone for Green Taxis (2020)

Which zone had the highest total revenue for Green taxis in 2020?

✅ **East Harlem North**

❌ Morningside Heights

❌ East Harlem South

❌ Washington Heights South

```sql
SELECT pickup_zone, SUM(total_revenue) as revenue
FROM `cohesive-folio-485508-e4.DBT_NY_Taxi.fct_monthly_zone_revenue`
WHERE service_type = 'Green'
  AND EXTRACT(YEAR FROM revenue_month) = 2020
GROUP BY pickup_zone
ORDER BY revenue DESC
LIMIT 1;
```

---

## Question 5: Green Taxi Trip Counts (October 2019)

What is the total number of trips for Green taxis in October 2019?

❌ 500,234

❌ 350,891

✅ **384,624**

❌ 421,509

```sql
SELECT SUM(total_trips) as trips
FROM `cohesive-folio-485508-e4.DBT_NY_Taxi.fct_monthly_zone_revenue`
WHERE service_type = 'Green'
  AND revenue_month = '2019-10-01';
```

---

## Question 6: Build a Staging Model for FHV Data

What is the count of records in `stg_fhv_tripdata` (after filtering `dispatching_base_num IS NULL`)?

❌ 42,084,899

✅ **43,244,693**

❌ 22,998,722

❌ 44,112,187

```sql
-- stg_fhv_tripdata model (filter NULL dispatching_base_num)
SELECT COUNT(*) as total
FROM `cohesive-folio-485508-e4.DBT_NY_Taxi.stg_fhv_tripdata`
WHERE dispatching_base_num IS NOT NULL;
```

```jinja-sql
-- stg_fhv_tripdata.sql
SELECT
    dispatching_base_num,
    pickup_datetime,
    dropoff_datetime,
    PUlocationID    AS pickup_location_id,
    DOlocationID    AS dropoff_location_id,
    SR_Flag,
    Affiliated_base_number
FROM {{ source('staging', 'fhv_tripdata') }}
WHERE dispatching_base_num IS NOT NULL
```

## Learning in Public