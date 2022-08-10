#!/bin/bash


function compute_service_status(){

	nova_compute=$(docker ps -a | grep -E 'nova_compute$' | awk '{printf $8}')
	openvswitch_agent=$(docker ps -a | grep -E 'neutron_openvswitch_agent$' | awk '{printf $8}')
	cinder_volume=$(docker ps -a | grep -E 'cinder_volume$'  | awk '{printf $8}')


}


function main(){

	compute_service_status

echo "{
\""nova_compute\"": \"${nova_compute:-[]}\",
\""openvswitch_agent\"": \"${openvswitch_agent:-[]}\",
\""cinder_volume\"": \"${cinder_volume:-[]}\"
}"


}

main
