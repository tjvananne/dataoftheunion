

# NAICS industry code change mapping tables 


# Script config -------

FILE_NAME_2012_TO_2017 <- "proc_data/NAICS_2012_to_2017_map.csv"


# Load libs -----

library(dplyr)
library(rvest)
library(xml2)

# Scrape changes -----

url <- "https://www.naics.com/naics-resources/2017-naics-changes-preview/"
urldata <- xml2::read_html(url)
urltables <- rvest::html_table(urldata)
industry_code_mapper <- urltables[[1]]
names(industry_code_mapper)
industry_code_mapper <- industry_code_mapper %>%
    rename(
        industry_code_2017=`2017 NAICS Codes`,
        industry_title_2017=`2017 NAICS Descriptions`,
        industry_code_2012=`2012 NAICS Codes`,
        industry_title_2012=`2012 NAICS Descriptions`
    )
write.csv(industry_code_mapper, FILE_NAME_2012_TO_2017, row.names=F)

