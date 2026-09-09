#!/bin/bash
echo "filename,size,num_lines" > wikimedia_data_summary.csv

for file in data/*.csv; do
    filename=$(basename "$file")
    size=$(ls -lh "$file" | awk '{print $5}')
    num_lines=$(wc -l < "$file")
    echo "$filename,$size,$num_lines" >> wikimedia_data_summary.csv
done
