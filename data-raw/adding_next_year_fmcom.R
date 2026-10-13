#############################################################################-
# Script that reads SGU data from the SGU OGC API, reformat it to match the #-
# fmcom database structure and binds it to the previous fmcom version       #-
#############################################################################-

library(httr)
library(jsonlite)
library(lubridate)
library(gam)
library(DescTools)
library(dplyr)
library(tidyr)
library(purrr)
library(stringr)
library(readr)


## define: marine/freshwater ----
purpose <- "All" #"Marine", "Freshwater" or "All"

stopifnot(purpose %in% c("Marine", "Freshwater", "All"))

year <- 2024


## read previous fmcom version ----
## building on last year
fmcom <- readRDS(paste0("data-raw/database", year-1,"/fmcom.rds"))

## extract station IDs from fmcom database ----
station_id <- fmcom |> 
  filter(
    .env$purpose == "All" | water_type == .env$purpose,
    !is.na(station_code_SGU)) |> 
  distinct(station_code_SGU) |>
  pull(station_code_SGU)


# extraction functions ----
## function to get data from SGU OGC API ---- 
get_station_ogc <- function(station_id,
                            from_year = new_year,
                            to_year   = new_year,
                            media     = "Biota",
                            provtag_org = "NRM",
                            base_url  = "https://api.sgu.se/oppnadata/miljogifter-analysresultat-provplatser/ogc/features/v1") {
  
  # nationellt_provplatsid is an integer field - strip any leading zeros / ensure numeric
  station_id_num <- as.integer(station_id)
  
  filter_expr <- sprintf(
    "nationellt_provplatsid = %d AND provtagningsdatum >= DATE('%d-01-01') AND provtagningsdatum <= DATE('%d-12-31') AND media = '%s' AND provtag_org = '%s'",
    station_id_num, from_year, to_year, media, provtag_org
  )
  
  all_pages <- list()
  start_index <- 0
  page_limit  <- 1000
  
  repeat {
    resp <- httr::GET(
      url = paste0(base_url, "/collections/analysresultat/items"),
      query = list(
        f             = "application/json",
        filter        = filter_expr,
        `filter-lang` = "cql2-text",
        limit         = page_limit,
        startIndex    = start_index
      )
    )
    
    if (httr::status_code(resp) >= 400) {
      message("Request URL: ", resp$url)
      message("Error body: ", httr::content(resp, as = "text", encoding = "UTF-8"))
    }
    httr::stop_for_status(resp)
    
    parsed <- jsonlite::fromJSON(
      httr::content(resp, as = "text", encoding = "UTF-8"),
      flatten = TRUE
    )
    
    n <- if (!is.null(parsed$features)) nrow(parsed$features) else 0
    if (n == 0) break
    
    all_pages[[length(all_pages) + 1]] <- parsed$features
    start_index <- start_index + page_limit
    if (n < page_limit) break
  }
  
  if (length(all_pages) == 0) return(tibble())
  dplyr::bind_rows(all_pages)
}

get_station_ogc_safe <- function(id, ...) {
  tryCatch(
    get_station_ogc(id, ...),
    error = function(e) {
      message("Station ", id, " failed: ", conditionMessage(e))
      NULL
    }
  )
}


# extract data from SGU OGC API ----
SGU_data <- purrr::map_df(station_id, get_station_ogc_safe, from_year = year, to_year = year) |>
  dplyr::rename_with(~ sub("^properties\\.", "", .x))


# reformat SGU_data to match fmcom structure ----

### read master tables ----
station <- read.csv("data-raw/master_tables/stations_SGU_NRM.csv",
                    na.strings = c("", "NA"),
                    fileEncoding = "UTF-8",
                    stringsAsFactors = FALSE) |>
  dplyr::select(station, station_name, station_code_SGU, latitude, longitude, 
         water_type, HELCOM_basin, ICES_basin, ICES_station)

con <- read.csv("data-raw/master_tables/contaminants_SGU_NRM.csv") |>
  dplyr::select(contaminant, substance_group, contaminant_full_name, 
         contaminant_alt_name, UNIK_PARAMETERKOD, CAS_number) |>
  rename(contaminant_code_SGU = 'UNIK_PARAMETERKOD')

analytic <- read.csv("data-raw/master_tables/analytical_method_SGU_NRM.csv")

### reformat ----
data_new0 <- SGU_data %>%
  ### explicit mapping: fmcom column name = SGU_data column name ----
  transmute(
    specimen_ID = provkodoriginal,
    year        = provtagningsdatum |> lubridate::year(),
    month       = provtagningsdatum |> lubridate::month() |> 
                                       stringr::str_pad(width = 2, pad = "0"),
    day         = provtagningsdatum |> lubridate::day() |> 
                                       stringr::str_pad(width = 2, pad = "0"),
    date        = provtagningsdatum |> lubridate::as_date(),
    station_code_SGU       = nationellt_provplatsid,
    contaminant_code_SGU   = ntlkemiparameterid,
    value       = matvardetal,
    enhet       = enhet,
    matvstd     = matvstd,
    uncertainty = matosakerhet,
    art         = art,
    organ       = organ,
    kon         = kon,
    number_individuals     = antal,
    sample_ID   = rapportkodlabb,
    laboratorium  = laboratorium,
    analysinstrument       = analysinstrument,
    analysmetod = analysmetod
  ) |>
  ### join master table content ----
  left_join(station, by = c("station_code_SGU")) |> 
  left_join(con, by = c("contaminant_code_SGU")) 

### extract bio data ----
#### extract age, length, weight and isotopes, sample ID specific merge ----
bio_data <- filter(data_new0, (contaminant_code_SGU %in% c("CH02/90",
                   'CH04/8','CH04/9','CH08/15','CH12/161','CH12/163','CH12/232',
                   'CH12/234','CH12/239','CH12/241'))) |>
  dplyr::select(specimen_ID, contaminant, value) |>
  pivot_wider(names_from = contaminant, values_from = value) 

#### extract fat and dry weight percentages, specimen specific merge ----
frac_data <- filter(data_new0, 
                    (contaminant_code_SGU %in% c('CH12/68','CH12/224'))) |>
  dplyr::select(sample_ID, contaminant, value) |>
  distinct() |>
  pivot_wider(names_from = contaminant, values_from = value)

data_new <- data_new0 |>
  #### exclude bio data ----
  filter(substance_group != "Biological") |>
  #### initiate new columns ----
  mutate(species = NA_character_,
         species_EN = NA_character_,
         class = NA_character_,
         unit = NA_character_,
         sex = NA_character_,
         season = NA_character_,
         laboratory = NA_character_) |>
  #### add Latin and English species names ----
  mutate(
    species = case_when(
      art %in% c("Sill",  "Stromming") ~ "Clupea harengus",
      art == "Torsk" ~ "Gadus morhua",
      art == "Abborre" ~ "Perca fluviatilis",
      art == "Tanglake" ~ "Zoarces viviparus",
      art == "Blamussla" ~ "Mytilus edulis",
      art == "Sillgrissla" ~ "Uria aalge",
      art == "Fisktarna" ~ "Sterna hirundo",
      art == "Strandskata" ~ "Haematopus ostralegus",
      art == 'Roding' ~ 'Salvelinus alpinus',
      art == 'Gadda' ~ 'Esox lucius',
      art == 'Mort' ~ 'Rutilus rutilus',
      TRUE ~ species
    ),
    species_EN = case_when(
      art %in% c("Sill",  "Stromming" ) ~ "Atlantic herring",
      art == "Torsk" ~ "Atlantic cod",
      art == "Abborre" ~ "European perch",
      art == "Tanglake" ~ "Viviparous eelpout",
      art == "Blamussla" ~ "Blue mussel",
      art == "Sillgrissla" ~ "Common guillemot",
      art == "Fisktarna" ~ "Common Tern",
      art == "Strandskata" ~ "Eurasian oystercatcher",
      art == 'Roding'~'Arctic char',
      art == 'Gadda'~'northern pike',
      art == 'Mort'~'Roach',
      TRUE ~ species_EN
    )) |>
  #### add class ----
  mutate(
    class = case_when(
    species %in% c("Clupea harengus", "Gadus morhua","Perca fluviatilis",
                    "Zoarces viviparus",'Salvelinus alpinus',
                   'Esox lucius','Rutilus rutilus') ~ "Fish",
    species %in% c("Uria aalge","Sterna hirundo",
                   "Haematopus ostralegus") ~ "Bird", 
    species == 'Mytilus edulis' ~ "Bivalve",
    TRUE ~ class)
  ) |>
  #### rename units ----
  mutate(unit = case_when(
    enhet == 'ug.g-1.tv-1' ~ 'ug.g-1.dw-1', 
    enhet == 'ng.g-1.vv-1' ~ 'ng.g-1.ww-1',
    enhet == 'ng.g-1.tv-1' ~ 'ng.g-1.dw-1',
    enhet == 'ng.g-1.lv-1' ~ 'ng.g-1.lw-1',
    enhet == 'pg.g-1.lv-1' ~ 'pg.g-1.lw-1',
    enhet == 'ug.g-1.lv-1' ~ 'ug.g-1.lw-1')) |>
  #### change organ names to English ----
  mutate(organ = case_when(
    organ == 'LEVER' ~'Liver',
    organ == 'MUSKEL' ~ 'Muscle',
    organ == 'MJUKKROPP' ~ 'Soft tissue',
    organ == 'HELKROPP' ~ 'Whole ind',
    organ == 'AGG' ~ 'Egg content',
    TRUE ~ organ)) |>
  #### change sex ----
  mutate(sex = case_when(
    kon == 'M' ~ 'Male',
    kon == 'F' ~ 'Female',
    kon == 'X' ~ 'Mixed',
    kon == "H" ~ "Hermaphrodite",
    kon == "I" ~ "Immature",
    kon == 'U' ~ NA_character_,
    TRUE ~ sex
  )) |>
  #### add season ----
  mutate(season = case_when(
    month %in% c("01", "02") ~ "Winter",
    month %in% c("03", "04", "05", "06") ~ "Spring",
    month %in% c( "08", "09", "10", "11", "12") ~ "Autumn",
    month == "07" & day %in% c(1:15) ~ "Spring",
    month == "07" & day %in% c(16:31) ~ "Autumn",
    TRUE ~ season
  )) |>
  #### add LOQ_LOD ----
mutate(LOQ_LOD = case_when(
  is.na(matvstd) ~ '>LOQ',
  matvstd == "q"~ "<LOQ",
  matvstd == "b" ~ "<LOD",
  matvstd == "Ja"~ ">LOD, <LOQ"),
  is_censored = case_when(
    is.na(matvstd) ~ FALSE,
    matvstd %in% c("q", "b", "Ja") ~ TRUE,
    TRUE ~ FALSE
  )) |>
  #### add laboratory information ----
  left_join(analytic, by = c("analysmetod"="SGU_analytical.method", 
                             "analysinstrument"="SGU_instrument")) |>
  #### add labb ----
  mutate(laboratory = case_when(
    laboratorium == "UMU_KEM_INST" ~ "UMU",
    laboratorium == "LIVSMEDELSVERKET" ~ "SFA",
    laboratorium == "ACES" ~ "SU",
    laboratorium == "SLU" ~ "SLU",
    laboratorium == "IVL" ~ "IVL",
    TRUE ~ laboratory)) |>
  #### add bio data ----
  left_join(bio_data, by = "specimen_ID") |>
  mutate(age = ifelse(organ ==  "Egg content", 0, age)) |>
  #### add fat and dry weight percentages ----
  left_join(frac_data, by = "sample_ID") |>
  #### remove PFAS muscle samples, keep liver ----
  filter(!(substance_group == "PFAS" & organ == "Muscle"))


# merge fmcom and new data ----
### guarantee every fmcom column exists, even if lack in SGU_data ----
missing_cols <- setdiff(colnames(fmcom), colnames(data_new))
data_new[missing_cols] <- NA

### enforce fmcom column order ----
data_new <- data_new[, colnames(fmcom)]

#### NB temporary until partial dates are fixed
# make the new dates the same type as the master (character, YYYY-MM-DD)
data_new$date <- format(as.Date(data_new$date), "%Y-%m-%d")

stopifnot(identical(class(fmcom$date), class(data_new$date)))
####

### merge fmcom and new data ----
fmcom_updated <- rbind(fmcom, data_new)


# add suspected outlines ----
fmcom_updated$suspected_outlier <- FALSE
fmcom_updated$logvalue <- NA

for( i in unique(fmcom_updated$contaminant)) {
  for (j in unique(fmcom_updated$station_name)){
    for(k in unique(fmcom_updated$species[which(fmcom_updated$contaminant == i & fmcom_updated$station_name == j)])){
      
      test <- fmcom_updated|> filter(contaminant == i,   species == k, station_name == j, is_censored == FALSE) |>
        mutate(logvalue = log(value )) |>
        filter(logvalue != -Inf)
      if( length(unique(test$year)) > 10 ){
        
        test_lm <-MASS::rlm(logvalue ~ year , test)
        
        summary(test_lm)
        
        med = median(test_lm$residuals)
        # subtract median from each value of x and get absolute deviation
        abs_dev = abs(test_lm$residuals-med)
        # get MAD
        mad = 1.4826 * median(abs_dev)
        
        # get threshold values for outliers
        Tmin = med-(5*mad)
        Tmax = med+(5*mad)
        
        # find outlier
        outliers <- test_lm$residuals[which(test_lm$residuals > Tmax)]
        
        fmcom_updated$suspected_outlier[which (rownames(fmcom_updated) %in% names(outliers))] <- TRUE
        
      }
    }
    
  }
}

fmcom_updated <- fmcom_updated |> dplyr::select(-logvalue)


# save updated fmcom ----
str(fmcom_updated)

### check all numerical columns ----
fmcom_updated <- fmcom_updated |> mutate(across(c(year, number_individuals, value, uncertainty,
                                total_length, age, weight, fat_percentage,
                                dry_weight_percentage, egg_shell_thickness,
                                d13C, d15N, C_dw_percentage, N_dw_percentage,
                                latitude, longitude, ICES_station), as.numeric))


### excel file ----
readr::write_excel_csv2(fmcom_updated, paste0("data-raw/database", year,"/fmcom.csv"))

### RDS file ----
saveRDS(fmcom_updated, paste0("data-raw/database", year,"/fmcom.rds")) 
