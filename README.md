# fmcom

`fmcom` is an R data package containing the Freshwater and Marine Contaminant
Monitoring (FMCoM) dataset, run by the Swedish Museum of Natural History and
funded by the Swedish Environmental Protection Agency.

This package builds on the earlier [`mcomDb`](https://github.com/NRM-MOC/mcomDb)
package (marine contaminants only). This version:

- Adds freshwater contaminant monitoring data alongside the marine data
- Introduces a `water_type` column (`"Marine"` / `"Freshwater"`)
- Includes structural updates and new columns -- see `?fmcom` for the full
  field list

The dataset contains 366,600 contaminant measurements: 114 contaminants
across 8 substance groups (metals, PFAS, PCBs, dioxins/furans, pesticides
and solvents, BFRs, PAH, organotin compounds), 11 species (fish, bivalve,
bird), 59 stations, spanning 1967-2023.

## Installation

```r
# install.packages("devtools")
devtools::install_github("YOUR-ORG/fmcom")
```

## Usage

```r
library(fmcom)

# Long-format dataset
head(fmcom)

# Reshape to wide format (one column per contaminant)
wide <- fmcom_long_to_wide(fmcom)
```

## Data

- `fmcom` -- long-format contaminant dataset (marine + freshwater), one row
  per contaminant measurement per sample

See `data-raw/prepare_data.R` for how the shipped `.rda` was built from the
raw delivered file, and `?fmcom` for full column documentation.

> Note: earlier drafts of this package also planned laboratory
> intercalibration tables (metals, PFAS, BFR, chlorinated compounds). Those
> weren't part of the delivered `fmcom.csv` -- add a section here (and a
> corresponding `data-raw` step) if/when that data is available.

## Citation

If you use this dataset, please cite:

> [Add citation here once available -- e.g. an updated data descriptor
> analogous to Ammar et al. (2024), Scientific Data]

## License

Data and code are licensed under [CC BY 4.0](LICENSE) -- you're free to
share and adapt, with attribution.
