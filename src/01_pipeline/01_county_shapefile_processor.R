

# definition of done:
# this script will write a RDS to the proc_data directory
# that contains all we need for shapefiles? 

# sounds like objects from "sp" package will have full
# functionality in leaflet.

# geoJSON and topoJSON objects will not have full functionality
# but they might render faster? I'd like to try both and 
# see what the difference is for myself

library(rgdal)
library(leaflet)

# Script config ------

COUNTY_SHAPE_ZIP_FILE <- "cache/01_us_counties_500k.zip"
COUNTY_SHAPE_FILE     <- "proc_data/county_shapes/cb_2017_us_county_500k.shp"

# Ensure directories exist --------
if(!dir.exists("cache")) {dir.create("cache")}
if(!dir.exists("proc_data")) {dir.create("proc_data")}
if(!dir.exists("proc_data/county_shapes")) {dir.create("proc_data/county_shapes")}



# download file --------

download.file("http://www2.census.gov/geo/tiger/GENZ2017/shp/cb_2017_us_county_500k.zip",
              destfile = COUNTY_SHAPE_ZIP_FILE)

shape_files <- unzip(COUNTY_SHAPE_ZIP_FILE, exdir = "proc_data/county_shapes")

counties <- readOGR(COUNTY_SHAPE_FILE)

class(counties)
class(counties$STATEFP)
class(counties$COUNTYFP)
class(counties$COUNTYNS)
counties$AFFGEOID
counties$GEOID
counties$NAME
counties$LSAD
counties$ALAND
counties

counties$full_fips <- paste0(as.character(counties$STATEFP), as.character(counties$COUNTYFP))


# this is how to access all the data we need -------

# first polygon data -- need to check if/when counties have multiple polygons associated with them
polys <- attr(counties, "polygon")[[1]]

# state fips, county fips, full fips, county name
counties$STATEFP[1]
counties$full_fips[1]
counties$NAME[1]

counties_alabama <- subset(counties, counties$STATEFP == "01")

leaflet(counties) %>%
    addPolygons(color = "#444444", weight=1, smoothFactor=0.5,
                opacity=1, fillOpacity=0.5,
                fillColor = "#00FF00")


