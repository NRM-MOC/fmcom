# Data pipeline

Scripts that extend the previous release of the `fmcom` dataset with a new
year of observations.

The observations originate from the Swedish national monitoring programmes for
contaminants in freshwater and marine biota, run by the Swedish Museum of
Natural History. Each year, the museum submits the most recent year's data to
the national contaminant database hosted by the Geological Survey of Sweden
(SGU), which holds all national biota contaminant data. This pipeline extracts
the data back from SGU and appends it to the `fmcom` dataset. 

Run the pipeline from the package root (open `fmcom.Rproj`).

## Steps

1. `adding_next_year_fmcom.R` – downloads the new year's data from SGU for the
   stations listed in `stations_SGU_NRM.csv` and appends it to the previous version 
   of the dataset.
2. `prepare_data.R` – builds `data/fmcom.rda`, the dataset shipped with the package.

Set the year and other options in the settings block at the top of the first script.

## Inputs

- `master_tables/stations_SGU_NRM.csv` – station table.
- `master_tables/contaminants_SGU_NRM.csv` - link between SGU and NRM naming convention
- `master_tables/analytical_method_SGU_NRM.csv` - link between SGU and NRM naming convention
- `database<year-1>/fmcom.rds` – the previous version of the dataset
  (**not included**, see below).

## Outputs

- `database<year>/fmcom.rds` and `fmcom.csv` – the updated dataset (not committed).
- `data/fmcom.rda` – the packaged dataset (committed).

## Inputs not in this repository

The data files are too large for git. The previous version of the dataset is
installed with the package: `fmcom::fmcom`"]. Place it in `data-raw/database<year-1>/` 
before running the pipeline.

## Required R packages

dplyr, tidyr, readr, lubridate, purr, string, jsonlite, httr, gam, DescTools, MASS