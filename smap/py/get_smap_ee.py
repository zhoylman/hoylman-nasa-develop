# this script interacts with earth engine to extract/ compute smap data.
# output is a download url that is then imported into R for additional
# manipulation, however, all manipulation could be done in python

import ee
import datetime as dt
from datetime import timedelta
import numpy
import ee.mapclient
import csv
import requests
import os

# initialize connection with earth engine
ee.Initialize()

#import states shape file (this will work for multiple states if required)
states = (ee.Collection.loadTable('users/zhoylman/states')
          #.filter(ee.Filter.Or(ee.Filter.eq("STATE_ABBR",   'MT')))
          .filter(ee.Filter.And(ee.Filter.neq("STATE_ABBR", 'AK'),
                               ee.Filter.neq("STATE_ABBR", 'HI')))
          .union())

# define clipping function to map over IC (if you want to clip multiple images)
def clipped(img):
    return img.clip(states)

# import smap soil moisture, select Surface soil moisture anomaly (ssma),
# different bands can be selected by changing band name
dataset = (ee.ImageCollection("NASA_USDA/HSL/SMAP_soil_moisture")
           .select('ssma')
# clip dataset to MT
           .map(clipped))



# get list of valid dates
dates = ee.List(dataset \
    .aggregate_array('system:time_start')) \
    .map(lambda time_start:
         ee.Date(time_start).format('Y-MM-dd')
    ).reverse() \
    .getInfo()

most_recent = dt.datetime.strptime(dates[0], '%Y-%m-%d').date()
yesterday_date = dt.datetime.strptime(dates[0], '%Y-%m-%d').date() + timedelta(days=-1)

# as an example, get the most recent image but you can use the
# dates defined above to filter for specific time periods
# I filter the image collection in this relatively clunky way
# to show you how to filter for different timescales. For example,
# you might want to take the average of the last month of data.
# in that case change the date range and change .first() to .mean()
# or alike. You must convert the image collection to image prior to export
current = (dataset.filter(ee.Filter.date(ee.Date(str(most_recent+ timedelta(days=-1))),
                                         ee.Date(str(most_recent+ timedelta(days=1)))))
           .first())


#find native resolution (in this case its 0.25 arc degrees)
res = (current.projection().nominalScale()).getInfo()

url_list = []

# Get a download URL for an image.
path = current.getDownloadUrl({
    'scale': res,
    'crs': 'EPSG:4326',
    'region': states.geometry()
})
# append the path to the list (so you can do this with multiple images
# if warented
url_list.append(path)

# PATH TO YOUR HOME DIRECTORY
with open('/home/zhoylman/hoylman-nasa-develop/smap/urls/url_list.csv', 'w') as myfile:
    wr = csv.writer(myfile, quoting=csv.QUOTE_ALL)
    wr.writerow(url_list)