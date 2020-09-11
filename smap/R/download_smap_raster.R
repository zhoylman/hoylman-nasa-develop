# import the url from py script (~/hoylman-nasa-develop/smap/py/get_smap_ee.py)

library(raster)
library(tidyverse)
library(httr)

#import url as csv  
url = read_csv('~/hoylman-nasa-develop/smap/urls/url_list.csv', col_names = F) %>%
  t()

#download data as a zipped archive
GET(url[1], write_disk(paste0(getwd(),'/smap/data/raw/temp_zip.zip'), overwrite = TRUE))

#unzip the data, and import as raster
# raw data is now in the ~/hoylman-nasa-develop/smap/data/raw folder

data = unzip(paste0(getwd(),'/smap/data/raw/temp_zip.zip'), exdir = paste0(getwd(),'/smap/data/raw/')) %>%
  raster::raster() 

#define na value from ee image
NAvalue(data) = -999
  
#visulaize!
plot(data)

