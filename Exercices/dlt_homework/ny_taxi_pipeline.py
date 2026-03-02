"""
================================================================================
 NYC TAXI DATA PIPELINE — DE Zoomcamp 2026 | Workshop dlt
================================================================================

 OBJECTIF :
   Ingérer les données de courses de taxi NYC depuis une REST API paginée
   et les charger dans une base DuckDB locale avec dlt (Data Load Tool).

 FLOW DU PIPELINE :
   REST API (paginée) ──► dlt (extract + normalize) ──► DuckDB (local)

 STRUCTURE :
   1. Source  : REST API Google Cloud Functions (données NYC Taxi)
   2. Resource: ny_taxi() — définit QUOI extraire et COMMENT paginer
   3. Pipeline: dlt.pipeline() — définit OÙ charger les données
   4. Run     : pipeline.run() — exécute l'ingestion complète

 COMMANDE D'EXECUTION :
   uv run python taxi_pipeline.py

================================================================================
"""

import dlt
from dlt.sources.helpers.rest_client import RESTClient
from dlt.sources.helpers.rest_client.paginators import PageNumberPaginator


# ==============================================================================
# CONFIGURATION DE L'API SOURCE
# ==============================================================================

# URL de base de l'API — hébergée sur Google Cloud Functions
BASE_URL = "https://us-central1-dlthub-analytics.cloudfunctions.net"

# Endpoint spécifique pour les données du Zoomcamp
API_ENDPOINT = "data_engineering_zoomcamp_api"


# ==============================================================================
# RESOURCE dlt — Définition de la source de données
# ==============================================================================
# @dlt.resource : décorateur qui transforme une fonction Python en "source dlt"
#   - name       : nom de la TABLE qui sera créée dans DuckDB
#   - write_disposition :
#       "replace" → vide et recharge la table à chaque run (mode FULL REFRESH)
#       "append"  → ajoute les nouvelles lignes sans toucher aux anciennes
#       "merge"   → upsert basé sur une primary key (nécessite primary_key=)
# ==============================================================================

@dlt.resource(
    name="rides",                    # <- Nom de la table dans DuckDB
    write_disposition="replace",     # <- Full refresh : on recharge tout
)
def ny_taxi():
    """
    Générateur qui extrait les courses de taxi depuis l'API paginée.

    POURQUOI un générateur (yield) ?
      - Traitement en streaming : on ne charge pas toutes les pages en RAM
      - dlt respecte le yield et traite chaque page au fur et à mesure
      - Idéal pour les grandes volumétries de données

    PAGINATION :
      L'API utilise une pagination par numéro de page (?page=1, ?page=2, ...)
      PageNumberPaginator gère automatiquement l'incrémentation
      et s'arrête quand une page vide est retournée.
    """

    # RESTClient : client HTTP dlt avec gestion intégrée de la pagination,
    # des retries automatiques et des rate limits
    client = RESTClient(
        base_url=BASE_URL,
        paginator=PageNumberPaginator(
            base_page=1,        # <- Commence à la page 1
            total_path=None,    # <- L'API ne retourne pas le total de pages,
                                #    on s'arrête quand la page est vide
        ),
    )

    # Itère sur toutes les pages de l'API et yield chaque page
    # dlt traite chaque page individuellement → mémoire faible (micro-batching)
    for i, page in enumerate(client.paginate(API_ENDPOINT)):
        yield page      # <- Chaque page est une liste de records JSON      


# ==============================================================================
# PIPELINE dlt — Définition de la destination
# ==============================================================================
# dlt.pipeline() configure le pipeline de chargement :
#   - pipeline_name : nom utilisé pour les métadonnées et le fichier .duckdb
#   - destination   : où charger ("duckdb", "bigquery", "postgres", etc.)
#   - dataset_name  : nom du SCHEMA/dataset dans la destination
# ==============================================================================

pipeline = dlt.pipeline(
    pipeline_name="ny_taxi",        # <- Crée un fichier ny_taxi.duckdb
    destination="duckdb",           # <- Destination locale DuckDB
    dataset_name="ny_taxi_data",    # <- Schema dans DuckDB
)


# ==============================================================================
# EXECUTION DU PIPELINE
# ==============================================================================

if __name__ == "__main__":

    print("🚀 Démarrage de l'ingestion NYC Taxi → DuckDB...")
    print(f"   Source  : {BASE_URL}/{API_ENDPOINT}")
    print(f"   Dest    : DuckDB (ny_taxi.duckdb)")
    print(f"   Dataset : ny_taxi_data")
    print(f"   Table   : rides")
    print("-" * 60)

    # pipeline.run() déclenche le pipeline complet :
    #   1. EXTRACT  : appelle ny_taxi() et collecte toutes les pages
    #   2. NORMALIZE: détecte les types, aplatit les JSON nested, renomme les colonnes
    #   3. LOAD     : insère les données dans DuckDB selon write_disposition
    load_info = pipeline.run(ny_taxi)

    # Affiche le résumé du chargement (nb de rows, tables créées, durée...)
    print(load_info)
    print("-" * 60)

    # ===========================================================================
    # EXPLORATION DES DONNÉES CHARGÉES
    # ===========================================================================
    # pipeline.dataset() ouvre une connexion au dataset DuckDB
    # .rides retourne la table "rides" sous forme de DataFrame pandas
    # ===========================================================================

    print("\n📊 Aperçu des données chargées :")
    df = pipeline.dataset().rides.df()

    print(f"   ✅ Nombre de lignes  : {len(df):,}")
    print(f"   ✅ Nombre de colonnes: {len(df.columns)}")
    print(f"\n   Colonnes disponibles :")
    for col in df.columns:
        print(f"     - {col} ({df[col].dtype})")

    print(f"\n   5 premières lignes :")
    print(df.head())