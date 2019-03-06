

# download and unzip INTO memory

# INFO ------------------

# This script has been built with the intention that it is 
# entirely reproducible. No need to go download a file or 
# set up your directory structure a special way. 

# the only pre-work necessary is to make sure you have the 
# packages that I'm using installed in your environment.


# Quarterly Census of Employment and Wages
# https://www.bls.gov/cew/datatoc.htm


# LOAD LIBS ------------

library(RCurl)  # web request
library(dplyr)  # data manipulation
library(readr)  # fast reading of binary data (read_table)
library(tidyr)  # more data manipulation


# HELPER FUNCS ---------


# build the URL to query for data zip file
build_qcew_query <- function(p_year) {
    paste0("https://data.bls.gov/cew/data/files/", p_year,
           "/csv/", p_year, "_qtrly_singlefile.zip")
}


# DOWNLOAD AND READ ZIP FILE ---------
temp      <- tempfile()  
download.file(build_qcew_query(2018),temp)  


# read.table is much much slower, but more robust to embedded double quotes
file_name <- unzip(temp, list=T)[[1]]  
df        <- read_table(unz(temp, file_name))  
rm(temp)
gc()


# clean up the column names (embedded quotes)
colnames_quoted <- names(df) %>%
  strsplit(split=",") %>%
  unlist() 
colnames <- gsub('\"', '', colnames_quoted)
  

# remove embedded quotes from the data
df <- data.frame(lapply(df, function(x) gsub('\"', '', x)), stringsAsFactors = F)
gc()

# give the one and only column a more reasonable name for now
names(df) <- 'V1'
df <- tidyr::separate(df, col=V1, sep=',', into=colnames)
gc()

df$qtr %>% unique() 





