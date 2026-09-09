aws s3 ls s3://dsan6000-wikipedia/hourly/
aws s3 cp s3://dsan6000-wikipedia/hourly/ data/ --recursive --exclude "*" --include "*.csv"
ls data/*.csv
