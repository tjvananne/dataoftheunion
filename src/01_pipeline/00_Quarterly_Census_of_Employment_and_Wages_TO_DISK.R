

# Quarterly Census of Employment and Wages 
# download and unzip to DISK (low memory solution)

# I'm targeting a machine with ~8GB RAM so that
# most people can also run this code

# INFO ------------------

# This script has been built with the intention that it is 
# entirely reproducible. No need to go download a file or 
# set up your directory structure a special way. 

# the only pre-work necessary is to make sure you have the 
# packages that I'm using installed in your environment.


# Quarterly Census of Employment and Wages
# https://www.bls.gov/cew/datatoc.htm

# SCRIPT CONFIG ------


YEAR <- 2010


ZIP_FILE_PATH <- paste0("cache/00_QCEW_", YEAR, ".zip")
FULL_FILE     <- paste0("cache/00_QCEW_", YEAR, "_FULL_FILE.rds")
INDUSTRY_CODE_FILE <- paste0("cache/industry_code_file.csv")

# high level == more summarized industry codes
# low level == more detailed industry codes
COUNTY_HIGH_LEVEL <- paste0("proc_data/00_QCEW_", YEAR, "_COUNTY_HIGHLVL.rds")
COUNTY_MID_LEVEL <- paste0("proc_data/00_QCEW_", YEAR, "_COUNTY_MIDLVL.rds")
COUNTY_LOW_LEVEL <- paste0("proc_data/00_QCEW_", YEAR, "_COUNTY_LOWLVL.rds")
COUNTY_DETAILED  <- paste0("proc_data/00_QCEW_", YEAR, "_COUNTY_DETAILED.rds")


# LOAD LIBS ------------

library(RCurl)  # web request
library(dplyr)  # data manipulation
library(readr)  # fast reading of binary data (read_table)
library(tidyr)  # more data manipulation
library(data.table)


# HELPER FUNCS ---------


# build the URL to query for data zip file
build_qcew_query <- function(p_year) {
    paste0("https://data.bls.gov/cew/data/files/", p_year,
           "/csv/", p_year, "_qtrly_singlefile.zip")
}


# not sure how useful this is yet... 
# do we need a read version of this as well?
persist_to_disk <- function(p_obj, p_file_name) {
    
    # check input
    this_extension <- tolower(tools::file_ext(p_file_name))
    if (!this_extension %in% c("rds", "csv")) {
        stop("Must pass in either a '.rds' or '.csv' filepath name")
    }
    
    # if rds
    if (this_extension == "rds") {
        saveRDS(p_obj, p_file_name)
    # if csv
    } else if (this_extension == "csv") {
        fwrite(p_obj, p_file_name)
    }
}


# DOWNLOAD AND SAVE INDUSTRY CODES --------
if (!file.exists(INDUSTRY_CODE_FILE)) {
    download.file("https://data.bls.gov/cew/doc/titles/industry/industry_titles.csv", 
                  destfile = INDUSTRY_CODE_FILE)
}


# CREATE CACHE DIR --------
if(!dir.exists("cache")) {dir.create("cache")}


# DOWNLOAD AND READ ZIP FILE ---------

if(!file.exists(FULL_FILE)) {
    
    # download and write to disk
    print("Downloading file...")
    download.file(url=build_qcew_query(YEAR), destfile=ZIP_FILE_PATH)  
    file_name <- unzip(ZIP_FILE_PATH, list=T)[[1]]  
    print("Caching to disk...")
    csv_path <- unzip(ZIP_FILE_PATH, files=file_name, exdir="cache")  
    
    
    # column descriptions:
    # https://data.bls.gov/cew/doc/layouts/csv_quarterly_layout.htm
    print("Reading from disk...")
    df <- fread(csv_path, nrows=5, colClasses="character")
    rem_cols <- names(df)[grepl("disclosure", names(df))]
    rem_cols <- c(rem_cols, names(df)[grepl("oty", names(df))])
    rem_cols <- c(rem_cols, names(df)[grepl("contribut", names(df))])
    df <- fread(csv_path, colClasses="character", drop=rem_cols)
    gc()

    print("Caching to disk in more efficient format...")
    saveRDS(df, FULL_FILE)
} else {
    df <- readRDS(FULL_FILE)
}


# I prefer the behavior of data frames
setDF(df)
gc()

# CREATE PROC_DATA CACHE -------
if(!dir.exists("proc_data")) {dir.create("proc_data")}


# COUNTY FILTERS -------

# https://data.bls.gov/cew/doc/titles/agglevel/agglevel_titles.htm
# It gets even more detailed than agglvl_code '76'

# read in the industry code data
industry_codes <- read.csv(INDUSTRY_CODE_FILE, stringsAsFactors = F)


# joining individually because it will save memory


df_highlvl <- df[df$agglvl_code == '74', ]
df_highlvl <- merge(x=df_highlvl, y=industry_codes, 
                    by="industry_code", all.x=T, all.y=F)
saveRDS(df_highlvl, COUNTY_HIGH_LEVEL)
rm(df_highlvl); gc()



df_midlvl <- df[df$agglvl_code == '75', ]
df_midlvl <- merge(x=df_midlvl, y=industry_codes, 
                    by="industry_code", all.x=T, all.y=F)
saveRDS(df_midlvl, COUNTY_MID_LEVEL)
rm(df_midlvl); gc()


df_lowlvl <- df[df$agglvl_code == '76', ]
df_lowlvl <- merge(x=df_lowlvl, y=industry_codes, 
                    by="industry_code", all.x=T, all.y=F)
saveRDS(df_lowlvl, COUNTY_LOW_LEVEL)
rm(df_lowlvl); gc()


# # I want to explore industries where agglvl_code is 78 (most detailed)
# industry_codes$industry_title[industry_codes$industry_code %in% 
#                               df$industry_code[df$agglvl_code == '78']]


df_detailed <- df[df$agglvl_code == '78', ]
df_detailed <- merge(x=df_detailed, y=industry_codes, 
                   by="industry_code", all.x=T, all.y=F)
saveRDS(df_detailed, COUNTY_DETAILED)
rm(df_detailed); gc()





