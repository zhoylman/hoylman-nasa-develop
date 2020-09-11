# import the url from py script (~/hoylman-nasa-develop/modis/py/get_modis_snowcover.py)

library(raster)
library(tidyverse)
library(httr)

#import url as csv  
url = read_csv('~/hoylman-nasa-develop/modis/urls/url_list.csv', col_names = F) %>%
  t()

#download data as a zipped archive
GET(url[1], write_disk(paste0(getwd(),'/modis/data/raw/temp_zip.zip'), overwrite = TRUE))

#unzip the data, and import as raster
# raw data is now in the ~/hoylman-nasa-develop/modis/data/raw folder
data = unzip(paste0(getwd(),'/modis/data/raw/temp_zip.zip'), exdir = paste0(getwd(),'/modis/data/raw/')) %>%
  raster::raster() 

#visulaize!
plot(data)

