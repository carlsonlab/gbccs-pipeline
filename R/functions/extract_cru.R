# First read in the CRU data for each variable of interest
# Explicitly set each layer to the variable name
# TODO: maybe use OS or similar to just grab all files in the data_dir? to avoid hard coding versions / years wihch might change
# NOTE: Also tried this with ncdf4, but ran into RAM issues
read_cru <- function(var, data_dir) {
  var_file <- paste0("cru_ts4.09.1901.2024.", var, ".dat.nc")
  var_path <- file.path(data_dir, var_file)

  r <- terra::rast(var_path, subds = var)

  # each layer = 1 momth
  names(r) <- paste0(var, "_", seq_len(terra::nlyr(r)))
  # gives back SpatRaster with dim [360, 720, 1488] = [lat, lon, time]
  return(r)
}

covs <- c("tmp", "tmn")
# covs <- c("tmp", "tmn", "tmx", "pre", "pet")

cru_data_dir <- here::here("data", "cru", "raw", "cru_ts_4.09")
cru <- lapply(covs, read_cru, cru_data_dir)
# name each spatraster with the variable
# so you can call cru$tmp
names(cru) <- covs

# TODO: Load polygon shapefiles to match Cholera data
# polys <- terra::vect("path/to/cholera.shp")
# # PLACEHOLDER: Africa for testing
# polys <- terra::ext(-30, 60, -37, 40) |> terra::as.polygons()
# polys$ID <- 1

extract_var <- function(cru_raster, var, polygons) {
  df <- terra::extract(cru_raster, polys, fun = mean, na.rm = TRUE)
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

# TODO: Consider targets options
tmp_mean <- extract_var(cru$tmp, "tmp", polys)
tmn_mean <- extract_var(cru$tmn, "tmn", polys)

long_cru <- tmp_mean %>%
  left_join(tmn_mean, by = c("ID", "date"))

out_path <- here::here("data", "cru", "clean")
out_name <- paste0("cru_all_vars_", format(Sys.Date(), "%Y%m%d"), ".csv")
write.csv(long_cru, file.path(out_path, out_name))
