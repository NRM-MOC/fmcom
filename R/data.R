#' Freshwater and Marine Contaminant Monitoring dataset (FMCoM)
#'
#' Long-format dataset of contaminant concentrations measured in Swedish
#' national environmental monitoring programmes, combining the marine
#' contaminant monitoring (MCoM) dataset with freshwater contaminant
#' monitoring data. One row is one contaminant measurement for one sample
#' (a pooled or individual specimen, in a given organ, analysed by a given
#' laboratory/method).
#'
#' 366,600 measurements; 114 contaminants across 8 substance groups; 11
#' species (fish, bivalve, bird); 59 stations; years 1967-2023.
#'
#' @format A data frame with 366,600 rows and 45 variables:
#' \describe{
#'   \item{specimen_ID}{Identifier for the specimen(s) a sample was taken from}
#'   \item{year}{Sampling year}
#'   \item{date}{Sampling date}
#'   \item{species}{Species sampled (scientific name)}
#'   \item{species_EN}{Species sampled (English common name)}
#'   \item{class}{Taxonomic class: "Fish", "Bivalve", or "Bird"}
#'   \item{number_individuals}{Number of individuals pooled into the sample}
#'   \item{sample_ID}{Identifier for the sample (specimen + organ +
#'     analytical method); unique together with \code{contaminant}}
#'   \item{substance_group}{Contaminant class, e.g. "Metals", "PFAS", "PCBs",
#'     "Dioxins and furans", "Pesticides and solvents", "BFRs", "PAH",
#'     "Organotin compounds"}
#'   \item{contaminant}{Contaminant/analyte short code (e.g. "Pb", "PFOS")}
#'   \item{value}{Measured concentration, in \code{unit}}
#'   \item{unit}{Unit of measurement, e.g. "ug.g-1.dw-1" (dw = dry weight,
#'     ww = wet weight, lw = lipid weight)}
#'   \item{is_censored}{Whether the value is censored (below/above a
#'     detection or quantification limit)}
#'   \item{LOQ_LOD}{Censoring flag relative to limit of quantification (LOQ)
#'     and/or limit of detection (LOD), e.g. "<LOQ", ">LOD"}
#'   \item{uncertainty}{Measurement uncertainty, same unit as \code{value}}
#'   \item{contaminant_full_name}{Full chemical name of the contaminant}
#'   \item{contaminant_alt_name}{Alternative/common name of the contaminant}
#'   \item{CAS_number}{CAS registry number of the contaminant}
#'   \item{suspected_outlier}{Whether the value is flagged as a suspected
#'     outlier}
#'   \item{laboratory}{Analysing laboratory}
#'   \item{instrument}{Analytical instrument, e.g. "ICP-MS", "GC-MS"}
#'   \item{analytical_method}{Analytical method/batch code}
#'   \item{sex}{Sex of the specimen(s)}
#'   \item{total_length}{Total length of the specimen (fish), cm}
#'   \item{age}{Age of the specimen}
#'   \item{weight}{Weight of the specimen}
#'   \item{organ}{Tissue/organ analysed: "Liver", "Muscle", "Soft tissue",
#'     or "Egg content"}
#'   \item{fat_percentage}{Fat content of the sample, \%}
#'   \item{dry_weight_percentage}{Dry weight content of the sample, \%}
#'   \item{egg_shell_thickness}{Egg shell thickness (bird eggs only)}
#'   \item{d13C}{Stable carbon isotope ratio}
#'   \item{d15N}{Stable nitrogen isotope ratio}
#'   \item{C_dw_percentage}{Carbon content, \% dry weight}
#'   \item{N_dw_percentage}{Nitrogen content, \% dry weight}
#'   \item{station_name}{Full monitoring station name}
#'   \item{latitude}{Station latitude (WGS84)}
#'   \item{longitude}{Station longitude (WGS84)}
#'   \item{HELCOM_basin}{HELCOM basin (marine stations); \code{"_"} where
#'     not classified, \code{NA} for freshwater stations}
#'   \item{ICES_basin}{ICES basin/subdivision (marine stations only)}
#'   \item{ICES_station}{ICES station code (marine stations only)}
#'   \item{season}{Sampling season: "Spring", "Autumn", or
#'     "no_season_applied"}
#'   \item{water_type}{"Marine" or "Freshwater" -- new in this version}
#'   \item{station}{Short station name/code}
#'   \item{station_code_SGU}{SGU station code}
#'   \item{contaminant_code_SGU}{SGU contaminant/method code}
#' }
#' @source Swedish Museum of Natural History environmental monitoring
#'   programmes, on behalf of the Swedish Environmental Protection Agency /
#'   Swedish Agency for Marine and Water Management.
"fmcom"

# `fmcom` is used as a default argument value in fmcom_long_to_wide() (the
# lazy-loaded dataset itself, not a global variable) -- this tells R CMD
# check that's intentional.
utils::globalVariables("fmcom")
