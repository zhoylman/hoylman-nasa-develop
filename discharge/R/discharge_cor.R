library(waterData)
library(lubridate)
library(tidyverse)

#define station ID and some import parameters
station = '06486000' # Missouri River at Sioux City, IA
start_date = "1960-01-01" #example start
end_date = "2020-12-31" #example end
variable_code = "00060" # discharge in cfs
#variable_code information at https://nwis.waterdata.usgs.gov/usa/nwis/pmcodes?radio_pm_search=param_group&pm_group=All+--+include+all+parameter+groups&pm_search=&casrn_search=&srsname_search=&format=html_table&show=parameter_group_nm&show=parameter_nm&show=casrn&show=srsname&show=parameter_units

#import station meta data e.g. location etc
meta = siteInfo(station)

#import raw data
raw_data = importDVs(station, code=variable_code, # 
                     sdate = start_date, edate = end_date) 

#compute mean fall q
fall_mean_q = raw_data %>%
  #convert dates to r recognized format
  mutate(dates = as.Date(dates),
         #compute month id
         month = month(dates),
         #compute year id
         #add a year to the year id, this is so we compare fall of 2017 (2017+1)
         #to summer of 2018, need to offet the year for the join function below
         year = year(dates)+1) %>% 
  #filter for months of interest (only october)
  filter(month >= 10 & month <= 10) %>%
  #group dataset by year
  group_by(year) %>%
  #calcaulte annual summary (NAs will be ignored for mean function)
  summarize(mean_fall_q = mean(val, na.rm = T))

#compute mean summer q
summer_mean_q = raw_data %>%
  #convert dates to r recognized format
  mutate(dates = as.Date(dates),
         #compute month id
         month = month(dates),
         #compute year id (no adding a year here, fall is the reference year)
         year = year(dates)) %>% 
  #filter for months of interest (july - october)
  filter(month >= 7 & month <= 10) %>%
  #group dataset by year
  group_by(year) %>%
  #calcaulte annual summary (NAs will be ignored for mean function)
  summarize(summer_mean_q = mean(val, na.rm = T))

#join data with a left join by year (reference year already taken care of)
joined_data = left_join(fall_mean_q, summer_mean_q, by = 'year')

#compute model
model = lm(joined_data$summer_mean_q ~ joined_data$mean_fall_q)
summary = summary(model)
print(summary)

#plot results
plot(joined_data$mean_fall_q, joined_data$summer_mean_q, 
     xlab = 'Mean Fall Q (Reference Year - 1)',
     ylab = 'Mean Summer Q (Reference Year)',
     main = meta$staname)
abline(model$coefficients)

#extract relevent information from model
export = data.frame(p_value = summary$coefficients[,'Pr(>|t|)'][2],
                    r2 = summary$r.squared,
                    slope = summary$coefficients[,'Estimate'][2])

#name it based on meta data
rownames(export) = meta$staname
