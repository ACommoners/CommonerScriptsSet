#!/usr/bin/python
# author: haha
# date: 2020-12-11

from __future__ import absolute_import, division, print_function
__metaclass__ = type

from ansible.module_utils.six import iteritems
import json
import os



def save_json_data(item, internal_dict):
    """
    Save json data to *.json
    """
    with open(internal_dict['os_inspection_path'], internal_dict['write_mode']) as f:
        f.write(json.dumps(item, indent=6, sort_keys=True))
  



def json_load(stdout):
    
    return json.loads(stdout.get('stdout'))


def platform_inspection_filter(data):
    """
    Get the json data from platform
    :param data: hostvars
    :return: dict
    """
    item = dict(platform_overview=None, control_overview=dict(), compute_overview=dict())
    internal_dict=dict()
    for host, value in iteritems(data):
	
	platform_res = value.get('platform_overview')
        control_res = value.get('control_service')
        compute_res = value.get('compute_service')
	try:
	   if platform_res.get('stdout', False):
              item['platform_overview'] = json_load(platform_res)

           if control_res.get('stdout', False):
              item['control_overview'][host] = json_load(control_res)

           if compute_res.get('stdout', False):
              item['compute_overview'][host] = json_load(compute_res)

	except Exception as e:
	   pass

    item['platform_overview']['cluser_node_count'] = value.get('cluser_node_count', 'None')	
    item['platform_overview']['now_day'] = value.get('now_day', 'None')	
    item['platform_overview']['engineer_name'] = value.get('engineer_name', 'None')	
    internal_dict['os_inspection_path'] = value.get('platform_inspection_path', '/root/platform.json')           
    internal_dict['write_mode'] = value.get('write_mode', 'w+')           
    internal_dict['generate_json'] = value.get('generate_json', True)
    if internal_dict['generate_json']:
       save_json_data(item, internal_dict)
    return 'Save json data to {0}'.format(internal_dict['os_inspection_path'])


class FilterModule(object):
    """
    Filters for working with output from platform
    """

    def filters(self):
        return {
            'platform_inspection_filter': platform_inspection_filter
        }
