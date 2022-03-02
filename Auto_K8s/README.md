## ansible自动化部署k8s

#### 项目结构
```
├── download 
├── group_vars 
├── hosts 
├── roles 
├── site.yml 
└── testfile 
```

> 部署环境: `centos7`及以上

> 节点要求：单节点或以上


#### k8s-hosts文件

```
[deploy]   # 部署节点IP，一般拿其中一个master节点作为部署节点既可以
172.20.163.244

[master] # 承载k8s控制节点服务api、schedule、controller或etcd等服务
172.20.163.244 
172.20.163.53
172.20.163.86

[etcd] # k8s集群数据存储，一般跟master节点一样，也可以单独分离出来
172.20.163.86
172.20.163.53
172.20.163.244

[worker] # k8s worker节点服务，docker、kubelet、proxy等服务，master节点跟worker可以共用节点
172.20.163.86
172.20.163.53
172.20.163.244
172.20.163.79

[docker:children]
worker

[loadblance] # k8s集群高可用，未完成
```
#### 部署包含服务
 - k8s集群服务
 - ingress
 - flannel or calico
 - coredns

#### 部署准备
```
1、下载k8s集群依赖包：sh download(下载失败多下载几次)
	> 离线部署: sh downloadh后，打包离线包：tar -zcf /root/kubelw.tar.gz /opt/kubelw  , 然后离线包传到部署机器：tar -zxvf /root/kubelw.tar.gz -C /opt/
	> 在线部署：sh downloadh后接着第2步
2、不管是离线还是在线部署，部署节点都需要安装ansible
	> 在线部署：yum install ansible
	> 离线部署：yum install --downloadonly --downloaddir=$(pwd) ansible 下载好传到部署节点：yum install *
3、配置k8s-hosts文件
4、部署节点于其它节点ssh 免密配置,可采用<password_free_conf.sh>一键绵密配置
5、测试网络连通性: ansible -i k8s-hosts all -m ping 
```

#### 执行部署

```
1、修改变量group_vars/all.yml
    > docker_registry: "172.20.163.244" # docker 仓库地址，一般为部署节点IP，必须按照实际修改
    > registry_port: 5000 # 仓库端口，按需求可改可不改
    > cluster_network: flannel  # calico or flannel， 按需求可改可不改
    > service_cidr: "10.68.0.0/16" # 按需求可改可不改
    > cluster_cidr: "172.20.0.0/16" # 按需求可改可不改

2、执行部署或者是扩容worker节点都是此步骤
   ansible-playbook -i  k8s-hosts site.yml
```
