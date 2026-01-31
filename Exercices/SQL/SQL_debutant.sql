-- ============================================
-- EXERCICES SQL - Module 1 Révision
-- Tables: green_taxi_trips, taxi_zones
-- ============================================

-- Q1: Affiche les 10 premières lignes de green_taxi_trips

SELECT * 
FROM public.green_taxi_data as green_taxi
LIMIT 10;

-- Q2: Combien de trajets ont transporté exactement 2 passagers ?

SELECT COUNT(*) 
FROM public.green_taxi_data as green_taxi
WHERE "passenger_count" = 2
;

-- Q3: Quelle est la distance moyenne (trip_distance) de tous les trajets ?

SELECT avg(trip_distance)
FROM public.green_taxi_data as green_taxi
;

-- Q4: Compte combien de trajets il y a eu par nombre de passagers (passenger_count).
--     Trie par ordre décroissant.

SELECT COUNT(*) as "quantity" , passenger_count
FROM public.green_taxi_data as green_taxi
GROUP BY passenger_count 
ORDER BY "quantity" DESC;

-- Q5: Affiche le nom de la zone (Zone) et le nombre de trajets qui sont partis de chaque zone.
--     Limite aux 5 zones les plus populaires.

SELECT count(t."PULocationID")as "Nb_Trajet", t."PULocationID", z."Zone"
FROM public.green_taxi_data as t
INNER JOIN public.taxi_zones as z ON  t."PULocationID" = z."LocationID"
GROUP BY t."PULocationID" , z."Zone"
ORDER BY "Nb_Trajet" DESC
LIMIT 5
;