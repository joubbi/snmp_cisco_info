# snmp_cisco_info

A script that presents information about Cisco devices using SNMP.
Suitable to use as a plugin for any Nagios compatible monitoring system.

The script utputs a string with:
>hostname,<br> model,<br> IOS version,<br> serial nr.,<br> location, <br> contact"

All the fields are queried by SNMP from the device.
The location field is whatever is configured with "snmp-server location" in running-config on the device.
The contact field is whatever is configured with "snmp-server contact".

The formatting of this string can easily be modified at the bottom of this script.
The string can then be used by some external system or just as information as is.
It is for example possible to query the API in Op5 Monitor for the information gathered by this plugin. 
Logical devices in a stack or cluster configuration will output one row of
information per physical device.

This script was wtitten for OP5 Monitor in order to populate a database for device inventory
consisting of more than 2000 Cisco network devices.
It has been tested with with: 6500, ASR and other routers, different Catalyst, Nexus...

### USAGE
Add this script as a service check in Op5/Nagios for a Cisco device.
Apply the SNMP authentication information as variables to the service.
The check will always return OK, even if the host is down.

Tested with: 6500, ASR and other routers, different Catalyst, Nexus...

Licensed under the Apache license version 2.0
Written by farid.joubbi@consign.se

* http://www.consign.se/monitoring/
