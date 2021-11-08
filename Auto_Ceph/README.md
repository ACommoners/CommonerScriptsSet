# kolla-ceph部署

> ##### kolla-ceph来源：

> 项目中的部分代码来自于kolla和kolla-ansible

> ##### kolla-ceph的介绍:

>1、镜像的构建很方便, 基于容器的方式部署，创建、删除方便

>2、kolla-ceph的操作幂等，多次执行不会产生副作用

>3、使用kolla-ceph(基于ansible)流程化部署

>4、通过给磁盘打上相应标签，创建osd非常简单

>5、升级便捷，通过构建新的ceph镜像，upgrade既可

>6、自动根据osd节点数量来设置故障域: "osd" 或 "host",及配置对应的副本数
 

### 项目结构

```
Auto_Ceph
├── 00-hosts
├── README.md
├── action_plugins
├── action.yml
├── bin
├── build
├── config
├── group_vars
├── library
├── os.yml
├── requirements.txt 
├── roles
└── site.yml
```
> 系统: Centos  
> 环境: 3台虚拟机(可采用单节点或多节点)，下载`Auto_Ceph`项目放在/root/目录下    


### ceph集群节点规划、网络规划
```
vi /root/Auto_Ceph/00-hosts

# storage_interface=eth0 ceph集群管理接口，必须配置 
# cluster_interface=eth1 ceph集群数据同步接口，为空默认就是storage_interface

[all:vars]
storage_interface=eth0
cluster_interface=eth1

[mon]
172.20.163.244  # 同时是部署节点
172.20.163.67 
172.20.163.238

[mgr]
172.20.163.244
172.20.163.67 
172.20.163.238 

[osd]
172.20.163.244
172.20.163.67 
172.20.163.238 

[rgw]
172.20.163.244
172.20.163.67 
172.20.163.238 

[mds]

```

### 下载ceph镜像<部署节点操作>
> 部署节点：可以是任意一台mon组的节点（172.20.163.244）

1. 在线部署: 下载ceph镜像、安装ansible、kolla-ceph<部署节点操作>
  
  ```
  1. type wget || yum install wget -y
  
  2. wget https://bootstrap.pypa.io/pip/2.7/get-pip.py --no-check-certificate
  
  3. python get-pip.py
  
  4.ceph镜像下载安装依赖
    pip install -r /root/Auto_Ceph/requirements.txt --ignore-installed
      
  5. 下载docker
     sh /root/Auto_Ceph/bin/install -D
      
  6. 运行docker
     sh /root/Auto_Ceph/bin/install -I
     systemctl status docker
      
  7. 下载registry
     sh /root/Auto_Ceph/bin/install -R
      
  8. 运行registry
     docker run -d -v /opt/registry:/var/lib/registry -p 5000:5000 --restart=always --name registry registry:latest
  	
  7. 修改配置
     vi /root/Auto_Ceph/build/ceph-build.conf
     registry = 172.17.2.179:5000 # 必须按照实际修改, 其它默认既可 
             
  8. 开始构建ceph镜像, 查看镜像
     cd /root/Auto_Ceph/build/ && sh build.sh --tag nautilus
     docker image ls
       REPOSITORY                                                TAG                 IMAGE ID            CREATED             SIZE
       172.20.163.77:5000/kolla-ceph/centos-binary-ceph-mon      nautilus            a5e8a5ff08fc        13 days ago         792MB
       172.20.163.77:5000/kolla-ceph/centos-binary-ceph-osd      nautilus            118b704bcf88        13 days ago         793MB
       172.20.163.77:5000/kolla-ceph/centos-binary-cephfs-fuse   nautilus            6b00fc4b6e2e        13 days ago         792MB
       172.20.163.77:5000/kolla-ceph/centos-binary-ceph-mds      nautilus            b206c578e594        13 days ago         792MB
       172.20.163.77:5000/kolla-ceph/centos-binary-ceph-rgw      nautilus            e9f5e4bca8ab        13 days ago         792MB
       172.20.163.77:5000/kolla-ceph/centos-binary-ceph-mgr      nautilus            b561bf427142        13 days ago         792MB
       172.20.163.77:5000/kolla-ceph/centos-binary-ceph-base     nautilus            eae0898ce208        13 days ago         792MB
       172.20.163.77:5000/kolla-ceph/centos-binary-base          nautilus            d48db6e179f9        13 days ago         410MB

      
  9. type ansible || yum install ansible -y
  
  10. 部署节点与节点之间ssh免密配置
  
  11. 安装kolla-ceph工具 
      cd /root/Auto_Ceph/bin && sh install -K
      
  ```
  
2. 在线部署: 下载docker<除部署节点外, 在其它节点操作以下步骤>

```
1. type wget || yum install wget -y

2. wget https://bootstrap.pypa.io/pip/2.7/get-pip.py --no-check-certificate

3. python get-pip.py

4. 安装docker模块 
    pip install docker
    
5. 安装并运行docker
   scp /root/Auto_Ceph/bin/install ${target_host}:/root/
   sh /root/install -D &&  sh /root/install -I

```


### 部署ceph集群
#### 1. 修改参数<部署节点操作>

```
vi /root/Auto_Ceph/config/globals.yml 

   ceph_tag: "nautilus"
   docker_registry: "仓库地址:端口"
   ceph_osd_store_type: "bluestore"
   ceph_pool_pg_num: 32 # 设置你的pg数
   ceph_pool_pgp_num: 32 # 设置你的pgp数
   enable_ceph_rgw: "true or false"
   enable_ceph_mds: "true or false"
```
   
#### 2. kolla-ceph部署使用<部署节点操作>

```

2.1 初始化ceph主机节点

    kolla-ceph -i /root/Auto_Ceph/00-hosts os
   
2.2 部署前检查配置

    kolla-ceph -i /root/Auto_Ceph/00-hosts prechecks
   
2.3 部署ceph集群

    1、bluestore osd: 为每个osd节点的磁盘打上标签
       parted  /dev/vdc  -s  -- mklabel  gpt  mkpart KOLLA_CEPH_OSD_BOOTSTRAP_BS  1 -1
    2、部署ceph-mon、ceph-osd、ceph-mgr、ceph-rgw、ceph-mds
       kolla-ceph -i /root/Auto_Ceph/00-hosts deploy
    3、docker exec ceph_mon ceph -s
         cluster:
           id:     4a9e463a-4853-4237-a5c5-9ae9d25bacda
           health: HEALTH_OK
        
         services:
           mon: 3 daemons, quorum 172.20.163.67,172.20.163.77,172.20.163.238 (age 2h)
           mgr: 172.20.163.238(active, since 2h), standbys: 172.20.163.77, 172.20.163.67
           mds: cephfs:1 {0=devops2=up:active} 2 up:standby
           osd: 4 osds: 4 up (since 2h), 4 in (since 13d)
           rgw: 1 daemon active (radosgw.gateway)
        
         data:
           pools:   7 pools, 104 pgs
           objects: 260 objects, 7.6 KiB
           usage:   4.1 GiB used, 76 GiB / 80 GiB avail
           pgs:     104 active+clean   

2.4 删除操作: ceph集群容器和volume

    kolla-ceph -i /root/Auto_Ceph/00-hosts  destroy --yes-i-really-really-mean-it
  
2.5 升级操作

    1、cd /root/Auto_Ceph/build/ && sh build.sh --tag new_ceph_version
    2、修改最新ceph_tag: "new_ceph_version"
    3、kolla-ceph -i /root/Auto_Ceph/00-hosts upgrade
   
2.6 单独更换部署osd

    kolla-ceph -i /root/Auto_Ceph/00-hosts -t ceph-osd

2.7 开启ceph dashborad
    enable_ceph_dashboard: true
    kolla-ceph -i /root/Auto_Ceph/00-hosts start-dashborad

2.8 启用对象网关管理前端
    enable_ceph_rgw: true   
    kolla-ceph -i /root/Auto_Ceph/00-hosts start-rgw-front


```
  
#### 3. 磁盘打标签介绍

##### 3.1. bluestore wal db共用一块盘打标签方式

  1. parted  /dev/vdc  -s  -- mklabel  gpt  mkpart KOLLA_CEPH_OSD_BOOTSTRAP_BS  1 -1
    
##### 3.2. bluestore 分离db和wal打标签方式

>  为了提高 ceph 性能,且ssd磁盘数量有限，通常将db和wal存放在单独的 ssd 磁盘上

```
  # SSD磁盘：vdb vdd HDD磁盘：vdc
    1. 指定元数据分区 
       parted /dev/vdc -s -- mklabel  gpt mkpart KOLLA_CEPH_OSD_BOOTSTRAP_BS_BLUE1 1 100
    2. 指定block 分区
       parted /dev/vdc -s -- mkpart KOLLA_CEPH_OSD_BOOTSTRAP_BS_BLUE1_B 101 100%
      
    3. 指定block.wal分区
       parted /dev/vdb -s -- mklabel  gpt mkpart KOLLA_CEPH_OSD_BOOTSTRAP_BS_BLUE1_W 1 1000
    4. 指定block.db分区
       parted /dev/vdd -s -- mklabel  gpt mkpart KOLLA_CEPH_OSD_BOOTSTRAP_BS_BLUE1_D 1 10000
    
```
> block.db 分区的大小为 block 分区 的 4%大小

##### 3.3 filestore 打标签方式
  1. parted /dev/vdc -s -- mklabel gpt mkpart KOLLA_CEPH_OSD_BOOTSTRAP 1 -1
 
##### 3.4 filestore 指定日志单独分区

> filestore 为了提高 ceph 性能，通常将日志存放在单独的 ssd 磁盘上

```
# SSD磁盘：vdb    HDD磁盘：vdc vdd 
1. vdc 作为数据盘
   parted /dev/vdc -s -- mklabel gpt mkpart KOLLA_CEPH_OSD_BOOTSTRAP_FILE1 1 -1
2. vdd 作为数据盘
   parted /dev/vdd -s -- mklabel gpt mkpart KOLLA_CEPH_OSD_BOOTSTRAP_FILE2 1 -1
3. vdb作为vdc、vdd 的journal盘
   parted /dev/vdb -s -- mklabel gpt
   parted /dev/vdb -s -- mkpart KOLLA_CEPH_OSD_BOOTSTRAP_FILE1_J 4M 2G
   parted /dev/vdb -s -- mkpart KOLLA_CEPH_OSD_BOOTSTRAP_FILE2_J 2G 4G

```

### 运维操作

```
1、任意一台montior节点进入ceph环境. 既可以正常执行ceph命令运维操作
   docker exec -it ceph_mon bash
   ceph -s
     
2、或者直接外部操作
   docker exec ceph_mon ceph -s

3、osd故障操作
   docker exec ceph_mon ceph osd crush rm osd.1
   docker exec ceph_mon ceph osd auth rm osd.1
   docker exec ceph_mon ceph osd rm osd.1
   到故障osd节点把容器给干掉,然后换新盘: docker rm -f ceph_osd_1
   为新磁盘盘打标签: parted  /dev/vdc  -s  -- mklabel  gpt  mkpart KOLLA_CEPH_OSD_BOOTSTRAP_BS  1 -1
   部署新osd: kolla-ceph -i /root/Auto_Ceph/00-hosts -t ceph-osd
```

### ceph dashboard 

![Image text](https://github.com/ACommoners/CommonerScriptsSet/blob/master/Auto_Ceph/image/dash1.png)

![Image text](https://github.com/ACommoners/CommonerScriptsSet/blob/master/Auto_Ceph/image/dash2.png)

![Image text](https://github.com/ACommoners/CommonerScriptsSet/blob/master/Auto_Ceph/image/rgw1.png)

### 待开发功能

```
1. 基于kolla-ceph的ceph集群健康状态巡检
2. 基于kolla-ceph的osd运维操作
```
