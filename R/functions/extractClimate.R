#' Extract CRU polygon means and save
#'
#' @param covs String vector of covariates we want; by default this is including:
#' - tmp (montly average daily mean temp)
#' - tmn (monthly average daily min temp)
#' - tmx (monthly average daily max temp)
#' - pre (monthly rainfall)
#' - pet (potential evapotranspiration)
#' @param data_dir The directory with raw CRU .dat.nc files
#' @param polygons File path to SpatVector of polygons
#' @param out_dir The directory for saving clean CRU extraction to CSV
#' @return cru_extract Tibble (1488 x 7) with columns
#' - ID: polygon ID (currently)
#' - date: %Y-%m-%d
#' - covs (above)

extractClimate <- function(
    covs = c("tmp", "tmn", "tmx", "pre", "pet"),
    data_dir = here::here("data", "cru", "raw", "cru_ts_4.09"),
    polygons, # e.g., = terra::vect("path/to/cholera.shp")
    out_dir = here::here("data", "cru", "clean")) {
  # HELPER: read in the CRU data for each variable of interest
  # Explicitly set each layer to the variable name
  # TODO: maybe use OS or similar to just grab all files in the data_dir? to avoid hard coding versions / years wihch might change
  # NOTE: Also tried this with ncdf4, but ran into RAM issues
  readClimate <- function(var, data_dir) {
    var_file <- paste0("cru_ts4.09.1901.2024.", var, ".dat.nc")
    var_path <- file.path(data_dir, var_file)

    r <- terra::rast(var_path, subds = var)

    # each layer = 1 momth
    names(r) <- paste0(var, "_", seq_len(terra::nlyr(r)))
    # gives back SpatRaster with dim [360, 720, 1488] = [lat, lon, time]
    return(r)
  }

  # HELPER: extract the variable means for each polygon for each month
  extractVar <- function(cru_raster, var, polygons) {
    df <- terra::extract(cru_raster, polygons, fun = mean, na.rm = TRUE)
    dates <- terra::time(cru_raster)
    long <- df %>%
      tidyr::pivot_longer(
        cols = -ID,
        names_to = "layer",
        values_to = var
      ) %>%
      dplyr::mutate(
        layer = as.integer(gsub(paste0(var, "_"), "", layer)),
        date = dates[layer]
      ) %>%
      dplyr::select(-layer)
    return(long)
  }

  cru <- lapply(covs, readClimate, data_dir)
  names(cru) <- covs

  all_vars <- lapply(seq_along(covs), function(i) {
    extractVar(cru[[i]], covs[i], polygons)
  })

  # Merge it all into one table with one row per time/place
  # TODO: Consider one row per time/place/cov....
  cru_extract <- all_vars[[1]]
  for (i in 2:length(all_vars)) {
    cru_extract <- dplyr::left_join(cru_extract, all_vars[[i]], by = c("ID", "date"))
  }

  out_name <- paste0("cru_all_vars_", format(Sys.Date(), "%Y%m%d"), ".csv")
  write.csv(cru_extract, file.path(out_dir, out_name))

  return(cru_extract)
}
