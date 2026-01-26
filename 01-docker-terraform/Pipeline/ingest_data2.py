"""
Script d'ingestion des données NY Taxi dans PostgreSQL
"""
import pandas as pd
from sqlalchemy import create_engine
from time import time

# Paramètres de connexion
user = "root"
password = "root"
host = "localhost"  # Depuis ton système hôte
port = "5432"       # Port exposé par Docker
db = "ny_taxi"

# Création de l'engine SQLAlchemy
engine = create_engine(f'postgresql://{user}:{password}@{host}:{port}/{db}')

def ingest_green_taxi_data():
    """Charge les données des taxis verts (Parquet)"""
    print("🚕 Chargement des données green taxi...")
    
    # Lecture du fichier Parquet
    df = pd.read_parquet('data/green_tripdata_2025-11.parquet')
    
    print(f"✅ Fichier chargé : {len(df)} lignes, {len(df.columns)} colonnes")
    print(f"📊 Colonnes : {list(df.columns)}")
    print(f"💾 Taille mémoire : {df.memory_usage(deep=True).sum() / 1024**2:.2f} MB")
    
    # Affiche les premières lignes
    print("\n📋 Aperçu des données :")
    print(df.head())
    print("\n📊 Types de données :")
    print(df.dtypes)
    
    # Insertion dans PostgreSQL
    print("\n💾 Insertion dans PostgreSQL...")
    t_start = time()
    
    # Insère les données par chunks (plus efficace pour gros fichiers)
    df.to_sql(
        name='green_taxi_data',      # Nom de la table
        con=engine,
        if_exists='replace',          # Remplace si existe déjà
        index=False,                  # N'insère pas l'index pandas
        chunksize=10000               # Insère par batch de 10k lignes
    )
    
    t_end = time()
    print(f"✅ Données insérées en {t_end - t_start:.2f} secondes")

def ingest_taxi_zones():
    """Charge les zones de taxi (CSV)"""
    print("\n🗺️  Chargement des zones de taxi...")
    
    # Lecture du CSV
    df_zones = pd.read_csv('data/taxi_zone_lookup.csv')
    
    print(f"✅ Fichier chargé : {len(df_zones)} lignes")
    print("\n📋 Aperçu des zones :")
    print(df_zones.head())
    
    # Insertion dans PostgreSQL
    print("\n💾 Insertion dans PostgreSQL...")
    df_zones.to_sql(
        name='taxi_zones',
        con=engine,
        if_exists='replace',
        index=False
    )
    
    print("✅ Zones insérées avec succès")

if __name__ == '__main__':
    print("🚀 Démarrage de l'ingestion des données...\n")
    
    # Teste la connexion
    try:
        engine.connect()
        print("✅ Connexion PostgreSQL OK\n")
    except Exception as e:
        print(f"❌ Erreur de connexion : {e}")
        exit(1)
    
    # Ingestion des données
    ingest_green_taxi_data()
    ingest_taxi_zones()
    
    print("\n🎉 Ingestion terminée avec succès !")