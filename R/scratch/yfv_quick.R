library(tidyverse)
library(here)
library(sf)
library(geobr)
library(terra)

data_dir <- here::here("data")
output_dir <- here::here("output")
yfv <- read.csv(file.path(data_dir, "yfv/brazil_yfv_paho_1994-2024.csv"))

munis <- geobr::read_municipality(code_muni = "all", year = "2024")
states <- geobr::read_state(code_state = "all", year = "2020")
uq_munis <- unique(munis$code_muni)

yfv2 <- yfv %>%
  dplyr::filter(year >= 2000) %>%
  dplyr::group_by(adm2_code, year) %>%
  dplyr::summarize(cases = sum(cases), fatal_cases = sum(fatal_cases))

blank2 <- tidyr::expand_grid(adm2_code = uq_munis, year = 2000:2024)

yfv2 <- blank2 %>%
  dplyr::left_join(yfv2) %>%
  dplyr::mutate(
    cases = tidyr::replace_na(cases, 0),
    fatal_cases = tidyr::replace_na(fatal_cases, 0)
  )

yfv2 <- munis %>%
  dplyr::left_join(yfv2, by = c("code_muni" = "adm2_code")) %>%
  dplyr::select(code_muni, code_state, year, cases, fatal_cases)

p_facets <- ggplot(yfv2) +
  geom_sf(aes(fill = cases + 1), color = NA, linewidth = 0) +
  scale_fill_viridis_c(option = "mako", direction = -1, trans = "log10", na.value = "white") +
  facet_wrap(~year) +
  theme_minimal() +
  labs(fill = "YFV cases (log)")

ggsave(file.path(output_dir, "yfv_cases/yfv_adm2_cases_2000_2024_log.png"),
  plot = p_facets, width = 12, height = 8, dpi = 500
)

yfv1 <- yfv %>%
  st_drop_geometry() %>%
  group_by(code_state, year) %>%
  summarize(cases = sum(cases), fatal_cases = sum(fatal_cases))

yfv1 <- states %>% left_join(yfv1, by = c("code_state"))

p_adm1facets <- yfv1 %>%
  ggplot() +
  geom_sf(aes(fill = cases + 1), color = NA, linewidth = 0) +
  scale_fill_viridis_c(option = "mako", direction = -1, trans = "log10", na.value = "white") +
  facet_wrap(~year) +
  theme_minimal() +
  labs(fill = "YFV cases (log)")

ggsave(file.path(output_dir, "yfv_cases/yfv_adm1_cases_2000_2024_log.png"),
  plot = p_adm1facets, width = 12, height = 8, dpi = 500
)
