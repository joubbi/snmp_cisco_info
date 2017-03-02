# snmp_cisco_info

A script that presents information about Cisco devices using SNMP.

Suitable to use as a plugin for any Nagios compatible monitoring system.

The script utputs a string with:
>hostname,<br> model,<br> IOS version,<br> serial nr.,<br> location, <br> contact"

All the fields are queried by SNMP from the device.

The location field is whatever is configured with "snmp-server location" in running-config on the device.

The contact field is whatever is configured with "snmp-server contact".


The formatting of the output string can easily be modified at the top of the script.
The string can then be used by some external system or just as information as is.
It is for example possible to query the API in Op5 Monitor for the information gathered by this plugin. 
Logical devices in a stack or cluster configuration will output one row of
information per physical device.

This script was wtitten for OP5 Monitor in order to populate a database for device inventory
consisting of more than 2000 Cisco network devices.
It has been tested with with: 6500, ASR and other routers, different Catalyst, Nexus...


See also [snmp_genera_info](https://gitlab.com/faridj/snmp_general_info).


### USAGE
Add this script as a service check in Op5/Nagios for a Cisco device.

Apply the SNMP authentication information as variables to the service.

The check will always return OK, even if the host is down.


## Version history
* 3.1 2016-08-26  Added support for WS-C3850-24XS-S
* 3.0 2016-06-21  Major cleaning since the script had grown + support for C6807-XL 
* 2.1 2016-06-08  Replaced the OID for Nexus model.
* 2.0 2015-10-27  Cleanups, more error handling and support for C3850.
* 1.0 2015-08-19  Initial public release with some added comments and a new name.
     2015-06-08  Added support for stacks bigger than 4.
     2015-05-22  Added support for some old ASR version.
     2014-11-07  Updated the logic for model 4500. 
     2014-11-05  Added Cisco 4500 VSS logic to get serial of switch2.
     2014-10-23  Fixed a bug with Nexus serial. 
     2014-10-14  Added section for Cisco WS-6500, and handling of SNMP error.
     2014-04-16  First version. 


___

Licensed under the [__Apache License Version 2.0__](https://www.apache.org/licenses/LICENSE-2.0)

Written by __farid@joubbi.se__

http://www.joubbi.se/monitoring.html

