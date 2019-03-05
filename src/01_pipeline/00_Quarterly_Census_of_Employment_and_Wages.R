

# Quarterly Census of Employment and Wages
# https://www.bls.gov/cew/datatoc.htm

library(RCurl)
library(rvest)
library(dplyr)
library(data.table)  # just for the fread()
library(openxlsx)

build_qcew_query <- function(p_year) {
    paste0("https://data.bls.gov/cew/data/files/", p_year,
           "/csv/", p_year, "_qtrly_singlefile.zip")
}


zip_file <- RCurl::getURI(build_qcew_query(2018))

zip_file <- RCurl::getURLContent("https://data.bls.gov/cew/data/files/2018/csv/2018_qtrly_singlefile.zip")
raw_data <- unzip(zip_file)
class(zip_file)


# can we use something from readr instead of read.table?
library(readr)
# readr::read_table
# ?readr::read_table2()

temp <- tempfile()  # <-- create temporary file in memory
download.file(build_qcew_query(2018),temp)  # download into that temp file
unzip(temp, list=T)  # list the contents of that temp file so you know what to extract
data <- read.table(unz(temp, "2018.q1-q2.singlefile.csv"))  # read.table is single-threaded very slow
data <- fread(unz(temp, "2018_qtrly_singlefile.zip"))

head(data)

unlink(temp)


?getURL



# https://data.bls.gov/cew/data/files/2018/csv/2018_qtrly_singlefile.zip






