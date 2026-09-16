
version <- "0.2.0.pre"
releasepath <- "/Volumes/bwh-sleepepi-nsrr-staging/20230418-klerman-fdcsr/nsrr-prep/_releases"

library(readxl)
library(dplyr)
library(readr)
library(stringr)
library(janitor)

sourcepath <- "/Volumes/bwh-sleepepi-nsrr-staging/20230418-klerman-fdcsr/nsrr-prep/_source"
  
numeric_vars <- c("age", "first_bl_sp", "last_bl_sp", "hab_wake", "hab_bed", "fd_t_cycle", "fd_sp_length", "fd_wp_length",
                  "start_analysis", "end_analysis", "start_analysis_s_pn", "end_analysis_s_pn_included",
                  "mel_tau", "mel_comp_amp", "mel_amp_circad", "mel_amp_t", "mel_comp_max", "mel_fund_max", 
                  "cbt_tau", "cbt_comp_ampl", "cbt_amp_circad", "cbt_amp_t", "cbt_comp_min", "cbt_fund_min")


df_1 <- read_excel(file.path(sourcepath, "FD-info_nsrr 2023a.xls")) |>
  clean_names()|>
  mutate(
    subject = if_else(subject == "1366HX", "1366HX4T2", subject) ##in notes states that these two IDs are the same
  ) 

df_2 <- read_excel(file.path(sourcepath, "Study Info - 2026a to NSRR.xlsx")) |>
  clean_names() 

  
##these datasets are largely the same, df2 has First BL SP and Last BL SP. Notes
#df1 has Hab Wake Hab Bed, EST/DST and last three file indicator columns. 

# ##inspect the IDs available:
# ids1 <- df_1$subject
# ids2 <- df_2$subject
# 
# setdiff(ids1, ids2) #"1366HX" "2091W" (in first release but not in second)
# setdiff(ids2, ids1) #"1366HX4T2" -> also 1366HX
# 
# common_vars <- intersect(
#   setdiff(names(df_1), "subject"),
#   setdiff(names(df_2), "subject")
# )

# Convert overlapping variables to character so joins/coalesce won't fail
df_1 <- df_1 |>
  mutate(across(all_of(common_vars), as.character))

df_2 <- df_2 |>
  mutate(across(all_of(common_vars), as.character))


##prepare nsrr dataset combining two releases
df_combined <- full_join(
  df_1,
  df_2,
  by = "subject",
  suffix = c("_2023", "_2026")
)

# Prefer 2026 version value, use 2023 if 2026 is missing
for (v in common_vars) {
  df_combined[[v]] <- coalesce(
    df_combined[[paste0(v, "_2026")]],
    df_combined[[paste0(v, "_2023")]]
  )
}

df_clean <- df_combined |>
  select(
    subject,
    all_of(common_vars),
    everything(),
    -any_of(paste0(common_vars, "_2023")),
    -any_of(paste0(common_vars, "_2026"))
  ) |>
  mutate(across(any_of(numeric_vars), as.numeric)) |>
  relocate(c(study2, study_code), .after = study) |>
  relocate(c(drug_placebo_no_drug, drug_no_drug_or_placebo, first_bl_sp, last_bl_sp, hab_wake, hab_bed), .after = hab_csr) |>
  select(-c(drug_no_drug_or_placebo)) |>
  mutate(across(all_of(numeric_vars)))


write.csv(df_clean, file.path(releasepath, paste0(version, "/fdcsr-dataset-", version, ".csv")), na = "", row.names = F)

##prepare harmonized dataset

df_h <- df_clean |>
  mutate(
    nsrr_age = case_when(
      age > 89 ~ 90,
      age <= 89 ~ as.numeric(age),
      TRUE ~ NA_real_
    ),
    # Sex
    nsrr_sex = case_when(
      gender == "M" ~ "male",
      gender == "F" ~ "female",
      is.na(gender) ~ "not reported",
      TRUE ~ NA_character_
    ),
    nsrrid = subject) |>
  select(nsrrid, nsrr_age, nsrr_sex)

