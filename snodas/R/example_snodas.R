#this script shows how to use the function 'get_snodas'
# the httr and tar unzip calls in the source script dont work well with 
# relative paths. this assumes you are working in a R project (as is set in this repo)
# alternatively you can set the working directory with setwd

#setwd('/path/to/working/dir')

#import source script that defines function
source('~/hoylman-nasa-develop/snodas/R/get_snodas.R')

# define dates of interest - this can be used to compute percentiles by ingesting the 
# same julian day for each year and post processing the cell-wise snodas data
date = as.Date(c('09-01-2020', '09-01-2019', '09-01-2018'), format = '%m-%d-%Y')

#exicute funtion
get_snodas(date)
