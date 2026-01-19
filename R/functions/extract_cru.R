# covs <- c("tmp", "tmn", "tmx", "pre", "pet")
covs <- c("tmp")
cru_data_dir <- here::here("data", "cru", "raw", "cru_ts_4.09")

# TODO: Load polygon shapefiles to match Cholera data

# First read in the CRU data for each variable of interest
# Explicitly set each layer to the variable name
read_cru <- function(var, data_dir) {
  var_file <- paste0("cru_ts4.09.1901.2024.", var, ".dat.nc")
  var_path <- file.path(data_dir, var_file)
  ncdf <- ncdf4::nc_open(var_path)
  # must explicitly close for future bootstrpaping
  on.exit(ncdf4::nc_close(ncdf))

  # so to call will be like:
  # cru$tmp$data
  # cru$tmp$time
  list(
    # dim(cru$tmp$data) = 720 360 1488 [lon, lat, time]
    data = ncdf4::ncvar_get(ncdf, var),
    lon = ncdf4::ncvar_get(ncdf, "lon"),
    lat = ncdf4::ncvar_get(ncdf, "lat"),
    time = ncdf4::ncvar_get(ncdf, "time")
  )
}

cru <- lapply(covs, read_cru, data_dir = cru_data_dir)
names(cru) <- covs

# TODO: Convert time to dates maybe?

# Validate dimensions since...
# native CRU is x = lat, y = lon format
# but that's different from native raster format (x = lon, y = lat)
check_dims <- function(x) {
  dim(x$data)[1] == length(x$lon)
}
lapply(cru, check_dims)

# Convert into raster native
# Transposing the slice and flipping to lon-lat
make_raster <- function(cru_slice) {
  r <- raster::raster(t(cru_slice))
  r <- raster::flip(r, direction = "y")
  # raster::extent(r) <- c(-180, 180, -90, 90)
}

# TODO: Make raster stack

# TODO: Extract polygon means
# Loop over time (in months?)
# for each month (cru$var$data)[,,i]
# make a raster for month i
# then extract mean values for each polygon

# TODO: Convert to tidy long
# Split into month/year/var
# Save as csv...
