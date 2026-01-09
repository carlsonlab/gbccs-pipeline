##' DESCRIPTION: Here are some basic visuals to get a sense of what the data
#' contain and what we might need to know about them
#' AUTHOR: Cole
#' DATE: 09 January 2025

surv_df <- readr::read_csv(
    here::here("./data/cholera/clean/public_surveillance.csv")
)

# Basic exploration ------------------------------------------------------------
names(surv_df)

# how many cases are filled on "assumptions" (whatever that means)
table(surv_df$phantom)

# how many unique locations are there?
length(unique(surv_df$location_name))
length(unique(surv_df$adm0))
length(unique(surv_df$region))
length(unique(surv_df$location_period_id))

# Spatial exploration ----------------------------------------------------------
library(ggplot2)
library(sf)

surv_shp <- readRDS(
    here::here("./data/cholera/raw/Public_surveillance_shapefiles.rds")
)

unique(surv_shp$location_period_id)
sf::st_crs(surv_shp$geometry[[1]])

# I think we can actually stitch this thing together into a map that has pretty
# much all the information we could want? Going to try to do this by:
#   1. creating a dataframe where the location names and the period ID are
#      all together in a useable format
#   2. then I'll bind the various sfg (polygons) together so I can use then as
#      as a single object that shares geometry

# this is slow...
surv_full <- dplyr::left_join(
    surv_shp,
    surv_df |>
        dplyr::select(
            location_period_id, spatial_scale,
            region, adm0, adm1, adm2, adm3
        ) |>
        dplyr::mutate(location_period_id = as.character(location_period_id)),
    by = "location_period_id"
)

class(surv_full)
# there's no CRS defined so I'm going to set it go WGS84 Sinusoidal -- the no
# CRS is actually because it's not a proper sfc object yet, but we're fixing
# that, so we can re-project it in an actual form
# surv_full$geometry <- sf::st_as_sfc(surv_full$geometry, crs = 3832)

# this takes forever and needs a lot of RAM
surv_full <- sf::st_transform(surv_full, crs = 3832)

surv_full <- dplyr::left_join(
    surv_full,
    surv_df |>
        dplyr::select(location_period_id, spatial_scale) |>
        dplyr::mutate(location_period_id = as.character(location_period_id)),
    by = "location_period_id"
)

# save the output -- this is like 4.6GB????
qs::qsave(surv_full, here::here("./data/cholera/clean/surv_geospatial.qs"))

ggplot() +
    geom_sf(data = surv_full$geometry[[1]], fill = "lightgrey")

# let's look at just the country ones
surv_country <- surv_full |>
    dplyr::filter(spatial_scale == "")
