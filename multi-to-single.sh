#!/bin/bash

# $1 => path to csv folder

# Extract header row and insert it into final file
# head -1 /path/to/input/<file name>.csv > /path/to/output/<file name>.csv

FILE=./final-csv/final.csv
if [ -f "$FILE" ]; then
    rm $FILE
fi

cp ./final-csv/header.csv ./final-csv/final.csv

mkdir temporary-folder

# Delete 3rd row of all files
for filename in $(ls $1/*.csv)
do
    f="$(basename -- $filename)"
    touch ./temporary-folder/$f
    sed 3d $filename >> ./temporary-folder/$f
done

# Combine all csv files into one csv file
for filename in $(ls ./temporary-folder/*.csv)
do
    sed 1d $filename >> ./final-csv/final.csv
done

rm -r ./temporary-folder