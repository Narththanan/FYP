#!/bin/bash

# Run jmeter tests
./run-order-service-test.sh

# convert all jtl files into csv files
./jtl-to-csv.sh /home/narthu/interests/FYP/JMeter/apache-jmeter-5.2.1/bin ./jmeter/results ./csv-folder

# combine all csv files and put it into one csv file
./multi-to-single.sh ./csv-folder
