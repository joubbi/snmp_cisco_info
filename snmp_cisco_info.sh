#!/bin/sh

########################################################################################
#                                                                                      #
# A script for presenting information about Cisco devices with SNMP.                   #
#                                                                                      #
# The script utputs a string with:                                                     #
# hostname,<br> model,<br> IOS version,<br> serial nr.,<br> location, <br> contact"    #
# (The formatting of this string can easily be modified at the top of this script).    #
# The string can then be used by some external system or just as information as is.    #
# Logical devices in a stack or cluster configuration will output one row of           #
# information per physical device.                                                     #
#                                                                                      #
# This script was wtitten for Op5 Monitor in order to populate a database for          #
# device inventory consisting of more than 2000 Cisco network devices.                 #
#                                                                                      #
#                                                                                      #
# USAGE:                                                                               #
# Add this script as a service check in Op5/Nagios/Icinga... for a Cisco device.       #
# Apply the SNMP authentication information as variables to the service.               #
# The check will always return OK, even if the host is down.                           #
#                                                                                      #
# Tested with: 6500, ASR and other routers, different Catalyst, Nexus...               #  
#                                                                                      #
#  Version history:                                                                    #
# 3.1 2016-08-26  Added support for WS-C3850-24XS-S                                    #
# 3.0 2016-06-21  Major cleaning since the script had grown + support for C6807-XL     # 
# 2.1 2016-06-08  Replaced the OID for Nexus model.                                    #
# 2.0 2015-10-27  Cleanups, more error handling and support for C3850.                 #
# 1.0 2015-08-19  Initial public release with some added comments and a new name.      #
#     2015-06-08  Added support for stacks bigger than 4.		               #
#     2015-05-22  Added support for some old ASR version.                              #
#     2014-11-07  Updated the logic for model 4500.                                    #
#     2014-11-05  Added Cisco 4500 VSS logic to get serial of switch2.                 #
#     2014-10-23  Fixed a bug with Nexus serial.                                       #
#     2014-10-14  Added section for Cisco WS-6500, and handling of SNMP error.         #
#     2014-04-16  First version.                                                       #
#                                                                                      #
# Licensed under the Apache License Version 2.0                                        #
# Written by farid@joubbi.se                                                           #
#                                                                                      #
########################################################################################


print_and_exit (){
# This is a function that prints the string with the gathered values after some sanity checks

  # OID does not exist
  echo "$hostname" | /bin/grep -E 'exists|available' > /dev/null
  if [ $? == 0 ]; then
    hostname="N/A"
  fi
  echo "$model" | /bin/grep -E 'exists|available' > /dev/null
  if [ $? == 0 ]; then
    model="N/A"
  fi
  echo "$version" | /bin/grep -E 'exists|available' > /dev/null
  if [ $? == 0 ]; then
    version="N/A"
  fi
  echo "$serial" | /bin/grep -E 'exists|available' > /dev/null
  if [ $? == 0 ]; then
    serial="N/A"
  fi
  echo "$location" | /bin/grep -E 'exists|available' > /dev/null
  if [ $? == 0 ]; then
    location="N/A"
  fi
  echo "$contact" | /bin/grep -E 'exists|available' > /dev/null
  if [ $? == 0 ]; then
    contact="N/A"
  fi

  # Check for empty variables
  if [ -z "$hostname" ]; then
    hostname="N/A"
  fi
  if [ -z "$model" ]; then
    model="N/A"
  fi
  if [ -z "$version" ]; then
    version="N/A"
  fi
  if [ -z "$serial" ]; then
    serial="N/A"
  fi
  if [ -z "$location" ]; then
    location="N/A"
  fi
  if [ -z "$contact" ]; then
    contact="N/A"
  fi

  # Edit this line if you want the output in some other order or format
  echo ""$hostname",<br> "$model",<br> "$version",<br> "$serial",<br> "$location",<br> "$contact""
  exit 0
}


# Make sure that this points to snmpget
SNMPGET="/usr/bin/snmpget"

if [ $# == 6 ]; then
  SNMPOPT="-v 3 -l authPriv -u $2 -a $3 -A $4 -x $5 -X $6 $1 -Ov -t 0.5 -Lo"
fi 

if [ $# == 2 ]; then
  SNMPOPT="-v 2c -c $2 $1 -Ov -t 0.5 -Lo"
fi

if [ $# != 2 ] && [ $# != 6 ]; then
  echo "Wrong amount of arguments!"
  echo
  echo "Usage:"
  echo "SNMPv2c: ./snmp_cisco_info.sh HOSTNAME community"
  echo "SNMPv3: ./snmp_cisco_info.sh HOSTNAME username MD5/SHA authpass DES/AES privpass"
  exit 3
fi


# Handle SNMP timeout
hostname=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.1.5.0`
if [ $? != 0 ]; then
  hostname="N/A"
  model="N/A"
  version="N/A"
  serial="N/A"
  location="N/A"
  contact="N/A"
  print_and_exit "$hostname" "$model" "$version" "$serial" "$location" "$contact"  
fi

hostname=`echo "$hostname" | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
# Handle SNMP error (Usually due to no SNMPv3 support)
echo "$hostname" | /bin/grep 'snmpget' > /dev/null
if [ $? == 0 ]; then
  hostname="N/A"
  model="N/A"
  version="N/A"
  serial="N/A"
  location="N/A"
  contact="N/A"
  print_and_exit "$hostname" "$model" "$version" "$serial" "$location" "$contact"
fi

# Location and contact should be the same for all devices
location=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.1.6.0 | /bin/sed -e 's/\STRING: //g' | tr '[<>]' '_'`
contact=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.1.4.0 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`

# This work for many Cisco switches
model=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.2.1001 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`

# 6807
echo "$model" | /bin/grep '6807' > /dev/null
if [ $? == 0 ]; then
  model=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.13.1000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
  version=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.10.3000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[,]' '_'`
  serial=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.1000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
  serial2=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.2000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
  echo "$serial2" | /bin/grep -v 'exists' > /dev/null
  if [ $? == 0 ]; then
    model2=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.13.2000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_i'`
    serial=`printf "%s, %s" "$serial" "$serial2"`
    model=`printf "%s, %s" "$model" "$model2"`
    version=`printf "%s, %s" "$version" "$version"`
  fi
  print_and_exit "$hostname" "$model" "$version" "$serial" "$location" "$contact"
fi

# These work for many Cisco switches
version=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.10.1001 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
serial=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.1001 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`

# Cisco routers
echo "$version" | /bin/grep 'exists' > /dev/null
if [ $? == 0 ]; then
  version=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.10.1 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[,]' '_'`
fi

# Cisco Nexus
echo "$version" | /bin/grep 'exists' > /dev/null
if [ $? == 0 ]; then
  version=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.10.22 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[,]' '_'`
fi

# Cisco 4500
if [ -z "$version" ]; then
  version=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.10.1000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[,]' '_'`
fi

# Cisco 6500 New IOS
if [ -z "$version" ]; then
  version=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.10.10000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[,]' '_'`
fi

# Cisco 4500 new IOS and C6807-XL
echo "$version" | /bin/grep 'exists' > /dev/null
if [ $? == 0 ]; then
  version=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.10.3000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[,]' '_'`
fi


######################## model #######################

# Cisco routers
echo "$model" | /bin/grep 'exists' > /dev/null
if [ $? == 0 ]; then
  model=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.2.1 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
fi

# Cisco Nexus
echo "$model" | /bin/grep 'exists' > /dev/null
if [ $? == 0 ]; then
  model=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.13.10 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
fi

# Some old Cisco ASR IOS
echo "$model" | /bin/grep 'V1' > /dev/null
if [ $? == 0 ]; then
  model=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.2.1 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
fi


#################### serial ############################

# Cisco routers
echo "$serial" | /bin/grep 'exists' > /dev/null
if [ $? == 0 ]; then
  serial=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.1 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
fi

# Cisco Nexus
echo "$serial" | /bin/grep 'exists' > /dev/null
if [ $? == 0 ]; then
  serial=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.10 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
fi


#################### Specific cases ############################

# Cisco 4500 VSS
$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.2.2 | /bin/grep 'WS-C45' > /dev/null
if [ $? == 0 ]; then
  model=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.2.2 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | /bin/sed -e 's/\Cisco Systems, Inc. //g' | cut -d' ' -f1`
  serial=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.2 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
  serial2=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.500 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
  echo "$serial2" | /bin/grep -v 'exists' > /dev/null
  if [ $? == 0 ]; then
    model2=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.2.500 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | /bin/sed -e 's/\Cisco Systems, Inc. //g' | cut -d' ' -f1`
    serial=`printf "%s, %s" "$serial" "$serial2"`
    model=`printf "%s, %s" "$model" "$model2"`
    version=`printf "%s, %s" "$version" "$version"` 
  fi

  # Cisco 4500 older versions
  if [ -z "$serial" ]; then
    serial=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.1 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
  fi

  # Cisco 4500 new IOS
  if [ -z "$serial" ]; then
    serial=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.2 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
  fi

  print_and_exit "$hostname" "$model" "$version" "$serial" "$location" "$contact"
fi

# Cisco 6500
echo "$model" | /bin/grep 'Chassis' | /bin/grep -Ev 'C3850|ASR' > /dev/null
if [ $? == 0 ]; then
  model=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.7.1000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
  serial=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.1000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
  echo "$model" | /bin/grep -v 'WS' > /dev/null
  if [ $? == 0 ]; then
    model=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.7.2 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
    serial=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.2 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
  fi
  model2=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.7.2000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
  serial2=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.2000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
  echo "$model2" | /bin/grep -v 'WS' > /dev/null
  if [ $? == 0 ]; then
    model2=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.7.3000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
    serial2=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.3000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
    echo "$model2" | /bin/grep -v 'WS' > /dev/null
    if [ $? == 0 ]; then
      model2=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.7.4000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
      serial2=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.4000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
      echo "$model2" | /bin/grep -v 'WS' > /dev/null
      if [ $? == 0 ]; then
        model2=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.7.5000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
        serial2=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.5000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
        echo "$model2" | /bin/grep -v 'WS' > /dev/null
        if [ $? == 0 ]; then
          model2=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.7.6000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
          serial2=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.6000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
          echo "$model2" | /bin/grep -v 'WS' > /dev/null
          if [ $? == 0 ]; then
            model2=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.7.7000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
            serial2=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.7000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
          fi
        fi
      fi
    fi
  fi
  model=`printf "%s, %s" "$model" "$model2"`
  serial=`printf "%s, %s" "$serial" "$serial2"`
  version=`printf "%s, %s" "$version" "$version"`
  print_and_exit "$hostname" "$model" "$version" "$serial" "$location" "$contact"
fi

# Cisco C3850
echo "$model" | /bin/grep -E 'C3850|StackPort' > /dev/null
if [ $? == 0 ]; then
  model=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.2.1000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
  serial=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.1000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
  serial2=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.2000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
  echo "$serial2" | /bin/grep 'exists' > /dev/null
  if [ $? == 1 ]; then
    serial=`printf "%s, %s" "$serial" "$serial2"`
    version2=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.10.2000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
    version=`printf "%s, %s" "$version" "$version2"`
    model2=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.2.2000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
    model=`printf "%s, %s" "$model" "$model2"`
    serial3=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.3000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
    echo "$serial3" | /bin/grep 'exists' > /dev/null
    if [ $? == 1 ]; then
      serial=`printf "%s, %s" "$serial" "$serial3"`
      version3=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.10.3000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
      version=`printf "%s, %s" "$version" "$version3"`
      model3=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.2.3000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
      model=`printf "%s, %s" "$model" "$model3"`
      serial4=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.4000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
      echo "$serial4" | /bin/grep 'exists' > /dev/null
      if [ $? == 1 ]; then
        serial=`printf "%s, %s" "$serial" "$serial4"`
        version4=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.10.4000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
        version=`printf "%s, %s" "$version" "$version4"`
        model4=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.2.4000 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
        model=`printf "%s, %s" "$model" "$model4"`
      fi
    fi
  fi
  print_and_exit "$hostname" "$model" "$version" "$serial" "$location" "$contact"
fi

# Cisco C2960S, C2960X and C3750 stack members
echo "$model" | /bin/grep -E 'C2960S|C2960X|C3750' > /dev/null
if [ $? == 0 ]; then
  serial2=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.2001 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
  echo "$serial2" | /bin/grep 'exists' > /dev/null
  if [ $? == 1 ]; then
    serial=`printf "%s, %s" "$serial" "$serial2"`
    version2=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.10.2001 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
    version=`printf "%s, %s" "$version" "$version2"`
    model2=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.2.2001 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
    model=`printf "%s, %s" "$model" "$model2"`
    serial3=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.3001 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
    echo "$serial3" | /bin/grep 'exists' > /dev/null
    if [ $? == 1 ]; then
      serial=`printf "%s, %s" "$serial" "$serial3"`
      version3=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.10.2001 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
      version=`printf "%s, %s" "$version" "$version3"`
      model3=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.2.3001 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
      model=`printf "%s, %s" "$model" "$model3"`
      serial4=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.4001 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
      echo "$serial4" | /bin/grep 'exists' > /dev/null
      if [ $? == 1 ]; then
        serial=`printf "%s, %s" "$serial" "$serial4"`
        version4=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.10.2001 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
        version=`printf "%s, %s" "$version" "$version4"`
        model4=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.2.4001 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
        model=`printf "%s, %s" "$model" "$model4"`
	serial5=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.5001 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
        echo "$serial5" | /bin/grep 'exists' > /dev/null
        if [ $? == 1 ]; then
          serial=`printf "%s, %s" "$serial" "$serial5"`
          version5=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.10.2001 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
          version=`printf "%s, %s" "$version" "$version5"`
          model5=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.2.5001 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
          model=`printf "%s, %s" "$model" "$model5"`
          serial6=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.6001 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
          echo "$serial6" | /bin/grep 'exists' > /dev/null
          if [ $? == 1 ]; then
            serial=`printf "%s, %s" "$serial" "$serial6"`
            version6=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.10.2001 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
            version=`printf "%s, %s" "$version" "$version6"`
            model6=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.2.6001 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
            model=`printf "%s, %s" "$model" "$model6"`
            serial7=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.7001 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
            echo "$serial7" | /bin/grep 'exists' > /dev/null
            if [ $? == 1 ]; then
              serial=`printf "%s, %s" "$serial" "$serial7"`
              version7=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.10.2001 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
              version=`printf "%s, %s" "$version" "$version7"`
              model7=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.2.7001 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
              model=`printf "%s, %s" "$model" "$model7"`
              serial8=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.11.8001 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
              echo "$serial8" | /bin/grep 'exists' > /dev/null
              if [ $? == 1 ]; then
                serial=`printf "%s, %s" "$serial" "$serial8"`
                version8=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.10.2001 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
                version=`printf "%s, %s" "$version" "$version8"`
                model8=`$SNMPGET $SNMPOPT .1.3.6.1.2.1.47.1.1.1.1.2.8001 | /bin/sed -e 's/\STRING: //g' | /bin/sed -e 's/\"//g' | tr '[<>]' '_'`
                model=`printf "%s, %s" "$model" "$model8"`
              fi
            fi
          fi
        fi
      fi
    fi
  fi
  print_and_exit "$hostname" "$model" "$version" "$serial" "$location" "$contact"
fi


print_and_exit "$hostname" "$model" "$version" "$serial" "$location" "$contact"

