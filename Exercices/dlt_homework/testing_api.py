import requests

BASE_URL = "https://us-central1-dlthub-analytics.cloudfunctions.net/data_engineering_zoomcamp_api"

# Test : juste la page 1
response = requests.get(BASE_URL, params={"page": 1})
print(f"Status : {response.status_code}")

data = response.json()
print(f"Nb records page 1 : {len(data)}")
print(f"Colonnes : {list(data[0].keys())}")
print(f"\nPremier record :")
for k, v in data[0].items():
    print(f"  {k}: {v}")