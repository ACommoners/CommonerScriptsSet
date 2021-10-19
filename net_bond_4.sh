#!/bin/bash
# 系统bond模块信息：modinfo bonding
# 查看bond的结果：cat/proc/net/bonding/bondpub

# 管理网bond4配置
systemctl disable NetworkManager
systemctl stop NetworkManager 

NET_PATH=/etc/sysconfig/network-scripts/ifcfg-
# NET_PATH=/Users/rowen/data/scrip/ssh_connet/

usage() {
    cat << EOF
Options:
    --help, -h                                                  Show help
    --net，-n <network-card name> <bond name>                   Configure the network card to bond
    --bond, -b <bond name>                                      Configure bond
    --subnet，-s <subnet name> <ip> <netmaske> <gateway>        Configure sub-interface

Example:
    sh network.sh -n eth1 bonddata                                      Configure the network card to bond
    sh network.sh -b bondtada                                           Configure bond
    sh network.sh -s bondata.500 10.41.0.100 255.255.255.0 10.41.0.254  Configure sub-interface
EOF

}

net() {
   cat << EOF | tee ${NET_PATH}${NET}
TYPE=Ethernet
PROXY_METHOD=none
BOOTPROTO=none
# DEFROUTE=yes
NAME=${NET}
DEVICE=${NET}
ONBOOT=yes
MASTER=${BOND_NAME}
SLAVE=yes
EOF
}


# [root@i620-3 network-scripts]# cat ifcfg-bondpub
bond() {
   cat << EOF | tee ${NET_PATH}${BOND_NAME}
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
# BOOTPROTO=static
# IPADDR=192.168.1.7
# NETMASK=255.255.255.0
# DEFROUTE=yes
IPV4_FAILURE_FATAL=no
NAME=${BOND_NAME}
DEVICE=${BOND_NAME}
ONBOOT=yes
BONDING_MASTER=yes
BONDING_OPTS='mode=4 miimon=100 lacp_rate=1 xmit_hash_policy=1'
EOF
}

# 因管理网需要走vlan网络，需要配置一个子接口，500为vlan id
# [root@i620-3 network-scripts]# cat ifcfg-bondpub.500
bond_vlan() {
   cat << EOF | tee ${NET_PATH}${BOND_NAME_VLAN}
TYPE=Ethernet
PROXY_METHOD=none
DEFROUTE=yes
BROWSER_ONLY=no
BOOTPROTO=none
IPADDR=${IP}
NETMASK=${NETMASK}
GATEWAY=${GATEWAY}
IPV4_FAILURE_FATAL=no
NAME=${BOND_NAME_VLAN}
DEVICE=${BOND_NAME_VLAN}
ONBOOT=yes
# BONDING_MASTER=yes
# BONDING_OPTS='mode=4 miimon=100 lacp_rate=1 xmit_hash_policy=1'
VLAN=yes
EOF
}


interface() {
   cat  << EOF | tee ${NET_PATH}${INTER_NAME}
DEVICE=${INTER_NAME}
TYPE=Ethernet
BOOTPROTO=none
ONBOOT=yes
EOF
}

interface_vlan(){
cat  << EOF | tee ${NET_PATH}${INTER_NAME_VLAN}
DEVICE=${INTER_NAME_VLAN}
BOOTPROTO=none
ONBOOT=yes
IPADDR=${IP}
NETMASK=${NETMASK}
GATEWAY=${GATEWAY}
# PREFIX=24
VLAN=yes                ##开启vlan，表明此子接口为vlan接口
EOF
}



#TEMP=`getopt -o hn:b:s:i: --long help,net:,bond:,bond_vlan:,interface:  -- "$@" 2>/dev/null`

[ $? != 0 ] && echo -e "\033[31mERROR: unknown argument! \033[0m\n" && usage && exit 1

# eval set -- "$TEMP"

while :
do
   [ -z "$1" ] && break;
   case "$1" in
      -h|--help)
              usage; exit 0
              ;;
      -i|--interface)
              [ $# == 2 ] && INTER_NAME=$2; interface && exit 0
              INTER_NAME_VLAN=$2
	      IP=$3
	      NETMASK=$4
	      GATEWAY=$5
              interface_vlan; exit 0
	      ;;
      -n|--net)
              NET=$2
	      BOND_NAME=$3
              net; exit 0
              ;;
      -b|--bond)
              BOND_NAME=$2 && bond; exit 0
              ;;
      -s|--subnet)
              BOND_NAME_VLAN=$2; IP=$3; NETMASK=$4; GATEWAY=$5 && bond_vlan; exit 0
              ;;
      *)
              echo -e "\033[31mERROR: unknown argument! \033[0m\n" && usage && exit 1
              ;;
   esac
done
