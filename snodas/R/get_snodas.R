# snodas ingestion script and conversion to GeoTiff
# This is a fuction to download snodas data
# Zach Hoylman 1-22-2020, modified 9-11-2020

# snodas help info
# help https://nsidc.org/support/how/how-do-i-convert-snodas-binary-files-geotiff-or-netcdf
# naming table 4 https://nsidc.org/data/g02158#untar_daily_nc
# data ftp://sidads.colorado.edu/DATASETS/NOAA/G02158/

# this script will download snodas grids for a given date. 
# this script also runs gdal commands via system calls. It also generates
# hdr files to as an intermediary to geotiffs

library(httr)
library(dplyr)
library(data.table)
library(tools)

get_snodas = function(date){
  for(d in 1:length(date)){
    #build data url
    url = paste0("ftp://sidads.colorado.edu/DATASETS/NOAA/G02158/masked/", 
                 date[d] %>% format(., "%Y"), "/", date[d] %>% format(., "%m_%b"), 
                 "/SNODAS_", date[d] %>% format(., "%Y%m%d"), ".tar")
    
    #define where raw tarball will be stored
    tar.dir = paste0(getwd(), "/snodas/data/raw/SNODAS_", date[d] %>% format(., "%Y%m%d"), ".tar")
    unzip.dir = paste0(getwd(), "/snodas/data/raw/SNODAS_", date[d] %>% format(., "%Y%m%d"))
    
    #downlaod zipped data
    httr::GET(url, write_disk(path = tar.dir, overwrite=TRUE))

    #create unzip location
    dir.create(unzip.dir)
    
    #unzip file
    untar(tarfile = tar.dir,  exdir = unzip.dir)
    
    #get files from unzipped dir
    files = list.files(unzip.dir, full.names = T) 
    
    #define NOAA IDs for variables of interest (SWE and snowdepth) can be modified - see naming table
    files_of_interest = c("1034", "1036")
    
    for(i in 1:length(files_of_interest)) {
      file_to_process = files[[which(files %like% files_of_interest[i] & files %like% ".dat.gz")]]
      
      writeLines(
        "ENVI
samples = 6935
lines   = 3351
bands   = 1
header offset = 0
file type = ENVI Standard
data type = 2
interleave = bsq
byte order = 1", con = file_to_process %>% gsub(".dat.gz", ".hdr", .))
      
      file_to_process %>%
        R.utils::gunzip(., destname = gsub(".gz", "", .)) 
      
      processed_name = paste0("~/hoylman-nasa-develop/snodas/data/processed/",
                              if(files_of_interest[i] == "1034") paste0("swe/snodas_swe_conus_", format(date[d],"%Y%m%d"), ".tif") 
                              else if (files_of_interest[i] == "1036") paste0("snow_depth/snodas_snow_depth_conus_", format(date[d],"%Y%m%d"), ".tif") else NA)
      
      system(paste0("gdal_translate -of GTiff -a_srs '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs' -a_nodata -9999 -a_ullr  -124.73333333 52.87500000 -66.94166667 24.95000000 ",
                    file_to_process %>% gsub(".gz", "", .), " ",
                    processed_name))
    }
    
    #erase raw data so we dont over store
    system(paste0("rm -r ", tar.dir))
    system(paste0("rm -r ", unzip.dir))
  }
}
