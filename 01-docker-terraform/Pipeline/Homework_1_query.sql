SELECT 
	lpep_pickup_datetime,
	lpep_dropoff_datetime,
	total_amount,
	CONCAT(zpu."Borough" , ' / ' , zpu."Zone") AS "pick_up_loc",
	CONCAT(zdo."Borough" , ' / ' , zdo."Zone") AS "dropoff_loc"
FROM
    public.green_taxi_data t,
    public.taxi_zones zpu,
    public.taxi_zones zdo
WHERE
    t."PULocationID" = zpu."LocationID"
    AND t."DOLocationID" = zdo."LocationID"
ORDER BY total_amount DESC
LIMIT 100;


/* Question 3. For the trips in November 2025, 
how many trips had a trip_distance of less than 
or equal to 1 mile? (1 point) */ 

SELECT COUNT(*)

FROM
    public.green_taxi_data t,
    public.taxi_zones zpu,
    public.taxi_zones zdo
WHERE
    t."PULocationID" = zpu."LocationID"
    AND t."DOLocationID" = zdo."LocationID"
	AND lpep_pickup_datetime >= '2025-11-01'
	AND lpep_pickup_datetime < '2025-12-01'
	AND trip_distance <= 1;

-- 8007

/* Question 4. Which was the pick up day with the longest 
trip distance? Only consider trips with trip_distance 
less than 100 miles. (1 point) */

SELECT 
	lpep_pickup_datetime,
	lpep_dropoff_datetime,
	total_amount,
	CONCAT(zpu."Borough" , ' / ' , zpu."Zone") AS "pick_up_loc",
	CONCAT(zdo."Borough" , ' / ' , zdo."Zone") AS "dropoff_loc",
	trip_distance
FROM
    public.green_taxi_data t,
    public.taxi_zones zpu,
    public.taxi_zones zdo
WHERE
    t."PULocationID" = zpu."LocationID"
    AND t."DOLocationID" = zdo."LocationID"
	AND trip_distance <= 100
ORDER BY trip_distance DESC
LIMIT 1;

-- 2025-11-14 15:36:27

/*Question 5. Which was the pickup zone 
with the largest total_amount (sum of all trips) 
on November 18th, 2025? (1 point) */

SELECT
	"PULocationID",
	CONCAT(zpu."Borough" , ' / ' , zpu."Zone") AS "pick_up_loc",
	SUM(total_amount) as total_amount

FROM
    public.green_taxi_data t,
	public.taxi_zones zpu
WHERE
    t."PULocationID" = zpu."LocationID"
	AND DATE(lpep_pickup_datetime) = '2025-11-18'
GROUP BY "PULocationID", "pick_up_loc"
ORDER BY total_amount DESC
LIMIT 1;

-- Manhattan / East Harlem North