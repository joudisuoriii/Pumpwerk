# Sales & Production Analysis Dashboard

Dieses Repository enthält SAS-Codes und Excel-Daten zur Analyse von Verkaufs- und Produktionsdaten. Ziel ist es, tägliche Verkaufszusammenfassungen, Heatmaps, Outlier-Analysen und Kundensegmentierungen zu erstellen und visualisieren.

## Projektinhalt

- **Excel-Dateien**:
  - `sales.xlsx` –  Verkaufsdaten
  - `production.xlsx` –  Produktionsdaten
  - `customers.xlsx` –  Kundendaten

- **SAS-Codes**:
  - `daily_sales_summary.sas` – Erstellung täglicher Verkaufsübersichten
  - `heatmap_visualization.sas` – Erstellung von Heatmaps für Revenue & Uptime
  - `dashboard.sas` – Dashboard Visualisierungen nach Region
  - `outlier_detection.sas` – Erkennung von Produktions-Outliers
  - `customer_clustering.sas` – Kundensegmentierung und Clusteranalyse
  - `segment_spend.sas` – Segmentanalyse der Kundenausgaben
  - `visualizations.sas` – Boxplots und Scatterplots

## Funktionsweise

1. **Datenbereinigung**: Rohdaten aus Excel werden bereinigt und konsistent formatiert (Datum, Zahlen, Flags).  
2. **Zusammenfassung**: Tägliche Verkaufszahlen und aggregierte Produktionsdaten werden zusammengeführt.  
3. **Heatmaps**: Visualisierung von Total Revenue und Average Uptime pro Region und Machine Group.  
4. **Dashboard**: Balkendiagramme für Total Revenue, Avg Output, Avg Uptime und Avg Customer Spend nach Region.  
5. **Outlier Detection**: Identifikation von Extremwerten in Produktionsdaten (Z-Score > 3).  
6. **Customer Clustering**: Standardisierung der Kundendaten und Clusteranalyse (3 Gruppen).  
7. **Segment Visuals**: Darstellung der durchschnittlichen Ausgaben pro Kundensegment.  
8. **Weitere Visualisierungen**: Boxplots und Scatterplots für Datenanalyse.

## Voraussetzungen

- SAS 9.4 oder höher  
- Excel-Dateien müssen im `xlsx`-Format vorliegen  
- Alle Tabellen müssen in SAS importiert werden, bevor die Analysen laufen

## Nutzung

1. Excel-Dateien ins SAS-Projekt laden (`libname` oder `PROC IMPORT`).  
2. SAS-Code in folgender Reihenfolge ausführen:  
   1. `daily_sales_summary.sas`  
   2. `heatmap_visualization.sas`  
   3. `dashboard.sas`  
   4. `outlier_detection.sas`  
   5. `customer_clustering.sas`  
   6. `segment_spend.sas`  
   7. `visualizations.sas`  
3. Ergebnisse und Grafiken werden in SAS Output generiert.  

## Autorin

- Joudi – Studentin Wirtschaftsinformatik, Datenanalyse & Visualisierung
