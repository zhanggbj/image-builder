#
# Copyright (C) 2023 VMware, Inc. All rights reserved.
#

import os

import yaml
from cloudinit.cmd import query

enable_system_service_format_str = "systemctl enable {service} && systemctl start {service}"
ntp_related_services_list = ["systemd-timesyncd", "chronyd", "chrony-wait.service"]


def handle_if_ntp_settings_present():
    for service in ntp_related_services_list:
        return_code = os.system(enable_system_service_format_str.format(service=service))
        if return_code != 0:
            print("failed to enable and start service: ", service)
            return 1
    return_code = os.system("/usr/bin/vmware-toolbox-cmd timesync disable")
    if return_code != 0:
        print("failed to disable timesync")
        return 1
    print("Successfully disabled timesync")


def handle_if_ntp_settings_not_present():
    return_code = os.system("/usr/bin/vmware-toolbox-cmd timesync enable")
    if return_code != 0:
        print("failed to enable timesync")
        return 1
    print("Successfully enable timesync")


# disable_tca_ntp_handler_service to avoid the ntp reconfig after rebooting
def disable_tca_ntp_handler_service():
    return_code = os.system("systemctl disable tca-ntp-handler.service")
    if return_code != 0:
        print("failed to disable tca-ntp-handler itself")
        return 1
    print("Successfully disabled tca-ntp-handler service")


enabled = False
try:
    data = query.load_userdata("/var/lib/cloud/instance/user-data.txt")
    enabled = yaml.safe_load(data)["ntp"]["enabled"]
except KeyError:
    print("ntp.enabled not found in user-data")

if enabled:
    print("NTP is enabled")
    handle_if_ntp_settings_present()
else:
    print("NTP is disabled")
    handle_if_ntp_settings_not_present()
disable_tca_ntp_handler_service()
print("Completed the processing of the ntp enabled={enabled} state".format(enabled=enabled))
