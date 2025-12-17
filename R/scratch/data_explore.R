#' let's look at this nonsense


surv_df <- readRDS(
    here::here("./data/cholera/raw/Public_surveillance_dataset.rds")
)
head(surv_df)
str(surv_df$spatial_scale)

unique(surv_df$spatial_scale)

# break location names into multiple columns
surv_df <- surv_df %>% tidyr::separate(
    location_name,
    into = c("region", "admin0", "admin1", "admin2", "admin3", "admin4"),
    fill = "right",
    sep = "::"
)

low_sp_scale <- surv_df[which(surv_df$spatial_scale %notin%
    c("admin1", "country", "admin2")), ]
head(low_sp_scale)
