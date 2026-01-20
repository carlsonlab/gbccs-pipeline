#' Load raw, unbiased CRU data.
#' NOTE: THIS IS CURRENTLY DEPRECATED!! In theory it would work, but you actually just have to point and click all the files on their site and unzip them manually to get uncorrupted versions.
#'
#' @title load_cru
#' @description This function downloads and unzips CRU TS 4.09 data for specified climate variables from CEDA website from 1901 to 2024 (most recent version as of Dec 2025)
#' @source University of East Anglia Climatic Research Unit; Harris, I.C.; Jones, P.D.; Osborn, T. (2025): CRU TS4.09: Climatic Research Unit (CRU) Time-Series (TS) version 4.09 of high-resolution gridded data of month-by-month variation in climate (Jan. 1901- Dec. 2024). NERC EDS Centre for Environmental Data Analysis, 14 Jan 2026. https://catalogue.ceda.ac.uk/uuid/9cf07e92afaa405da4f40b6733f362d3
#' @param covs A character vector of the covariates to download. Default is c("tmp", "tmn", "tmx", "pre", "pet") which is air temperature (mean, min, max), precipitation, and potential evapotranspiration.
#' @param file_format The file format of the data files. Default is "dat.nc" which is the NetCDF format.
#' @return Nothing But downloads and unzips the files in the "data/cru/raw" directory.

# TODO: Come back to this and make it handle access tokens correctly (???)


# , "tmn", "tmx", "pre", "pet"
load_cru <- function(covs = c("tmp"),
                     file_format = "dat.nc",
                     token = CEDA_TOKEN) {
  # HELPER Generate new Archive Access Token from CEDA website
  get_token <- function() {
    user <- Sys.getenv("CEDA_USERNAME")
    pass <- Sys.getenv("CEDA_PASSWORD")

    resp <- httr2::request(
      "https://services.ceda.ac.uk/api/token/create/"
    ) |>
      httr2::req_auth_basic(user, pass) |>
      httr2::req_headers(Accept = "application/json") |>
      httr2::req_method("POST") |>
      httr2::req_perform()

    httr2::resp_check_status(resp)

    httr2::resp_body_json(resp)$access_token
  }
  base <- "https://dap.ceda.ac.uk/badc/cru/data/cru_ts/cru_ts_4.09/data/"
  output_dir <- here::here("data", "cru", "raw", "test")

  for (var in covs) {
    file_name <- paste0("cru_ts4.09.1901.2024.", var, ".", file_format, ".gz")
    url <- paste0(base, var, "/", file_name)
    dest <- file.path(output_dir, file_name)

    if (!file.exists(dest)) {
      req <- httr2::request(url) |>
        httr2::req_auth_bearer_token(token) |>
        httr2::req_method("GET")

      resp <- httr2::req_perform(req)
      if (httr2::resp_status(resp) == 401) {
        token <- get_ceda_token()
        resp <- httr2::request(url) |>
          httr2::req_auth_bearer_token(token) |>
          httr2::req_method("GET") |>
          httr2::req_perform()
      }
      httr2::resp_check_status(resp)
      httr2::resp_body_raw(resp) |>
        writeBin(dest)

      R.utils::gunzip(
        dest,
        destname = substr(dest, 1, nchar(dest) - 3),
        remove = FALSE
      )
    }

    # if (!file.exists(dest)) {
    #   download.file(url, destfile = dest, mode = "wb")
    #   # unzipping .gz but keeping them in the folder
    #   # dest is the compressed file path, destname is the uncompressed file inside (the way splicing is INSANE in R???????)
    #   R.utils::gunzip(dest, destname = substr(dest, 1, nchar(dest) - 3), remove = FALSE)
    # } else {
    #   message(paste0("File", file_name, "already exists. Skipping download."))
    # }
  }
}
