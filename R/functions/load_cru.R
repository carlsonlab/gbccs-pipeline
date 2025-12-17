#' Load unbiased CRU data
#'
#' @title load_cru
#' @description This function downloads CRU TS 4.09 data for specified climate variables from CEDA website from 1901 to 2024 (most recent version as of Dec 2025)
#' @param covs A character vector of the covariates to download. Default is c("tmp", "tmn", "tmx", "pre", "pet") which is air temperature (mean, min, max), precipitation, and potential evapotranspiration.
#' @param file_format The file format of the data files. Default is "dat" which is the ASCII gridded format.
#' @return Nothing But downloads the files in the "data/cru/raw" directory.

load_cru <- function(covs = c("tmp", "tmn", "tmx", "pre", "pet"),
                     file_format = "dat") {
  base <- "https://data.ceda.ac.uk/badc/cru/data/cru_ts/cru_ts_4.09/data"

  output_dir <- here::here("data", "cru", "raw")

  for (var in covs) {
    file_name <- paste0("cru_ts4.09.1901.2024.", var, ".", file_format, ".gz")
    url <- paste0(base, "/", var, "/", file_name)
    dest <- file.path(output_dir, file_name)

    if (!file.exists(dest)) {
      download.file(url, destfile = dest, mode = "wb")
    } else {
      message(paste0("File", file_name, "already exists. Skipping download."))
    }
  }
}
