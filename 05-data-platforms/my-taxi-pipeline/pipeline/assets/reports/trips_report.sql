/* @bruin
name: reports.trips_report
type: duckdb.sql

depends:
  - staging.trips

materialization:
  type: table
  # Même stratégie et même clé que staging pour garantir la cohérence des fenêtres de données
  strategy: time_interval
  incremental_key: trip_date
  time_granularity: date

columns:
  - name: trip_date
    type: date
    description: "Date de la course (tronquée depuis pickup_datetime)"
    primary_key: true
    checks:
      - name: not_null
  - name: taxi_type
    type: string
    description: "Type de taxi : yellow ou green"
    primary_key: true
    checks:
      - name: not_null
  - name: payment_type_description
    type: string
    description: "Libellé du mode de paiement"
    primary_key: true
    checks:
      - name: not_null
  - name: trip_count
    type: bigint
    description: "Nombre de courses pour cette combinaison date/taxi/paiement"
    checks:
      - name: non_negative
  - name: total_revenue
    type: float
    description: "Somme des montants totaux payés en USD"
    checks:
      - name: non_negative
  - name: avg_fare
    type: float
    description: "Tarif de base moyen en USD"
    checks:
      - name: non_negative
  - name: avg_trip_distance
    type: float
    description: "Distance moyenne des courses en miles"
    checks:
      - name: non_negative
  - name: total_passengers
    type: bigint
    description: "Nombre total de passagers transportés"
    checks:
      - name: non_negative

# Vérifie que le rapport n'est pas vide après le run
custom_checks:
  - name: row_count_positive
    description: "Le rapport ne doit pas être vide"
    query: SELECT COUNT(*) > 0 FROM reports.trips_report
    value: 1
@bruin */

-- ============================================================
-- REPORTS LAYER : agrégation pour dashboards et analytics
-- ============================================================
-- On agrège par jour / taxi_type / payment_type_description
-- Même fenêtre temporelle que staging via {{ start_datetime }} / {{ end_datetime }}
-- Important : time_interval sur trip_date (DATE) donc time_granularity: date
-- ============================================================

SELECT
    CAST(pickup_datetime AS DATE)   AS trip_date,
    taxi_type,
    payment_type_description,

    -- Métriques volumétriques
    COUNT(*)                        AS trip_count,
    SUM(total_amount)               AS total_revenue,

    -- Métriques moyennes (utiles pour détecter des anomalies tarifaires)
    ROUND(AVG(fare_amount), 2)      AS avg_fare,
    ROUND(AVG(trip_distance), 2)    AS avg_trip_distance,

    -- Métriques passagers
    SUM(passenger_count)            AS total_passengers

FROM staging.trips
WHERE pickup_datetime >= '{{ start_datetime }}'
  AND pickup_datetime <  '{{ end_datetime }}'
GROUP BY
    CAST(pickup_datetime AS DATE),
    taxi_type,
    payment_type_description