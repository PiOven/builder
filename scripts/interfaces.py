import netifaces
import os
import socket
import struct


def decimal_to_ip(decimal):
    return socket.inet_ntoa(struct.pack('!L', decimal))


def get_default_gateway_linux():
    """Read the default gateway directly from /proc."""
    with open("/proc/net/route") as fh:
        for line in fh:
            fields = line.strip().split()
            if fields[1] != "00000000" or not int(fields[3], 16) & 2:
                continue

            return socket.inet_ntoa(struct.pack("<L", int(fields[2], 16)))


def get_ip_address(start_ip, end_ip):
    start_ip_decimal = ip_to_decimal(start_ip)
    end_ip_decimal = ip_to_decimal(end_ip)
    target_ip = None

    # Try each of these
    for current_ip_decimal in range(start_ip_decimal, end_ip_decimal + 1):
        current_ip = decimal_to_ip(current_ip_decimal)

        try:
            # The IP is in use
            socket.gethostbyaddr(current_ip)
            continue
        except socket.herror:
            # The IP address is free
            target_ip = current_ip
            break

    if target_ip is None:
        raise Exception('Unable to find a free IP address between ' + start_ip + ' and ' + end_ip)

    return target_ip


def ip_to_decimal(ip):
    packed_ip = socket.inet_aton(ip)
    return struct.unpack("!L", packed_ip)[0]


ifaces = [
    "eth0",
    "wlan0",
    "wlan1"
]

values = []

for iface in ifaces:
    try:
        gateway = get_default_gateway_linux()
        addrs = netifaces.ifaddresses(iface)[netifaces.AF_INET]

        start_ip = os.environ.get('PI_IP_ADDRESS_RANGE_START')
        end_ip = os.environ.get('PI_IP_ADDRESS_RANGE_END')

        if start_ip is not None and end_ip is not None:
            # We've got an IP address range set
            addrs[0]['addr'] = get_ip_address(start_ip, end_ip)

        values.append({
            "iface": iface,
            "values": [
                addrs[0],
                gateway
            ]
        })
    except Exception as err:
        """
        Do nothing
        """

if len(values) == 0:
    raise Exception('No interfaces available')

"""
Do the output
"""
print "# interfaces(5) file used by ifup(8) and ifdown(8)"
print ""
print "# Please note that this file is written to be used with dhcpcd"
print "# For static IP, consult /etc/dhcpcd.conf and \"man dhcpcd.conf\""
print ""
print "# Include files from /etc/network/interfaces.d:"
print "source-directory /etc/network/interfaces.d"
print ""
print "auto lo"
print "iface lo inet loopback"
print ""

for value in values:
    iface = value['iface']
    values = value['values']

    if iface.startswith("wlan"):
        print "allow-hotplug " + iface

    if values:
        print "iface " + iface + " inet static"
        print "    address " + values[0]["addr"]
        print "    netmask " + values[0]["netmask"]
        print "    gateway " + values[1]
    else:
        print "iface " + iface + " inet manual"

    if iface.startswith("wlan"):
        print "    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf"

    print ""
