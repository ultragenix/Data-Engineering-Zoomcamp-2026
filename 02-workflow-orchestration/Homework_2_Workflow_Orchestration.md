# Homework 2 - Workflow Orchestration with Kestra

## Question 1: Uncompressed File Size
**Within the execution for Yellow Taxi data for the year 2020 and month 12: what is the uncompressed file size (i.e. the output file `yellow_tripdata_2020-12.csv` of the extract task)?**

- ✅ **128.3 MiB**
- ❌ 134.5 MiB
- ❌ 364.7 MiB
- ❌ 692.6 MiB

**Note:** Pour obtenir le fichier dans les outputs, retirer cette instruction du `kestra.yaml` :
```yaml
- id: purge_files
  type: io.kestra.plugin.core.storage.PurgeCurrentExecutionFiles
  description: This will remove output files. If you'd like to explore Kestra outputs, disable it.
```

---

## Question 2: Rendered Variable Value
**What is the rendered value of the variable `file` when the inputs `taxi` is set to `green`, `year` is set to `2020`, and `month` is set to `04` during execution?**

- ❌ `{{inputs.taxi}}_tripdata_{{inputs.year}}-{{inputs.month}}.csv`
- ✅ **`green_tripdata_2020-04.csv`**
- ❌ `green_tripdata_04_2020.csv`
- ❌ `green_tripdata_2020.csv`

**Configuration des variables :**
```yaml
variables:
  file: "{{inputs.taxi}}_tripdata_{{inputs.year}}-{{inputs.month}}.csv"
  staging_table: "public.{{inputs.taxi}}_tripdata_staging"
  table: "public.{{inputs.taxi}}_tripdata"
  data: "{{outputs.extract.outputFiles[inputs.taxi ~ '_tripdata_' ~ inputs.year ~ '-' ~ inputs.month ~ '.csv']}}"
```

---

## Question 3: Yellow Taxi 2020 Total Rows
**How many rows are there for the Yellow Taxi data for all CSV files in the year 2020?**

- ❌ 13,537,299
- ✅ **24,648,499**
- ❌ 18,324,219
- ❌ 29,430,127

**Query utilisée :**
```sql
SELECT COUNT(*)
FROM public.yellow_tripdata
WHERE filename LIKE 'yellow_tripdata_2020%';

-- Query duration: 1m26s on local machine
```

---

## Question 4: Green Taxi 2020 Total Rows
**How many rows are there for the Green Taxi data for all CSV files in the year 2020?**

- ❌ 5,327,301
- ❌ 936,199
- ✅ **1,734,051**
- ❌ 1,342,034

**Query utilisée :**
```sql
SELECT COUNT(*)
FROM public.green_tripdata
WHERE filename LIKE 'green_tripdata_2020%';

-- Query duration: 6s on local machine
```

---

## Question 5: Yellow Taxi March 2021 Rows
**How many rows are there for the Yellow Taxi data for the March 2021 CSV file?**

- ❌ 1,428,092
- ❌ 706,911
- ✅ **1,925,152**
- ❌ 2,561,031

**Query utilisée :**
```sql
SELECT COUNT(*)
FROM public.yellow_tripdata
WHERE filename LIKE 'yellow_tripdata_2021-03%';
```

---

## Question 6: Timezone Configuration
**How would you configure the timezone to New York in a Schedule trigger?**

- ❌ Add a timezone property set to EST in the Schedule trigger configuration
- ✅ **Add a timezone property set to America/New_York in the Schedule trigger configuration**
- ❌ Add a timezone property set to UTC-5 in the Schedule trigger configuration
- ❌ Add a location property set to New_York in the Schedule trigger configuration

**Configuration correcte :**
```yaml
triggers:
  - id: daily
    type: io.kestra.plugin.core.trigger.Schedule
    cron: "@daily"
    timezone: America/New_York
```

---

**Homework completed** ✅