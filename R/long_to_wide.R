#' Shift the FMCoM dataset from long to wide format
#'
#' Pivots the long-format \code{fmcom} dataset so that each contaminant
#' becomes its own column, with one row per sample (\code{sample_ID}).
#' Columns that vary per-contaminant rather than per-sample (e.g.
#' \code{unit}, \code{value}, \code{CAS_number}, \code{laboratory}) are
#' dropped from the identifying columns by default, since they describe the
#' measurement, not the sample -- see \code{id_cols} to customise this.
#'
#' @param data A data frame in the same format as \code{\link{fmcom}}.
#'   Defaults to the built-in \code{fmcom} dataset.
#' @param id_cols Character vector of columns that uniquely identify a
#'   sample. Defaults to all sample/specimen-level columns in \code{fmcom}
#'   (i.e. everything except the contaminant-measurement columns).
#' @param names_from Column to take new column names from. Default
#'   \code{"contaminant"}.
#' @param values_from Column to take new column values from. Default
#'   \code{"value"}.
#'
#' @return A wide-format tibble, one row per sample, one column per
#'   contaminant.
#' @export
#'
#' @examples
#' \dontrun{
#' wide <- fmcom_long_to_wide(fmcom)
#'
#' # Only metals, wide by contaminant
#' wide_metals <- fmcom_long_to_wide(subset(fmcom, substance_group == "Metals"))
#' }
fmcom_long_to_wide <- function(
    data = fmcom,
    id_cols = c(
      "specimen_ID", "sample_ID", "year", "date", "species", "species_EN",
      "class", "number_individuals", "sex", "total_length", "age", "weight",
      "organ", "fat_percentage", "dry_weight_percentage",
      "egg_shell_thickness", "d13C", "d15N", "C_dw_percentage",
      "N_dw_percentage", "station_name", "station", "latitude", "longitude",
      "HELCOM_basin", "ICES_basin", "ICES_station", "season", "water_type",
      "station_code_SGU"
    ),
    names_from = "contaminant",
    values_from = "value") {

  missing_cols <- setdiff(c(id_cols, names_from, values_from), names(data))
  if (length(missing_cols) > 0) {
    stop(
      "Column(s) not found in `data`: ", paste(missing_cols, collapse = ", "),
      ".\nUpdate `id_cols`/`names_from`/`values_from` to match your dataset.",
      call. = FALSE
    )
  }

  data |>
    dplyr::select(dplyr::all_of(c(id_cols, names_from, values_from))) |>
    tidyr::pivot_wider(
      id_cols = dplyr::all_of(id_cols),
      names_from = dplyr::all_of(names_from),
      values_from = dplyr::all_of(values_from)
    )
}
