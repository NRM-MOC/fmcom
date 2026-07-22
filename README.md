# fmcom

`fmcom` is an R data package containing the Freshwater and Marine Contaminant
Monitoring dataset, run by the Swedish Museum of Natural History. The program 
was historically funded by the Swedish Environmental Protection Agency and is 
currently funded by the Swedish Agency for Marine and Water Management.

This package builds on the earlier [`mcomDb`](https://github.com/NRM-MOC/mcomDb)
package (marine contaminants only), which also included intercalibration files 
for instances when laboratories where changed. This version:

- Adds freshwater contaminant monitoring data alongside the marine data
- Introduces a `water_type` column (`"Marine"` / `"Freshwater"`)
- Includes structural updates and new columns -- see `?fmcom` for the full
  field list

The dataset contains 366,600 contaminant measurements: 114 contaminants
across 8 substance groups (metals, PFAS, PCBs, dioxins/furans, pesticides
and solvents, BFRs, PAH, organotin compounds), 11 species (fish, bivalve,
bird egg), 59 stations, spanning 1967-2023.

## Installation

```r
# install.packages("devtools")
devtools::install_github("https://github.com/NRM-MOC/fmcom")
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

## Citation

If you use this dataset, please cite:
Soerensen, A.L. & Faxneld, S. (2026). fmcom: Freshwater and Marine
Contaminant Monitoring Dataset. R package. <https://github.com/NRM-MOC/fmcom>

For background information and basic structure, and marine data:
Ammar, Y., S. Faxneld, M. Sköld, A.L. Soerensen (2024), Long term dataset 
for contaminants in fish, mussels, and bird eggs from the Baltic Sea, 
Scientific Data, 11 (1), doi: 10.1038/s41597-024-03216-0

For freshwater data:
Faxneld, S., A.L. Soerensen (2026), Graphic and statistical overview of 
temporal trends and spatial variations in the Swedish National Monitoring 
Programme for Contaminants in Freshwater Biota (including data through 2024). 
Swedish Museum of Natural History, Stockholm, Sweden

## License

Data and code are licensed under [CC BY 4.0](LICENSE) -- you're free to
share and adapt, with attribution.
