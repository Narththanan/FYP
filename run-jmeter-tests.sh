#!/bin/bash

# testing parameters
concurrencies=(500) # 1 10 20 50 100 200 500
heap_sizes=(512m) # 64m 128m 256M 512m 1g
cores=(1.2) # 0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0
prime_numbers=(11) # 11 101 1009 10007 100003 , 11 1000003 10000019
durations=(30)

# assign cpu core allocation to jmeter container
jmeter_cpu_cores=1.5

# setting volume path and jmeter path
volume_path=./jmeter
jmeter_path=/jmeter-files

# test case number to help the automation process
test_case=0

for heap_size in ${heap_sizes[@]}
do
	for no_of_users in ${concurrencies[@]}
	do
		for core in ${cores[@]}
		do
			for prime in ${prime_numbers[@]}
			do
				for duration in ${durations[@]}
				do
					test_case=$(($test_case + 1))
					echo "Running test-${test_case} with [heap size: ${heap_size}, users: ${no_of_users}, cores: ${core}, prime number: ${prime}, duration: ${duration}]"

					# Run prime service inside container
					echo "---> step(1/4) run prime service"
					docker run -p 9002:9002 -d --cpus ${core} --entrypoint "" --name prime prime_service java -Xms${heap_size} -Xmx${heap_size} -jar prime-service-0.1.0.jar
				
					# getting and setting the prime containers ip address in bridge network
					prime_ip_address=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' prime)
					echo "ip: ${prime_ip_address}"

					# Check service
					echo "---> step(2/4) check service"
					while true
					do
						echo "Checking service"
						response_code=$(curl -s -o /dev/null -w "%{http_code}" http://${prime_ip_address}:9002/prime?number=${prime})
						echo "${response_code}"
						if [ $response_code -eq 200 ]
						then
							echo "Prime service started"
							break
						else
							sleep 10
						fi
					done
		
					# Run JMeter inside container and do the test
					echo "---> step(3/4) run JMeter and do test"
					sudo docker run --cpus ${jmeter_cpu_cores} --volume $(realpath ${volume_path}):${jmeter_path} --name jmeter justb4/jmeter -Jusers=${no_of_users} -Jprime=${prime} -Jip=${prime_ip_address} -Jduration=${duration} -n -t ${jmeter_path}/Test-Plan.jmx -l ${jmeter_path}/results/result-${test_case}-${heap_size}-${no_of_users}-${core}-${prime}-${duration}.jtl -j ${jmeter_path}/logs/log-${test_case}-${heap_size}-${no_of_users}-${core}-${prime}-${duration}.log

				
					# Stop and remove both containers
					echo "---> step(4/4) stop and remove containers"
					docker stop prime
					docker container prune -f

					sleep 5
				done							
			done
		done
	done
done
