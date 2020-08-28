#!/bin/bash

# testing parameters
concurrencies=(1 10) # 100 1000
heap_sizes=(64m) # 128m 256m 512m 1g
cores=(1.5) # 0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0
prime_numbers=(35171)

# setting jmeter test plan properties [can be given directly in the script]
# ramp_up_time=0
# hold_time=30
# ip=localhost
# port=9002
# path=/prime
jmeter_cpu_cores=1.5

# setting volume path and jmeter path
volume_path=./jmeter
jmeter_path=/jmeter-files

for heap_size in ${heap_sizes[@]}
do
	for no_of_users in ${concurrencies[@]}
	do
		for core in ${cores[@]}
		do
			for prime in ${prime_numbers[@]}
			do
				echo "Running test with [heap size: ${heap_size}, users: ${no_of_users}, cores: ${core}, prime number: ${prime}]"

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
				sudo docker run --cpus ${jmeter_cpu_cores} --volume $(realpath ${volume_path}):${jmeter_path} --name jmeter justb4/jmeter -Jusers=${no_of_users} -Jprime=${prime} -Jip=${prime_ip_address} -n -t ${jmeter_path}/Test-Plan.jmx -l ${jmeter_path}/results/result-${heap_size}-${no_of_users}-${core}-${prime}.jtl -j ${jmeter_path}/logs/log-${heap_size}-${no_of_users}-${core}-${prime}.log

				
				# Stop and remove both containers
				echo "---> step(4/4) stop and remove containers"
				docker stop prime
				docker container prune -f

				sleep 5									
			done
		done
	done
done
