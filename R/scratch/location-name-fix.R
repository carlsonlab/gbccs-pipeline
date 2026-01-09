##' DESCRIPTION:
#' A scratch file to try and fix the location naming problem so that we don't
#' have to deal with it later. just scripting this out, no need for anything
#' fancy I think

# Public Surveillance Dataset --------------------------------------------------
df_surv <- readRDS(
    here::here("./data/cholera/raw/Public_surveillance_dataset.rds")
)
head(df_surv)

# what's the max number of the "::" separaters we have?
hist(stringr::str_count(df_surv$location_name, pattern = "::"))
new_names <- tibble::as_tibble(
    stringr::str_split_fixed(df_surv$location_name, "::", 5)
)
names(new_names) <- c(
    "region",
    "adm0",
    "adm1",
    "adm2",
    "adm3"
)
df_surv <- cbind(df_surv, new_names)
readr::write_csv(
    df_surv,
    here::here("./data/cholera/clean/public_surveillance.csv")
)

# Public Outbreak Dataset ------------------------------------------------------
df_out <- readRDS(
    here::here("./data/cholera/raw/Public_outbreak_dataset.rds")
)

nrow(df_out)
unique(df_out$spatial_scale)
unique(df_out[which(df_out$spatial_scale == "admin3"), "location_name"])
unique(df_out$location_name)

# what's the max number of the "::" separaters we have?
hist(stringr::str_count(df_out$location_name, pattern = "::"))
new_names <- tibble::as_tibble(
    stringr::str_split_fixed(df_out$location_name, "::", 5)
)
names(new_names) <- c(
    "region",
    "adm0",
    "adm1",
    "adm2",
    "adm3"
)
df_out <- cbind(df_out, new_names)
readr::write_csv(
    df_out,
    here::here("./data/cholera/clean/public_outbreaks.csv")
)
