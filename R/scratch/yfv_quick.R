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
  theme_void() +
  labs(fill = "YFV cases (log)")

ggsave(file.path(output_dir, "yfv_cases/yfv_adm2_cases_2000_2024_log.png"),
  plot = p_facets, bg = "white", width = 12, height = 8, dpi = 500
)

yfv1 <- yfv2 %>%
  st_drop_geometry() %>%
  group_by(code_state, year) %>%
  summarize(cases = sum(cases), fatal_cases = sum(fatal_cases))

yfv1 <- states %>% left_join(yfv1, by = c("code_state"))

p_adm1facets <- yfv1 %>%
  ggplot() +
  geom_sf(aes(fill = cases + 1), color = NA, linewidth = 0) +
  scale_fill_viridis_c(option = "mako", direction = -1, trans = "log10", na.value = "white") +
  facet_wrap(~year) +
  theme_void() +
  labs(fill = "YFV cases (log)")

ggsave(file.path(output_dir, "yfv_cases/yfv_adm1_cases_2000_2024_log.png"),
  plot = p_adm1facets, bg = "white", width = 12, height = 8, dpi = 500
)

temp <- terra::rast(file.path(data_dir, "cru/raw/cru_ts_4.09/cru_ts4.09.1901.2024.tmp.dat.nc"))["tmp"]
prec <- terra::rast(file.path(data_dir, "cru/raw/cru_ts_4.09/cru_ts4.09.1901.2024.pre.dat.nc"))["pre"]

states <- sf::st_transform(munis, crs(temp))
munis <- sf::st_transform(munis, crs(temp))

years <- 2000:2024
months_idx <- function(year) ((year - 1901) * 12 + 1):((year - 1901 + 1) * 12)
prec_annual <- rast()
temp_annual <- rast()

for (y in years) {
  idx <- months_idx(y)
  prec_annual <- c(prec_annual, mean(prec[[idx]]))
  temp_annual <- c(temp_annual, mean(temp[[idx]]))
}
names(prec_annual) <- paste0("pre_", years)
names(temp_annual) <- paste0("tmp_", years)

adm2_climate <- data.frame()

for (i in seq_along(years)) {
  y <- years[i]
  t_vals <- terra::extract(temp_annual[[i]], vect(munis), fun = mean, na.rm = TRUE)[, 2]
  p_vals <- terra::extract(prec_annual[[i]], vect(munis), fun = mean, na.rm = TRUE)[, 2]

  df <- data.frame(
    code_muni = munis$code_muni,
    name_muni = munis$name_muni,
    year = y,
    temp = t_vals,
    prec = p_vals
  )

  adm2_climate <- bind_rows(adm2_climate, df)
}

library(brpop)

pop <- brpop::mun_pop_totals(source = "datasus2024")

yfv2 <- yfv2 %>%
  dplyr::left_join(pop, by = c("code_muni" = "code_muni", "year" = "year"))

yfv2 <- yfv2 %>% dplyr::left_join(adm2_climate, by = c("code_muni" = "code_muni", "year" = "year"))

yfv2 %>% ggplot(aes(x = temp, y = log10(cases + 1))) +
  geom_point(alpha = 0.1)

yfv2 %>% ggplot(aes(x = prec, y = log10(cases + 1))) +
  geom_point(alpha = 0.1)

library(mgcv)

model <- gam(
  cases ~ s(temp, bs = "cr") +
    s(prec, bs = "cr") +
    offset(log(pop + 1)),
  data = yfv2,
  family = ziP(),
  method = "REML"
)
png(file.path(output_dir, "yfv_cases/yfv_gam_ziP_adm2_2000-2024.png"),
  width = 12, height = 8, units = "in", res = 500
)
plot.gam(model, pages = 1)
dev.off()

preds <- mgcv::predict.gam(model, yfv2, type = "response")

yfv2$preds <- preds
yfv2 %>%
  ggplot(aes(x = cases + 1, y = preds + 1)) +
  geom_point(alpha = 0.05) +
  scale_x_log10() +
  scale_y_log10() +
  geom_smooth(method = "lm")


p_preds_facets <- ggplot(yfv2) +
  geom_sf(aes(fill = preds + 1), color = NA, linewidth = 0) +
  scale_fill_viridis_c(
    option = "mako",
    direction = -1,
    trans = "log10",
    na.value = "white",
    name = "Predicted YFV cases (log)"
  ) +
  facet_wrap(~year) +
  theme_void() +
  labs(title = "Predicted Yellow Fever cases by municipality, 2000-2025")

ggsave(
  file.path(output_dir, "yfv_cases/yfv_adm2_predicted_cases_2000_2024_log.png"),
  plot = p_preds_facets,
  bg = "white",
  width = 12,
  height = 8,
  dpi = 500
)

yfv2 <- yfv2 %>%
  mutate(diff = cases - preds)

p_diff_facets <- ggplot(yfv2) +
  geom_sf(aes(fill = diff), color = NA, linewidth = 0) +
  scale_fill_gradient2(
    low = "blue",
    mid = "grey",
    high = "red",
    na.value = "grey80",
    name = "Observed - Predicted"
  ) +
  facet_wrap(~year) +
  theme_minimal() +
  labs(title = "Difference between observed and predicted YFV cases by municipality")

ggsave(
  file.path(output_dir, "yfv_cases/yfv_adm2_diff_obs_pred_1994_2024.png"),
  plot = p_diff_facets,
  width = 12,
  height = 8,
  dpi = 500
)


p_temp_cases <- ggplot(yfv2, aes(x = year, y = cases, group = code_muni, color = temp)) +
  geom_line(alpha = 0.3, linewidth = 0.5) +
  scale_color_viridis_c(option = "magma", direction = -1) +
  labs(
    x = "Year",
    y = "YFV Cases",
    color = "Temperature (°C)"
  ) +
  theme_minimal()

ggsave(file.path(output_dir, "yfv_cases/yfv_adm2_temp_cases_2000-2024.png"), plot = p_temp_cases, width = 12, height = 8, dpi = 500)
