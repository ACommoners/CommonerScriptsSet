# IAAS自动化巡检生成xlsx报告

### 项目结构:
```
├── README.md
├── filter_plugins 生成json数据
├── generate_xlsx.yml 生成xlsx文件
├── group_vars 全局变量 
├── library 数据处理及生成xlsx模块
├── report 最终xlsx报告保存
├── roles  巡检代码
├── save_data json数据保存
├── site.yml  巡检入口
└── xlsx_template  模板
```

注意事项：

```
部署节点的IP需要放在control主机组的第一位，比如部署节点IP是：1.88.88.1
example：
	[control]
	1.88.88.1
	1.88.88.2
	1.88.88.3

```



### 执行巡检并处理json数据
> 注意：执行节点要与目标节点免密
- ansible-playbook -i /etc/ansible/hosts/00-nodes site.yml 



### 数据处理后生成os和platform的json数据(生成xlsx报告使用)
```json
{
      "os": {
            "1.88.88.1": {
                  "cpu_usedutilization": "5.17%", 
                  "default_ipv4": "1.88.88.1", 
                  "hostname": "control01", 
                  "mem_usedutilization": "27.46%", 
                  "os_pretty_name": "CentOS Linux 7 (Core)", 
                  "size_usedutilization": "64%", 
                  "uptime": "256"
            }, 
            "1.88.88.2": {
                  "cpu_usedutilization": "9.04%", 
                  "default_ipv4": "1.88.88.2", 
                  "hostname": "control02", 
                  "mem_usedutilization": "37.85%", 
                  "os_pretty_name": "CentOS Linux 7 (Core)", 
                  "size_usedutilization": "56%", 
                  "uptime": "256"
            }, 
            "1.88.88.3": {
                  "cpu_usedutilization": "5.39%", 
                  "default_ipv4": "1.88.88.3", 
                  "hostname": "control03", 
                  "mem_usedutilization": "24.08%", 
                  "os_pretty_name": "CentOS Linux 7 (Core)", 
                  "size_usedutilization": "44%", 
                  "uptime": "256"
            }, 
      }, 
      "platform": {
            "compute_overview": {
                  "cinder_volume": true, 
                  "nova_compute": true, 
                  "openvswitch_agent": true
            }, 
            "control_overview": {
                  "control_ceph_mon": true, 
                  "control_cinder": true, 
                  "control_glance": true, 
                  "control_haproxy": true, 
                  "control_heat": true, 
                  "control_horizon": true, 
                  "control_keepalived": true, 
                  "control_keystone": true, 
                  "control_memcached": true, 
                  "control_mysql": true, 
                  "control_network": true, 
                  "control_network_dhcp": true, 
                  "control_neutron": true, 
                  "control_nova": true, 
                  "control_rabbitmq": true
            }, 
            "platform_overview": {
                  "ceph_cluster_overview": {
                        "ceph_health_status": true, 
                        "ceph_osd_status": true, 
                        "ceph_storage_rate": "1.94%", 
                        "ceph_storage_total": "218TiB", 
                        "ceph_storage_used": "4.2TiB"
                  }, 
                  "cluser_node_count": "8", 
                  "engineer_name": "test", 
                  "iaas_memory_overview": {
                        "memory_total_gb": "306124GiB", 
                        "memory_total_mb": "3134712", 
                        "memory_used_mb": "245760", 
                        "mepm_used_rate": "7.84%"
                  }, 
                  "iaas_service_overview": {
                        "ops_cinder": false, 
                        "ops_heat": false, 
                        "ops_neutron": true, 
                        "ops_nova": false
                  }, 
                  "iaas_url": "https://1.88.88253:81", 
                  "iaas_vcpus_overview": {
                        "vcpus_core_rate": "24.11%", 
                        "vcpus_core_total": "448", 
                        "vcpus_core_used": "108"
                  }, 
                  "iaas_version": "train", 
                  "iaas_vm_sum": 11, 
                  "montior_url": "https://1.88.88.253:3000", 
                  "mysql_cluster_status": true, 
                  "now_day": "2021-03-02", 
                  "rabbitmq_cluster_status": true
            }
      }
}

```


### 生成xlsx巡检报告

> 注意：执行前当前节点需要预先安装openpyxl模块`pip install openpyxl`

- ansible-playbook generate_xlsx.yml 



### xlxs报告模板

#### platform 
![Image text](https://github.com/self-bug/inspection/blob/master/iaas_inspection/images/platform.png)

#### os
![Image text](https://github.com/self-bug/inspection/blob/master/iaas_inspection/images/os.png)
