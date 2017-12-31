import netifaces
import socket
import struct


def get_default_gateway_linux():
    """Read the default gateway directly from /proc."""
    with open("/proc/net/route") as fh:
        for line in fh:
            fields = line.strip().split()
            if fields[1] != "00000000" or not int(fields[3], 16) & 2:
                continue

            return socket.inet_ntoa(struct.pack("<L", int(fields[2], 16)))


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

        values.append({
            "iface": iface,
            "values": [
                addrs[0],
                gateway
            ]
        })
    except:
        # Do nothing
        values.append({
            "iface": iface,
            "values": None
        })

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
