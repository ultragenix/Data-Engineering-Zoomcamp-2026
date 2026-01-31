-- ============================================
-- EXERCICES SQL - Niveau Avancé (Final Boss)
-- ============================================

-- Q11: Utilise une CTE (WITH) pour calculer la distance moyenne,
--      puis affiche tous les trajets qui ont une distance supérieure à cette moyenne.
--      (Indice : WITH ma_moyenne AS (...) SELECT ... FROM ... WHERE ...)

WITH "avg_distanceCTE" ("avg_distance") AS (
		SELECT AVG("trip_distance")
    	FROM public.yellow_taxi_trips_2021_1
	)
SELECT *
FROM public.yellow_taxi_trips_2021_1
WHERE 
	"trip_distance" > (SELECT "avg_distance" FROM "avg_distanceCTE");

-- Q12: Pour chaque zone de départ, affiche :
--      - Zone name
--      - Nombre de trajets
--      - Le rang de cette zone par popularité (1 = la plus populaire)
--      (Indice : RANK() OVER (ORDER BY ...))

SELECT 
	z."Zone",
	COUNT(*) as "nb_trajet",
	RANK() OVER ( ORDER BY COUNT(*) DESC) as "Rank"
FROM public.yellow_taxi_trips_2021_1 as yellow_taxi
INNER JOIN public.taxi_zones as z ON  yellow_taxi."PULocationID" = z."LocationID"
GROUP BY z."Zone"

-- Q13: Affiche les 3 trajets les plus chers de chaque Borough.
--      (Indice : ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...) puis WHERE rn <= 3)

SELECT 
	"PULocationID" , "total_amount", "Borough", rn
FROM (
	SELECT t."PULocationID", t."total_amount",z."Borough", ROW_NUMBER() OVER ( PARTITION BY "PULocationID" ORDER BY "total_amount" DESC) as rn
	FROM public.yellow_taxi_trips_2021_1 AS t
	INNER JOIN public.taxi_zones as z ON  t."PULocationID" = z."LocationID"
	) q
WHERE rn <= 3
;

-- Q14: Calcule le montant total par jour (DATE),
--      ET affiche aussi une colonne avec le total cumulé jour après jour.
--      (Indice : SUM() OVER (ORDER BY date))


-- Q15: Trouve les zones où le prix moyen (AVG total_amount) 
--      est supérieur au prix moyen global de toute la table.
--      (Indice : Subquery dans WHERE)