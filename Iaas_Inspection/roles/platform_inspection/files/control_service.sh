#!/bin/bash

set -e



function control_service_status(){

	# horizon keystone memcached neutron-server nova cinder glance heat 

	control_horizon=$(docker ps -a | grep -E horizon$ | awk '{printf $8}')

	control_memcached=$(docker ps -a | grep -E memcached$ | awk '{printf $8}')

	control_nova=$(docker ps -a | grep -E 'nova_novncproxy$|nova_api$|nova_scheduler$|nova_conductor$' | awk '{print $8}' | xargs -I{} echo -n '{} ')

	control_cinder=$(docker ps -a | grep -E 'cinder_api$|cinder_scheduler$' | awk '{print $8}' | xargs -I{} echo -n '{} ')

	control_glance=$(docker ps -a | grep -E glance_api$ | awk '{printf $8}')

	control_heat=$(docker ps -a | grep -E 'heat_engine$|heat_api_cfn$|heat_api$' | awk '{print $8}' | xargs -I{} echo -n '{} ')

	control_neutron=$(docker ps -a | grep -E neutron_server$ | awk '{printf $8}')
	control_keystone=$(docker ps -a | grep -E keystone$ | awk '{printf $8}')

        control_ceph_mon=$( docker ps -a | grep -E ceph_mon$ | awk '{printf $8}')

}

function mysql_service_status(){

        control_mysql=$(docker ps -a | grep mariadb$ | awk '{printf $9}')


}


function rabbitmq_service_status(){

        control_rabbitmq=$(docker ps -a | grep rabbitmq$ | awk '{printf $8}')


}


function network_service_status(){

        control_network=$(docker ps -a | grep -E 'neutron_l3_agent$|neutron_metadata_agent$' | awk '{print $8}' | xargs -I{} echo -n '{} ')
        control_network_dhcp=$(docker ps -a | grep -E 'neutron_dhcp_agent$' | awk '{print $8}')
        control_haproxy=$(docker ps -a | grep -Ew 'haproxy$'  | awk '{printf $8}')
        control_keepalived=$(docker ps -a | grep -E 'keepalived$' | awk '{printf $8}')


}


function main(){

	control_service_status
	mysql_service_status
	rabbitmq_service_status
	network_service_status

echo "{
\""control_horizon\"": \"${control_horizon:-[]}\",
\""control_memcached\"": \"${control_memcached:-[]}\",
\""control_keystone\"": \"${control_keystone:-[]}\",
\""control_nova\"": \"${control_nova:-[]}\",
\""control_cinder\"": \"${control_cinder:-[]}\",
\""control_glance\"": \"${control_glance:-[]}\",
\""control_heat\"": \"${control_heat:-[]}\",
\""control_neutron\"": \"${control_neutron:-[]}\",
\""control_mysql\"": \"${control_mysql:-[]}\",
\""control_rabbitmq\"": \"${control_rabbitmq:-[]}\",
\""control_network\"": \"${control_network:-[]}\",
\""control_network_dhcp\"": \"${control_network_dhcp:-[]}\",
\""control_haproxy\"": \"${control_haproxy:-[]}\",
\""control_keepalived\"": \"${control_keepalived:-[]}\",
\""control_ceph_mon\"": \"${control_ceph_mon:-[]}\"

}"

}


main

