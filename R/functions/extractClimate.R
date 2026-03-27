#' Extract CRU polygon means and save to .csv
#'
#' @param covs String vector of covariates we want; by default this is including:
#' - tmp (montly average daily mean temp)
#' - tmn (monthly average daily min temp)
#' - tmx (monthly average daily max temp)
#' - pre (monthly rainfall)
#' - pet (potential evapotranspiration)
#' @param data_dir The directory with raw, unzipped CRU .dat.nc files (have to #' download these manually, as of writing! See README.md)
#' @param polygons File path to SpatVector of polygons (e.g., adm1 shapefiles)
#' - TODO: potentially write some function that defines the extent (e.g.,
#' Africa, global, whatever) and then uses that as a parameter so everything is
#' the right way
#' @param out_dir The directory for saving clean CRU extraction to CSV
#' @return cru_extract Tibble (1488 x 7) with columns
#' - ID: polygon ID (currently)
#' - date: %Y-%m-%d
#' - covs (above)

# Honestly I thought this would make it smaller to commit to Github but no
buildStack <- function(
    covs = c("tmp", "pre"),
    data_dir = here::here("data", "cru", "raw", "cru_ts_4.09"),
    stack_file = file.path(data_dir, "cru_ts_4.09_stacked.tif")) {
  # HELPER: read in the CRU data for each variable of interest
  # Explicitly set each layer to the variable name
  # TODO: maybe use OS or similar to just grab all files in the data_dir? to avoid hard coding versions / years wihch might change
  # NOTE: Also tried this with ncdf4, but ran into RAM issues
  readClimate <- function(var, data_dir) {
    var_file <- paste0("cru_ts4.09.1901.2024.", var, ".dat.nc")
    var_path <- file.path(data_dir, var_file)

    # 0.5 x 0.5, CRS84 for cru
    r <- terra::rast(var_path, subds = var)

    # each layer = 1 momth
    names(r) <- paste0(var, "_", seq_len(terra::nlyr(r)))
    # gives back SpatRaster with dim [360, 720, 1488] = [lat, lon, time]
    return(r)
  }

  cru_list <- lapply(covs, readClimate, data_dir)
  cru_stack <- do.call(c, cru_list)
  message("Saving!")
  terra::writeRaster(
    cru_stack,
    stack_file,
    overwrite = TRUE
  )
  message("Done!")
  return(stack_file)
}

extractClimate <- function(
    stack_file = stack_file,
    polygons,
    out_dir = here::here("data", "cru", "clean")) {
  cru_stack <- terra::rast(stack_file)
  # I'm not sure I should do this (reproject???) - don't think it makes a big difference though
  # NOTE: polygons needs to be a terravector
  # NOTE/TODO: CRU projection needs to match the polygon projection and extent
  polygons <- terra::vect(polygons)
  polygons <- terra::project(polygons, terra::crs(cru_stack))
  cru_stack <- terra::crop(cru_stack, polygons)
  message("Finished the polygons!")


  # Currently uses an area-weighted average, so gives mean weighted by fraction of each CRU grid cell within the admin polygon
  # Makes only a slight difference if we use weights or not
  # TODO: plot / do sensitivity analysis at administrative level
  message("Extracting the means!")
  df <- terra::extract(cru_stack, polygons, fun = mean, na.rm = TRUE, weights = TRUE)
  message("Done with the means!")

  dates <- terra::time(cru_stack)

  long <- df |>
    tidyr::pivot_longer(
      cols = -ID,
      names_to = "layer",
      values_to = "value"
    ) |>
    tidyr::separate(layer, into = c("var", "layer_id"), sep = "_") |>
    dplyr::mutate(
      layer_id = as.integer(layer_id),
      date = dates[layer_id]
    ) |>
    dplyr::select(ID, date, var, value)

  wide <- tidyr::pivot_wider(
    long,
    names_from = var,
    values_from = value
  )


  out_name <- paste0("cru_all_vars_", format(Sys.Date(), "%Y%m%d"), ".csv")
  write.csv(wide, file.path(out_dir, out_name))

  return(wide)
}
