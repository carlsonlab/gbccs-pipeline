#' let's look at this nonsense

`%notin%` <- Negate(`%in%`)

surv_df <- readRDS(
    here::here("./data/cholera/raw/Public_surveillance_dataset.rds")
)
head(surv_df)
str(surv_df$spatial_scale)

unique(surv_df$spatial_scale)


low_sp_scale <- surv_df[which(surv_df$spatial_scale %notin%
    c("admin1", "country", "admin2")), ]
head(low_sp_scale)
