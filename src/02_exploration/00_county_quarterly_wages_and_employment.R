

list.files('proc_data')

library(dplyr)
library(tidyr)
library(ggplot2)
library(rvest)
library(xml2)
# library()

# read data ----------

# let's compare Q1 to Q1

# this is using 2012 NAICS industry codes still...
df_old <- readRDS("proc_data/00_QCEW_2014_COUNTY_DETAILED.rds")
df_old <- df_old[df_old$qtr == 1,]
gc()

industry_code_map <- read.csv("proc_data/NAICS_2012_to_2017_map.csv", stringsAsFactors = F)


# The Plan:
# change 2012 industry code name to match what is in industry code map for 2012
# join in the new 2017 code and rename it to be the same as what it is in 2018 data

# let's redo this to use "rename" in dplyr?
df_old$industry_code_2012 <- df_old$industry_code
df_old$industry_code <- NULL
df_old$industry_title <- NULL
df_old <- merge(x=df_old, y=industry_code_map, by="industry_code_2012", all.x=T, all.y=F)
df_old$industry_code_2012 <- NULL
df_old$industry_title_2012 <- NULL
df_old$industry_code <- df_old$industry_code_2017
df_old$industry_title <- df_old$industry_title_2017
df_old$industry_code_2017 <- NULL
df_old$industry_title_2017 <- NULL

# there are a ton of NA values now... need to check on this
sapply(df_old, function(x) sum(is.na(x)))


df_old$industry_code_2012 <- df_old$industry_code



# this is using new 2017 NAICS industry codes...
df_new <- readRDS("proc_data/00_QCEW_2018_COUNTY_DETAILED.rds")
df_new <- df_new[df_new$qtr == 1,]
gc()

# > any industries pop up or drop out? --------
industry_codes <- unique(
    rbind(
        df_new[, c("industry_code", "industry_title")],
        df_old[, c("industry_code", "industry_title")]
    )
)

# sectors that have dropped out?
industry_codes$industry_title[
    industry_codes$industry_code %in% setdiff(df_old$industry_code, df_new$industry_code)]

# sectors that have popped up?
industry_codes$industry_title[
    industry_codes$industry_code %in% setdiff(df_new$industry_code, df_old$industry_code)]



# > industry codes have changed -----

# Popped up   "NAICS 452311 Warehouse clubs and supercenters"
# dropped out "NAICS12 452910 Warehouse clubs and supercenters"

industry_codes$industry_title[grepl("warehouse", industry_codes$industry_title, ignore.case = T)]
df_old[, c("industry_code", "industry_title")][df_old$industry_code == 452311,] %>% unique()
df_old[, c("industry_code", "industry_title")][df_old$industry_code == 452910,] %>% unique()


# this industry code changed...
# https://www.census.gov/cgi-bin/sssd/naics/naicsrch?code=452311&search=2017%20NAICS%20Search







