library(tidyverse)
library(here)
library(sf)
library(geobr)
library(terra)

data_dir <- here::here("data")
yfv <- read.csv(file.path(data_dir, "yfv/brazil_yfv_paho_1994-2024.csv"))

codigos <- geobr::read_municipality(code_muni = "all", year = "2024")
uq_codis <- unique(codigos$code_muni)

yfv <- yfv %>%
  dplyr::group_by(adm2_code, year) %>%
  dplyr::summarize(cases = sum(cases), fatal_cases = sum(fatal_cases))

blank <- tidyr::expand_grid(adm2_code = uq_codis, year = 1994:2024)

yfv <- blank %>%
  dplyr::left_join(yfv) %>%
  dplyr::mutate(cases = tidyr::replace_na(cases, 0), fatal_cases = tidyr::replace_na(fatal_cases, 0))

yfv <- codigos %>%
  dplyr::left_join(yfv, by = c("code_muni" = "adm2_code")) %>%
  dplyr::select(code_muni, year, cases, fatal_cases)

yfv %>%
  filter(year == 2017) %>%
  ggplot() +
  geom_sf(aes(
    fill = cases,
    colour = ggplot2::after_scale(fill),
    linewidth = I(0.3)
  )) +
  scale_fill_gradient()
