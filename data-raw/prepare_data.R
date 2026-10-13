# data-raw/prepare_data.R
#
# Builds data/fmcom.rda, the dataset shipped with the package, from the
# updated master file data-raw/database<year>/fmcom.rds (the output of the
# pipeline scripts in this folder).
# Not run at install time -- documents/reproduces how the shipped dataset
# was produced. Re-run (source this file from the package root) whenever
# the master .rds is updated.
#
# NOTE: the master .rds (and the .csv written alongside it) are in .gitignore
# and NOT committed to the repo -- too large for GitHub. Place your copy of
# the file in data-raw/database<year>/ locally before running this script
# (see data-raw/README.md for where to get the previous version). Only the
# processed, compressed data/fmcom.rda (~3MB) is committed and ships with
# the package.
#
# The .rds keeps the original column types, so the type cleanup below
# only applies the final package types (Date, logical, factors).


# Read the master .rds (from the pipeline output) and store as fmcom
# Change folder name for appropriate year (e.g., database2025) when re-running 
# this script for a new release
fmcom <- readRDS("data-raw/database2024/fmcom.rds")

# ---- Type cleanup -----------------------------------------------------

fmcom$date        <- as.Date(fmcom$date)
fmcom$is_censored <- as.logical(fmcom$is_censored)
fmcom$suspected_outlier <- as.logical(fmcom$suspected_outlier)

# stop if more than 72 specimen_id (13198 data points) have no valid date (incomplete in source)
n_na_date <- sum(is.na(fmcom$date))
message(n_na_date, " records have no valid date (incomplete in source)")
stopifnot(n_na_date == 13198)   # update when the source dates are fixed

# water_type / class / substance_group / season / sex / organ / LOQ_LOD /
# unit are small, fixed-vocabulary fields -- store as factors
factor_cols <- c(
  "water_type", "class", "substance_group", "season", "sex",
  "organ", "LOQ_LOD", "unit", "HELCOM_basin", "ICES_basin"
)
fmcom[factor_cols] <- lapply(fmcom[factor_cols], factor)

# station/species/contaminant identifiers stay as character (used for
# joins/filtering, not as categorical summaries)

# ---- Sanity checks -----------------------------------------------------

stopifnot(
  all(c("Marine", "Freshwater") %in% levels(fmcom$water_type)),
  !anyNA(fmcom$station),
  !anyNA(fmcom$contaminant),
  !anyNA(fmcom$value)
)

# ---- Save as package data ----------------------------------------------

if (!dir.exists("data")) dir.create("data")
save(fmcom, file = "data/fmcom.rda", compress = "bzip2")
