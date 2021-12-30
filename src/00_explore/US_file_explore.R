
# This is a very ad-hoc exploratory file. I want to represent what my
# initial dataset exploration strategies are, so instead of cleaning
# this file up, I'm leaving the dirty code I used to explore and
# understand these datasets

library(rstudioapi)
library(dplyr)
library(data.table)  # just for the fread() 
library(readr)
library(openxlsx)



# quickly read large CSV files and make all columns character
fread_char <- function(p_csv_path) {
    require(data.table)
    output_df <- fread(p_csv_path, 
        colClasses = rep("character", ncol(read.csv(p_csv_path, nrows = 2))))
    
    # I prefer data.frames instead of data.tables (even if they're slower)
    setDF(output_df)
    return(output_df)
}


# Single File EXPLORE ------------------------------------------

# going to check out this "singlefile.csv" file
# singlefile     <- fread_char("data/01_raw/2018_qtrly_singlefile/2018.q1-q4.singlefile.csv")
singlefile     <- read_csv("data/01_raw/2018_qtrly_singlefile/2018.q1-q4.singlefile.csv")
industry_codes <- read.csv("data/01_raw/industry_titles.csv", stringsAsFactors = F)
singlefile     <- merge(x=singlefile, y=industry_codes, by="industry_code", all.x=T, all.y=F)


# the "10*" industry codes seem pretty high level:
industry_codes[grepl("^10", industry_codes$industry_code), ]
# give me rows where (industry code is 2 digits) or 
#                    (is 4 digits and starts with "10")
industry_codes[nchar(industry_codes$industry_code) == 2 | 
               (grepl("^10", industry_codes$industry_code) & 
                    nchar(industry_codes$industry_code) == 4) , ]
# give me rows where (industry code is 2 digits) and
#                    (industry code doesn't start with "10")
industry_codes[nchar(industry_codes$industry_code) == 2 & 
               !grepl("^10", industry_codes$industry_code), ] 


# the four-digit NAIC codes that start with "10" are the top-level aggregates
# the remaining two-digit NAIC codes that don't start 
# with "10" are more granular breakdowns


# now lets identify the grain of the file
head(names(singlefile), 10)

# we have mixed grains in here based on the agglevel code
sort(unique(singlefile$agglvl_code))

# any of those codes that start with a "7" means they are at the county level.
# the next digit represents the "ownership" of the data? still unclear on that.

sf_county <- singlefile %>% filter(grepl("^7", agglvl_code))

# ok, so we still have overlapping data because of the different 
# granularity of the industry codes
# https://data.bls.gov/cew/doc/titles/industry/industry_titles.htm
naics_code_agglvl <- sf_county %>% 
    select(industry_code, agglvl_code, industry_title) %>% 
    unique() %>%
    filter(nchar(industry_code) == 2)
    
    # ^ agg level 74 is most high level without being one of the 10* SUPER high level categories

    # agg level 75 (second most detailed)
    # walking through the various levels of detail among industry codes (3 characters)
    naics_code_agglvl_3char <- sf_county %>%
        select(industry_code, agglvl_code, industry_title) %>% 
        unique() %>%
        filter(nchar(industry_code) == 3)
    
    # agg level 76 (most detailed)
    # walking through the various levels of detail among industry codes (4 characters)
    naics_code_agglvl_4char <- sf_county %>%
        select(industry_code, agglvl_code, industry_title) %>% 
        unique() %>%
        filter(nchar(industry_code) == 4)



# ok so based on this file above, we should be good with agglvl_code 74
# agglvl_code 74 are all of the non-"10" codes that are two-digits long
county74 <- singlefile %>%
    filter(agglvl_code == 74)

# county74 is all of the agglvl_code==74 rows, now we can safely identify 
# the granularity (or the "grain") of this dataset

View(head(county74))


    county76 <- singlefile %>%
        filter(agglvl_code == 76)


# based on viewing the data, I believe the grain can be identified by:
# * area_fips - five-digit code for the state / county
# * industry_code - the NAICS industry code at this level of detail (two-digit)
# * year
# * qtr (the quarter of the year)

# Since I'll be building a sortable key on this field, I want to
# make sure all fields have consistent character-length:

# here I'm passing in a data.frame with only the columns I'm
# interested in, along with an anonymous function to determine
# the number of unique character-count values per field
sapply(county74[, c("area_fips", "industry_code", "year", "qtr")], function(x) {
    return(length(unique(nchar(x))))
})

# most are the same length! nice
table(nchar(county74$industry_code))
unique(county74$industry_code)

unique(county74$industry_title) %>% sort()

# some industry codes are 2 digit, some are 5 - that should be fine!
# the 5 digit codes follow this pattern: xx-xx, so as long as we
# don't use hyphens as our separator for our key, we're golden

# creating the key now: fips_naics_yr_qtr
county74 <- county74 %>%
    mutate(fips_naics_yr_qtr=paste(area_fips, industry_code, year, qtr, sep="_")) %>%
    arrange(fips_naics_yr_qtr)


sum(duplicated(county74$fips_naics_yr_qtr))

dupe_keys <- county74$fips_naics_yr_qtr[duplicated(county74$fips_naics_yr_qtr)]
dupe_rows <- county74 %>% filter(fips_naics_yr_qtr %in% dupe_keys)

View(dupe_rows[1:100, ])

# hmm, ton's of duplicates. I think we need to add "own_code" to our key
# it looks like this own code describes who is reporting the numbers?
# I'm wondering if we could aggregate this out, not sure if the 
# measurements are additive across this field. This is where we need
# to be very careful not to make a bad assumption... What if instead
# of being able to add across this field, it's actually just different
# attempts at the same total measurement. In that case, maybe an 
# average instead of a sum would be more appropriate.


# creating the key now: unq_key
county74 <- county74 %>%
    mutate(unq_key=paste(area_fips, industry_code, own_code, year, qtr, sep="_")) %>%
    arrange(unq_key) %>%
    select(-fips_naics_yr_qtr)


sum(duplicated(county74$unq_key))
# success! no duplicates!

# quick inspection of our key:
head(county74$unq_key)
tail(county74$unq_key)
# area_fips _ industry_code _ own_code _ year _ quarter

# https://data.bls.gov/cew/doc/titles/ownership/ownership_titles.htm

View(t(county74[1:100, ]))


dallas_county74 <- county74 %>%
    filter(area_fips == 48113)


# All County High Level ----------------

# https://www.bls.gov/cew/datatoc.htm (left-hand column has .xlsx file links)

# what is in this xlsx file? this is the "highlevel county data"
# I'm hoping this file will give us a better understanding of the
# "own_code" field as well. I wonder if it's even present in this
# file at all.
openxlsx::getSheetNames("data/01_raw/2018_all_county_high_level/allhlcn181.xlsx")
x1 <- openxlsx::read.xlsx("data/01_raw/2018_all_county_high_level/allhlcn181.xlsx", sheet="US_St_Cn_MSA")
x2 <- openxlsx::read.xlsx("2018_all_county_high_level/allhlcn181.xlsx", sheet="US_PR_VI")

# ok so this "US_St_Cn_MSA" sheet has 62.7k rows, "US_PR_VI" has 1.5k rows
# the first one is probably the one I'm most interested in

# the first thing I'm noticing is which NAICS codes are present.
# I think that's what is meant by "high-level"
unique(x1$NAICS)

# it's just all of the ones that start with "10" - so that's what highlevel means


# now let's figure out this own_code thing...
# in this dataset, it's actually just called "Own"
head(unique(x1$Area.Code))
x1_one_county <- x1 %>% 
    filter(Area.Code == "01005") %>%
    select(Area, Own, Ownership, NAICS, January.Employment)


# ok, this is starting to make sense
# the private sector is broken down into more granular
# categories, while the local, state, and federal gov
# are all combined into a single row each


# so all of the three-digit NAICS codes should roll
# up to the NAICS=="10" code for "private" ownership
sum(x1_one_county$January.Employment[
    x1_one_county$Ownership == "Private" &
    nchar(x1_one_county$NAICS) == 3])

sum(x1_one_county$January.Employment[
    x1_one_county$Ownership == "Private" &
    x1_one_county$NAICS == "10"])

# cool! figured that out, this should also hold 
# true for the four-digit NAICS which should
# just be able to also roll up to the three-digit
# codes:
sum(x1_one_county$January.Employment[
    x1_one_county$Ownership == "Private" &
    nchar(x1_one_county$NAICS) == 4])

# perfect! Now I just hope this holds true and helps explain
# the "own_code" field in the singlefile dataset
county74$area_fips %>% head()
county74_one_county <- county74 %>%
    filter(area_fips == "01005")

singlefile_one_county <- singlefile %>%
    filter(area_fips == "01005")



