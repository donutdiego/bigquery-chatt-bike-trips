--- Trips per Station
SELECT
  start_station_name,
  COUNT(*) AS trips
FROM chatt_bike_share.bike_trips
GROUP BY 1
ORDER BY 2 DESC;

--- Trips per Member Status
WITH member_trips AS (
  SELECT
  EXTRACT(YEAR FROM start_time) AS year,
  member_type,
  COUNT(*) AS trips
FROM chatt_bike_share.bike_trips
GROUP BY 1, 2
ORDER BY 1, 2
)
SELECT *
FROM member_trips
PIVOT(
  MAX(trips) 
  FOR member_type IN ('Customer','Subscriber', 'Dependent')
)
ORDER BY year;

--- Yearly and Monthly Trips Grouped
SELECT
  EXTRACT(YEAR FROM start_time) AS year,
  FORMAT_DATE('%B', start_time) AS month,
  --CAST(DATE_TRUNC(start_time, month)AS DATE) AS month,
  COUNT(*) AS trips
FROM chatt_bike_share.bike_trips
GROUP BY
  ROLLUP (1, 2)
ORDER BY 1, MIN(start_time);

--- Trip Duration Bins
SELECT
  CASE WHEN trip_duration_min BETWEEN 0 AND 30 THEN '0 - 30'
    WHEN trip_duration_min BETWEEN 31 AND 60 THEN '30 - 60'
    WHEN trip_duration_min BETWEEN 61 AND 90 THEN '60 - 90'
    ELSE '> 90' END AS trip_bin,
  COUNT(*) AS trips
FROM chatt_bike_share.bike_trips
GROUP BY 1
ORDER BY 1;

--- \\ Weather // ---

--- Finding Weather Station for Chattanooga
SELECT *
FROM `bigquery-public-data.noaa_gsod.stations`
WHERE name LIKE '%CHATT%';

--- Weather for 2022
SELECT
  CAST(DATE_TRUNC(date, week)AS DATE) AS week,
  ROUND(AVG(temp), 2) AS avg_temp,
  ROUND(AVG(prcp), 2) AS avg_precipitation
FROM `bigquery-public-data.noaa_gsod.gsod2022`
WHERE wban = '13882'
GROUP BY 1
ORDER BY 1;

--- \\ Linear Regression Model // ---
SELECT
  trip_duration_min AS trip_duration,
  EXTRACT(HOUR FROM start_time) AS hour,
  EXTRACT(DAYOFWEEK FROM start_time) AS weekday
FROM chatt_bike_share.bike_trips;
  --- Model Training ---
CREATE OR REPLACE MODEL `chatt_bike_share.bike_trip_forecast`
OPTIONS(
  model_type = 'linear_reg',
  labels = ['trip_duration'],
  max_iterations = 3
) AS 
SELECT
  trip_duration_min AS trip_duration,
  EXTRACT(HOUR FROM start_time) AS hour,
  EXTRACT(DAYOFWEEK FROM start_time) AS weekday
FROM chatt_bike_share.bike_trips;


--- \\ ARIMA Model // ---
SELECT
  CAST(DATE_TRUNC(start_time, week) AS DATE) AS month,
  COUNT(*) AS trips,
  ROUND(AVG(trip_duration_min), 2) AS avg_trip_duration_mins
FROM chatt_bike_share.bike_trips
GROUP BY 1
ORDER BY 1;
  --- Model Training ---
CREATE OR REPLACE MODEL `chatt_bike_share.bike_trip_forecast`
OPTIONS(
  model_type = 'ARIMA_PLUS',
  time_series_timestamp_col = 'week',
  time_series_data_col = 'trips',
  auto_arima = TRUE,
  data_frequency = 'AUTO_FREQUENCY',
  decompose_time_series = TRUE,
  holiday_region = 'US',
  seasonalities = ['MONTHLY']
) AS
SELECT
  CAST(DATE_TRUNC(start_time, week) AS DATE) AS week,
  COUNT(*) AS trips
FROM chatt_bike_share.bike_trips
GROUP BY 1
ORDER BY 1;

SELECT
  CAST(DATE_TRUNC(forecast_timestamp, month) AS DATE) AS month,
  ROUND(forecast_value, 2) AS predicted_trips,
  'yes' AS is_predicted
FROM ML.FORECAST(MODEL `sql-practice-375701.chatt_bike_share.bike_trip_forecast`,
STRUCT(
  6 AS horizon, 
  0.5 AS confidence_level))