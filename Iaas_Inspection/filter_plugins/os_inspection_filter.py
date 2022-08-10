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
  

def os_inspection_filter(data):
    """
    Get the json data from inspection_result
    :param data: hostvars
    :return: dict
    """
    item = dict()
    internal_dict=dict()

    for host, value in iteritems(data):
        result = value.get('inspection_result')
        if result:
           system = result.get('stdout', None)
           if not system:
              item[host] = dict(unreachable=True)
              continue
           internal_dict['os_inspection_path'] = value.get('os_inspection_path', '/root/os.json')           
           internal_dict['write_mode'] = value.get('write_mode', 'w+')           
           internal_dict['generate_json'] = value.get('generate_json', True)
           item[host] = json.loads(system)
    if internal_dict['generate_json']:
       save_json_data(item, internal_dict)
    return 'Save json data to {0}'.format(internal_dict['os_inspection_path'])


class FilterModule(object):
    """
    Filters for working with output from inspection_result
    """

    def filters(self):
        return {
            'os_inspection_filter': os_inspection_filter
        }
