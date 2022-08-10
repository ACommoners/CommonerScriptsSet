#!/usr/bin/python
# -*- coding: utf-8 -*-


from __future__ import (absolute_import, division, print_function)
__metaclass__ = type


from ansible.module_utils.basic import AnsibleModule
import json


class Json(object):

    def __init__(self, module):
        self.platform_json = module.params['platform_json']
        self.os_json = module.params['os_json']
        self.report_json = module.params['report_json_path']
        self.module= module

    def json_loads(self, json_load):
        """
        Load json data to *.json
        """
        try:
            with open(json_load, 'r') as f:
                d = f.read()
                return json.loads(d)
        except Exception as err:
            self.module.fail_json(err, **dict(stdout='<platform_process> json loads data failure'))


    def json_dumps(self, items):
        """
        Save json data to *.json
        """
        try:
            with open(self.report_json, 'w+') as f:
                f.write(json.dumps(items, indent=6, sort_keys=True))
        except Exception as err:
            self.module.fail_json(err, **dict(stdout='<platform_process> json dumps data failure'))


class Process_data(object):

    @staticmethod
    def mysql_cluster(cluster_data):
        if cluster_data.split()[2] != '3':
            return [False, u'mysql cluster failure']
        return True

    @staticmethod
    def rabbit_cluster(cluster_data):
        if len(cluster_data.split(u',')) != 3:
            return [False, u'rabbitmq cluster failure']
        return True

    @staticmethod
    def ceph_osd(ceph_data):
        osd_down = [o for o in ceph_data.split() if 'down' in o]
        if osd_down:
            return [False, ' '.join(osd_down)]
        return True

    @staticmethod
    def ceph_cluster(ceph_data):
        if 'HEALTH_OK' not in ceph_data:
            return [False, ceph_data]
        return True

    @staticmethod
    def compute(compute_data):
        if compute_data.lower().find('exited') != -1:
            return False
        return True

    @staticmethod
    def control(control_data):
        if control_data.lower().find('exited') != -1:
            return False
        return True

    @staticmethod
    def iaas_service(iaas_service_data):
        if 'down' in iaas_service_data or 'False' in iaas_service_data:
            return False
        return True


def main():
    module = AnsibleModule(
        argument_spec=dict(
            report_json_path=dict(required=True, type='str'),
            platform_json=dict(default=None, type='str'),
            os_json=dict(default=None, type='str')
        ),
        supports_check_mode=True,
    )

    json_obj = Json(module)
    overview = dict(platform=False, os=False)

    # cloud platform data process
    if json_obj.platform_json:
        platform_dict = json_obj.json_loads(json_obj.platform_json)


        # ceph cluster data process
        platform_dict['platform_overview']['ceph_cluster_overview']['ceph_health_status'] = Process_data.ceph_cluster(
            platform_dict['platform_overview']['ceph_cluster_overview']['ceph_health_status']
        )

        # ceph osd stataus data proccess
        platform_dict['platform_overview']['ceph_cluster_overview']['ceph_osd_status'] = Process_data.ceph_osd(

            platform_dict['platform_overview']['ceph_cluster_overview']['ceph_osd_status']
        )

        # openstack platform service data process
        for ikey, ivalue in platform_dict['platform_overview']['iaas_service_overview'].items():
            platform_dict['platform_overview']['iaas_service_overview'][ikey] = Process_data.iaas_service(
                platform_dict['platform_overview']['iaas_service_overview'][ikey]
            )

        # mysql cluster data process
        platform_dict['platform_overview']['mysql_cluster_status'] = Process_data.mysql_cluster(
            platform_dict['platform_overview']['mysql_cluster_status']
        )

        # rabbitmq cluster data process
        platform_dict['platform_overview']['rabbitmq_cluster_status'] = Process_data.rabbit_cluster(
            platform_dict['platform_overview']['rabbitmq_cluster_status']
        )

        # control service data process
        control_overview = dict()
        for host, value in platform_dict['control_overview'].items():
            for ckey, cvlaue in value.items():
                if ckey in control_overview:
                    control_overview[ckey] = control_overview[ckey] + cvlaue
                    continue
                control_overview[ckey] = cvlaue
        platform_dict['control_overview'] = control_overview
        for ckey, cvlaue in platform_dict['control_overview'].items():
            platform_dict['control_overview'][ckey] = Process_data.control(cvlaue)

        # compute service data process
        compute_overview = dict()
        for chost, cvalue in platform_dict['compute_overview'].items():
            for cpkey, cpvlaue in cvalue.items():
                if cpkey in compute_overview:
                    compute_overview[cpkey] = compute_overview[cpkey] + cpvlaue
                    continue
                compute_overview[cpkey] = cpvlaue

        platform_dict['compute_overview'] = compute_overview
        for cpkey, cpvlaue in platform_dict['compute_overview'].items():
            platform_dict['compute_overview'][cpkey] = Process_data.compute(cpkey)



        overview['platform'] = dict(platform_dict)


    # hosts resource data process
    if json_obj.os_json:
        os_dict = json_obj.json_loads(json_obj.os_json)

        os = dict()
        for phost, pvalue in os_dict.items():

            if phost not in os:
                os[phost] = dict()

            if os_dict[phost].get('unreachable', False):
                os[phost]['unreachable'] = True
                continue

            if isinstance(pvalue['disk'], list):
                for disks in pvalue['disk']:
                    if disks['mount'] == '/':
                        os[phost]['size_usedutilization'] = disks['size_usedutilization']
            os[phost]['mem_usedutilization'] = pvalue['mem']['mem_usedutilization']
            os[phost]['default_ipv4'] = pvalue['system']['default_ipv4']
            os[phost]['os_pretty_name'] = pvalue['system']['os_pretty_name']
            os[phost]['uptime'] = pvalue['system']['uptime']
            os[phost]['hostname'] = pvalue['system']['hostname']
            os[phost]['cpu_usedutilization'] = pvalue['cpu']['cpu_usedutilization']
            overview['os'] = os

    json_obj.json_dumps(overview)
    json_obj.module.exit_json(**dict(stdout='Data processing completed successfully',rc=0, changed=True))


if __name__ == '__main__':
    main()
