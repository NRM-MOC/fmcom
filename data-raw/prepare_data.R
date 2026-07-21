# data-raw/prepare_data.R
#
# Builds data/fmcom.rda from the raw delivered file data-raw/fmcom_raw.csv.
# Not run at install time -- documents/reproduces how the shipped dataset
# was produced. Re-run (source this file from the package root) whenever
# fmcom_raw.csv is updated.
#
# NOTE: fmcom_raw.csv (~186MB) is in .gitignore and NOT committed to the
# repo -- too large for GitHub. Place your copy of it in data-raw/ locally
# before running this script (e.g. copy from your shared drive / data
# archive). Only the processed, compressed data/fmcom.rda (~3MB) is
# committed and ships with the package.
#
# Only base R is used here (no CRAN packages needed) since the file is a
# semicolon-delimited, comma-decimal export -- read.csv2() handles that
# natively.
#
# NOTE: the raw file contains non-ASCII characters, and some systems (esp.
# Linux servers/containers) default to a "C" locale that mis-parses UTF-8
# multi-byte sequences, causing rows to silently drop. If you see far fewer
# rows than expected, set a UTF-8 locale first, e.g. from the shell:
#   LC_ALL=C.utf8 Rscript data-raw/prepare_data.R
# or from within R: Sys.setlocale("LC_ALL", "C.utf8") / "en_US.UTF-8"

raw <- read.csv2(
  "data-raw/fmcom_raw.csv",
  fileEncoding   = "UTF-8",
  stringsAsFactors = FALSE,
  na.strings     = c("NA", "")
)

fmcom <- raw

# ---- Type cleanup -----------------------------------------------------

fmcom$date        <- as.Date(fmcom$date)
fmcom$is_censored <- as.logical(fmcom$is_censored)
fmcom$suspected_outlier <- as.logical(fmcom$suspected_outlier)

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
