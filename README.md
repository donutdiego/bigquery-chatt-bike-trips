## Chattanooga Bike Trips Analysis ## 

My goal with this project was to explore public data on bike trips for the city of Chattanooga. This data is publicly available on the [ChattaData](https://data.chattlibrary.org/) website. The queries I used for analysis are uploaded to this repo along with a Jupyter notebook that I used to convert the query result into a Pandas DataFrame to be able to visualize all in one place.

One of my learning objectives was to create a time-series forecast machine learning model and predict the number of trips for the remainder of the year since the data has a cut-off for June 2022. Using BigQuery ML, this is a fairly straightforward process and only involved a few lines of SQL to get the results. Also, I wanted to use the NOAA public database to gather weather information and see if any correlation exists between the number of trips and temperature.

As of now, I will be working to implement the data into a Streamlit app and implement the time-series forecast model in some way, such as allowing the user to interact with the results using widgets.
