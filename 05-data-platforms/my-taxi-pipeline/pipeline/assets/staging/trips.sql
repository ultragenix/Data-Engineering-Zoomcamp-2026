/* @bruin
name: staging.trips
type: duckdb.sql

# Dépendances : Bruin s'assure que ces assets tournent avant staging.trips
depends:
  - ingestion.trips
  - ingestion.payment_lookup

materialization:
  type: table
  # time_interval = la stratégie la plus adaptée pour des données temporelles :
  # 1. Bruin SUPPRIME les lignes où pickup_datetime est dans la fenêtre [start, end]
  # 2. Bruin INSERT le résultat de ta query pour cette même fenêtre
  # → Permet de re-processer une période sans reconstruire toute la table
  strategy: time_interval
  incremental_key: pickup_datetime   # colonne DATE/TIMESTAMP qui définit la fenêtre
  time_granularity: timestamp        # 'date' si tu travailles par jour, 'timestamp' pour plus de précision

columns:
  - name: pickup_datetime
    type: timestamp
    description: "Heure de prise en charge — clé de la fenêtre incrémentale"
    primary_key: true
    checks:
      - name: not_null
  - name: dropoff_datetime
    type: timestamp
    description: "Heure de dépose"
    checks:
      - name: not_null
  - name: pickup_location_id
    type: integer
    description: "Zone de prise en charge"
    primary_key: true
    checks:
      - name: not_null
  - name: dropoff_location_id
    type: integer
    description: "Zone de dépose"
    primary_key: true
    checks:
      - name: not_null
  - name: fare_amount
    type: float
    description: "Montant de base de la course en USD"
    primary_key: true
    checks:
      - name: non_negative
  - name: total_amount
    type: float
    description: "Montant total payé en USD"
    checks:
      - name: non_negative
  - name: trip_distance
    type: float
    description: "Distance parcourue en miles"
    checks:
      - name: non_negative
  - name: passenger_count
    type: integer
    description: "Nombre de passagers"
  - name: payment_type_description
    type: string
    description: "Libellé du mode de paiement (enrichi depuis payment_lookup)"
  - name: taxi_type
    type: string
    description: "Type de taxi : yellow ou green"
  - name: extracted_at
    type: timestamp
    description: "Timestamp d'extraction depuis la couche ingestion"

# Custom check : vérifie que la table n'est pas vide après le run
custom_checks:
  - name: row_count_positive
    description: "La table staging.trips ne doit pas être vide"
    query: SELECT COUNT(*) > 0 FROM staging.trips
    value: 1
@bruin */

-- ============================================================
-- STAGING LAYER : nettoyage, déduplication, enrichissement
-- ============================================================
-- Rappel time_interval :
--   Bruin injecte automatiquement {{ start_datetime }} et {{ end_datetime }}
--   basés sur les flags --start-date / --end-date du bruin run.
--   Tu DOIS filtrer sur cette fenêtre pour éviter les doublons :
--   sans ce filtre → Bruin delete la fenêtre mais insert TOUT = doublons.
-- ============================================================

WITH
-- Étape 1 : Filtrer la fenêtre temporelle + lignes valides
filtered AS (
    SELECT *
    FROM ingestion.trips
    WHERE pickup_datetime >= '{{ start_datetime }}'
      AND pickup_datetime <  '{{ end_datetime }}'
      -- On écarte les lignes sans clé composite (inutilisables en staging)
      AND pickup_datetime   IS NOT NULL
      AND dropoff_datetime  IS NOT NULL
      AND pickup_location_id IS NOT NULL
      AND dropoff_location_id IS NOT NULL
      -- On écarte les montants négatifs (données corrompues)
      AND fare_amount  >= 0
      AND total_amount >= 0
      AND trip_distance >= 0
),

-- Étape 2 : Déduplication par clé composite
-- L'ingestion utilise `append` → des doublons peuvent apparaître si on re-run.
-- ROW_NUMBER() partitionné sur la clé composite garde 1 ligne par trip unique.
-- La clé composite = ce qui identifie un trajet de façon unique (pas d'ID dispo dans les données TLC)
deduplicated AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                pickup_datetime,
                dropoff_datetime,
                pickup_location_id,
                dropoff_location_id,
                fare_amount
            ORDER BY extracted_at DESC  -- On garde la version la plus récente en cas de doublon
        ) AS rn
    FROM filtered
),

-- Étape 3 : Enrichissement avec la table de lookup des paiements
-- payment_lookup contient les libellés lisibles pour chaque code de paiement
enriched AS (
    SELECT
        d.vendor_id,
        d.pickup_datetime,
        d.dropoff_datetime,
        d.passenger_count,
        d.trip_distance,
        d.pickup_location_id,
        d.dropoff_location_id,
        d.fare_amount,
        d.total_amount,
        d.taxi_type,
        d.extracted_at,
        COALESCE(p.payment_type_name, 'Unknown') AS payment_type_description
    FROM deduplicated d
    LEFT JOIN ingestion.payment_lookup p
        ON d.payment_type = p.payment_type_id
    WHERE d.rn = 1  -- On ne garde que la ligne dédupliquée
)

SELECT * FROM enriched