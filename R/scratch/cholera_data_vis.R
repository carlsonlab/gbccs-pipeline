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


# Spatial exploration ----------------------------------------------------------
pak::pkg_install("sf")
surv_shp <- readRDS(
    here::here("./data/cholera/raw/Public_surveillance_shapefiles.rds")
)
str(surv_shp)
