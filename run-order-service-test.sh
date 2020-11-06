#!/bin/bash

# Testing parameters
concurrencies=(1 10 50 100 200 500) # TODO: Have to choose suitable values
memory_limit=(2g) # TODO: Later
heap_sizes=(128m 256m 512m 1024m) # 64m 128m 256m 512m 1024m
cores=(0.4 0.8 1.2 1.6 2.0) # 0.4 0.8 1.2 1.6 2.0
durations=(150)

jmeter_cpu_cores=1.5 # assign cpu core allocation to jmeter container

# setting volume path and jmeter path
volume_path=./jmeter
jmeter_path=/jmeter-files

test_case=10030 # to help the automation process

for heap_size in ${heap_sizes[@]}
do
	for no_of_users in ${concurrencies[@]}
	do
		for core in ${cores[@]}
		do
			for duration in ${durations[@]}
			do
				test_case=$(($test_case + 1))
				echo "Running test-${test_case} with [heap size: ${heap_size}, users: ${no_of_users}, cores: ${core}, duration: ${duration}]"
					
				# Run sock shop
				echo "---> step(1/4) run sock shop application"
				#  add MEM_LIMIT=${memory_limit} to pass containers memory limit
				CPUS=${core} HEAP=${heap_size} docker-compose -f ./../microservices-demo/deploy/docker-compose/docker-compose.yml up -d

				# getting and setting order service ip address
				order_ip_address=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' docker-compose_orders_1)
				echo "ip: ${order_ip_address}"

				# Check order service
				echo "---> step(2/4) check service"
				while true
				do
					echo "Checking service"
					response_code=$(curl -s -o /dev/null -w "%{http_code}" http://${order_ip_address}:80/orders)
					echo "${response_code}"
					if [ $response_code -eq 200 ]
					then
						echo "Order service started"
						break
					else
						sleep 10
					fi
				done
				
				# Run JMeter inside container and do the test
				echo "---> step(3/4) run JMeter and do test"
				docker run --cpus ${jmeter_cpu_cores} --network=docker-compose_default --volume $(realpath ${volume_path}):${jmeter_path} --name jmeter justb4/jmeter -Jusers=${no_of_users} -Jip=${order_ip_address} -Jduration=${duration} -n -t ${jmeter_path}/Order-Test-Plan.jmx -l ${jmeter_path}/results/order-result-${test_case}-${heap_size}-${no_of_users}-${core}-${duration}.jtl -j ${jmeter_path}/logs/order-log-${test_case}-${heap_size}-${no_of_users}-${core}-${duration}.log
				
				# Stop and remove both sock shop and jmeter container
				echo "---> step(4/4) stop and remove containers"
				CPUS=${core} HEAP=${heap_size} docker-compose -f ./../microservices-demo/deploy/docker-compose/docker-compose.yml down
				docker container prune -f

				sleep 5

			done
		done
	done
done

