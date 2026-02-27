"""@bruin

# TODO: Set the asset name (recommended pattern: schema.asset_name).
# - Convention in this module: use an `ingestion.` schema for raw ingestion tables.
name: ingestion.trips

# TODO: Set the asset type.
# Docs: https://getbruin.com/docs/bruin/assets/python
type: python

# TODO: Pick a Python image version (Bruin runs Python in isolated environments).
# Example: python:3.11
image: python:3.11

# TODO: Set the connection.
connection: duckdb-default

# TODO: Choose materialization (optional, but recommended).
# Bruin feature: Python materialization lets you return a DataFrame (or list[dict]) and Bruin loads it into your destination.
# This is usually the easiest way to build ingestion assets in Bruin.
# Alternative (advanced): you can skip Bruin Python materialization and write a "plain" Python asset that manually writes
# into DuckDB (or another destination) using your own client library and SQL. In that case:
# - you typically omit the `materialization:` block
# - you do NOT need a `materialize()` function; you just run Python code
# Docs: https://getbruin.com/docs/bruin/assets/python#materialization
materialization:
  # TODO: choose `table` or `view` (ingestion generally should be a table)
  type: table
  # TODO: pick a strategy.
  # suggested strategy: append
  strategy: append

# TODO: Define output columns (names + types) for metadata, lineage, and quality checks.
# Tip: mark stable identifiers as `primary_key: true` if you plan to use `merge` later.
# Docs: https://getbruin.com/docs/bruin/assets/columns
columns:
  - name: vendor_id
    type: integer
    description: "ID du prestataire de taxi"
  - name: pickup_datetime
    type: timestamp
    description: "Heure de prise en charge du passager"
    primary_key: true
  - name: dropoff_datetime
    type: timestamp
    description: "Heure de dépose du passager"
    primary_key: true
  - name: passenger_count
    type: integer
    description: "Nombre de passagers"
  - name: trip_distance
    type: float
    description: "Distance parcourue en miles"
  - name: pickup_location_id
    type: integer
    description: "ID de la zone de prise en charge"
    primary_key: true
  - name: dropoff_location_id
    type: integer
    description: "ID de la zone de dépose"
    primary_key: true
  - name: payment_type
    type: integer
    description: "Code du mode de paiement"
  - name: fare_amount
    type: float
    description: "Montant de base de la course en USD"
    primary_key: true
  - name: total_amount
    type: float
    description: "Montant total payé en USD"
  - name: taxi_type
    type: string
    description: "Type de taxi (yellow, green)"
  - name: extracted_at
    type: timestamp
    description: "Timestamp d'extraction pour le lineage"

@bruin"""

# TODO: Add imports needed for your ingestion (e.g., pandas, requests).
# - Put dependencies in the nearest `requirements.txt` (this template has one at the pipeline root).
# Docs: https://getbruin.com/docs/bruin/assets/python

import os
import json
import requests
import pandas as pd
from datetime import datetime
from dateutil.relativedelta import relativedelta

# TODO: Only implement `materialize()` if you are using Bruin Python materialization.
# If you choose the manual-write approach (no `materialization:` block), remove this function and implement ingestion
# as a standard Python script instead.
def materialize():
    """
    TODO: Implement ingestion using Bruin runtime context.

    Required Bruin concepts to use here:
    - Built-in date window variables:
      - BRUIN_START_DATE / BRUIN_END_DATE (YYYY-MM-DD)
      - BRUIN_START_DATETIME / BRUIN_END_DATETIME (ISO datetime)
      Docs: https://getbruin.com/docs/bruin/assets/python#environment-variables
    - Pipeline variables:
      - Read JSON from BRUIN_VARS, e.g. `taxi_types`
      Docs: https://getbruin.com/docs/bruin/getting-started/pipeline-variables

    Design TODOs (keep logic minimal, focus on architecture):
    - Use start/end dates + `taxi_types` to generate a list of source endpoints for the run window.
    - Fetch data for each endpoint, parse into DataFrames, and concatenate.
    - Add a column like `extracted_at` for lineage/debugging (timestamp of extraction).
    - Prefer append-only in ingestion; handle duplicates in staging.
    """

        # --- Récupération des variables Bruin ---
    start_date = datetime.strptime(os.environ["BRUIN_START_DATE"], "%Y-%m-%d")
    end_date = datetime.strptime(os.environ["BRUIN_END_DATE"], "%Y-%m-%d")

    bruin_vars = json.loads(os.environ.get("BRUIN_VARS", "{}"))
    taxi_types = bruin_vars.get("taxi_types", ["yellow"])

    base_url = "https://d37ci6vzurychx.cloudfront.net/trip-data"

    # --- Génération des mois dans la fenêtre start_date → end_date ---
    months = []
    current = start_date.replace(day=1)
    while current <= end_date:
        months.append(current)
        current += relativedelta(months=1)

    # --- Téléchargement et concaténation des fichiers parquet ---
    dataframes = []

    for taxi_type in taxi_types:
        for month in months:
            filename = f"{taxi_type}_tripdata_{month.strftime('%Y-%m')}.parquet"
            url = f"{base_url}/{filename}"

            print(f"Fetching: {url}")
            response = requests.get(url, timeout=60)

            if response.status_code != 200:
                print(f"Skipping {filename}: HTTP {response.status_code}")
                continue

            df = pd.read_parquet(pd.io.common.BytesIO(response.content))

            # Colonnes communes entre yellow et green
            rename_map = {
                "tpep_pickup_datetime": "pickup_datetime",
                "tpep_dropoff_datetime": "dropoff_datetime",
                "lpep_pickup_datetime": "pickup_datetime",
                "lpep_dropoff_datetime": "dropoff_datetime",
                "PULocationID": "pickup_location_id",
                "DOLocationID": "dropoff_location_id",
                "VendorID": "vendor_id",
                "RatecodeID": "ratecode_id",
            }
            df = df.rename(columns={k: v for k, v in rename_map.items() if k in df.columns})

            # Ajout des colonnes de lineage
            df["taxi_type"] = taxi_type
            df["extracted_at"] = datetime.utcnow()

            dataframes.append(df)

    if not dataframes:
        print("Aucune donnée récupérée pour cette fenêtre de dates.")
        return pd.DataFrame()

    final_df = pd.concat(dataframes, ignore_index=True)
    print(f"Total lignes ingérées : {len(final_df)}")

    return final_df

    # return final_dataframe


