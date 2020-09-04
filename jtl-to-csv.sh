#!/bin/bash

# $1 -> path to JMeter bin folder
# $2 -> path to the JTL files directory(input)
# $3 -> path to the CSV files directory(output)

# loop through the jtl files and create their respective csv files
for file in $2/*.jtl
do
	filename=$(basename ${file} .jtl)
	$1/JMeterPluginsCMD.sh --generate-csv $3/${filename}.csv --input-jtl ${file} --plugin-type AggregateReport
done

