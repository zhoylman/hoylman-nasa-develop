library(waterData)
library(lubridate)
library(tidyverse)

#define station ID and some import parameters
station = '12350250' # Missouri River near Culbertson MT
start_date = "1960-01-01" #example start
end_date = "2020-12-31" #example end
variable_code = "00060" # discharge in cfs
#variable_code information at https://nwis.waterdata.usgs.gov/usa/nwis/pmcodes?radio_pm_search=param_group&pm_group=All+--+include+all+parameter+groups&pm_search=&casrn_search=&srsname_search=&format=html_table&show=parameter_group_nm&show=parameter_nm&show=casrn&show=srsname&show=parameter_units

#import station meta data e.g. location etc
meta = siteInfo(station)

#import raw data
raw_data = importDVs(station, code=variable_code, # 
          sdate = start_date, edate = end_date) 

#compute cumulative q
cumulative_q = raw_data %>%
  #convert dates to r recognized format
  mutate(dates = as.Date(dates),
         #compute month id
         month = month(dates),
         #compute year id
         year = year(dates),
         #calculate daily cumulative q assuming q is constant for each day
         integrated_q = val*86400)%>% # convert from cfs to cf/day
  #filter for months of interest
  filter(month >= 7 & month <= 10) %>%
  #group dataset by year
  group_by(year) %>%
  #calcaulte annual summary (NAs will cause a NA cumulative flow!!!)
  summarize(cumulative_q = sum(integrated_q, na.rm = T))

min = raw_data %>%
  #convert dates to r recognized format
  mutate(dates = as.Date(dates),
         #compute month id
         month = month(dates),
         #compute year id
         year = year(dates),
         #calculate daily cumulative q assuming q is constant for each day
         integrated_q = val*86400)%>% # convert from cfs to cf/day
  #filter for months of interest
  filter(month >= 1 & month <= 3) %>%
  #group dataset by year
  group_by(year) %>%
  #calcaulte annual summary (NAs will cause a NA cumulative flow!!!)
  summarize(cumulative_q = sum(integrated_q, na.rm = F))

plot(min$cumulative_q %>% log, cumulative_q$cumulative_q %>% log)
lm(cumulative_q$cumulative_q %>% log ~ min$cumulative_q %>% log) %>% summary
#plot data
plot(cumulative_q$year, cumulative_q$cumulative_q, main = meta$staname,
     ylab = 'Cumulative Q (ft^3)', xlab = '')
lines(cumulative_q$year, cumulative_q$cumulative_q)

#write out data
write_csv(cumulative_q, paste0('/home/zhoylman/hoylman-nasa-develop/discharge/data/cumulative_q_station_', station, '.csv'))
