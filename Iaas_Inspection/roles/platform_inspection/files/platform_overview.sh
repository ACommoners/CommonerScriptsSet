#!/bin/bash

set -e


source /etc/kolla/admin-openrc.sh 


# static path
KOLLA_GLOBLA=/etc/kolla/globals.yml
KOLLA_PASS=/etc/kolla/passwords.yml
ICT_GLOBLA=/etc/ict/globals.yml

# dynamic vars
IAAS_PORT=$(sed -n '/^portal_port/p' ${ICT_GLOBLA} | grep -Po  '\d+' )
IAAS_ADDR=$(sed -n '/^kolla_external_vip_address/p' ${KOLLA_GLOBLA}  | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')

# mysql info password/conterner/user
MYSQL_PASS=$( sed -n '/^database_password/p' ${KOLLA_PASS}  | awk '{print $2}')
MYSQL_CONTER=mariadb
MYSQL_USER=root

# ceph mon conterner
CEPH_CONTER=ceph_mon


# rabbitmq conterner
RABBITMQ_CONTER=rabbitmq



function platfrom_version(){

	plat_version=$(sed -n '/^openstack_release/p' ${KOLLA_GLOBLA}  | awk '{print $2}')
}


function iaas_platfrom_url(){

	iaas_url="\"https://${IAAS_ADDR}:${IAAS_PORT}"\"

}


function montior_platfrom_url(){	

	montior_url="\"https://${IAAS_ADDR}:3000\""

}


function iaas_service_overview(){
	
	# openstack cli get status
	ops_nova=$(/usr/bin/openstack compute service list -c State -f value | xargs -I{} echo -n '{} ')
	ops_cinder=$(/usr/bin/openstack volume service list -c State -f value | xargs -I{} echo -n '{} ')
        ops_neutron=$(/usr/bin/openstack network agent list -c Alive -f value | xargs -I{} echo -n '{} ' )
        ops_heat=$(/usr/bin/openstack orchestration service list -c Status -f value | xargs -I{} echo -n '{} ')
	vm_sum=$(/usr/bin/openstack server list --all-projects -c ID -f value  | /usr/bin/wc -l)
        

        iaas_service_facts=$(cat << EOF
{
        "ops_nova": "${ops_nova:-0}",
        "ops_cinder": "${ops_cinder:-0}",
        "ops_neutron": "${ops_neutron:-0}",
        "ops_heat": "${ops_heat:-0}"
}
EOF
)

}


function iaas_vm_sum(){

	vm_sum=$(/usr/bin/openstack server list --all-projects -c ID -f value  | /usr/bin/wc -l)
}


function iaas_memory_overview(){

	# virtualization mem total/used/rate
        memory_total_mb=$(/usr/bin/openstack hypervisor stats show -c memory_mb  -f value)
        memory_used_mb=$(/usr/bin/openstack hypervisor stats show -c memory_mb_used  -f value)
	
	# memory GB
	memory_total_gb=$(awk 'BEGIN{printf "%.0fGiB\n",('$memory_total_mb' / '1024')}')
	# memory rate
	mepm_used_rate=$(awk 'BEGIN{printf "%.2f%\n",('$memory_used_mb'/'$memory_total_mb')*100}')

	iaas_memory_facts=$(cat << EOF
{
	"memory_total_mb": "${memory_total_mb:-0}",
	"memory_used_mb": "${memory_used_mb:-0}",
	"memory_total_gb": "${memory_total_gb:-0}",
	"mepm_used_rate": "${mepm_used_rate:-0}"
}
EOF
)

}


function iaas_vcpus_overview(){

	# virtualization cpu total/used/rate
	vcpus_core_total=$(/usr/bin/openstack hypervisor stats show -c vcpus -f value)
        vcpus_core_used=$(/usr/bin/openstack hypervisor stats show -c vcpus_used -f value)
	vcpus_used_rate=$(/usr/bin/awk 'BEGIN{printf "%.2f%",('$vcpus_core_used'/'$vcpus_core_total')*100}')

	iaas_vcpus_facts=$(cat << EOF
 {
	"vcpus_core_total": "${vcpus_core_total:-0}",
	"vcpus_core_used": "${vcpus_core_used:-0}",
	"vcpus_core_rate": "${vcpus_used_rate:-0}"
}
EOF
)

}






function ceph_clustere_overview(){

	# ceph storage/used/rate
	ceph_storage_total=$(/usr/bin/docker exec ${CEPH_CONTER} /usr/bin/ceph df | awk  '/TOTAL/{print $2$3}')
        ceph_storage_used=$(/usr/bin/docker exec ${CEPH_CONTER} /usr/bin/ceph df | awk  '/TOTAL/{print $8$9}')
	ceph_storage_rate=$( /usr/bin/docker exec ${CEPH_CONTER} /usr/bin/ceph df | awk '/TOTAL/{printf "%.2f%\n", $10}')
	ceph_osd_status=$(docker exec ${CEPH_CONTER} ceph osd tree | grep  -E 'down|up' | awk '{print $4"_"$5}' | xargs -I{} echo -n '{} ')
	ceph_health_status=$(docker exec ${CEPH_CONTER} ceph health detail |xargs -I{} echo -n {})
	ceph_cluster_facts=$(cat << EOF
{
	"ceph_health_status": "${ceph_health_status:-0}",
        "ceph_storage_total": "${ceph_storage_total:-0}",
        "ceph_storage_used": "${ceph_storage_used:-0}",
        "ceph_storage_rate": "${ceph_storage_rate:-0}",
	"ceph_osd_status": "${ceph_osd_status:-0}"
}
EOF
)

}



function mysql_cluster_status(){
	mysql_cluster_info=\"$(/usr/bin/docker exec ${MYSQL_CONTER} mysql -u ${MYSQL_USER} -p${MYSQL_PASS} \
	-e "show status where Variable_name='wsrep_cluster_size'" | xargs -I{} echo -n '{}')\"
#        mysql_cluster_number=$(echo ${mysql_cluster_info} | grep -Po '\d+')

}


function rabbitmq_cluster_status(){
	rabbitmq_cluster_node=\"$(/usr/bin/docker exec ${RABBITMQ_CONTER} rabbitmqctl  cluster_status | \
	gawk 'BEGIN{RS="\r\n"} match($0, /\{running_nodes,\[(.*)\]},(.*){cluster_name/,a) gsub(/\n +/, "", a[1]) {print a[1]}')\"


}


function main(){
	platfrom_version
	iaas_platfrom_url
	montior_platfrom_url

	iaas_service_overview
	iaas_vm_sum
	iaas_memory_overview
	iaas_vcpus_overview
	ceph_clustere_overview
		
	mysql_cluster_status
	rabbitmq_cluster_status

echo "{
\""iaas_version\"": ${plat_version:-[]},
\""iaas_url\"": ${iaas_url:-[]},
\""montior_url\"": ${montior_url:-[]},
\""iaas_service_overview\"": ${iaas_service_facts:-[]},
\""iaas_vm_sum\"": ${vm_sum:-[]},
\""iaas_memory_overview\"": ${iaas_memory_facts:-[]},
\""iaas_vcpus_overview\"": ${iaas_vcpus_facts:-[]},
\""ceph_cluster_overview\"": ${ceph_cluster_facts:-[]},
\""mysql_cluster_status\"": "${mysql_cluster_info:-[]}",
\""rabbitmq_cluster_status\"": "${rabbitmq_cluster_node:-[]}"
}"
}
main
