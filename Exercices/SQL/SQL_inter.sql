-- ============================================
-- EXERCICES SQL - Niveau Intermédiaire
-- ============================================

-- Q6: Combien de trajets ont eu lieu le 15 janvier 2019 ?
--     (Utilise lpep_pickup_datetime et filtre sur cette date exacte)

SELECT count(*)
FROM public.green_taxi_data as green_taxi
WHERE "lpep_pickup_datetime" >= '2019-01-15 00:00:00'
AND "lpep_pickup_datetime" < '2019-01-16 00:00:00'
LIMIT 10;

-- Q7: Affiche tous les trajets qui ont :
--     - plus de 5 passagers (passenger_count)
--     - ET une distance supérieure à 10 miles (trip_distance)

SELECT *
FROM public.green_taxi_data as green_taxi
WHERE "passenger_count" > 5 AND "trip_distance" > 10
;

-- Q8: Affiche chaque zone de départ (PULocationID) avec le nombre total de trajets,
--     MAIS uniquement les zones qui ont eu plus de 10000 trajets.
--     (Indice : HAVING)

SELECT "PULocationID" ,z."Zone", COUNT(*) as "nb_trajet"
FROM public.yellow_taxi_trips_2021_1 as yellow_taxi
INNER JOIN public.taxi_zones as z ON  yellow_taxi."PULocationID" = z."LocationID"
GROUP BY "PULocationID", z."Zone"
HAVING COUNT(*) > 10000
ORDER BY "nb_trajet" 
;

-- Q9: Pour chaque Borough (arrondissement), affiche :
--     - Le nom du Borough
--     - Le montant total généré (SUM de total_amount)
--     Trie par montant décroissant.

SELECT t."PULocationID" ,z."Zone" , z."Borough", sum(t."total_amount") AS "total_amount"
FROM public.yellow_taxi_trips_2021_1 as t
INNER JOIN public.taxi_zones as z ON  t."PULocationID" = z."LocationID"
GROUP BY t."PULocationID" ,z."Zone", z."Borough"
ORDER BY "total_amount" DESC
;

-- Q10: Affiche les trajets avec une colonne "distance_category" qui dit :
--      - "Court" si trip_distance < 2
--      - "Moyen" si entre 2 et 10
--      - "Long" si > 10
--      Limite à 20 lignes.
--      (Indice : CASE WHEN)

SELECT *,
CASE
	WHEN "trip_distance" < 2 THEN 'Court'
	WHEN "trip_distance" >= 2 AND "trip_distance" <= 10 THEN 'Moyen'
	ELSE 'Long'
END AS distance_category
FROM public.yellow_taxi_trips_2021_1
LIMIT 20;